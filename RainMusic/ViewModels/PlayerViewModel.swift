import SwiftUI

@Observable
class PlayerViewModel {
    private let audioManager = AudioPlayerManager.shared
    
    var currentSong: Song? { audioManager.currentSong }
    var isPlaying: Bool { audioManager.isPlaying }
    var currentTime: Double { audioManager.currentTime }
    var duration: Double { audioManager.duration }
    var volume: Float { audioManager.volume }
    var shuffleMode: ShuffleMode { audioManager.shuffleMode }
    var repeatMode: RepeatMode { audioManager.repeatMode }
    var lyrics: [LyricLine] { audioManager.lyrics }
    var currentLyricIndex: Int { audioManager.currentLyricIndex }
    var showLyrics: Bool { audioManager.showLyrics }
    var playlist: [Song] { audioManager.playlist }
    var currentIndex: Int { audioManager.currentIndex }
    
    var currentTimeFormatted: String { audioManager.currentTimeFormatted }
    var durationFormatted: String { audioManager.durationFormatted }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    init() {}
    
    func play(song: Song) {
        audioManager.play(song: song)
    }
    
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
    
    func setVolume(_ volume: Float) {
        audioManager.setVolume(volume)
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
        audioManager.toggleLyrics()
    }
    
    func updateLyrics() {
        audioManager.updateLyrics()
    }
    
    func formatTime(_ time: Double) -> String {
        audioManager.formatTime(time)
    }
}