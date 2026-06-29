package com.rain.music.ui.screen

import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.nestedscroll.NestedScrollConnection
import androidx.compose.ui.input.nestedscroll.NestedScrollSource
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlin.math.abs
import coil.compose.AsyncImage
import com.rain.music.data.model.Song
import com.rain.music.ui.theme.RainColors
import com.rain.music.viewmodel.LibraryViewModel
import com.rain.music.viewmodel.PlayerViewModel
import com.rain.music.viewmodel.SortOrder

@Composable
fun LibraryScreen(
    viewModel: PlayerViewModel,
    libraryViewModel: LibraryViewModel,
    onNavigateToPlayer: () -> Unit
) {
    val songs by libraryViewModel.songs.collectAsState()
    val currentSong by viewModel.currentSong.collectAsState()
    val isScanning by libraryViewModel.isScanning.collectAsState()
    val scanResult by libraryViewModel.scanResult.collectAsState()
    val sortOrder by libraryViewModel.sortOrder.collectAsState()
    var searchQuery by remember { mutableStateOf("") }
    var showSortMenu by remember { mutableStateOf(false) }
    var isSearchActive by remember { mutableStateOf(false) }
    val snackbarHostState = remember { SnackbarHostState() }
    val listState = rememberLazyListState()

    // 上下滑动切歌状态
    var switchTargetOffset by remember { mutableFloatStateOf(0f) }
    var lastSwitchTime by remember { mutableLongStateOf(0L) }
    val switchOffset by animateFloatAsState(
        targetValue = switchTargetOffset,
        animationSpec = tween(durationMillis = 300, easing = EaseInOut),
        label = "switchOffset"
    )

    val nestedScrollConnection = remember {
        object : NestedScrollConnection {
            override fun onPostScroll(
                consumed: Offset,
                available: Offset,
                source: NestedScrollSource
            ): Offset {
                val now = System.currentTimeMillis()
                if (now - lastSwitchTime < 1500) return Offset.Zero
                if (abs(available.y) > 40f) {
                    if (available.y > 0 && listState.firstVisibleItemIndex == 0 && listState.firstVisibleItemScrollOffset == 0) {
                        switchTargetOffset = 60f
                        lastSwitchTime = now
                        viewModel.playPrevious(songs)
                    } else if (available.y < 0) {
                        val layoutInfo = listState.layoutInfo
                        val lastItem = layoutInfo.visibleItemsInfo.lastOrNull()
                        val isAtBottom = lastItem != null &&
                            lastItem.index == layoutInfo.totalItemsCount - 1 &&
                            lastItem.offset + lastItem.size <= layoutInfo.viewportEndOffset
                        if (isAtBottom || layoutInfo.totalItemsCount == 0) {
                            switchTargetOffset = -60f
                            lastSwitchTime = now
                            viewModel.playNext(songs)
                        }
                    }
                }
                return Offset.Zero
            }
        }
    }

    LaunchedEffect(switchTargetOffset) {
        if (switchTargetOffset != 0f) {
            delay(200)
            switchTargetOffset = 0f
        }
    }

    LaunchedEffect(isSearchActive) {
        if (!isSearchActive) {
            searchQuery = ""
            libraryViewModel.setSearchQuery("")
        }
    }

    LaunchedEffect(scanResult) {
        scanResult?.let {
            snackbarHostState.showSnackbar(it)
        }
    }


    Scaffold(
        containerColor = RainColors.BgDark,
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // 自定义 Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    "我的音乐",
                    fontSize = 28.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = RainColors.TextPrimary
                )
                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    // 搜索
                    IconButton(onClick = { isSearchActive = !isSearchActive }) {
                        Icon(
                            if (isSearchActive) Icons.Default.Close else Icons.Default.Search,
                            contentDescription = "搜索",
                            tint = Color.White
                        )
                    }
                    // 排序菜单
                    Box {
                        IconButton(onClick = { showSortMenu = true }) {
                            Icon(
                                Icons.Default.MoreVert,
                                contentDescription = "菜单",
                                tint = Color.White
                            )
                        }
                        DropdownMenu(
                            expanded = showSortMenu,
                            onDismissRequest = { showSortMenu = false }
                        ) {
                            SortOrder.entries.forEach { order ->
                                DropdownMenuItem(
                                    text = {
                                        Text(
                                            when (order) {
                                                SortOrder.DATE_ADDED -> "添加时间"
                                                SortOrder.TITLE -> "歌曲名"
                                                SortOrder.ARTIST -> "艺术家"
                                                SortOrder.ALBUM -> "专辑"
                                            },
                                            color = RainColors.TextPrimary
                                        )
                                    },
                                    onClick = {
                                        libraryViewModel.setSortOrder(order)
                                        showSortMenu = false
                                    },
                                    leadingIcon = if (order == sortOrder) {
                                        { Icon(Icons.Default.Check, contentDescription = null, tint = RainColors.Accent) }
                                    } else null
                                )
                            }
                        }
                    }
                }
            }

            // 搜索栏
            if (isSearchActive) {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = {
                        searchQuery = it
                        libraryViewModel.setSearchQuery(it)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 4.dp),
                    placeholder = { Text("搜索歌曲、艺术家、专辑", color = RainColors.TextSecondary) },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = RainColors.TextSecondary) },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = {
                                searchQuery = ""
                                libraryViewModel.setSearchQuery("")
                            }) {
                                Icon(Icons.Default.Clear, contentDescription = "清除", tint = RainColors.TextSecondary)
                            }
                        }
                    },
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = RainColors.Accent,
                        unfocusedBorderColor = RainColors.BgBorder,
                        focusedTextColor = RainColors.TextPrimary,
                        unfocusedTextColor = RainColors.TextPrimary,
                        cursorColor = RainColors.Accent
                    )
                )
            }

            if (songs.isEmpty() && !isSearchActive) {
                // 空状态
                Column(
                    modifier = Modifier.fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Icon(
                        Icons.Default.LibraryMusic,
                        contentDescription = null,
                        modifier = Modifier.size(64.dp),
                        tint = RainColors.TextSecondary
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text("音乐库为空", fontSize = 18.sp, fontWeight = FontWeight.Medium, color = RainColors.TextPrimary)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("扫描设备音乐库或导入音频文件", fontSize = 14.sp, color = RainColors.TextSecondary)
                    Spacer(modifier = Modifier.height(24.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Button(
                            onClick = { libraryViewModel.scanMusic() },
                            colors = ButtonDefaults.buttonColors(containerColor = RainColors.Accent, contentColor = RainColors.BgDark)
                        ) {
                            Icon(Icons.Default.Search, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("扫描音乐库")
                        }
                    }
                }
            } else {
                // 歌曲列表
                LazyColumn(
                    state = listState,
                    modifier = Modifier
                        .fillMaxSize()
                        .nestedScroll(nestedScrollConnection)
                        .graphicsLayer { translationY = switchOffset },
                    contentPadding = PaddingValues(start = 20.dp, end = 20.dp, bottom = 110.dp)
                ) {
                    // 歌曲计数
                    item {
                        Text(
                            "所有歌曲 · ${songs.size}首",
                            fontSize = 14.sp,
                            color = RainColors.TextSecondary,
                            modifier = Modifier.padding(bottom = 8.dp)
                        )
                    }

                    items(songs, key = { it.id }) { song ->
                        SongRow(
                            song = song,
                            isCurrentPlaying = currentSong?.id == song.id,
                            onClick = {
                                viewModel.setPlaylist(songs, songs.indexOf(song))
                                onNavigateToPlayer()
                            },
                            onDelete = { libraryViewModel.deleteSong(song) }
                        )
                    }
                }
            }

            // 扫描中遮罩
            if (isScanning) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = Color.Black.copy(alpha = 0.4f)
                ) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Card(
                            modifier = Modifier.padding(32.dp),
                            colors = CardDefaults.cardColors(containerColor = RainColors.BgPill)
                        ) {
                            Column(
                                modifier = Modifier.padding(24.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                CircularProgressIndicator(color = RainColors.Accent)
                                Spacer(modifier = Modifier.height(16.dp))
                                Text("正在扫描音乐库...", color = RainColors.TextPrimary)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun SongRow(
    song: Song,
    isCurrentPlaying: Boolean,
    onClick: () -> Unit,
    onDelete: () -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 8.dp, vertical = 8.dp)
            .clip(RoundedCornerShape(8.dp)),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // 封面
        if (song.albumArtUri != null) {
            AsyncImage(
                model = song.albumArtUri,
                contentDescription = null,
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(6.dp)),
                contentScale = ContentScale.Crop
            )
        } else {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(RainColors.CoverNavy1)
            )
        }

        Spacer(modifier = Modifier.width(12.dp))

        // 歌曲信息
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = song.title,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                color = if (isCurrentPlaying) RainColors.Accent else RainColors.TextPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = song.artist,
                fontSize = 12.sp,
                color = RainColors.TextSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }

        // 时长
        Text(
            text = song.formattedDuration,
            fontSize = 13.sp,
            color = RainColors.TextSecondary
        )

        // 竖三点更多按钮
        Box {
            IconButton(onClick = { showMenu = true }, modifier = Modifier.size(24.dp)) {
                // 竖三点图标
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(3.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(3.dp)
                            .clip(RoundedCornerShape(50))
                            .background(RainColors.DotGray)
                    )
                    Box(
                        modifier = Modifier
                            .size(3.dp)
                            .clip(RoundedCornerShape(50))
                            .background(RainColors.DotGray)
                    )
                    Box(
                        modifier = Modifier
                            .size(3.dp)
                            .clip(RoundedCornerShape(50))
                            .background(RainColors.DotGray)
                    )
                }
            }
            DropdownMenu(
                expanded = showMenu,
                onDismissRequest = { showMenu = false }
            ) {
                DropdownMenuItem(
                    text = { Text("删除", color = RainColors.TextPrimary) },
                    onClick = { onDelete(); showMenu = false },
                    leadingIcon = { Icon(Icons.Default.Delete, contentDescription = null, tint = RainColors.TextSecondary) }
                )
            }
        }
    }
}
