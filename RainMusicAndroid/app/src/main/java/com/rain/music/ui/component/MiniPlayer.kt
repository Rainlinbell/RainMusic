package com.rain.music.ui.component

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.rain.music.data.model.Song
import com.rain.music.viewmodel.PlayerViewModel

@Composable
fun MiniPlayer(
    viewModel: PlayerViewModel,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val currentSong by viewModel.currentSong.collectAsState()
    val isPlaying by viewModel.isPlaying.collectAsState()
    val currentTime by viewModel.currentTime.collectAsState()
    val duration by viewModel.duration.collectAsState()

    currentSong ?: return

    Surface(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 4.dp)
            .clip(MaterialTheme.shapes.medium),
        tonalElevation = 4.dp,
        shadowElevation = 4.dp
    ) {
        Column {
            // 进度条
            LinearProgressIndicator(
                progress = if (duration > 0) currentTime.toFloat() / duration.toFloat() else 0f,
                modifier = Modifier.fillMaxWidth().height(2.dp),
            )

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onClick)
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // 封面
                if (currentSong?.albumArtUri != null) {
                    AsyncImage(
                        model = currentSong?.albumArtUri,
                        contentDescription = null,
                        modifier = Modifier.size(40.dp).clip(MaterialTheme.shapes.small),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    Surface(
                        modifier = Modifier.size(40.dp),
                        shape = MaterialTheme.shapes.small,
                        color = MaterialTheme.colorScheme.primaryContainer
                    ) {
                        Icon(
                            Icons.Default.MusicNote,
                            contentDescription = null,
                            modifier = Modifier.padding(8.dp),
                            tint = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    }
                }

                Spacer(modifier = Modifier.width(12.dp))

                // 歌曲信息
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = currentSong?.title ?: "",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = androidx.compose.ui.text.font.FontWeight.Medium,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = currentSong?.artist ?: "",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1
                    )
                }

                // 播放/暂停
                IconButton(onClick = { viewModel.togglePlayPause() }) {
                    Icon(
                        if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                        contentDescription = if (isPlaying) "暂停" else "播放"
                    )
                }

                // 下一曲
                IconButton(onClick = { viewModel.playNext() }) {
                    Icon(Icons.Default.SkipNext, contentDescription = "下一曲")
                }
            }
        }
    }
}
