import { Song } from '../model/SongModel'
import { fileIo } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'

/**
 * 音乐扫描器 - 使用文件系统扫描音频
 */
export class MusicScanner {
  private context: common.UIAbilityContext

  constructor(context: common.UIAbilityContext) {
    this.context = context
  }

  /**
   * 扫描设备音乐库（仅扫描应用沙盒目录，无需额外权限）
   */
  async scanDeviceMusic(): Promise<Song[]> {
    const songs: Song[] = []
    const scannedPaths = new Set<string>()

    try {
      // 仅扫描应用沙盒内的音乐目录（无需 READ_MEDIA 权限）
      const musicDir = this.context.filesDir + '/music'
      try {
        const exists = fileIo.accessSync(musicDir)
        if (exists) {
          this.scanDirectory(musicDir, songs, scannedPaths, 0)
        }
      } catch (e) {
        // 目录不存在，跳过
      }
    } catch (e) {
      console.error('扫描音乐失败: ' + String(e))
    }

    return songs
  }

  /**
   * 递归扫描目录下的音频文件（最多3层深度）
   */
  private scanDirectory(dir: string, songs: Song[], scannedPaths: Set<string>, depth: number) {
    if (depth > 3) return
    if (scannedPaths.has(dir)) return
    scannedPaths.add(dir)

    try {
      const dirEntries = fileIo.listFileSync(dir)
      for (const entry of dirEntries) {
        const fullPath = dir + '/' + entry
        try {
          const stat = fileIo.statSync(fullPath)
          if (stat.isDirectory()) {
            // 递归扫描子目录
            this.scanDirectory(fullPath, songs, scannedPaths, depth + 1)
          } else if (this.isAudioFile(entry) && stat.size > 10000) {
            // 跳过小于10KB的文件（大概率不是有效音频）
            const song = new Song({
              id: this.hashId(fullPath),
              title: entry.replace(/\.[^/.]+$/, ''),
              artist: '未知艺术家',
              album: '未知专辑',
              duration: 0,
              fileUri: fullPath,
              dateAdded: stat.mtime,
              sourceType: 'scan'
            })
            song.lyricsPath = this.findLyricsFile(fullPath)
            songs.push(song)
          }
        } catch (e) {
          // 单个文件/目录出错，跳过继续
        }
      }
    } catch (e) {
      // 目录读取失败，跳过
    }
  }

  /**
   * 导入单个音频文件（从文件选择器 URI 复制到应用沙盒）
   */
  async importFile(sourceUri: string): Promise<Song | null> {
    try {
      // 确保目标目录存在
      const destDir = this.context.filesDir + '/music'
      if (!fileIo.accessSync(destDir)) {
        fileIo.mkdirSync(destDir, true)
      }

      // 从 URI 提取文件名，确保唯一性
      let fileName = sourceUri.split('/').pop() ?? 'imported_audio'
      // 去除可能的查询参数
      fileName = fileName.split('?')[0]
      // 添加时间戳避免重名覆盖
      const nameParts = fileName.lastIndexOf('.')
      if (nameParts > 0) {
        fileName = fileName.substring(0, nameParts) + '_' + Date.now() + fileName.substring(nameParts)
      } else {
        fileName = fileName + '_' + Date.now()
      }
      const destPath = destDir + '/' + fileName

      // 复制文件到应用沙盒
      const srcFile = fileIo.openSync(sourceUri, fileIo.OpenMode.READ_ONLY)
      const destFile = fileIo.openSync(destPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
      const buffer = new ArrayBuffer(1024 * 64)
      let readLen: number = 0
      while ((readLen = fileIo.readSync(srcFile.fd, buffer)) > 0) {
        fileIo.writeSync(destFile.fd, buffer.slice(0, readLen))
      }
      fileIo.closeSync(srcFile)
      fileIo.closeSync(destFile)

      const stat = fileIo.statSync(destPath)

      const song = new Song({
        id: Date.now(),
        title: fileName.replace(/\.[^/.]+$/, '').replace(/_\d+$/, ''),
        artist: '未知艺术家',
        album: '未知专辑',
        duration: 0,
        fileUri: destPath,
        dateAdded: stat.mtime,
        sourceType: 'import'
      })
      song.lyricsPath = this.findLyricsFile(destPath)
      return song
    } catch (e) {
      console.error('导入文件失败: ' + String(e))
      return null
    }
  }

  /**
   * 判断是否为音频文件
   */
  private isAudioFile(fileName: string): boolean {
    const ext = fileName.split('.').pop()?.toLowerCase() ?? ''
    const audioExts: string[] = ['mp3', 'flac', 'wav', 'aac', 'ogg', 'm4a', 'wma', 'ape']
    return audioExts.indexOf(ext) >= 0
  }

  /**
   * 查找同名歌词文件
   */
  private findLyricsFile(audioUri: string): string {
    const dir = audioUri.substring(0, audioUri.lastIndexOf('/'))
    const baseName = audioUri.split('/').pop()?.replace(/\.[^/.]+$/, '') ?? ''
    const lrcPath = dir + '/' + baseName + '.lrc'

    try {
      if (fileIo.accessSync(lrcPath)) {
        return lrcPath
      }
    } catch (e) {
      // 文件不存在
    }
    return ''
  }

  /**
   * 简单哈希 ID
   */
  private hashId(str: string): number {
    let hash = 0
    for (let i = 0; i < str.length; i++) {
      hash = ((hash << 5) - hash) + str.charCodeAt(i)
      hash = hash & hash
    }
    return Math.abs(hash)
  }
}
