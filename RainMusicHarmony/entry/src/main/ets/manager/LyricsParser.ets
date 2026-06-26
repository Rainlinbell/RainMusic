import { LyricLine } from '../model/SongModel'
import { fileIo } from '@kit.CoreFileKit'
import { util } from '@kit.ArkTS'

/**
 * LRC 歌词解析器
 */
export class LyricsParser {
  /**
   * 解析 LRC 歌词文本
   */
  static parseLrc(content: string): LyricLine[] {
    const lines = content.split('\n')
    const result: LyricLine[] = []

    for (const line of lines) {
      const trimmed = line.trim()
      if (!trimmed) continue

      const times: number[] = []

      // 提取所有时间标签（一行可能有多个）
      const tempRegex = new RegExp('\\[(\\d{1,3}):(\\d{2})\\.(\\d{2,3})\\]', 'g')
      let matchResult: RegExpExecArray | null = tempRegex.exec(trimmed)
      while (matchResult !== null) {
        const minutes = parseInt(matchResult[1])
        const seconds = parseInt(matchResult[2])
        const ms = matchResult[3].length === 2
          ? parseInt(matchResult[3]) * 10
          : parseInt(matchResult[3])
        times.push(minutes * 60000 + seconds * 1000 + ms)
        matchResult = tempRegex.exec(trimmed)
      }

      // 提取歌词文本（去掉所有时间标签）
      const replaceRegex = new RegExp('\\[\\d{1,3}:\\d{2}\\.\\d{2,3}\\]', 'g')
      const text = trimmed.replace(replaceRegex, '').trim()
      if (text && times.length > 0) {
        for (const time of times) {
          const lyricLine: LyricLine = { time: time, text: text }
          result.push(lyricLine)
        }
      }
    }

    // 按时间排序
    result.sort((a: LyricLine, b: LyricLine) => a.time - b.time)
    return result
  }

  /**
   * 加载歌词文件（优先指定路径，回退同名 .lrc）
   */
  static loadLyrics(lyricsPath: string, audioPath?: string): LyricLine[] | null {
    // 优先使用关联的歌词文件
    if (lyricsPath) {
      const content = LyricsParser.readFileContent(lyricsPath)
      if (content) {
        const lines = LyricsParser.parseLrc(content)
        if (lines.length > 0) return lines
      }
    }

    // 回退：在音频文件同目录查找同名 .lrc
    if (audioPath) {
      const lrcPath = audioPath.substring(0, audioPath.lastIndexOf('.')) + '.lrc'
      try {
        if (fileIo.accessSync(lrcPath)) {
          const content = LyricsParser.readFileContent(lrcPath)
          if (content) {
            const lines = LyricsParser.parseLrc(content)
            if (lines.length > 0) return lines
          }
        }
      } catch (e) {
        // 文件不存在，忽略
      }
    }

    return null
  }

  /**
   * 读取文件内容，支持多种编码（UTF-8 / GBK）
   */
  private static readFileContent(filePath: string): string | null {
    try {
      const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
      const buffer = new ArrayBuffer(1024 * 64)
      const readResult = fileIo.readSync(file.fd, buffer)
      fileIo.closeSync(file)

      const uint8Buf = new Uint8Array(buffer.slice(0, readResult))

      // 先尝试 UTF-8
      const utf8Decoder = new util.TextDecoder('utf-8')
      const utf8Content = utf8Decoder.decodeToString(uint8Buf)
      // 检查是否有乱码标志（替换字符 U+FFFD）
      if (utf8Content.indexOf('\uFFFD') < 0) {
        return utf8Content
      }

      // 尝试 GBK
      try {
        const gbkDecoder = new util.TextDecoder('gbk')
        const gbkContent = gbkDecoder.decodeToString(uint8Buf)
        return gbkContent
      } catch (e) {
        // GBK 解码失败，返回 UTF-8 结果
      }

      return utf8Content
    } catch (e) {
      return null
    }
  }

  /**
   * 二分查找当前歌词行索引
   */
  static findCurrentLineIndex(lyrics: LyricLine[], currentTime: number): number {
    if (lyrics.length === 0) return -1

    let low = 0
    let high = lyrics.length - 1

    if (currentTime < lyrics[0].time) return -1
    if (currentTime >= lyrics[high].time) return high

    while (low <= high) {
      const mid = Math.floor((low + high) / 2)
      if (mid === lyrics.length - 1) return mid

      if (currentTime >= lyrics[mid].time && currentTime < lyrics[mid + 1].time) {
        return mid
      } else if (currentTime < lyrics[mid].time) {
        high = mid - 1
      } else {
        low = mid + 1
      }
    }

    return high
  }
}
