package com.rain.music

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.*
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import androidx.lifecycle.viewmodel.compose.viewModel
import com.rain.music.ui.component.BottomTabBar
import com.rain.music.ui.component.TabItem
import com.rain.music.ui.screen.ImportScreen
import com.rain.music.ui.screen.LibraryScreen
import com.rain.music.ui.screen.PlayerScreen
import com.rain.music.ui.theme.RainColors
import com.rain.music.ui.theme.RainMusicTheme
import com.rain.music.viewmodel.LibraryViewModel
import com.rain.music.viewmodel.PlayerViewModel

class MainActivity : ComponentActivity() {

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { result ->
        val allGranted = result.values.all { it }
        if (!allGranted) {
            android.widget.Toast.makeText(
                this, "部分权限未授予，扫描音乐功能可能受限", android.widget.Toast.LENGTH_LONG
            ).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        requestPermissions()

        setContent {
            RainMusicTheme {
                val viewModel: PlayerViewModel = viewModel()
                val libraryViewModel: LibraryViewModel = viewModel()
                var selectedTab by remember { mutableStateOf(TabItem.Library) }
                var showPlayer by remember { mutableStateOf(false) }

                Box(modifier = Modifier.fillMaxSize()) {
                    if (showPlayer) {
                        // 全屏播放器
                        AnimatedContent(
                            targetState = showPlayer,
                            transitionSpec = {
                                (slideInVertically(animationSpec = tween(300)) { height -> height } +
                                    fadeIn(animationSpec = tween(300))) togetherWith
                                (slideOutVertically(animationSpec = tween(300)) { height -> height } +
                                    fadeOut(animationSpec = tween(300)))
                            },
                            label = "player_transition"
                        ) {
                            PlayerScreen(
                                viewModel = viewModel,
                                onNavigateBack = { showPlayer = false }
                            )
                        }
                    } else {
                        // Tab 内容
                        AnimatedContent(
                            targetState = selectedTab,
                            transitionSpec = {
                                fadeIn(animationSpec = tween(200)) togetherWith
                                    fadeOut(animationSpec = tween(200))
                            },
                            label = "tab_transition"
                        ) { tab ->
                            when (tab) {
                                TabItem.Library -> {
                                    LibraryScreen(
                                        viewModel = viewModel,
                                        libraryViewModel = libraryViewModel,
                                        onNavigateToPlayer = { showPlayer = true }
                                    )
                                }
                                TabItem.Import -> {
                                    ImportScreen(
                                        libraryViewModel = libraryViewModel
                                    )
                                }
                            }
                        }

                        // 底部 Tab 栏（常驻）
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .align(Alignment.BottomCenter)
                        ) {
                            BottomTabBar(
                                viewModel = viewModel,
                                selectedTab = selectedTab,
                                onTabSelected = { selectedTab = it },
                                onOpenPlayer = { showPlayer = true }
                            )
                        }
                    }
                }
            }
        }
    }

    private fun requestPermissions() {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                Manifest.permission.READ_MEDIA_AUDIO,
                Manifest.permission.POST_NOTIFICATIONS
            )
        } else {
            arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        }

        val notGranted = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (notGranted.isNotEmpty()) {
            requestPermissionLauncher.launch(notGranted.toTypedArray())
        }
    }
}
