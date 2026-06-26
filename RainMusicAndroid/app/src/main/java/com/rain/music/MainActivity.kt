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
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import androidx.lifecycle.viewmodel.compose.viewModel
import com.rain.music.ui.component.MiniPlayer
import com.rain.music.ui.screen.ImportScreen
import com.rain.music.ui.screen.LibraryScreen
import com.rain.music.ui.screen.PlayerScreen
import com.rain.music.ui.theme.RainMusicTheme
import com.rain.music.viewmodel.PlayerViewModel

class MainActivity : ComponentActivity() {

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { _ -> }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        requestPermissions()

        setContent {
            RainMusicTheme {
                val viewModel: PlayerViewModel = viewModel()
                var currentScreen by remember { mutableStateOf(Screen.Library) }

                Box(modifier = Modifier.fillMaxSize()) {
                    AnimatedContent(
                        targetState = currentScreen,
                        transitionSpec = {
                            when (targetState) {
                                Screen.Player -> {
                                    (slideInVertically(animationSpec = tween(300)) { height -> height } +
                                        fadeIn(animationSpec = tween(300))) togetherWith
                                    (slideOutVertically(animationSpec = tween(300)) { height -> -height / 3 } +
                                        fadeOut(animationSpec = tween(300)))
                                }
                                Screen.Import -> {
                                    (slideInHorizontally(animationSpec = tween(300)) { width -> width } +
                                        fadeIn(animationSpec = tween(300))) togetherWith
                                    (slideOutHorizontally(animationSpec = tween(300)) { width -> -width } +
                                        fadeOut(animationSpec = tween(300)))
                                }
                                else -> {
                                    (slideInVertically(animationSpec = tween(300)) { height -> -height } +
                                        fadeIn(animationSpec = tween(300))) togetherWith
                                    (slideOutVertically(animationSpec = tween(300)) { height -> height } +
                                        fadeOut(animationSpec = tween(300)))
                                }
                            }
                        },
                        label = "screen_transition"
                    ) { screen ->
                        when (screen) {
                            Screen.Library -> {
                                LibraryScreen(
                                    viewModel = viewModel,
                                    onNavigateToPlayer = { currentScreen = Screen.Player },
                                    onNavigateToImport = { currentScreen = Screen.Import }
                                )
                            }
                            Screen.Player -> {
                                PlayerScreen(
                                    viewModel = viewModel,
                                    onNavigateBack = { currentScreen = Screen.Library }
                                )
                            }
                            Screen.Import -> {
                                ImportScreen(
                                    viewModel = viewModel,
                                    onNavigateBack = { currentScreen = Screen.Library }
                                )
                            }
                        }
                    }

                    // 底部迷你播放器（仅在 Library 页面显示）
                    if (currentScreen == Screen.Library) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .align(androidx.compose.ui.Alignment.BottomCenter)
                        ) {
                            MiniPlayer(
                                viewModel = viewModel,
                                onClick = { currentScreen = Screen.Player }
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

enum class Screen {
    Library, Player, Import
}
