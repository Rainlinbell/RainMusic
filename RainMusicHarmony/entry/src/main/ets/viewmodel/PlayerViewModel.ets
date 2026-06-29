import { Song, SortOrder, LyricLine, ShuffleMode, RepeatMode } from '../model/SongModel'
import { AudioPlayerManager } from '../manager/AudioPlayerManager'
import { MusicScanner } from '../manager/MusicScanner'
import { LyricsParser } from '../manager/LyricsParser'
import { SongDatabase } from '../data/SongDatabase'
import { common } from '@kit.AbilityKit'

/**
 * 视图模型 - @Observed 实现响应式数据绑定
 * 所有播放状态存储为直接属性，audioManager 回调中直接更新这些属性以触发 UI 刷新
 */
@Observed
export class PlayerViewModel {
  // 歌曲列表
  songs: Song[] = []
  sortOrder: SortOrder = SortOrder.DATE_ADDED
  searchQuery: string = ''
  isScanning: boolean = false
  scanResult: string = ''

  // 播放状态（直接存储，非 getter 代理）
  currentSong: Song | null = null
  isPlaying: boolean = false
  currentTime: number = 0
  duration: number = 0
  shuffleMode: ShuffleMode = ShuffleMode.OFF
  repeatMode: RepeatMode = RepeatMode.OFF
  lyrics: LyricLine[] = []
  currentLyricIndex: number = -1

  // 显示状态
  showLyrics: boolean = false

  // 依赖
  private audioManager: AudioPlayerManager
  private musicScanner: MusicScanner
  private songDb: SongDatabase

  constructor(context: common.UIAbilityContext) {
    this.audioManager = AudioPlayerManager.getInstance(context)
    this.musicScanner = new MusicScanner(context)
    this.songDb = new SongDatabase()

    // 异步加载持久化歌曲数据（不阻塞构造）
    this.songDb.init(context).then(async () => {
      this.songs = await this.songDb.loadAllSongs()
    })

    // 初始化播放状态
    this.syncFromAudioManager()

    // 监听状态变化 —— 直接更新属性触发响应式刷新
    this.audioManager.onStateChange = () => {
      this.syncFromAudioManager()
    }
  }

  /**
   * 从 audioManager 同步播放状态到直接属性
   */
  private syncFromAudioManager() {
    this.currentSong = this.audioManager.currentSong
    this.isPlaying = this.audioManager.isPlaying
    this.currentTime = this.audioManager.currentTime
    this.duration = this.audioManager.duration
    this.shuffleMode = this.audioManager.shuffleMode
    this.repeatMode = this.audioManager.repeatMode
    this.lyrics = this.audioManager.lyrics
    this.currentLyricIndex = this.audioManager.currentLyricIndex
  }

  // 音量属性
  get volume(): number { return this.audioManager.volume }
  set volume(v: number) { this.audioManager.setVolume(v) }

  // 过滤后的歌曲列表
  get filteredSongs(): Song[] {
    let filtered = this.songs
    if (this.searchQuery) {
      const q = this.searchQuery.toLowerCase()
      filtered = filtered.filter(s =>
        s.title.toLowerCase().includes(q) ||
        s.artist.toLowerCase().includes(q) ||
        s.album.toLowerCase().includes(q)
      )
    }

    return filtered.sort((a, b) => {
      switch (this.sortOrder) {
        case SortOrder.DATE_ADDED: return b.dateAdded - a.dateAdded
        case SortOrder.TITLE: return a.title.localeCompare(b.title)
        case SortOrder.ARTIST: return a.artist.localeCompare(b.artist)
        case SortOrder.ALBUM: return a.album.localeCompare(b.album)
        default: return 0
      }
    })
  }

  // 播放控制
  play(song: Song) { this.audioManager.play(song) }
  togglePlayPause() { this.audioManager.togglePlayPause() }
  playNext() {
    // 如果播放列表为空，自动用歌曲列表填充
    if (this.audioManager.playlist.length === 0 && this.songs.length > 0) {
      const idx = this.songs.findIndex(s => s.id === this.currentSong?.id)
      this.audioManager.setPlaylist(this.songs, idx >= 0 ? idx : 0)
      return
    }
    this.audioManager.playNext()
  }
  playPrevious() {
    if (this.audioManager.playlist.length === 0 && this.songs.length > 0) {
      const idx = this.songs.findIndex(s => s.id === this.currentSong?.id)
      this.audioManager.setPlaylist(this.songs, idx >= 0 ? idx : 0)
      return
    }
    this.audioManager.playPrevious()
  }
  seekTo(position: number) { this.audioManager.seekTo(position) }
  setVolume(vol: number) { this.audioManager.setVolume(vol) }
  setPlaylist(songs: Song[], startIndex: number = 0) { this.audioManager.setPlaylist(songs, startIndex) }
  toggleShuffle() { this.audioManager.toggleShuffle() }
  cycleRepeatMode() { this.audioManager.cycleRepeatMode() }
  toggleLyricsDisplay() { this.showLyrics = !this.showLyrics }

  formatTime(ms: number): string {
    return AudioPlayerManager.formatTime(ms)
  }

  // 扫描（支持去重合并）
  async scanMusic() {
    this.isScanning = true
    try {
      const result = await this.musicScanner.scanDeviceMusic()
      // 去重：与现有歌曲列表按 fileUri 合并
      const existingUris = new Set(this.songs.map(s => s.fileUri))
      const newSongs = result.filter(s => !existingUris.has(s.fileUri))
      this.songs = [...this.songs, ...newSongs]
      // 持久化新增歌曲
      await this.songDb.batchInsertSongs(newSongs)
      this.scanResult = newSongs.length > 0
        ? `扫描完成，新增 ${newSongs.length} 首歌曲（跳过 ${result.length - newSongs.length} 首重复）`
        : '未找到新歌曲'
    } catch (e) {
      this.scanResult = '扫描失败: ' + String(e)
    } finally {
      this.isScanning = false
    }
  }

  // 导入（支持去重）
  async importFile(uri: string) {
    const song = await this.musicScanner.importFile(uri)
    if (song) {
      // 检查是否已存在（根据文件路径去重）
      const exists = this.songs.some(s => s.fileUri === song.fileUri)
      if (!exists) {
        this.songs = [...this.songs, song]
        // 持久化导入的歌曲
        await this.songDb.insertSong(song)
        this.scanResult = `导入成功: ${song.title}`
      } else {
        this.scanResult = `歌曲已存在: ${song.title}`
      }
    }
  }

  // 删除
  async deleteSong(song: Song) {
    this.songs = this.songs.filter(s => s.id !== song.id)
    await this.songDb.deleteSongById(song.id)
  }

  // 更新封面
  updateAlbumArt(uri: string) {
    const song = this.currentSong
    if (song) {
      song.albumArtUri = uri
      this.syncFromAudioManager()
    }
  }
}
