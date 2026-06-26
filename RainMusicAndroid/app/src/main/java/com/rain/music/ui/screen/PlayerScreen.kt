package com.rain.music.ui.screen

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.rain.music.manager.LyricLine
import com.rain.music.manager.RepeatMode
import com.rain.music.manager.ShuffleMode
import com.rain.music.viewmodel.PlayerViewModel
import kotlinx.coroutines.delay
import java.io.File

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun PlayerScreen(
    viewModel: PlayerViewModel,
    onNavigateBack: () -> Unit
) {
    val currentSong by viewModel.currentSong.collectAsState()
    val isPlaying by viewModel.isPlaying.collectAsState()
    val currentTime by viewModel.currentTime.collectAsState()
    val duration by viewModel.duration.collectAsState()
    val shuffleMode by viewModel.shuffleMode.collectAsState()
    val repeatMode by viewModel.repeatMode.collectAsState()
    val lyrics by viewModel.lyrics.collectAsState()
    val currentLyricIndex by viewModel.currentLyricIndex.collectAsState()
    val showLyrics by viewModel.showLyrics.collectAsState()
    val systemVolume by viewModel.systemVolume.collectAsState()
    val context = LocalContext.current

    // 图片选择器
    val imagePicker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri ->
        uri?.let { selectedUri ->
            val song = currentSong ?: return@let
            val destFile = File(context.filesDir, "albumArt_${song.id}_${System.currentTimeMillis()}.jpg")
            context.contentResolver.openInputStream(selectedUri)?.use { input ->
                destFile.outputStream().use { output -> input.copyTo(output) }
            }
            viewModel.updateAlbumArt(song.id, destFile.absolutePath)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("正在播放") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.KeyboardArrowDown, contentDescription = "返回")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(8.dp))

            // 封面 / 歌词切换
            if (showLyrics) {
                LyricsContent(
                    lyrics = lyrics,
                    currentIndex = currentLyricIndex,
                    modifier = Modifier.height(320.dp)
                )
            } else {
                // 专辑封面（长按更换封面）
                if (currentSong?.albumArtUri != null) {
                    AsyncImage(
                        model = currentSong?.albumArtUri,
                        contentDescription = null,
                        modifier = Modifier
                            .size(280.dp)
                            .clip(MaterialTheme.shapes.large)
                            .combinedClickable(
                                onClick = { },
                                onLongClick = {
                                    imagePicker.launch(
                                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                    )
                                }
                            ),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    Surface(
                        modifier = Modifier
                            .size(280.dp)
                            .combinedClickable(
                                onClick = { },
                                onLongClick = {
                                    imagePicker.launch(
                                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                    )
                                }
                            ),
                        shape = MaterialTheme.shapes.large,
                        color = MaterialTheme.colorScheme.primaryContainer
                    ) {
                        Icon(
                            Icons.Default.MusicNote,
                            contentDescription = null,
                            modifier = Modifier.size(80.dp),
                            tint = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    }
                }

                // 更换封面提示
                Text(
                    "长按封面可更换图片",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.outline
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            // 切换提示
            TextButton(onClick = { viewModel.toggleLyrics() }) {
                Text(
                    if (showLyrics) "显示封面" else "显示歌词",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // 歌曲信息
            Text(
                text = currentSong?.title ?: "未在播放",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center
            )
            Text(
                text = currentSong?.artist ?: "",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1
            )
            Text(
                text = currentSong?.album ?: "",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.outline,
                maxLines = 1
            )

            Spacer(modifier = Modifier.height(24.dp))

            // 进度条
            var isSeeking by remember { mutableStateOf(false) }
            var seekPosition by remember { mutableFloatStateOf(0f) }

            Slider(
                value = if (isSeeking) seekPosition else if (duration > 0) currentTime.toFloat() else 0f,
                onValueChange = {
                    isSeeking = true
                    seekPosition = it
                },
                onValueChangeFinished = {
                    viewModel.seekTo(seekPosition.toLong())
                    isSeeking = false
                },
                valueRange = 0f..(duration.toFloat().coerceAtLeast(1f)),
                modifier = Modifier.fillMaxWidth()
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    viewModel.formatTime(currentTime),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    viewModel.formatTime(duration),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // 控制按钮
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // 随机
                IconButton(onClick = { viewModel.toggleShuffle() }) {
                    Icon(
                        Icons.Default.Shuffle,
                        contentDescription = "随机",
                        tint = if (shuffleMode == ShuffleMode.ON) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                // 上一曲
                IconButton(onClick = { viewModel.playPrevious() }) {
                    Icon(Icons.Default.SkipPrevious, contentDescription = "上一曲", modifier = Modifier.size(36.dp))
                }

                // 播放/暂停
                FilledIconButton(
                    onClick = { viewModel.togglePlayPause() },
                    modifier = Modifier.size(64.dp)
                ) {
                    Icon(
                        if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                        contentDescription = if (isPlaying) "暂停" else "播放",
                        modifier = Modifier.size(36.dp)
                    )
                }

                // 下一曲
                IconButton(onClick = { viewModel.playNext() }) {
                    Icon(Icons.Default.SkipNext, contentDescription = "下一曲", modifier = Modifier.size(36.dp))
                }

                // 循环
                IconButton(onClick = { viewModel.cycleRepeatMode() }) {
                    Icon(
                        when (repeatMode) {
                            RepeatMode.OFF -> Icons.Default.Repeat
                            RepeatMode.ALL -> Icons.Default.Repeat
                            RepeatMode.ONE -> Icons.Default.RepeatOne
                        },
                        contentDescription = "循环",
                        tint = if (repeatMode != RepeatMode.OFF) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // 音量（系统音量）
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Default.VolumeDown, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                Slider(
                    value = systemVolume,
                    onValueChange = { viewModel.setVolume(it) },
                    modifier = Modifier.weight(1f)
                )
                Icon(Icons.Default.VolumeUp, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
fun LyricsContent(
    lyrics: List<LyricLine>,
    currentIndex: Int,
    modifier: Modifier = Modifier
) {
    if (lyrics.isEmpty()) {
        Box(modifier = modifier.fillMaxWidth()) {
            Column(
                modifier = Modifier.align(Alignment.Center),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    Icons.Default.MusicNote,
                    contentDescription = null,
                    modifier = Modifier.size(40.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text("暂无歌词", color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    } else {
        val listState = rememberLazyListState()

        // 自动滚动到当前歌词行（居中显示）
        LaunchedEffect(currentIndex) {
            if (currentIndex >= 0 && currentIndex < lyrics.size) {
                delay(100) // 微小延迟确保布局完成
                listState.animateScrollToItem(
                    index = currentIndex,
                    scrollOffset = -200 // 偏移使当前行居中
                )
            }
        }

        LazyColumn(
            state = listState,
            modifier = modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            contentPadding = PaddingValues(vertical = 80.dp)
        ) {
            items(lyrics.size) { index ->
                val line = lyrics[index]
                val isCurrent = index == currentIndex
                val color by animateColorAsState(
                    targetValue = if (isCurrent) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                    label = "lyricColor"
                )

                Text(
                    text = line.text,
                    fontSize = if (isCurrent) 18.sp else 14.sp,
                    fontWeight = if (isCurrent) androidx.compose.ui.text.font.FontWeight.Bold else androidx.compose.ui.text.font.FontWeight.Normal,
                    color = color,
                    textAlign = TextAlign.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 6.dp)
                )
            }
        }
    }
}
