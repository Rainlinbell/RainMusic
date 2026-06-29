import { media } from '@kit.MediaKit'
import { audio } from '@kit.AudioKit'
import { Song, ShuffleMode, RepeatMode, LyricLine } from '../model/SongModel'
import { LyricsParser } from './LyricsParser'
import { common } from '@kit.AbilityKit'
import avSession from '@ohos.multimedia.avsession'

/**
 * 音频播放管理器 - 使用 AVPlayer 实现无极音量控制
 */
export class AudioPlayerManager {
  private static instance: AudioPlayerManager | null = null
  private player: media.AVPlayer | null = null
  private context: common.UIAbilityContext
  private lastSystemVolume: number = 1.0
  private avSession: avSession.AVSession | null = null

  // 播放状态
  currentSong: Song | null = null
  isPlaying: boolean = false
  currentTime: number = 0
  duration: number = 0
  volume: number = 1.0  // 0.0-1.0 无极调节
  shuffleMode: ShuffleMode = ShuffleMode.OFF
  repeatMode: RepeatMode = RepeatMode.OFF
  playlist: Song[] = []
  currentIndex: number = -1

  // 歌词
  lyrics: LyricLine[] = []
  currentLyricIndex: number = -1

  // 状态变更回调
  onStateChange: (() => void) | null = null

  private constructor(context: common.UIAbilityContext) {
    this.context = context
    this.initPlayer()
    this.initVolume()
    this.initAVSession()
  }

  static getInstance(context?: common.UIAbilityContext): AudioPlayerManager {
    if (!AudioPlayerManager.instance && context) {
      AudioPlayerManager.instance = new AudioPlayerManager(context)
    }
    return AudioPlayerManager.instance!
  }

  private async initPlayer() {
    try {
      this.player = await media.createAVPlayer()
      this.setupPlayerCallbacks()
    } catch (e) {
      console.error('创建 AVPlayer 失败: ' + JSON.stringify(e))
    }
  }

  /**
   * 初始化系统音量同步 —— 使用事件监听替代轮询
   */
  private initVolume() {
    try {
      const sysVol = this.getSystemVolume()
      this.volume = sysVol
      this.lastSystemVolume = sysVol
      // 延迟设置 AVPlayer 音量（等 player 就绪）
      if (this.player) {
        this.player.setVolume(sysVol)
      }

      // 使用事件监听检测硬件音量键变化
      try {
        const audioManager = audio.getAudioManager()
        const volumeManager = audioManager.getVolumeManager()
        volumeManager.on('streamVolumeChange', audio.StreamUsage.STREAM_USAGE_MUSIC, (event: audio.StreamVolumeEvent) => {
          const maxVol: number = volumeManager.getMaxVolumeByStream(audio.StreamUsage.STREAM_USAGE_MUSIC)
          const curVol: number = event.volume
          if (maxVol > 0) {
            const newVol = curVol / maxVol
            if (Math.abs(newVol - this.lastSystemVolume) > 0.01) {
              this.lastSystemVolume = newVol
              this.volume = newVol
              if (this.player) {
                this.player.setVolume(newVol)
              }
              this.notifyChange()
            }
          }
        })
      } catch (e) {
        console.error('注册音量事件监听失败: ' + JSON.stringify(e))
      }
    } catch (e) {
      console.error('初始化音量失败: ' + JSON.stringify(e))
    }
  }

  /**
   * 读取系统音量 (0.0-1.0)
   */
  private getSystemVolume(): number {
    try {
      const audioManager = audio.getAudioManager()
      const volumeManager = audioManager.getVolumeManager()
      const groupManager = volumeManager.getVolumeGroupManagerSync(0)
      const maxVol = groupManager.getMaxVolumeSync(audio.AudioVolumeType.MEDIA)
      const curVol = groupManager.getVolumeSync(audio.AudioVolumeType.MEDIA)
      return maxVol > 0 ? curVol / maxVol : 0
    } catch (e) {
      return this.volume
    }
  }

  /**
   * 写入系统音量 (0.0-1.0)
   */
  private setSystemVolume(vol: number): void {
    try {
      const audioManager = audio.getAudioManager()
      const volumeManager = audioManager.getVolumeManager()
      const groupManager = volumeManager.getVolumeGroupManagerSync(0)
      const maxVol = groupManager.getMaxVolumeSync(audio.AudioVolumeType.MEDIA)
      const targetVol = Math.round(vol * maxVol)
      audioManager.setVolume(audio.AudioVolumeType.MEDIA, targetVol)
    } catch (e) {
      console.error('设置系统音量失败: ' + JSON.stringify(e))
    }
  }

  private setupPlayerCallbacks() {
    if (!this.player) return

    this.player.on('stateChange', (state: string) => {
      switch (state) {
        case 'prepared':
          this.duration = this.player?.duration ?? 0
          this.player?.play()
          this.updateAVPlaybackState()
          break
        case 'playing':
          this.isPlaying = true
          this.startProgressTimer()
          this.updateAVPlaybackState()
          this.notifyChange()
          break
        case 'paused':
          this.isPlaying = false
          this.stopProgressTimer()
          this.updateAVPlaybackState()
          this.notifyChange()
          break
        case 'completed':
          this.isPlaying = false
          this.stopProgressTimer()
          this.playNext()
          break
        case 'stopped':
          this.isPlaying = false
          this.currentTime = 0
          this.stopProgressTimer()
          this.updateAVPlaybackState()
          this.notifyChange()
          break
      }
    })

    this.player.on('timeUpdate', (time: number) => {
      this.currentTime = time
      this.currentLyricIndex = LyricsParser.findCurrentLineIndex(this.lyrics, time)
      this.notifyChange()
    })

    this.player.on('durationUpdate', (duration: number) => {
      this.duration = duration
      this.notifyChange()
    })
  }

  // MARK: - AVSession 通知栏控制

  private async initAVSession() {
    try {
      this.avSession = await avSession.createAVSession(this.context, 'RainMusic', 'audio')
      // 注册远程控制命令回调
      this.avSession.on('play', () => {
        if (!this.isPlaying) this.togglePlayPause()
      })
      this.avSession.on('pause', () => {
        if (this.isPlaying) this.togglePlayPause()
      })
      this.avSession.on('playNext', () => {
        this.playNext()
      })
      this.avSession.on('playPrevious', () => {
        this.playPrevious()
      })
      this.avSession.on('seek', (time: number) => {
        this.seekTo(time)
      })
    } catch (e) {
      console.error('初始化 AVSession 失败: ' + JSON.stringify(e))
    }
  }

  private updateAVMetadata() {
    if (!this.avSession || !this.currentSong) return
    const metadata: avSession.AVMetadata = {
      assetId: this.currentSong.id.toString(),
      title: this.currentSong.title,
      artist: this.currentSong.artist,
      album: this.currentSong.album,
      duration: this.currentSong.duration,
      mediaImage: this.currentSong.albumArtUri ?? ''
    }
    this.avSession.setAVMetadata(metadata)
  }

  private updateAVPlaybackState() {
    if (!this.avSession) return
    const playbackState: avSession.AVPlaybackState = {
      state: this.isPlaying
        ? avSession.PlaybackState.PLAYBACK_STATE_PLAY
        : avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
      speed: 1.0,
      position: {
        elapsedTime: this.currentTime,
        updateTime: Date.now()
      }
    }
    this.avSession.setAVPlaybackState(playbackState)
  }

  // MARK: - 播放控制

  async play(song: Song) {
    if (!this.player) return
    if (this.currentSong?.id === song.id && this.isPlaying) return

    try {
      await this.player.reset()
      // 设置播放源
      this.player.url = song.fileUri
      await this.player.prepare()

      this.currentSong = song
      this.currentIndex = this.playlist.findIndex(s => s.id === song.id)

      // 更新通知栏元数据
      this.updateAVMetadata()

      // 加载歌词（优先关联歌词文件，回退同名 .lrc）
      this.lyrics = LyricsParser.loadLyrics(song.lyricsPath, song.fileUri) ?? []
      this.currentLyricIndex = -1

      // 设置音量
      this.player.setVolume(this.volume)

      this.notifyChange()
    } catch (e) {
      console.error('播放失败: ' + JSON.stringify(e))
    }
  }

  async setPlaylist(songs: Song[], startIndex: number = 0) {
    this.playlist = songs
    if (songs.length > 0 && startIndex >= 0 && startIndex < songs.length) {
      await this.play(songs[startIndex])
    }
  }

  togglePlayPause() {
    if (!this.player) return
    if (this.isPlaying) {
      this.player.pause()
    } else {
      this.player.play()
    }
  }

  async playNext() {
    if (this.playlist.length === 0) return

    let nextIndex: number
    if (this.repeatMode === RepeatMode.ONE) {
      nextIndex = this.currentIndex
    } else if (this.shuffleMode === ShuffleMode.ON) {
      nextIndex = Math.floor(Math.random() * this.playlist.length)
    } else if (this.repeatMode === RepeatMode.ALL) {
      nextIndex = (this.currentIndex + 1) % this.playlist.length
    } else {
      nextIndex = (this.currentIndex + 1) % this.playlist.length
    }

    if (nextIndex >= 0 && nextIndex < this.playlist.length) {
      this.currentIndex = nextIndex
      await this.play(this.playlist[nextIndex])
    }
  }

  async playPrevious() {
    if (this.playlist.length === 0) return

    if (this.currentTime > 3000) {
      this.seekTo(0)
      return
    }

    let prevIndex: number
    if (this.repeatMode === RepeatMode.ONE) {
      prevIndex = this.currentIndex
    } else if (this.repeatMode === RepeatMode.ALL) {
      prevIndex = this.currentIndex - 1
      if (prevIndex < 0) prevIndex = this.playlist.length - 1
    } else {
      prevIndex = this.currentIndex - 1
      if (prevIndex < 0) {
        this.seekTo(0)
        return
      }
    }

    if (prevIndex >= 0 && prevIndex < this.playlist.length) {
      this.currentIndex = prevIndex
      await this.play(this.playlist[prevIndex])
    }
  }

  seekTo(position: number) {
    if (!this.player) return
    this.player.seek(position)
    this.currentTime = position
  }

  /**
   * 设置音量 - 无极调节 + 系统音量同步
   */
  setVolume(vol: number) {
    this.volume = Math.max(0, Math.min(1, vol))
    // AVPlayer 无极调节（连续浮点，控制实际播放音量）
    if (this.player) {
      this.player.setVolume(this.volume)
    }
    // 同步写入系统音量
    this.setSystemVolume(this.volume)
    this.lastSystemVolume = this.volume
    this.notifyChange()
  }

  toggleShuffle() {
    this.shuffleMode = this.shuffleMode === ShuffleMode.OFF ? ShuffleMode.ON : ShuffleMode.OFF
    this.notifyChange()
  }

  cycleRepeatMode() {
    switch (this.repeatMode) {
      case RepeatMode.OFF:
        this.repeatMode = RepeatMode.ALL
        break
      case RepeatMode.ALL:
        this.repeatMode = RepeatMode.ONE
        break
      case RepeatMode.ONE:
        this.repeatMode = RepeatMode.OFF
        break
    }
    this.notifyChange()
  }

  stop() {
    if (!this.player) return
    this.player.stop()
    this.currentSong = null
    this.isPlaying = false
    this.currentTime = 0
    this.duration = 0
    this.stopProgressTimer()
    this.notifyChange()
  }

  release() {
    if (this.player) {
      this.player.release()
      this.player = null
    }
    AudioPlayerManager.instance = null
  }

  // MARK: - 进度定时器（已移除，仅依赖 timeUpdate 事件）

  private startProgressTimer() {
    // 进度更新由 player.on('timeUpdate') 事件驱动，无需定时器
  }

  private stopProgressTimer() {
    // 无需清理
  }

  private notifyChange() {
    if (this.onStateChange) {
      this.onStateChange()
    }
  }

  // MARK: - 格式化

  static formatTime(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000)
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  }
}
