import Foundation
import SwiftUI

@Observable
final class PlayerViewModel {
    // MARK: - State
    var lyrics: [LyricLine] = []
    var currentLyricIndex: Int = -1
    var showLyrics: Bool = false

    // MARK: - Dependencies
    private let audioManager = AudioPlayerManager.shared
    private var lastSongID: UUID?

    // MARK: - Computed Properties

    var currentSong: Song? {
        audioManager.currentSong
    }

    var isPlaying: Bool {
        audioManager.isPlaying
    }

    var currentTime: Double {
        audioManager.currentTime
    }

    var duration: Double {
        audioManager.duration
    }

    var volume: Float {
        get { audioManager.volume }
        set { audioManager.setVolume(newValue) }
    }

    var shuffleMode: ShuffleMode {
        audioManager.shuffleMode
    }

    var repeatMode: RepeatMode {
        audioManager.repeatMode
    }

    var currentTimeFormatted: String {
        formatTime(currentTime)
    }

    var durationFormatted: String {
        formatTime(duration)
    }

    var currentLyricText: String {
        guard currentLyricIndex >= 0 && currentLyricIndex < lyrics.count else {
            return "暂无歌词"
        }
        return lyrics[currentLyricIndex].text
    }

    // MARK: - Init

    init() {
        // 监听歌曲变化加载歌词
        checkSongChange()
    }

    // MARK: - Playback Control

    func togglePlayPause() {
        audioManager.togglePlayPause()
    }

    func playNext() {
        audioManager.playNext()
    }

    func playPrevious() {
        audioManager.playPrevious()
    }

    func seek(to time: Double) {
        audioManager.seek(to: time)
    }

    func setPlaylist(_ songs: [Song], startIndex: Int = 0) {
        audioManager.setPlaylist(songs, startIndex: startIndex)
    }

    func toggleShuffle() {
        audioManager.toggleShuffle()
    }

    func cycleRepeatMode() {
        audioManager.cycleRepeatMode()
    }

    func toggleLyrics() {
        showLyrics.toggle()
    }

    // MARK: - Update

    func update() {
        checkSongChange()
        updateLyricIndex()
    }

    private func checkSongChange() {
        guard let song = currentSong else { return }

        if song.id != lastSongID {
            lastSongID = song.id
            loadLyrics(for: song)
        }
    }

    private func loadLyrics(for song: Song) {
        if let loadedLyrics = LyricsParser.loadLyrics(for: song) {
            lyrics = loadedLyrics
        } else {
            lyrics = []
        }
        currentLyricIndex = -1
    }

    private func updateLyricIndex() {
        guard !lyrics.isEmpty else {
            currentLyricIndex = -1
            return
        }

        let newIndex = LyricsParser.currentLineIndex(in: lyrics, at: currentTime)
        if newIndex != currentLyricIndex {
            currentLyricIndex = newIndex
        }
    }

    // MARK: - Helpers

    private func formatTime(_ time: Double) -> String {
        guard time.isFinite && !time.isNaN else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
