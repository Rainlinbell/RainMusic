package com.rain.music.data.db

import androidx.room.*
import com.rain.music.data.model.Song
import kotlinx.coroutines.flow.Flow

@Dao
interface SongDao {
    @Query("SELECT * FROM songs ORDER BY dateAdded DESC")
    fun getAllSongs(): Flow<List<Song>>

    @Query("SELECT * FROM songs ORDER BY title ASC")
    fun getSongsByTitle(): Flow<List<Song>>

    @Query("SELECT * FROM songs ORDER BY artist ASC")
    fun getSongsByArtist(): Flow<List<Song>>

    @Query("SELECT * FROM songs ORDER BY album ASC")
    fun getSongsByAlbum(): Flow<List<Song>>

    @Query("SELECT * FROM songs WHERE id = :id")
    suspend fun getSongById(id: Long): Song?

    @Query("SELECT * FROM songs WHERE title LIKE '%' || :query || '%' OR artist LIKE '%' || :query || '%' OR album LIKE '%' || :query || '%'")
    fun searchSongs(query: String): Flow<List<Song>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(song: Song): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(songs: List<Song>): List<Long>

    @Delete
    suspend fun delete(song: Song)

    @Query("DELETE FROM songs WHERE id = :id")
    suspend fun deleteById(id: Int)

    @Query("SELECT COUNT(*) FROM songs")
    suspend fun getSongCount(): Int
}
