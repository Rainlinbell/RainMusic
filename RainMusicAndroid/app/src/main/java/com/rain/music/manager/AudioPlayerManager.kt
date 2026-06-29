package com.rain.music.manager

import android.content.ComponentName
import android.content.Context
import android.media.AudioManager
import android.net.Uri
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.google.common.util.concurrent.ListenableFuture
import com.google.common.util.concurrent.MoreExecutors
import com.rain.music.data.model.Song
import com.rain.music.service.MusicService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

enum class ShuffleMode { OFF, ON }
enum class RepeatMode { OFF, ONE, ALL }

class AudioPlayerManager(private val context: Context) {

    private var controllerFuture: ListenableFuture<MediaController>? = null
    private var mediaController: MediaController? = null
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    // UI 状态
    private val _currentSong = MutableStateFlow<Song?>(null)
    val currentSong: StateFlow<Song?> = _currentSong

    private val _isPlaying = MutableStateFlow(false)
    val isPlaying: StateFlow<Boolean> = _isPlaying

    private val _currentTime = MutableStateFlow(0L)
    val currentTime: StateFlow<Long> = _currentTime

    private val _duration = MutableStateFlow(0L)
    val duration: StateFlow<Long> = _duration

    private val _shuffleMode = MutableStateFlow(ShuffleMode.OFF)
    val shuffleMode: StateFlow<ShuffleMode> = _shuffleMode

    private val _repeatMode = MutableStateFlow(RepeatMode.OFF)
    val repeatMode: StateFlow<RepeatMode> = _repeatMode

    // 音量（ExoPlayer 无极 + 系统音量同步）
    private val _systemVolume = MutableStateFlow(getSystemVolume())
    val systemVolume: StateFlow<Float> = _systemVolume

    private val handler = android.os.Handler(android.os.Looper.getMainLooper())

    private val volumeChecker = object : Runnable {
        override fun run() {
            val newVol = getSystemVolume()
            if (kotlin.math.abs(newVol - _systemVolume.value) > 0.01f) {
                _systemVolume.value = newVol
                // 硬件音量键变化时同步到 ExoPlayer
                mediaController?.volume = newVol
            }
            handler.postDelayed(this, 500)
        }
    }

    private val progressUpdater = object : Runnable {
        override fun run() {
            mediaController?.let {
                _currentTime.value = it.currentPosition
            }
            handler.postDelayed(this, 500)
        }
    }

    var playlist: List<Song> = emptyList()
    var currentIndex: Int = -1

    fun initialize() {
        val sessionToken = SessionToken(context, ComponentName(context, MusicService::class.java))
        controllerFuture = MediaController.Builder(context, sessionToken).buildAsync()
        controllerFuture?.addListener({
            mediaController = controllerFuture?.let {
                try { it.get() } catch (e: Exception) { null }
            }
            // 初始化时同步系统音量到 ExoPlayer
            mediaController?.volume = getSystemVolume()
            setupPlayerListener()
        }, MoreExecutors.directExecutor())

        // 启动系统音量监听（检测硬件音量键变化）
        handler.post(volumeChecker)
    }

    private fun setupPlayerListener() {
        mediaController?.addListener(object : Player.Listener {
            override fun onIsPlayingChanged(isPlaying: Boolean) {
                _isPlaying.value = isPlaying
                // 仅在播放时启动进度更新，暂停时停止
                if (isPlaying) {
                    handler.post(progressUpdater)
                } else {
                    handler.removeCallbacks(progressUpdater)
                }
            }

            override fun onMediaMetadataChanged(mediaMetadata: MediaMetadata) {
                // 更新进度
            }

            override fun onPlaybackStateChanged(playbackState: Int) {
                if (playbackState == Player.STATE_READY) {
                    _duration.value = mediaController?.duration ?: 0L
                }
                if (playbackState == Player.STATE_ENDED) {
                    playNext()
                }
            }
        })
    }

    fun play(song: Song) {
        if (_currentSong.value?.id == song.id && mediaController?.isPlaying == true) return
    
        val songIndex = playlist.indexOfFirst { it.id == song.id }
    
        if (songIndex >= 0 && playlist.size > 1) {
            // 设置完整播放列表（带封面），通知栏上一曲/下一曲自动生效
            val mediaItems = playlist.map { s -> buildMediaItem(s) }
            mediaController?.setMediaItems(mediaItems, songIndex, 0L)
        } else {
            // 单首播放
            mediaController?.setMediaItem(buildMediaItem(song))
        }
        mediaController?.prepare()
        mediaController?.play()
    
        _currentSong.value = song
        currentIndex = if (songIndex >= 0) songIndex else 0
    }
    
    /**
     * 构建带封面的 MediaItem
     */
    private fun buildMediaItem(song: Song): MediaItem {
        val metadataBuilder = MediaMetadata.Builder()
            .setTitle(song.title)
            .setArtist(song.artist)
            .setAlbumTitle(song.album)
        song.albumArtUri?.let {
            metadataBuilder.setArtworkUri(Uri.parse(it))
        }
        return MediaItem.Builder()
            .setUri(song.fileUri)
            .setMediaMetadata(metadataBuilder.build())
            .build()
    }

    fun setPlaylist(songs: List<Song>, startIndex: Int = 0) {
        playlist = songs
        if (songs.isNotEmpty() && startIndex in songs.indices) {
            val mediaItems = songs.map { song -> buildMediaItem(song) }
            mediaController?.setMediaItems(mediaItems, startIndex, 0L)
            mediaController?.prepare()
            mediaController?.play()
            _currentSong.value = songs[startIndex]
            currentIndex = startIndex
        }
    }

    fun togglePlayPause() {
        mediaController?.let {
            if (it.isPlaying) it.pause() else it.play()
        }
    }

    fun playNext() {
        if (playlist.isEmpty()) return

        val nextIndex = when {
            _repeatMode.value == RepeatMode.ONE -> currentIndex
            _shuffleMode.value == ShuffleMode.ON -> (0 until playlist.size).random()
            _repeatMode.value == RepeatMode.ALL -> (currentIndex + 1) % playlist.size
            else -> (currentIndex + 1) % playlist.size
        }

        if (nextIndex in playlist.indices) {
            currentIndex = nextIndex
            play(playlist[nextIndex])
        }
    }

    fun playPrevious() {
        if (playlist.isEmpty()) return

        if ((_currentTime.value / 1000) > 3) {
            seekTo(0L)
            return
        }

        val prevIndex = when (_repeatMode.value) {
            RepeatMode.ONE -> currentIndex
            RepeatMode.ALL -> {
                val prev = currentIndex - 1
                if (prev >= 0) prev else playlist.size - 1
            }
            RepeatMode.OFF -> {
                val prev = currentIndex - 1
                if (prev >= 0) prev else return
            }
        }

        if (prevIndex in playlist.indices) {
            currentIndex = prevIndex
            play(playlist[prevIndex])
        }
    }

    fun seekTo(position: Long) {
        mediaController?.seekTo(position)
        _currentTime.value = position
    }

    fun setVolume(volume: Float) {
        val v = volume.coerceIn(0f, 1f)
        // ExoPlayer 无极调节（连续浮点，控制实际播放音量）
        mediaController?.volume = v
        // 同步写入系统音量（映射到整数步长，保持系统音量条一致）
        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val targetVolume = (v * max).toInt()
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, targetVolume, 0)
        _systemVolume.value = v
    }

    private fun getSystemVolume(): Float {
        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val current = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        return if (max > 0) current.toFloat() / max.toFloat() else 0f
    }

    fun toggleShuffle() {
        _shuffleMode.value = if (_shuffleMode.value == ShuffleMode.OFF) ShuffleMode.ON else ShuffleMode.OFF
    }

    fun cycleRepeatMode() {
        _repeatMode.value = when (_repeatMode.value) {
            RepeatMode.OFF -> RepeatMode.ALL
            RepeatMode.ALL -> RepeatMode.ONE
            RepeatMode.ONE -> RepeatMode.OFF
        }
    }

    fun stop() {
        mediaController?.stop()
        _currentSong.value = null
        _isPlaying.value = false
        _currentTime.value = 0L
        _duration.value = 0L
    }

    fun release() {
        handler.removeCallbacks(volumeChecker)
        handler.removeCallbacks(progressUpdater)
        controllerFuture?.let {
            MediaController.releaseFuture(it)
        }
    }
}
