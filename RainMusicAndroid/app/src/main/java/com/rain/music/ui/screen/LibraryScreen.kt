package com.rain.music.ui.screen

import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.nestedscroll.NestedScrollConnection
import androidx.compose.ui.input.nestedscroll.NestedScrollSource
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlin.math.abs
import coil.compose.AsyncImage
import com.rain.music.data.model.Song
import com.rain.music.viewmodel.PlayerViewModel
import com.rain.music.viewmodel.SortOrder

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LibraryScreen(
    viewModel: PlayerViewModel,
    onNavigateToPlayer: () -> Unit,
    onNavigateToImport: () -> Unit
) {
    val songs by viewModel.songs.collectAsState()
    val currentSong by viewModel.currentSong.collectAsState()
    val isScanning by viewModel.isScanning.collectAsState()
    val scanResult by viewModel.scanResult.collectAsState()
    val sortOrder by viewModel.sortOrder.collectAsState()
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
                        viewModel.playPrevious()
                    } else if (available.y < 0) {
                        val layoutInfo = listState.layoutInfo
                        val lastItem = layoutInfo.visibleItemsInfo.lastOrNull()
                        val isAtBottom = lastItem != null &&
                            lastItem.index == layoutInfo.totalItemsCount - 1 &&
                            lastItem.offset + lastItem.size <= layoutInfo.viewportEndOffset
                        if (isAtBottom || layoutInfo.totalItemsCount == 0) {
                            switchTargetOffset = -60f
                            lastSwitchTime = now
                            viewModel.playNext()
                        }
                    }
                }
                return Offset.Zero
            }
        }
    }

    // 切歌平滑回弹动画
    LaunchedEffect(switchTargetOffset) {
        if (switchTargetOffset != 0f) {
            delay(200)
            switchTargetOffset = 0f
        }
    }

    // 搜索栏关闭时清除搜索状态
    LaunchedEffect(isSearchActive) {
        if (!isSearchActive) {
            searchQuery = ""
            viewModel.setSearchQuery("")
        }
    }

    LaunchedEffect(scanResult) {
        scanResult?.let {
            snackbarHostState.showSnackbar(it)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("音乐库") },
                actions = {
                    // 搜索按钮
                    IconButton(onClick = { isSearchActive = !isSearchActive }) {
                        Icon(
                            if (isSearchActive) Icons.Default.Close else Icons.Default.Search,
                            contentDescription = "搜索"
                        )
                    }

                    // 排序菜单
                    Box {
                        IconButton(onClick = { showSortMenu = true }) {
                            Icon(Icons.Default.Sort, contentDescription = "排序")
                        }
                        DropdownMenu(
                            expanded = showSortMenu,
                            onDismissRequest = { showSortMenu = false }
                        ) {
                            SortOrder.entries.forEach { order ->
                                DropdownMenuItem(
                                    text = {
                                        Text(when (order) {
                                            SortOrder.DATE_ADDED -> "添加时间"
                                            SortOrder.TITLE -> "歌曲名"
                                            SortOrder.ARTIST -> "艺术家"
                                            SortOrder.ALBUM -> "专辑"
                                        })
                                    },
                                    onClick = {
                                        viewModel.setSortOrder(order)
                                        showSortMenu = false
                                    },
                                    leadingIcon = if (order == sortOrder) {
                                        { Icon(Icons.Default.Check, contentDescription = null) }
                                    } else null
                                )
                            }
                        }
                    }

                    // 导入按钮
                    IconButton(onClick = onNavigateToImport) {
                        Icon(Icons.Default.Add, contentDescription = "导入文件")
                    }
                }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Box(modifier = Modifier.padding(paddingValues)) {
            Column {
                // 搜索栏
                if (isSearchActive) {
                    OutlinedTextField(
                        value = searchQuery,
                        onValueChange = {
                            searchQuery = it
                            viewModel.setSearchQuery(it)
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp),
                        placeholder = { Text("搜索歌曲、艺术家、专辑") },
                        leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                        trailingIcon = {
                            if (searchQuery.isNotEmpty()) {
                                IconButton(onClick = {
                                    searchQuery = ""
                                    viewModel.setSearchQuery("")
                                }) {
                                    Icon(Icons.Default.Clear, contentDescription = "清除")
                                }
                            }
                        },
                        singleLine = true
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
                        tint = MaterialTheme.colorScheme.secondary
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text("音乐库为空", style = MaterialTheme.typography.titleMedium)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        "扫描设备音乐库或导入音频文件",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Button(onClick = { viewModel.scanMusic() }) {
                            Icon(Icons.Default.Search, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("扫描音乐库")
                        }
                        OutlinedButton(onClick = onNavigateToImport) {
                            Icon(Icons.Default.FileDownload, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("导入文件")
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
                    contentPadding = PaddingValues(bottom = if (currentSong != null) 80.dp else 0.dp)
                ) {
                    items(songs, key = { it.id }) { song ->
                        SongRow(
                            song = song,
                            isCurrentPlaying = currentSong?.id == song.id,
                            onClick = {
                                viewModel.setPlaylist(songs, songs.indexOf(song))
                                onNavigateToPlayer()
                            },
                            onDelete = { viewModel.deleteSong(song) }
                        )
                    }
                }
            }
            } // Column end

            // 扫描中遮罩
            if (isScanning) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.scrim.copy(alpha = 0.4f)
                ) {
                    Card(
                        modifier = Modifier.align(Alignment.Center).padding(32.dp),
                        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
                    ) {
                        Column(
                            modifier = Modifier.padding(24.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            CircularProgressIndicator()
                            Spacer(modifier = Modifier.height(16.dp))
                            Text("正在扫描音乐库...")
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
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // 封面
        if (song.albumArtUri != null) {
            AsyncImage(
                model = song.albumArtUri,
                contentDescription = null,
                modifier = Modifier.size(48.dp)
            )
        } else {
            Surface(
                modifier = Modifier.size(48.dp),
                shape = MaterialTheme.shapes.small,
                color = MaterialTheme.colorScheme.primaryContainer
            ) {
                Icon(
                    Icons.Default.MusicNote,
                    contentDescription = null,
                    modifier = Modifier.padding(12.dp),
                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
        }

        Spacer(modifier = Modifier.width(12.dp))

        // 歌曲信息
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = song.title,
                style = MaterialTheme.typography.bodyLarge,
                color = if (isCurrentPlaying) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface,
                fontWeight = if (isCurrentPlaying) androidx.compose.ui.text.font.FontWeight.SemiBold else androidx.compose.ui.text.font.FontWeight.Normal,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = "${song.artist} · ${song.album}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }

        // 时长
        Text(
            text = song.formattedDuration,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        // 更多菜单
        Box {
            IconButton(onClick = { showMenu = true }) {
                Icon(Icons.Default.MoreVert, contentDescription = "更多")
            }
            DropdownMenu(expanded = showMenu, onDismissRequest = { showMenu = false }) {
                DropdownMenuItem(
                    text = { Text("删除") },
                    onClick = { onDelete(); showMenu = false },
                    leadingIcon = { Icon(Icons.Default.Delete, contentDescription = null) }
                )
            }
        }
    }
}
