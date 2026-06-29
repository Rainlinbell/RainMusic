package com.rain.music.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

object RainSpacing {
    val xs = 4.dp
    val sm = 8.dp
    val md = 12.dp
    val lg = 16.dp
    val xl = 20.dp
    val xxl = 24.dp
    val xxxl = 32.dp
}

object RainTypography {
    const val bodySmall = 12.sp
    const val body = 13.sp
    const val bodyMedium = 14.sp
    const val headline = 15.sp
    const val headlineLarge = 16.sp
    const val title = 28.sp
}

object RainCornerRadius {
    val xs = RoundedCornerShape(4.dp)
    val sm = RoundedCornerShape(6.dp)
    val md = RoundedCornerShape(8.dp)
    val lg = RoundedCornerShape(12.dp)
    val xl = RoundedCornerShape(16.dp)
    val xxl = RoundedCornerShape(20.dp)
    val pill = RoundedCornerShape(26.dp)
    val full = RoundedCornerShape(9999.dp)
}

object RainShadow {
    val small = androidx.compose.ui.graphics.Shadow(Color.Black.copy(alpha = 0.06f), blurRadius = 4.dp, offsetY = 2.dp)
    val medium = androidx.compose.ui.graphics.Shadow(Color.Black.copy(alpha = 0.12f), blurRadius = 8.dp, offsetY = 4.dp)
    val large = androidx.compose.ui.graphics.Shadow(Color.Black.copy(alpha = 0.15f), blurRadius = 10.dp, offsetY = 4.dp)
    val xl = androidx.compose.ui.graphics.Shadow(Color.Black.copy(alpha = 0.2f), blurRadius = 16.dp, offsetY = 8.dp)
}

object RainLayout {
    val appWidth = 390.dp
    val appHeight = 844.dp
    val statusBarHeight = 62.dp
    val bottomTabHeight = 95.dp
    val albumArtSize = 280.dp
    val progressBarWidth = 350.dp
    val controlsPanelHeight = 80.dp
}