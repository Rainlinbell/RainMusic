import { relationalStore } from '@kit.ArkData'
import { Song } from '../model/SongModel'
import { common } from '@kit.AbilityKit'

const DB_NAME = 'rainmusic.db'
const DB_VERSION = 1
const TABLE_SONGS = 'songs'

const SQL_CREATE_SONGS = `CREATE TABLE IF NOT EXISTS ${TABLE_SONGS} (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL DEFAULT '',
  artist TEXT NOT NULL DEFAULT '未知艺术家',
  album TEXT NOT NULL DEFAULT '未知专辑',
  duration INTEGER NOT NULL DEFAULT 0,
  fileUri TEXT NOT NULL DEFAULT '' UNIQUE,
  albumArtUri TEXT NOT NULL DEFAULT '',
  lyricsPath TEXT NOT NULL DEFAULT '',
  dateAdded INTEGER NOT NULL DEFAULT 0,
  sourceType TEXT NOT NULL DEFAULT 'scan'
)`

/**
 * 歌曲数据库 — 使用 @ohos.data.relationalStore 实现持久化
 */
export class SongDatabase {
  private rdbStore: relationalStore.RdbStore | null = null

  /**
   * 初始化数据库
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    }
    this.rdbStore = await relationalStore.getRdbStore(context, config)
    await this.rdbStore.executeSql(SQL_CREATE_SONGS)
  }

  /**
   * 加载全部歌曲
   */
  async loadAllSongs(): Promise<Song[]> {
    if (!this.rdbStore) return []
    const songs: Song[] = []
    let resultSet: relationalStore.ResultSet | null = null
    try {
      resultSet = await this.rdbStore.querySql(`SELECT * FROM ${TABLE_SONGS} ORDER BY dateAdded DESC`)
      while (resultSet.goToNextRow()) {
        const song = new Song({
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          title: resultSet.getString(resultSet.getColumnIndex('title')),
          artist: resultSet.getString(resultSet.getColumnIndex('artist')),
          album: resultSet.getString(resultSet.getColumnIndex('album')),
          duration: resultSet.getLong(resultSet.getColumnIndex('duration')),
          fileUri: resultSet.getString(resultSet.getColumnIndex('fileUri')),
          albumArtUri: resultSet.getString(resultSet.getColumnIndex('albumArtUri')),
          lyricsPath: resultSet.getString(resultSet.getColumnIndex('lyricsPath')),
          dateAdded: resultSet.getLong(resultSet.getColumnIndex('dateAdded')),
          sourceType: resultSet.getString(resultSet.getColumnIndex('sourceType'))
        })
        songs.push(song)
      }
    } catch (e) {
      console.error('加载歌曲数据失败: ' + String(e))
    } finally {
      if (resultSet) {
        resultSet.close()
      }
    }
    return songs
  }

  /**
   * 批量插入歌曲（扫描用）
   */
  async batchInsertSongs(songs: Song[]): Promise<void> {
    if (!this.rdbStore || songs.length === 0) return
    // 分批插入，每批最多 500 条
    const BATCH_SIZE = 500
    for (let i = 0; i < songs.length; i += BATCH_SIZE) {
      const batch = songs.slice(i, i + BATCH_SIZE)
      const valueBuckets: relationalStore.ValuesBucket[] = batch.map(song => this.songToBucket(song))
      try {
        await this.rdbStore.batchInsert(TABLE_SONGS, valueBuckets)
      } catch (e) {
        // 批量插入失败时逐条插入（处理冲突）
        for (const song of batch) {
          await this.insertSong(song)
        }
      }
    }
  }

  /**
   * 单条插入歌曲（导入用），冲突时替换已有记录
   */
  async insertSong(song: Song): Promise<void> {
    if (!this.rdbStore) return
    try {
      const bucket = this.songToBucket(song)
      await this.rdbStore.insert(TABLE_SONGS, bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
    } catch (e) {
      console.error('插入歌曲失败: ' + String(e))
    }
  }

  /**
   * 按 ID 删除歌曲
   */
  async deleteSongById(id: number): Promise<void> {
    if (!this.rdbStore) return
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_SONGS)
      predicates.equalTo('id', id)
      await this.rdbStore.delete(predicates)
    } catch (e) {
      console.error('删除歌曲失败: ' + String(e))
    }
  }

  /**
   * Song → ValuesBucket 转换
   */
  private songToBucket(song: Song): relationalStore.ValuesBucket {
    return {
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: song.duration,
      fileUri: song.fileUri,
      albumArtUri: song.albumArtUri,
      lyricsPath: song.lyricsPath,
      dateAdded: song.dateAdded,
      sourceType: song.sourceType
    }
  }
}
