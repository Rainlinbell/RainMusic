package com.rain.music.viewmodel

import android.app.Application
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.content.ContextCompat
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.rain.music.data.db.MusicDatabase
import com.rain.music.data.model.Song
import com.rain.music.manager.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

enum class SortOrder { DATE_ADDED, TITLE, ARTIST, ALBUM }

class LibraryViewModel(application: Application) : AndroidViewModel(application) {

    private val database = MusicDatabase.getInstance(application)
    private val songDao = database.songDao()
    private val musicScanner = MusicScanner(application, songDao)

    // 歌曲列表 + 排序 + 搜索
    private val _sortOrder = MutableStateFlow(SortOrder.DATE_ADDED)
    val sortOrder: StateFlow<SortOrder> = _sortOrder

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery

    @OptIn(ExperimentalCoroutinesApi::class)
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

    // 扫描状态
    private val _isScanning = MutableStateFlow(false)
    val isScanning: StateFlow<Boolean> = _isScanning

    private val _scanResult = MutableStateFlow<String?>(null)
    val scanResult: StateFlow<String?> = _scanResult

    // 排序
    fun setSortOrder(order: SortOrder) { _sortOrder.value = order }
    fun setSearchQuery(query: String) { _searchQuery.value = query }

    // 扫描
    fun scanMusic() {
        viewModelScope.launch {
            val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                android.Manifest.permission.READ_MEDIA_AUDIO
            } else {
                android.Manifest.permission.READ_EXTERNAL_STORAGE
            }
            val granted = ContextCompat.checkSelfPermission(
                getApplication(), permission
            ) == PackageManager.PERMISSION_GRANTED

            if (!granted) {
                _scanResult.value = "未获得存储权限，请在系统设置中授权"
                return@launch
            }

            _isScanning.value = true
            try {
                val count = musicScanner.scanDeviceMusic()
                _scanResult.value = if (count > 0) "扫描完成，新增 $count 首歌曲" else "未找到新歌曲"
            } catch (e: Throwable) {
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
}
