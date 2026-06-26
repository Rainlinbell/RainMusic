package com.rain.music.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "songs")
data class Song(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val title: String,
    val artist: String = "未知艺术家",
    val album: String = "未知专辑",
    val duration: Long = 0,         // 毫秒
    val fileUri: String,            // 文件路径
    val albumArtUri: String? = null, // 封面 URI
    val hasLyrics: Boolean = false,
    val lyricsFilePath: String? = null,
    val dateAdded: Long = System.currentTimeMillis(),
    val sourceType: String = "imported" // "library" 或 "imported"
) {
    val formattedDuration: String
        get() {
            val minutes = (duration / 1000) / 60
            val seconds = (duration / 1000) % 60
            return String.format("%d:%02d", minutes, seconds)
        }
}
