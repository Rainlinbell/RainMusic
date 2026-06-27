import { Song, SortOrder, LyricLine, ShuffleMode, RepeatMode } from '../model/SongModel'
import { AudioPlayerManager } from '../manager/AudioPlayerManager'
import { MusicScanner } from '../manager/MusicScanner'
import { LyricsParser } from '../manager/LyricsParser'
import { common } from '@kit.AbilityKit'

/**
 * 视图模型 - @Observed 实现响应式数据绑定
 */
@Observed
export class PlayerViewModel {
  // 歌曲列表
  songs: Song[] = []
  sortOrder: SortOrder = SortOrder.DATE_ADDED
  searchQuery: string = ''
  isScanning: boolean = false
  scanResult: string = ''

  // 播放状态
  private audioManager: AudioPlayerManager
  private musicScanner: MusicScanner

  get currentSong(): Song | null { return this.audioManager.currentSong }
  get isPlaying(): boolean { return this.audioManager.isPlaying }
  get currentTime(): number { return this.audioManager.currentTime }
  get duration(): number { return this.audioManager.duration }
  get volume(): number { return this.audioManager.volume }
  set volume(v: number) { this.audioManager.setVolume(v) }
  get shuffleMode(): ShuffleMode { return this.audioManager.shuffleMode }
  get repeatMode(): RepeatMode { return this.audioManager.repeatMode }
  get lyrics(): LyricLine[] { return this.audioManager.lyrics }
  get currentLyricIndex(): number { return this.audioManager.currentLyricIndex }

  // 状态版本号 - 每次状态变化递增，触发 UI 刷新
  stateVersion: number = 0

  // 显示状态
  showLyrics: boolean = false

  constructor(context: common.UIAbilityContext) {
    this.audioManager = AudioPlayerManager.getInstance(context)
    this.musicScanner = new MusicScanner(context)

    // 监听状态变化
    this.audioManager.onStateChange = () => {
      // 递增版本号触发所有 @Prop 更新
      this.stateVersion++
      this.songs = [...this.songs]
    }
  }

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
  playNext() { this.audioManager.playNext() }
  playPrevious() { this.audioManager.playPrevious() }
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
      this.scanResult = newSongs.length > 0
        ? `扫描完成，新增 ${newSongs.length} 首歌曲（跳过 ${result.length - newSongs.length} 首重复）`
        : '未找到新歌曲'
    } catch (e) {
      this.scanResult = '扫描失败: ' + JSON.stringify(e)
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
        this.scanResult = `导入成功: ${song.title}`
      } else {
        this.scanResult = `歌曲已存在: ${song.title}`
      }
    }
  }

  // 删除
  deleteSong(song: Song) {
    this.songs = this.songs.filter(s => s.id !== song.id)
  }

  // 更新封面
  updateAlbumArt(uri: string) {
    const song = this.currentSong
    if (song) {
      song.albumArtUri = uri
      this.stateVersion++
    }
  }
}
