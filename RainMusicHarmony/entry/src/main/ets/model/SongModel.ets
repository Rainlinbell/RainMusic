/**
 * 歌曲数据模型
 */
@Observed
export class Song {
  id: number = 0
  title: string = ''
  artist: string = '未知艺术家'
  album: string = '未知专辑'
  duration: number = 0
  fileUri: string = ''
  albumArtUri: string = ''
  lyricsPath: string = ''
  dateAdded: number = 0
  sourceType: string = 'scan'

  get formattedDuration(): string {
    const totalSeconds = Math.floor(this.duration / 1000)
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60
    return `${minutes}:${seconds < 10 ? '0' : ''}${seconds}`
  }

  constructor(init?: SongInit) {
    if (init) {
      this.id = init.id ?? 0
      this.title = init.title ?? ''
      this.artist = init.artist ?? '未知艺术家'
      this.album = init.album ?? '未知专辑'
      this.duration = init.duration ?? 0
      this.fileUri = init.fileUri ?? ''
      this.albumArtUri = init.albumArtUri ?? ''
      this.lyricsPath = init.lyricsPath ?? ''
      this.dateAdded = init.dateAdded ?? 0
      this.sourceType = init.sourceType ?? 'scan'
    }
  }
}

/**
 * 歌曲初始化参数
 */
export interface SongInit {
  id?: number
  title?: string
  artist?: string
  album?: string
  duration?: number
  fileUri?: string
  albumArtUri?: string
  lyricsPath?: string
  dateAdded?: number
  sourceType?: string
}

/**
 * 排序方式
 */
export enum SortOrder {
  DATE_ADDED = 'dateAdded',
  TITLE = 'title',
  ARTIST = 'artist',
  ALBUM = 'album'
}

/**
 * 随机模式
 */
export enum ShuffleMode {
  OFF,
  ON
}

/**
 * 循环模式
 */
export enum RepeatMode {
  OFF,
  ALL,
  ONE
}

/**
 * 歌词行
 */
export interface LyricLine {
  time: number
  text: string
}
