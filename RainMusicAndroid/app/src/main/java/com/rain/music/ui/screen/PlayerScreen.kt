package com.rain.music.ui.screen

import android.content.res.Configuration
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.PlaylistPlay
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.rain.music.data.model.Song
import com.rain.music.manager.LyricLine
import com.rain.music.manager.RepeatMode
import com.rain.music.manager.ShuffleMode
import com.rain.music.ui.theme.RainColors
import com.rain.music.viewmodel.PlayerViewModel
import kotlinx.coroutines.delay
import java.io.File

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun PlayerScreen(
    viewModel: PlayerViewModel,
    onNavigateBack: () -> Unit
) {
    val currentSong by viewModel.currentSong.collectAsState()
    val isPlaying by viewModel.isPlaying.collectAsState()
    val currentTime by viewModel.currentTime.collectAsState()
    val duration by viewModel.duration.collectAsState()
    val repeatMode by viewModel.repeatMode.collectAsState()
    val lyrics by viewModel.lyrics.collectAsState()
    val currentLyricIndex by viewModel.currentLyricIndex.collectAsState()
    val showLyrics by viewModel.showLyrics.collectAsState()
    val context = LocalContext.current
    val configuration = LocalConfiguration.current
    val screenHeight = configuration.screenHeightDp.dp
    val isLandscape = configuration.orientation == Configuration.ORIENTATION_LANDSCAPE

    // 上下滑动切歌状态
    var dragOffsetY by remember { mutableFloatStateOf(0f) }
    val animatedOffset by animateFloatAsState(
        targetValue = dragOffsetY,
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessLow),
        label = "swipeOffset"
    )
    var swipeAlpha by remember { mutableFloatStateOf(1f) }
    val animatedAlpha by animateFloatAsState(
        targetValue = swipeAlpha,
        animationSpec = tween(durationMillis = 180, easing = EaseInOut),
        label = "swipeAlpha"
    )
    var pendingSwitch by remember { mutableIntStateOf(0) }

    // 两阶段切歌动画
    LaunchedEffect(pendingSwitch) {
        if (pendingSwitch != 0) {
            val dir = if (pendingSwitch > 0) -1f else 1f
            val slideDist = 400f
            dragOffsetY = dir * slideDist
            swipeAlpha = 0f
            delay(200)
            if (pendingSwitch > 0) viewModel.playNext() else viewModel.playPrevious()
            dragOffsetY = -dir * slideDist
            delay(16)
            dragOffsetY = 0f
            swipeAlpha = 1f
            pendingSwitch = 0
        }
    }

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

    val albumSize = if (isLandscape) {
        (configuration.screenHeightDp * 0.75f).dp.coerceIn(160.dp, 320.dp)
    } else {
        (screenHeight.value * 0.30f).dp.coerceIn(200.dp, 280.dp)
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(RainColors.BgDark)
    ) {
        // 上下滑动切歌容器
        Box(
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer {
                    translationY = animatedOffset
                    alpha = animatedAlpha
                }
                .pointerInput(Unit) {
                    detectVerticalDragGestures(
                        onDragEnd = {
                            val threshold = size.height * 0.18f
                            if (dragOffsetY < -threshold) {
                                pendingSwitch = 1
                            } else if (dragOffsetY > threshold) {
                                pendingSwitch = -1
                            } else {
                                dragOffsetY = 0f
                            }
                        },
                        onDragCancel = { dragOffsetY = 0f },
                        onVerticalDrag = { change, dragAmount ->
                            change.consume()
                            dragOffsetY += dragAmount
                        }
                    )
                }
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // 顶部导航栏：返回箭头 + 竖三点菜单
                TopNavBar(
                    onNavigateBack = onNavigateBack,
                    onPickImage = {
                        imagePicker.launch(
                            PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                        )
                    }
                )

                if (isLandscape) {
                    // 横屏布局：封面居左 + 控制区居右
                    Row(
                        modifier = Modifier.fillMaxSize(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // 左侧封面
                        Box(
                            modifier = Modifier.weight(0.45f),
                            contentAlignment = Alignment.Center
                        ) {
                            CoverSection(
                                albumSize = albumSize,
                                currentSong = currentSong,
                                showLyrics = showLyrics,
                                lyrics = lyrics,
                                currentLyricIndex = currentLyricIndex,
                                viewModel = viewModel,
                                imagePicker = imagePicker
                            )
                        }
                        // 右侧控制区
                        Column(
                            modifier = Modifier
                                .weight(0.55f)
                                .padding(start = 16.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            SongInfoSection(currentSong = currentSong, titleSize = 22.sp)
                            Spacer(modifier = Modifier.height(12.dp))
                            ProgressBarSection(
                                currentTime = currentTime,
                                duration = duration,
                                isLandscape = true,
                                rightWidthDp = (configuration.screenWidthDp * 0.55f - 48),
                                viewModel = viewModel
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            ControlPanelSection(viewModel = viewModel, isPlaying = isPlaying, repeatMode = repeatMode)
                            Spacer(modifier = Modifier.height(8.dp))
                            ActionRowSection(viewModel = viewModel, showLyrics = showLyrics)
                            Spacer(modifier = Modifier.height(4.dp))
                            SwipeHint()
                        }
                    }
                } else {
                    // 竖屏布局：复用 CoverSection
                    CoverSection(
                        albumSize = albumSize,
                        currentSong = currentSong,
                        showLyrics = showLyrics,
                        lyrics = lyrics,
                        currentLyricIndex = currentLyricIndex,
                        viewModel = viewModel,
                        imagePicker = imagePicker
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // 歌曲信息
                    SongInfoSection(currentSong = currentSong, titleSize = 28.sp)

                    Spacer(modifier = Modifier.height(16.dp))

                    // 进度条
                    ProgressBarSection(
                        currentTime = currentTime,
                        duration = duration,
                        isLandscape = false,
                        rightWidthDp = (configuration.screenWidthDp - 48).toFloat(),
                        viewModel = viewModel
                    )

                    // 时间标签
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            viewModel.formatTime(currentTime),
                            fontSize = 12.sp,
                            color = RainColors.TextSecondary
                        )
                        Text(
                            viewModel.formatTime(duration),
                            fontSize = 12.sp,
                            color = RainColors.TextSecondary
                        )
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    // 药丸控制面板
                    ControlPanelSection(viewModel = viewModel, isPlaying = isPlaying, repeatMode = repeatMode)

                    Spacer(modifier = Modifier.height(12.dp))

                    // 额外操作行
                    ActionRowSection(viewModel = viewModel, showLyrics = showLyrics)

                    Spacer(modifier = Modifier.height(8.dp))

                    SwipeHint()
                }
            }
        }
    }
}

@Composable
private fun TopNavBar(
    onNavigateBack: () -> Unit,
    onPickImage: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = onNavigateBack) {
            Icon(
                Icons.Default.KeyboardArrowDown,
                contentDescription = "返回",
                tint = RainColors.TextPrimary,
                modifier = Modifier.size(28.dp)
            )
        }
        var showMenu by remember { mutableStateOf(false) }
        Box {
            IconButton(onClick = { showMenu = true }) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(3.dp)
                ) {
                    Box(modifier = Modifier.size(3.dp).clip(RoundedCornerShape(50)).background(RainColors.DotGray))
                    Box(modifier = Modifier.size(3.dp).clip(RoundedCornerShape(50)).background(RainColors.DotGray))
                    Box(modifier = Modifier.size(3.dp).clip(RoundedCornerShape(50)).background(RainColors.DotGray))
                }
            }
            DropdownMenu(
                expanded = showMenu,
                onDismissRequest = { showMenu = false }
            ) {
                DropdownMenuItem(
                    text = { Text("更换封面", color = RainColors.TextPrimary) },
                    onClick = {
                        onPickImage()
                        showMenu = false
                    }
                )
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun CoverSection(
    albumSize: androidx.compose.ui.unit.Dp,
    currentSong: Song?,
    showLyrics: Boolean,
    lyrics: List<LyricLine>,
    currentLyricIndex: Int,
    viewModel: PlayerViewModel,
    imagePicker: androidx.activity.result.ActivityResultLauncher<androidx.activity.result.PickVisualMediaRequest>
) {
    androidx.compose.animation.AnimatedContent(
        targetState = currentSong?.id,
        transitionSpec = {
            (fadeIn(animationSpec = tween(200))) togetherWith (fadeOut(animationSpec = tween(200)))
        },
        label = "song_transition"
    ) { _ ->
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            if (showLyrics) {
                LyricsContent(
                    lyrics = lyrics,
                    currentIndex = currentLyricIndex,
                    modifier = Modifier.height(albumSize + 20.dp)
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(albumSize)
                        .shadow(16.dp, RoundedCornerShape(20.dp))
                ) {
                    if (currentSong?.albumArtUri != null) {
                        AsyncImage(
                            model = currentSong.albumArtUri,
                            contentDescription = null,
                            modifier = Modifier
                                .matchParentSize()
                                .clip(RoundedCornerShape(20.dp))
                                .combinedClickable(onClick = {}, onLongClick = {
                                    imagePicker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                                }),
                            contentScale = ContentScale.Crop
                        )
                    } else {
                        Box(
                            modifier = Modifier
                                .matchParentSize()
                                .clip(RoundedCornerShape(20.dp))
                                .background(RainColors.CoverNavy1)
                                .combinedClickable(onClick = {}, onLongClick = {
                                    imagePicker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                                }),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Default.MusicNote, contentDescription = null, modifier = Modifier.size(80.dp), tint = RainColors.TextSecondary)
                        }
                    }
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            TextButton(onClick = { viewModel.toggleLyrics() }) {
                Text(
                    if (showLyrics) "显示封面" else "显示歌词",
                    fontSize = 12.sp,
                    color = RainColors.TextSecondary
                )
            }
        }
    }
}

@Composable
private fun SongInfoSection(
    currentSong: Song?,
    titleSize: androidx.compose.ui.unit.TextUnit
) {
    Text(
        text = currentSong?.title ?: "未在播放",
        fontSize = titleSize,
        fontWeight = FontWeight.Bold,
        color = RainColors.TextPrimary,
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
        textAlign = TextAlign.Center
    )
    Text(
        text = currentSong?.artist ?: "",
        fontSize = 16.sp,
        color = RainColors.TextSecondary,
        maxLines = 1
    )
}

@Composable
private fun ProgressBarSection(
    currentTime: Long,
    duration: Long,
    isLandscape: Boolean,
    rightWidthDp: Float,
    viewModel: PlayerViewModel
) {
    val progress = if (duration > 0) currentTime.toFloat() / duration.toFloat() else 0f
    var isSeeking by remember { mutableStateOf(false) }
    var seekProgress by remember { mutableFloatStateOf(0f) }
    val displayProgress = if (isSeeking) seekProgress else progress

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(24.dp)
            .pointerInput(duration) {
                detectHorizontalDragGestures(
                    onDragStart = { isSeeking = true },
                    onDragEnd = {
                        viewModel.seekTo((seekProgress * duration).toLong())
                        isSeeking = false
                    },
                    onDragCancel = {
                        viewModel.seekTo((seekProgress * duration).toLong())
                        isSeeking = false
                    },
                    onHorizontalDrag = { change, _ ->
                        change.consume()
                        seekProgress = (change.position.x / size.width).coerceIn(0f, 1f)
                    }
                )
            }
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.Center)
                .height(4.dp)
                .clip(RoundedCornerShape(2.dp))
                .background(RainColors.BgBorder)
        )
        Box(
            modifier = Modifier
                .fillMaxWidth(fraction = displayProgress)
                .align(Alignment.CenterStart)
                .height(4.dp)
                .clip(RoundedCornerShape(2.dp))
                .background(RainColors.Accent)
        )
        Box(
            modifier = Modifier
                .align(Alignment.CenterStart)
                .offset(x = (displayProgress * rightWidthDp).dp)
                .size(12.dp)
                .clip(CircleShape)
                .background(RainColors.Accent)
        )
    }

    if (!isLandscape) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(viewModel.formatTime(currentTime), fontSize = 12.sp, color = RainColors.TextSecondary)
            Text(viewModel.formatTime(duration), fontSize = 12.sp, color = RainColors.TextSecondary)
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun ControlPanelSection(
    viewModel: PlayerViewModel,
    isPlaying: Boolean,
    repeatMode: RepeatMode
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(80.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(RainColors.BgPill),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = { viewModel.toggleShuffle() }) {
            Icon(Icons.Default.Shuffle, contentDescription = "随机", tint = RainColors.TextSecondary, modifier = Modifier.size(22.dp))
        }
        IconButton(onClick = { viewModel.playPrevious() }) {
            Icon(Icons.Default.SkipPrevious, contentDescription = "上一曲", tint = RainColors.TextPrimary, modifier = Modifier.size(30.dp))
        }
        Box(
            modifier = Modifier
                .size(56.dp)
                .clip(CircleShape)
                .background(RainColors.Accent)
                .combinedClickable(onClick = { viewModel.togglePlayPause() }),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                contentDescription = if (isPlaying) "暂停" else "播放",
                tint = RainColors.BgDark,
                modifier = Modifier.size(28.dp)
            )
        }
        IconButton(onClick = { viewModel.playNext() }) {
            Icon(Icons.Default.SkipNext, contentDescription = "下一曲", tint = RainColors.TextPrimary, modifier = Modifier.size(30.dp))
        }
        IconButton(onClick = { viewModel.cycleRepeatMode() }) {
            Icon(
                when (repeatMode) {
                    RepeatMode.OFF -> Icons.Default.Repeat
                    RepeatMode.ALL -> Icons.Default.Repeat
                    RepeatMode.ONE -> Icons.Default.RepeatOne
                },
                contentDescription = "循环",
                tint = RainColors.TextSecondary,
                modifier = Modifier.size(22.dp)
            )
        }
    }
}

@Composable
private fun ActionRowSection(
    viewModel: PlayerViewModel,
    showLyrics: Boolean
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        IconButton(onClick = { viewModel.toggleLyrics() }) {
            Icon(
                Icons.Default.Subtitles,
                contentDescription = "歌词",
                tint = if (showLyrics) RainColors.Accent else RainColors.TextSecondary,
                modifier = Modifier.size(24.dp)
            )
        }
        IconButton(onClick = { }) {
            Icon(Icons.AutoMirrored.Filled.PlaylistPlay, contentDescription = "播放列表", tint = RainColors.TextSecondary, modifier = Modifier.size(24.dp))
        }
    }
}

@Composable
private fun SwipeHint() {
    Text(
        "\u2191\u2193 滑动切换歌曲",
        fontSize = 11.sp,
        color = RainColors.TextSecondary.copy(alpha = 0.5f)
    )
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
                    tint = RainColors.TextSecondary
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text("暂无歌词", color = RainColors.TextSecondary, fontSize = 14.sp)
            }
        }
    } else {
        val listState = rememberLazyListState()

        LaunchedEffect(currentIndex) {
            if (currentIndex >= 0 && currentIndex < lyrics.size) {
                delay(100)
                listState.animateScrollToItem(
                    index = currentIndex,
                    scrollOffset = -200
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
                    targetValue = if (isCurrent) RainColors.Accent else RainColors.TextSecondary,
                    label = "lyricColor"
                )

                Text(
                    text = line.text,
                    fontSize = if (isCurrent) 18.sp else 14.sp,
                    fontWeight = if (isCurrent) FontWeight.Bold else FontWeight.Normal,
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
