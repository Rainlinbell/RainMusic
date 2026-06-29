package com.rain.music.ui.component

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.rain.music.ui.theme.RainColors
import com.rain.music.viewmodel.PlayerViewModel

enum class TabItem(val label: String, val icon: @Composable () -> Unit) {
    Library("音乐库", {
        Icon(Icons.Default.LibraryMusic, contentDescription = "音乐库", modifier = Modifier.size(20.dp))
    }),
    Import("导入音乐", {
        Icon(Icons.Default.FileDownload, contentDescription = "导入音乐", modifier = Modifier.size(20.dp))
    })
}

@Composable
fun BottomTabBar(
    viewModel: PlayerViewModel,
    selectedTab: TabItem,
    onTabSelected: (TabItem) -> Unit,
    onOpenPlayer: () -> Unit,
    modifier: Modifier = Modifier
) {
    val currentSong by viewModel.currentSong.collectAsState()
    val isPlaying by viewModel.isPlaying.collectAsState()

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 8.dp)
    ) {
        Column {
            // 迷你播放区域（有歌曲时显示）
            if (currentSong != null) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 6.dp)
                        .clip(RoundedCornerShape(20.dp))
                        .background(RainColors.BgPill)
                        .clickable(onClick = onOpenPlayer)
                        .padding(horizontal = 14.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // 小封面
                    if (currentSong?.albumArtUri != null) {
                        AsyncImage(
                            model = currentSong?.albumArtUri,
                            contentDescription = null,
                            modifier = Modifier
                                .size(36.dp)
                                .clip(RoundedCornerShape(8.dp)),
                            contentScale = ContentScale.Crop
                        )
                    } else {
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(RainColors.CoverNavy1),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                Icons.Default.MusicNote,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp),
                                tint = RainColors.TextSecondary
                            )
                        }
                    }

                    Spacer(modifier = Modifier.width(10.dp))

                    // 歌曲标题
                    Text(
                        text = currentSong?.title ?: "",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = RainColors.TextPrimary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f)
                    )

                    Spacer(modifier = Modifier.width(8.dp))

                    // 播放/暂停按钮
                    IconButton(
                        onClick = { viewModel.togglePlayPause() },
                        modifier = Modifier.size(32.dp)
                    ) {
                        Icon(
                            if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                            contentDescription = if (isPlaying) "暂停" else "播放",
                            modifier = Modifier.size(20.dp),
                            tint = RainColors.Accent
                        )
                    }

                    // 下一曲按钮
                    IconButton(
                        onClick = { viewModel.playNext() },
                        modifier = Modifier.size(32.dp)
                    ) {
                        Icon(
                            Icons.Default.SkipNext,
                            contentDescription = "下一曲",
                            modifier = Modifier.size(18.dp),
                            tint = RainColors.TextSecondary
                        )
                    }
                }
            }

            // Tab 栏（药丸形）
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(36.dp))
                    .background(RainColors.BgPill)
                    .height(52.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                TabItem.entries.forEach { tab ->
                    val isSelected = tab == selectedTab
                    Row(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                            .clip(RoundedCornerShape(36.dp))
                            .background(if (isSelected) RainColors.Accent else Color.Transparent)
                            .clickable { onTabSelected(tab) },
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        tab.icon()
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = tab.label,
                            fontSize = 14.sp,
                            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                            color = if (isSelected) RainColors.BgDark else RainColors.TextSecondary
                        )
                    }
                }
            }
        }
    }
}
