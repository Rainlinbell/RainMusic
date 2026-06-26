package com.rain.music.manager

import com.rain.music.data.model.Song
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

data class LyricLine(
    val time: Long,      // 毫秒
    val text: String
)

object LyricsParser {

    /**
     * 解析 LRC 歌词内容
     */
    fun parse(lrcContent: String): List<LyricLine> {
        val lines = mutableListOf<LyricLine>()
        val timePattern = Regex("""\[(\d{1,3}):(\d{2})\.(\d{2,3})\]""")

        for (line in lrcContent.lines()) {
            val matches = timePattern.findAll(line).toList()
            if (matches.isEmpty()) continue

            // 提取歌词文本（去掉所有时间标签）
            var text = line
            val times = mutableListOf<Long>()

            for (match in matches) {
                val minutes = match.groupValues[1].toLongOrNull() ?: 0
                val seconds = match.groupValues[2].toLongOrNull() ?: 0
                val msStr = match.groupValues[3]
                val milliseconds = if (msStr.length == 2) {
                    (msStr.toLongOrNull() ?: 0) * 10
                } else {
                    msStr.toLongOrNull() ?: 0
                }

                val time = minutes * 60 * 1000 + seconds * 1000 + milliseconds
                times.add(time)
                text = text.replace(match.value, "")
            }

            text = text.trim()

            // 跳过元数据标签
            if (text.startsWith("[") && text.contains(":")) continue

            for (time in times) {
                lines.add(LyricLine(time, text))
            }
        }

        return lines.sortedBy { it.time }
    }

    /**
     * 二分查找当前歌词行索引
     */
    fun findCurrentLineIndex(lyrics: List<LyricLine>, currentTimeMs: Long): Int {
        if (lyrics.isEmpty()) return -1

        var left = 0
        var right = lyrics.size - 1
        var result = -1

        while (left <= right) {
            val mid = (left + right) / 2
            if (lyrics[mid].time <= currentTimeMs) {
                result = mid
                left = mid + 1
            } else {
                right = mid - 1
            }
        }

        return result
    }

    /**
     * 加载歌曲的歌词
     */
    fun loadLyrics(song: Song): List<LyricLine>? {
        // 优先使用关联的歌词文件
        song.lyricsFilePath?.let { path ->
            val content = readFileContent(path)
            if (content != null) {
                val lines = parse(content)
                if (lines.isNotEmpty()) return lines
            }
        }

        // 尝试在音频文件同目录查找同名 .lrc
        val audioPath = song.fileUri
        if (audioPath.isNotEmpty()) {
            val lrcPath = audioPath.substringBeforeLast(".") + ".lrc"
            val file = File(lrcPath)
            if (file.exists()) {
                val content = readFileContent(lrcPath)
                if (content != null) {
                    val lines = parse(content)
                    if (lines.isNotEmpty()) return lines
                }
            }
        }

        return null
    }

    /**
     * 读取文件内容，支持多种编码
     */
    private fun readFileContent(path: String): String? {
        return try {
            val file = File(path)
            if (!file.exists()) return null

            // 先尝试 UTF-8
            file.bufferedReader(Charsets.UTF_8).use { it.readText() }
        } catch (e: Exception) {
            try {
                // 尝试 GBK
                val file = File(path)
                file.bufferedReader(java.nio.charset.Charset.forName("GBK")).use { it.readText() }
            } catch (e: Exception) {
                null
            }
        }
    }
}
