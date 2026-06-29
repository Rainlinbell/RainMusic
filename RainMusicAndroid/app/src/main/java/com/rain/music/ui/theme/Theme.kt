package com.rain.music.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

// 设计色板
object RainColors {
    val BgDark = Color(0xFF0A1628)
    val BgPill = Color(0xFF111B40)
    val BgBorder = Color(0xFF1E3A5F)
    val Accent = Color(0xFF4FC3F7)
    val AccentDark = Color(0xFF29B6F6)
    val TextPrimary = Color(0xFFE0E8F0)
    val TextSecondary = Color(0xFF8899AA)
    val DotGray = Color(0xFFB3B3B3)
    val CoverNavy1 = Color(0xFF2B4D76)
    val CoverNavy2 = Color(0xFF1E3A5F)
}

private val RainDarkColorScheme = darkColorScheme(
    primary = RainColors.Accent,
    onPrimary = RainColors.BgDark,
    secondary = RainColors.AccentDark,
    tertiary = RainColors.CoverNavy1,
    background = RainColors.BgDark,
    onBackground = RainColors.TextPrimary,
    surface = RainColors.BgDark,
    onSurface = RainColors.TextPrimary,
    surfaceVariant = RainColors.BgPill,
    onSurfaceVariant = RainColors.TextSecondary,
    outline = RainColors.BgBorder,
    outlineVariant = RainColors.BgBorder,
)

@Composable
fun RainMusicTheme(
    useDynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = if (useDynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val context = LocalContext.current
        dynamicDarkColorScheme(context)
    } else {
        RainDarkColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography(),
        content = content
    )
}
