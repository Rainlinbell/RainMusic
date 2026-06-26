# 🎵 RainMusic

一款界面简洁的跨平台音乐播放器，支持 **iOS**、**Android** 和 **HarmonyOS NEXT** 三端。

> **本项目完全由 AI 开发编写**，从架构设计到功能实现，三端代码均由 AI 独立完成并保持功能同步。

## ✨ 功能特性

### 🎶 播放控制
- 播放 / 暂停 / 上一曲 / 下一曲
- 进度条拖拽跳转
- 随机播放 / 单曲循环 / 列表循环 / 顺序播放
- 后台播放（Android 通知栏控制、iOS 锁屏控制中心）

### 🔊 无极音量控制
- 滑块拖动实现连续浮点音量调节，无阶梯感
- 与系统音量双向同步：App 内调节同步到系统，硬件音量键变化同步到 App
- 三端各自使用平台原生 API 实现（iOS: MPVolumeView + KVO / Android: AudioManager / HarmonyOS: VolumeGroupManager）

### 📝 歌词同步
- 支持 LRC 格式歌词解析
- 支持一行多时间标签（重复歌词）
- 二分查找实时定位当前歌词行
- 自动滚动居中显示，当前行高亮动画
- 支持 UTF-8 / GBK 多编码检测
- 自动查找同名 `.lrc` 歌词文件

### 📱 音乐管理
- 设备音乐库扫描
- 文件导入（支持 MP3 / FLAC / WAV / AAC / OGG / M4A / APE 等格式）
- 歌曲搜索（按歌名 / 艺术家 / 专辑）
- 多种排序方式（按添加时间 / 歌名 / 艺术家 / 专辑）
- 专辑封面显示

### 🎨 界面设计
- 简洁 Material Design 3 风格
- 封面 / 歌词点击切换
- 底部迷你播放条
- 流畅的页面切换动画

## 📦 三端技术栈

| 平台 | 语言 | UI 框架 | 播放引擎 | 数据存储 | 架构 |
|------|------|---------|---------|---------|------|
| **iOS** | Swift | SwiftUI | AVAudioPlayer | SwiftData | MVVM |
| **Android** | Kotlin | Jetpack Compose + Material 3 | Media3 ExoPlayer | Room Database | MVVM |
| **HarmonyOS** | ArkTS | ArkUI | AVPlayer | 内存存储 | MVVM |

## 📂 项目结构

```
rain/
├── RainMusic/              # iOS 端 (SwiftUI)
│   ├── Managers/           # 播放管理、歌词解析、音乐库
│   ├── Models/             # 数据模型
│   ├── ViewModels/         # 视图模型
│   └── Views/              # UI 组件与页面
│
├── RainMusicAndroid/       # Android 端 (Jetpack Compose)
│   └── app/src/main/java/com/rain/music/
│       ├── data/           # 数据库 & 数据模型
│       ├── manager/        # 播放管理、歌词解析、音乐扫描
│       ├── service/        # 后台播放服务
│       ├── ui/             # 页面 & 组件
│       └── viewmodel/      # 视图模型
│
└── RainMusicHarmony/       # HarmonyOS NEXT 端 (ArkTS)
    └── entry/src/main/ets/
        ├── components/     # UI 组件
        ├── manager/        # 播放管理、歌词解析、音乐扫描
        ├── model/          # 数据模型
        ├── pages/          # 页面
        └── viewmodel/      # 视图模型
```

## 🚀 构建运行

### iOS
- 环境：Xcode 15+ / iOS 17+
- 使用 Xcode 打开项目，连接设备或模拟器运行

### Android
- 环境：Android Studio / JDK 17
- 命令行构建：
  ```bash
  cd RainMusicAndroid
  ./gradlew assembleDebug
  ```
- APK 输出路径：`app/build/outputs/apk/debug/`

### HarmonyOS NEXT
- 环境：DevEco Studio / HarmonyOS SDK
- 命令行构建：
  ```bash
  cd RainMusicHarmony
  # 设置环境变量
  export DEVECO_SDK_HOME=/path/to/DevEcoStudio/sdk
  # 执行构建
  node /path/to/DevEcoStudio/tools/hvigor/bin/hvigorw.js assembleHap
  ```
- HAP 输出路径：`entry/build/default/outputs/default/`

## 🤖 AI 开发说明

本项目是一个 AI 全栈开发实践案例，展示了 AI 在移动应用开发中的完整能力：

- **架构设计**：三端均采用 MVVM 架构，功能模块对齐
- **功能同步**：播放控制、音量同步、歌词解析、音乐扫描等核心功能在三端保持一致
- **平台适配**：各端使用原生 API 和最佳实践，而非跨平台框架
- **持续迭代**：从基础播放到无极音量、歌词同步等高级功能，逐步完善

## 📄 License

MIT License
