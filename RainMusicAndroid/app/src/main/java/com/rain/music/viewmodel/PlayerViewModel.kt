package com.rain.music.viewmodel

import android.app.Application
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.rain.music.data.db.MusicDatabase
import com.rain.music.data.model.Song
import com.rain.music.manager.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

enum class SortOrder { DATE_ADDED, TITLE, ARTIST, ALBUM }

class PlayerViewModel(application: Application) : AndroidViewModel(application) {

    private val database = MusicDatabase.getInstance(application)
    private val songDao = database.songDao()
    private val musicScanner = MusicScanner(application, songDao)
    private val audioPlayerManager = AudioPlayerManager(application)

    // 歌曲列表
    private val _sortOrder = MutableStateFlow(SortOrder.DATE_ADDED)
    val sortOrder: StateFlow<SortOrder> = _sortOrder

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery

    val songs: StateFlow<List<Song>> = combine(
        _sortOrder,
        _searchQuery,
        ::Pair
    ).flatMapLatest { (sort, query) ->
        val flow = when {
            query.isNotBlank() -> musicScanner.searchSongs(query)
            else -> when (sort) {
                SortOrder.DATE_ADDED -> musicScanner.getAllSongs()
                SortOrder.TITLE -> musicScanner.getSongsByTitle()
                SortOrder.ARTIST -> musicScanner.getSongsByArtist()
                SortOrder.ALBUM -> musicScanner.getSongsByAlbum()
            }
        }
        flow
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

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

    // 扫描状态
    private val _isScanning = MutableStateFlow(false)
    val isScanning: StateFlow<Boolean> = _isScanning

    private val _scanResult = MutableStateFlow<String?>(null)
    val scanResult: StateFlow<String?> = _scanResult

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
    fun playNext() = audioPlayerManager.playNext()
    fun playPrevious() = audioPlayerManager.playPrevious()
    fun seekTo(position: Long) = audioPlayerManager.seekTo(position)
    fun setVolume(volume: Float) = audioPlayerManager.setVolume(volume)

    fun setPlaylist(songs: List<Song>, startIndex: Int = 0) {
        audioPlayerManager.setPlaylist(songs, startIndex)
    }

    fun toggleShuffle() = audioPlayerManager.toggleShuffle()
    fun cycleRepeatMode() = audioPlayerManager.cycleRepeatMode()
    fun toggleLyrics() { _showLyrics.value = !_showLyrics.value }

    // 排序
    fun setSortOrder(order: SortOrder) { _sortOrder.value = order }
    fun setSearchQuery(query: String) { _searchQuery.value = query }

    // 扫描
    fun scanMusic() {
        viewModelScope.launch {
            _isScanning.value = true
            try {
                val count = musicScanner.scanDeviceMusic()
                _scanResult.value = if (count > 0) "扫描完成，新增 $count 首歌曲" else "未找到新歌曲"
            } catch (e: Exception) {
                _scanResult.value = "扫描失败: ${e.message}"
            } finally {
                _isScanning.value = false
            }
        }
    }

    // 导入
    fun importFile(uri: Uri) {
        viewModelScope.launch {
            val song = musicScanner.importFile(uri)
            if (song != null) {
                _scanResult.value = "导入成功: ${song.title}"
            }
        }
    }

    // 删除
    fun deleteSong(song: Song) {
        viewModelScope.launch {
            musicScanner.deleteSong(song)
        }
    }

    // 更新封面
    fun updateAlbumArt(songId: Long, newArtUri: String) {
        viewModelScope.launch {
            val song = songDao.getSongById(songId)
            if (song != null) {
                // 删除旧封面文件
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
