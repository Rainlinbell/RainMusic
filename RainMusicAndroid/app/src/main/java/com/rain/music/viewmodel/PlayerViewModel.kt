package com.rain.music.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.rain.music.data.db.MusicDatabase
import com.rain.music.data.model.Song
import com.rain.music.manager.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

class PlayerViewModel(application: Application) : AndroidViewModel(application) {

    private val audioPlayerManager = AudioPlayerManager(application)
    private val songDao = MusicDatabase.getInstance(application).songDao()

    // 播放状态
    val currentSong = audioPlayerManager.currentSong
    val isPlaying = audioPlayerManager.isPlaying
    val currentTime = audioPlayerManager.currentTime
    val duration = audioPlayerManager.duration
    val shuffleMode = audioPlayerManager.shuffleMode
    val repeatMode = audioPlayerManager.repeatMode
    val systemVolume = audioPlayerManager.systemVolume

    // 歌词
    private val _lyrics = MutableStateFlow<List<LyricLine>>(emptyList())
    val lyrics: StateFlow<List<LyricLine>> = _lyrics

    private val _currentLyricIndex = MutableStateFlow(-1)
    val currentLyricIndex: StateFlow<Int> = _currentLyricIndex

    private val _showLyrics = MutableStateFlow(false)
    val showLyrics: StateFlow<Boolean> = _showLyrics

    init {
        audioPlayerManager.initialize()

        // 监听歌曲变化加载歌词
        viewModelScope.launch {
            currentSong.collect { song ->
                if (song != null) {
                    _lyrics.value = LyricsParser.loadLyrics(song) ?: emptyList()
                    _currentLyricIndex.value = -1
                }
            }
        }

        // 更新歌词索引
        viewModelScope.launch {
            currentTime.collect { time ->
                if (_lyrics.value.isNotEmpty()) {
                    _currentLyricIndex.value = LyricsParser.findCurrentLineIndex(_lyrics.value, time)
                }
            }
        }
    }

    // 播放控制
    fun play(song: Song) = audioPlayerManager.play(song)
    fun togglePlayPause() = audioPlayerManager.togglePlayPause()
    fun seekTo(position: Long) = audioPlayerManager.seekTo(position)
    fun setVolume(volume: Float) = audioPlayerManager.setVolume(volume)

    fun setPlaylist(songs: List<Song>, startIndex: Int = 0) {
        audioPlayerManager.setPlaylist(songs, startIndex)
    }

    fun playNext(songs: List<Song> = emptyList()) {
        if (audioPlayerManager.playlist.isEmpty() && songs.isNotEmpty()) {
            val currentIndex = songs.indexOfFirst { it.id == currentSong.value?.id }
            audioPlayerManager.setPlaylist(songs, if (currentIndex >= 0) currentIndex else 0)
            return
        }
        audioPlayerManager.playNext()
    }

    fun playPrevious(songs: List<Song> = emptyList()) {
        if (audioPlayerManager.playlist.isEmpty() && songs.isNotEmpty()) {
            val currentIndex = songs.indexOfFirst { it.id == currentSong.value?.id }
            audioPlayerManager.setPlaylist(songs, if (currentIndex >= 0) currentIndex else 0)
            return
        }
        audioPlayerManager.playPrevious()
    }

    fun toggleShuffle() = audioPlayerManager.toggleShuffle()
    fun cycleRepeatMode() = audioPlayerManager.cycleRepeatMode()
    fun toggleLyrics() { _showLyrics.value = !_showLyrics.value }

    // 更新封面
    fun updateAlbumArt(songId: Long, newArtUri: String) {
        viewModelScope.launch {
            val song = songDao.getSongById(songId)
            if (song != null) {
                song.albumArtUri?.let { oldUri ->
                    try { java.io.File(oldUri).delete() } catch (_: Exception) {}
                }
                songDao.update(song.copy(albumArtUri = newArtUri))
            }
        }
    }

    // 格式化时间
    fun formatTime(ms: Long): String {
        val totalSeconds = ms / 1000
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return String.format("%d:%02d", minutes, seconds)
    }

    override fun onCleared() {
        super.onCleared()
        audioPlayerManager.release()
    }
}
