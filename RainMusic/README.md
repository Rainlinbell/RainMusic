# RainMusic - iOS 本地音乐播放器

一款简洁美观的 iOS 本地音乐播放器，支持自动扫描设备音乐库和手动导入音频文件。

## 功能特性

- **音乐库管理**: 自动扫描设备音乐库，支持手动导入音频文件
- **播放控制**: 播放/暂停、上下首、进度条拖拽、音量调节
- **播放模式**: 随机播放、单曲循环、列表循环
- **专辑封面**: 自动提取并展示歌曲专辑封面
- **歌词显示**: 支持 LRC 歌词文件同步滚动显示
- **后台播放**: 支持后台播放、锁屏控制、耳机线控
- **简洁界面**: 现代化 SwiftUI 设计，简洁美观

## 技术栈

- **框架**: SwiftUI + SwiftData (iOS 17+)
- **音频**: AVFoundation (AVAudioPlayer)
- **媒体库**: MediaPlayer (MPMediaQuery)
- **架构**: MVVM + 单例 Manager

## 项目结构

```
RainMusic/
├── RainMusicApp.swift              # 应用入口
├── Models/
│   └── Song.swift                  # 歌曲数据模型
├── Managers/
│   ├── AudioPlayerManager.swift    # 音频播放管理器
│   ├── MusicLibraryManager.swift   # 音乐库管理器
│   └── LyricsParser.swift          # LRC 歌词解析器
├── ViewModels/
│   └── PlayerViewModel.swift       # 播放视图模型
├── Views/
│   ├── LibraryView.swift           # 音乐库列表
│   ├── PlayerView.swift            # 完整播放器界面
│   ├── MiniPlayerView.swift        # 迷你播放条
│   ├── ImportView.swift            # 文件导入界面
│   └── Components/
│       ├── AlbumArtView.swift      # 专辑封面组件
│       ├── SongRowView.swift       # 歌曲行组件
│       └── LyricsView.swift        # 歌词滚动组件
└── Info.plist                      # 权限和后台配置
```

## 在 Xcode 中创建项目

由于项目文件需要在 Xcode 中创建，请按以下步骤操作：

### 步骤 1: 创建 Xcode 项目

1. 打开 Xcode，选择 **File → New → Project**
2. 选择 **iOS → App** 模板
3. 填写项目信息：
   - **Product Name**: `RainMusic`
   - **Team**: 选择你的开发者账号
   - **Organization Identifier**: `com.yourname`
   - **Interface**: `SwiftUI`
   - **Storage**: `SwiftData`
   - **Language**: `Swift`
4. 选择保存位置：`d:\Develop\rain\`
5. 点击 **Create** 创建项目

### 步骤 2: 替换源文件

1. 在 Xcode 项目导航器中，删除自动生成的以下文件：
   - `ContentView.swift`
   - `Item.swift`（如果存在）

2. 将本项目中的所有 `.swift` 文件拖入 Xcode 项目：
   - `RainMusicApp.swift`
   - `Models/Song.swift`
   - `Managers/AudioPlayerManager.swift`
   - `Managers/MusicLibraryManager.swift`
   - `Managers/LyricsParser.swift`
   - `ViewModels/PlayerViewModel.swift`
   - `Views/LibraryView.swift`
   - `Views/PlayerView.swift`
   - `Views/MiniPlayerView.swift`
   - `Views/ImportView.swift`
   - `Views/Components/AlbumArtView.swift`
   - `Views/Components/SongRowView.swift`
   - `Views/Components/LyricsView.swift`

3. 确保勾选 **Copy items if needed** 和 **Create groups**

### 步骤 3: 配置 Info.plist

1. 在 Xcode 中选择项目 Target
2. 切换到 **Info** 标签页
3. 添加以下配置：

**权限配置**:
- 添加 `Privacy - Media Library Usage Description`
- Value: `RainMusic 需要访问您的媒体资料库以播放本地音乐`

**后台模式**:
- 切换到 **Signing & Capabilities** 标签页
- 点击 **+ Capability** 添加 **Background Modes**
- 勾选 **Audio, AirPlay, and Picture in Picture**

或者直接替换项目中的 `Info.plist` 为本项目提供的 `Info.plist` 文件。

### 步骤 4: 配置项目设置

1. **Minimum Deployments**: 设置为 `iOS 17.0`
2. **Supported Destinations**: 选择 `iPhone`

### 步骤 5: 编译运行

1. 选择模拟器或真机
2. 按 `Cmd + R` 编译运行

## 使用说明

### 扫描音乐库

1. 打开 App
2. 点击右上角 **+** 按钮
3. 选择 **扫描音乐库**
4. 等待扫描完成，歌曲将自动添加到音乐库

### 导入音频文件

1. 打开 App
2. 点击右上角 **+** 按钮
3. 选择 **导入文件**
4. 从 Files app 或其他位置选择音频文件
5. 支持格式：MP3、M4A、WAV、AIFF

### 播放音乐

1. 在音乐库列表中点击歌曲开始播放
2. 底部显示迷你播放器
3. 点击迷你播放器展开完整播放界面
4. 支持播放/暂停、上下首、进度拖拽、音量调节
5. 支持随机播放和循环模式切换

### 歌词显示

1. 在播放界面点击封面切换到歌词视图
2. 歌词会自动同步滚动
3. 需要 `.lrc` 格式歌词文件，与音频文件同名并放在同一目录

## 注意事项

1. **真机测试**: 音乐库扫描功能需要在真机上测试，模拟器没有 iPod 音乐库
2. **DRM 保护**: 无法导入 DRM 保护的 Apple Music 歌曲
3. **后台播放**: 需要在真机上测试后台播放功能
4. **歌词文件**: 歌词文件需要与音频文件同名（如 `song.mp3` 对应 `song.lrc`）

## 系统要求

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## 许可证

MIT License
