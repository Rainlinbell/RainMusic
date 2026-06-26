import Foundation
import AVFoundation
import MediaPlayer
import SwiftUI
import UIKit

enum ShuffleMode {
    case off
    case on
}

enum RepeatMode {
    case off
    case one
    case all
}

@Observable
final class AudioPlayerManager: NSObject {
    static let shared = AudioPlayerManager()

    // MARK: - Published State
    var currentSong: Song?
    var isPlaying: Bool = false
    var currentTime: Double = 0
    var duration: Double = 0
    var volume: Float = 0.8 {
        didSet {
            player?.volume = volume
            syncSystemVolume(to: volume)
        }
    }
    var shuffleMode: ShuffleMode = .off
    var repeatMode: RepeatMode = .off
    var playlist: [Song] = []
    var currentIndex: Int = -1

    // MARK: - Private
    private var player: AVAudioPlayer?
    private var progressTimer: Timer?
    private var lastSongID: UUID?
    private var volumeSlider: UISlider?  // 隐藏的系统音量控制
    private var volumeObservation: NSKeyValueObservation?  // 监听系统音量变化

    // MARK: - Init
    private override init() {
        super.init()
        setupSystemVolume()
        setupRemoteCommands()
        setupInterruptionHandling()
        setupRouteChangeHandling()
    }

    // MARK: - System Volume Sync

    private func setupSystemVolume() {
        // 创建隐藏的 MPVolumeView 用于控制系统音量
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.showsRouteButton = false
        volumeView.showsVolumeSlider = false
        // 必须添加到视图层级才能工作
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first {
            window.addSubview(volumeView)
            volumeView.isHidden = true
        }

        // 获取 MPVolumeView 内部的 slider
        volumeSlider = volumeView.subviews.compactMap({ $0 as? UISlider }).first

        // 从系统音量读取初始值
        let systemVol = AVAudioSession.sharedInstance().outputVolume
        self.volume = systemVol
        player?.volume = systemVol

        // KVO 监听系统音量变化（硬件音量键）
        volumeObservation = AVAudioSession.sharedInstance().observe(
            \.outputVolume,
            options: [.new]
        ) { [weak self] session, _ in
            let newVol = session.outputVolume
            if let self = self, abs(self.volume - newVol) > 0.01 {
                self.volume = newVol
                self.player?.volume = newVol
            }
        }
    }

    private func syncSystemVolume(to vol: Float) {
        // 通过 MPVolumeView 的 slider 设置系统音量
        volumeSlider?.setValue(vol, animated: false)
    }

    // MARK: - Playback Control

    func play(song: Song) {
        // 如果已经在播放同一首歌，跳过
        if currentSong?.id == song.id, player != nil {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: song.fileURL)
            player.delegate = self
            player.prepareToPlay()
            player.volume = volume
            player.play()

            self.player = player
            self.currentSong = song
            self.isPlaying = true
            self.duration = player.duration
            self.currentTime = 0

            // 更新播放列表索引
            if let index = playlist.firstIndex(where: { $0.id == song.id }) {
                self.currentIndex = index
            }

            startProgressTimer()
            updateNowPlayingInfo()

        } catch {
            print("⚠️ 播放失败: \(error.localizedDescription)")
        }
    }

    func togglePlayPause() {
        guard let player = player else { return }

        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        updateNowPlayingInfo()
    }

    func playNext() {
        guard !playlist.isEmpty else { return }

        let nextIndex = getNextIndex()
        if let nextIndex = nextIndex, nextIndex < playlist.count {
            currentIndex = nextIndex
            play(song: playlist[nextIndex])
        }
    }

    func playPrevious() {
        guard !playlist.isEmpty else { return }

        // 如果播放超过3秒，重头开始
        if currentTime > 3 {
            seek(to: 0)
            return
        }

        let prevIndex = getPreviousIndex()
        if let prevIndex = prevIndex, prevIndex >= 0 {
            currentIndex = prevIndex
            play(song: playlist[prevIndex])
        } else {
            seek(to: 0)
        }
    }

    func seek(to time: Double) {
        player?.currentTime = time
        currentTime = time
        updateNowPlayingInfo()
    }

    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
    }

    func setPlaylist(_ songs: [Song], startIndex: Int = 0) {
        playlist = songs
        if startIndex >= 0 && startIndex < songs.count {
            currentIndex = startIndex
            play(song: songs[startIndex])
        }
    }

    func toggleShuffle() {
        shuffleMode = shuffleMode == .off ? .on : .off
    }

    func cycleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .off
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        stopProgressTimer()
        clearNowPlayingInfo()
    }

    // MARK: - Queue Logic

    private func getNextIndex() -> Int? {
        guard !playlist.isEmpty else { return nil }

        switch (shuffleMode, repeatMode) {
        case (_, .one):
            return currentIndex
        case (.on, _):
            if playlist.count == 1 { return 0 }
            var next = Int.random(in: 0..<playlist.count)
            while next == currentIndex {
                next = Int.random(in: 0..<playlist.count)
            }
            return next
        case (.off, .all):
            return (currentIndex + 1) % playlist.count
        case (.off, .off):
            return (currentIndex + 1) % playlist.count
        }
    }

    private func getPreviousIndex() -> Int? {
        guard !playlist.isEmpty else { return nil }

        switch repeatMode {
        case .one:
            return currentIndex
        case .all:
            let prev = currentIndex - 1
            return prev >= 0 ? prev : playlist.count - 1
        case .off:
            let prev = currentIndex - 1
            return prev >= 0 ? prev : nil
        }
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            self.currentTime = player.currentTime
            self.updateNowPlayingInfo()
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - Now Playing Info

    private func updateNowPlayingInfo() {
        guard let song = currentSong else { return }

        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPMediaItemPropertyAlbumTitle: song.album,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        // 添加封面
        if let artData = song.albumArtData, let image = UIImage(data: artData) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Remote Commands

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: event.position)
            return .success
        }

        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.seek(to: (self?.currentTime ?? 0) + 15)
            return .success
        }

        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.seek(to: max(0, (self?.currentTime ?? 0) - 15))
            return .success
        }
    }

    // MARK: - Interruption Handling

    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // 中断开始（如来电），暂停播放
            if isPlaying {
                player?.pause()
                isPlaying = false
                updateNowPlayingInfo()
            }
        case .ended:
            // 中断结束
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    player?.play()
                    isPlaying = true
                    updateNowPlayingInfo()
                }
            }
        @unknown default:
            break
        }
    }

    // MARK: - Route Change Handling

    private func setupRouteChangeHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        if reason == .oldDeviceUnavailable {
            // 拔出耳机，暂停播放
            if isPlaying {
                player?.pause()
                isPlaying = false
                updateNowPlayingInfo()
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            playNext()
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("⚠️ 解码错误: \(error?.localizedDescription ?? "未知")")
        playNext()
    }
}
