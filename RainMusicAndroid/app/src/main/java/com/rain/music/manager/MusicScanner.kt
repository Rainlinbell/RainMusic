package com.rain.music.manager

import android.content.ContentUris
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.core.content.ContextCompat
import com.rain.music.data.db.SongDao
import com.rain.music.data.model.Song
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext
import java.io.File

class MusicScanner(private val context: Context, private val songDao: SongDao) {

    fun getAllSongs(): Flow<List<Song>> = songDao.getAllSongs()

    fun getSongsByTitle(): Flow<List<Song>> = songDao.getSongsByTitle()
    fun getSongsByArtist(): Flow<List<Song>> = songDao.getSongsByArtist()
    fun getSongsByAlbum(): Flow<List<Song>> = songDao.getSongsByAlbum()

    fun searchSongs(query: String): Flow<List<Song>> = songDao.searchSongs(query)

    suspend fun deleteSong(song: Song) {
        // 删除文件
        try {
            val file = File(song.fileUri)
            if (file.exists()) file.delete()
            song.lyricsFilePath?.let { File(it).delete() }
        } catch (_: Exception) {}
        songDao.delete(song)
    }

    /**
     * 扫描设备音乐库
     */
    suspend fun scanDeviceMusic(): Int = withContext(Dispatchers.IO) {
        val songs = mutableListOf<Song>()
        try {
            // 扫描前二次校验权限
            val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                android.Manifest.permission.READ_MEDIA_AUDIO
            } else {
                android.Manifest.permission.READ_EXTERNAL_STORAGE
            }
            val granted = ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
            if (!granted) {
                return@withContext 0
            }

            val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
            } else {
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            }

            val projection = arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.TITLE,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ALBUM,
                MediaStore.Audio.Media.DURATION,
                MediaStore.Audio.Media.DATA
            )

            val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

            context.contentResolver.query(
                collection,
                projection,
                null,
                null,
                sortOrder
            )?.use { cursor ->
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                val titleColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
                val artistColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
                val albumColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
                val durationColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
                val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)

                while (cursor.moveToNext()) {
                    try {
                        val id = cursor.getLong(idColumn)
                        val title = cursor.getString(titleColumn) ?: "未知歌曲"
                        val artist = cursor.getString(artistColumn) ?: "未知艺术家"
                        val album = cursor.getString(albumColumn) ?: "未知专辑"
                        val duration = cursor.getLong(durationColumn)
                        val data = cursor.getString(dataColumn)

                        if (duration > 10000) {
                            val fileUri = data ?: ContentUris.withAppendedId(collection, id).toString()
                            // 去重：检查是否已存在相同文件路径
                            val existing = songDao.getSongByFilePath(fileUri)
                            if (existing != null) continue

                            val albumArtUri = getAlbumArtUri(id)

                            val song = Song(
                                title = title,
                                artist = artist,
                                album = album,
                                duration = duration,
                                fileUri = fileUri,
                                albumArtUri = albumArtUri,
                                sourceType = "library"
                            )
                            songs.add(song)
                        }
                    } catch (e: Exception) {
                        // 单首歌曲解析失败不影响整体扫描
                        continue
                    }
                }
            }

            if (songs.isNotEmpty()) {
                songDao.insertAll(songs)
            }
        } catch (e: Throwable) {
            // 顶层捕获：权限拒绝、数据库错误、厂商 ROM 非标准异常等
            e.printStackTrace()
        }

        songs.size
    }

    /**
     * 导入文件
     */
    suspend fun importFile(uri: Uri): Song? = withContext(Dispatchers.IO) {
        try {
            val projection = arrayOf(
                MediaStore.Audio.Media.TITLE,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ALBUM,
                MediaStore.Audio.Media.DURATION,
                MediaStore.Audio.Media.DATA
            )

            var title = "未知歌曲"
            var artist = "未知艺术家"
            var album = "未知专辑"
            var duration = 0L
            var filePath = ""

            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    title = cursor.getString(0) ?: title
                    artist = cursor.getString(1) ?: artist
                    album = cursor.getString(2) ?: album
                    duration = cursor.getLong(3)
                    filePath = cursor.getString(4) ?: ""
                }
            }

            val resolvedPath = filePath.ifEmpty { uri.toString() }

            // 去重：检查是否已存在相同文件路径
            val existing = songDao.getSongByFilePath(resolvedPath)
            if (existing != null) return@withContext null

            // 查找同名歌词文件
            val lyricsPath = findLyricsFile(filePath)

            val song = Song(
                title = title,
                artist = artist,
                album = album,
                duration = duration,
                fileUri = resolvedPath,
                hasLyrics = lyricsPath != null,
                lyricsFilePath = lyricsPath,
                sourceType = "imported"
            )

            val id = songDao.insert(song)
            song.copy(id = id)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun getAlbumArtUri(audioId: Long): String? {
        val albumArtUri = Uri.parse("content://media/external/audio/albumart")
        return ContentUris.withAppendedId(albumArtUri, audioId).toString()
    }

    private fun findLyricsFile(audioPath: String): String? {
        if (audioPath.isEmpty()) return null

        val lrcPath = audioPath.substringBeforeLast(".") + ".lrc"
        val lrcFile = File(lrcPath)
        return if (lrcFile.exists()) lrcPath else null
    }
}
