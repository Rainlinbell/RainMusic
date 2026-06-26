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
   * 扫描设备音乐库（扫描公共音乐目录）
   */
  async scanDeviceMusic(): Promise<Song[]> {
    const songs: Song[] = []

    try {
      // 扫描常见的音乐目录
      const musicDirs: string[] = [
        '/data/storage/el2/base/files/music',
        this.context.filesDir + '/music'
      ]

      for (const dir of musicDirs) {
        try {
          if (!fileIo.accessSync(dir)) {
            continue
          }
          const dirEntries = fileIo.listFileSync(dir)
          for (const entry of dirEntries) {
            const fullPath = dir + '/' + entry
            if (this.isAudioFile(entry)) {
              const stat = fileIo.statSync(fullPath)
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
          }
        } catch (e) {
          // 目录不存在或无法访问，跳过
        }
      }
    } catch (e) {
      console.error('扫描音乐失败: ' + JSON.stringify(e))
    }

    return songs
  }

  /**
   * 导入单个音频文件
   */
  async importFile(sourceUri: string): Promise<Song | null> {
    try {
      // 复制到应用沙盒
      const destDir = this.context.filesDir + '/music'
      if (!fileIo.accessSync(destDir)) {
        fileIo.mkdirSync(destDir, true)
      }

      const fileName = sourceUri.split('/').pop() ?? 'imported_audio'
      const destPath = destDir + '/' + fileName

      // 复制文件
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

      return new Song({
        id: Date.now(),
        title: fileName.replace(/\.[^/.]+$/, ''),
        artist: '未知艺术家',
        album: '未知专辑',
        duration: 0,
        fileUri: destPath,
        dateAdded: stat.mtime,
        sourceType: 'import'
      })
    } catch (e) {
      console.error('导入文件失败: ' + JSON.stringify(e))
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
