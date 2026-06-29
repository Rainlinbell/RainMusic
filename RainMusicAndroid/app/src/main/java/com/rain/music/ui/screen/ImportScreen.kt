package com.rain.music.ui.screen

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.rain.music.ui.theme.RainColors
import com.rain.music.viewmodel.LibraryViewModel

@Composable
fun ImportScreen(
    libraryViewModel: LibraryViewModel
) {
    val scanResult by libraryViewModel.scanResult.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    val filePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenMultipleDocuments()
    ) { uris: List<Uri> ->
        uris.forEach { uri ->
            libraryViewModel.importFile(uri)
        }
    }

    LaunchedEffect(scanResult) {
        scanResult?.let {
            snackbarHostState.showSnackbar(it)
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(RainColors.BgDark)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 24.dp, vertical = 16.dp)
                .padding(bottom = 110.dp), // 为底部 Tab 栏留空间
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(32.dp))

            // 标题
            Text(
                "导入音乐",
                fontSize = 24.sp,
                fontWeight = FontWeight.SemiBold,
                color = RainColors.TextPrimary
            )

            Spacer(modifier = Modifier.height(32.dp))

            Icon(
                Icons.Default.FileDownload,
                contentDescription = null,
                modifier = Modifier.size(56.dp),
                tint = RainColors.Accent
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                "导入音频文件",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                color = RainColors.TextPrimary
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                "支持 MP3、M4A、WAV、FLAC、OGG 等格式",
                fontSize = 14.sp,
                color = RainColors.TextSecondary
            )

            Spacer(modifier = Modifier.height(32.dp))

            // 选择文件按钮
            Button(
                onClick = {
                    filePickerLauncher.launch(arrayOf("audio/*"))
                },
                modifier = Modifier.fillMaxWidth().height(48.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = RainColors.Accent,
                    contentColor = RainColors.BgDark
                ),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Default.FolderOpen, contentDescription = null, modifier = Modifier.size(20.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("选择文件", fontWeight = FontWeight.SemiBold)
            }

            Spacer(modifier = Modifier.height(16.dp))

            // 扫描设备音乐库按钮
            OutlinedButton(
                onClick = { libraryViewModel.scanMusic() },
                modifier = Modifier.fillMaxWidth().height(48.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.outlinedButtonColors(
                    contentColor = RainColors.TextPrimary
                ),
                border = androidx.compose.foundation.BorderStroke(1.dp, RainColors.BgBorder)
            ) {
                Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(20.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("扫描设备音乐库")
            }

            Spacer(modifier = Modifier.height(32.dp))

            // 提示信息卡片
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = RainColors.BgPill),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        "提示",
                        style = MaterialTheme.typography.titleSmall,
                        color = RainColors.TextPrimary,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        "• 扫描将自动发现设备上的所有音乐文件\n" +
                        "• 导入支持从文件管理器选择音频文件\n" +
                        "• 歌词文件(.lrc)会自动关联同名音频",
                        style = MaterialTheme.typography.bodySmall,
                        color = RainColors.TextSecondary
                    )
                }
            }

            Spacer(modifier = Modifier.weight(1f))
        }

        // Snackbar
        if (scanResult != null) {
            SnackbarHost(
                hostState = snackbarHostState,
                modifier = Modifier.align(Alignment.BottomCenter).padding(bottom = 120.dp)
            )
        }
    }
}
