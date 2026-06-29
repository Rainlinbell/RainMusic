import SwiftUI
import PhotosUI

struct PlayerView: View {
    @Binding var showPlayerSheet: Bool
    @State private var isSeeking = false
    @State private var seekTime: Double = 0
    @State private var showPhotosPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var dragOffsetY: CGFloat = 0
    @State private var lastSwitchTime: Date = .distantPast
    @State private var updateTimer: Timer?

    private let audioManager = AudioPlayerManager.shared

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                Color.rainBgDark
                    .ignoresSafeArea()

                if isLandscape {
                    // 横屏布局：封面居左 + 控制区居右
                    VStack(spacing: 0) {
                        topNavBar

                        HStack(spacing: 0) {
                            // 左侧封面
                            albumArtSection(size: min(geometry.size.height * 0.65, 280))
                                .frame(width: geometry.size.height * 0.8)
                                .frame(maxHeight: .infinity)
                                .padding(.horizontal, 16)

                            // 右侧控制区
                            ScrollView {
                                VStack(spacing: 0) {
                                    songInfoSection(titleSize: 22, artistSize: 14)
                                        .padding(.horizontal, 16)

                                    progressBar
                                        .padding(.horizontal, 16)
                                        .padding(.top, 12)

                                    controlPanel
                                        .padding(.horizontal, 16)
                                        .padding(.top, 8)

                                    extraActionsRow
                                        .padding(.top, 8)

                                    Text("↑↓ 滑动切换歌曲")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.rainTextSecondary.opacity(0.5))
                                        .padding(.top, 4)
                                }
                                .padding(.vertical, 8)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(maxHeight: .infinity)
                    }
                } else {
                    // 竖屏布局
                    ScrollView {
                        VStack(spacing: 0) {
                            topNavBar

                            albumArtSection(size: min(geometry.size.width * 0.7, 280))

                            // 切换歌词/封面按钮
                            Button {
                                withAnimation(.easeInOut) {
                                    audioManager.toggleLyrics()
                                }
                            } label: {
                                Text(audioManager.showLyrics ? "显示封面" : "显示歌词")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.rainTextSecondary)
                            }
                            .padding(.top, 4)

                            songInfoSection(titleSize: 28, artistSize: 16)
                                .padding(.horizontal, 32)
                                .padding(.top, 12)

                            progressBar
                                .padding(.horizontal, 24)
                                .padding(.top, 16)

                            controlPanel
                                .padding(.top, 12)

                            extraActionsRow
                                .padding(.top, 12)

                            Text("↑↓ 滑动切换歌曲")
                                .font(.system(size: 11))
                                .foregroundStyle(.rainTextSecondary.opacity(0.5))
                                .padding(.top, 8)
                        }
                        .padding(.vertical, 8)
                    }
                    .offset(y: dragOffsetY)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 20)
                            .onChanged { value in
                                // 只在垂直方向移动明显大于水平方向时触发
                                if abs(value.translation.height) > abs(value.translation.width) * 1.5 {
                                    if Date().timeIntervalSince(lastSwitchTime) > 1.5 {
                                        dragOffsetY = value.translation.height
                                    }
                                }
                            }
                            .onEnded { value in
                                let threshold = geometry.size.height * 0.18
                                let now = Date()
                                let slideDistance = geometry.size.height * 0.9

                                if dragOffsetY < -threshold && now.timeIntervalSince(lastSwitchTime) > 1.5 {
                                    lastSwitchTime = now
                                    withAnimation(.easeIn(duration: 0.18)) {
                                        dragOffsetY = -slideDistance
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                        audioManager.playNext()
                                        dragOffsetY = slideDistance
                                        withAnimation(.interpolatingSpring(stiffness: 170, damping: 20)) {
                                            dragOffsetY = 0
                                        }
                                    }
                                } else if dragOffsetY > threshold && now.timeIntervalSince(lastSwitchTime) > 1.5 {
                                    lastSwitchTime = now
                                    withAnimation(.easeIn(duration: 0.18)) {
                                        dragOffsetY = slideDistance
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                        audioManager.playPrevious()
                                        dragOffsetY = -slideDistance
                                        withAnimation(.interpolatingSpring(stiffness: 170, damping: 20)) {
                                            dragOffsetY = 0
                                        }
                                    }
                                } else {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        dragOffsetY = 0
                                    }
                                }
                            }
                    )
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            updateTimer?.invalidate()
            updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                audioManager.updateLyrics()
            }
        }
        .onDisappear {
            updateTimer?.invalidate()
            updateTimer = nil
        }
    }

    // MARK: - Shared Subviews

    @ViewBuilder
    private var topNavBar: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPlayerSheet = false
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.rainTextPrimary)
            }

            Spacer()

            Menu {
                Button {
                    showPhotosPicker = true
                } label: {
                    Label("更换封面", systemImage: "photo")
                }
            } label: {
                VStack(spacing: 3) {
                    Circle().fill(.rainDotGray).frame(width: 3, height: 3)
                    Circle().fill(.rainDotGray).frame(width: 3, height: 3)
                    Circle().fill(.rainDotGray).frame(width: 3, height: 3)
                }
                .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    /// 封面/歌词切换区域（横竖屏共用）
    @ViewBuilder
    private func albumArtSection(size: CGFloat) -> some View {
        VStack(spacing: 4) {
            if audioManager.showLyrics {
                LyricsView(
                    lyrics: audioManager.lyrics,
                    currentIndex: audioManager.currentLyricIndex
                )
                .frame(height: size)
                .onTapGesture {
                    withAnimation(.easeInOut) { audioManager.toggleLyrics() }
                }
            } else {
                AlbumArtView(
                    albumArtData: audioManager.currentSong?.albumArtData,
                    size: size
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
                .onTapGesture {
                    withAnimation(.easeInOut) { audioManager.toggleLyrics() }
                }
                .onLongPressGesture { showPhotosPicker = true }
                .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhotoItem, matching: .images)
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        if let newItem, let data = try? await newItem.loadTransferable(type: Data.self) {
                            audioManager.currentSong?.albumArtData = data
                        }
                        selectedPhotoItem = nil
                    }
                }
            }
        }
    }

    /// 歌曲信息区域（横竖屏共用，字号可配置）
    @ViewBuilder
    private func songInfoSection(titleSize: CGFloat, artistSize: CGFloat) -> some View {
        VStack(spacing: 4) {
            Text(audioManager.currentSong?.title ?? "未在播放")
                .font(.system(size: titleSize, weight: .bold))
                .foregroundStyle(.rainTextPrimary)
                .lineLimit(1)
            Text(audioManager.currentSong?.artist ?? "")
                .font(.system(size: artistSize))
                .foregroundStyle(.rainTextSecondary)
                .lineLimit(1)
        }
    }

    /// 4px 进度条（横竖屏共用）
    @ViewBuilder
    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.rainBgBorder)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(.rainAccent)
                        .frame(width: geo.size.width * progressFraction, height: 4)

                    Circle()
                        .fill(.rainAccent)
                        .frame(width: 12, height: 12)
                        .offset(x: geo.size.width * progressFraction - 6)
                }
                .frame(height: 24)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isSeeking = true
                            let fraction = max(0, min(1, value.location.x / geo.size.width))
                            seekTime = fraction * max(audioManager.duration, 1)
                        }
                        .onEnded { _ in
                            audioManager.seek(to: seekTime)
                            isSeeking = false
                        }
                )
            }
            .frame(height: 24)

            HStack {
                Text(audioManager.currentTimeFormatted)
                    .font(.system(size: 12))
                    .foregroundStyle(.rainTextSecondary)
                    .monospacedDigit()

                Spacer()

                Text(audioManager.durationFormatted)
                    .font(.system(size: 12))
                    .foregroundStyle(.rainTextSecondary)
                    .monospacedDigit()
            }
        }
    }

    /// 药丸控制面板（横竖屏共用）
    @ViewBuilder
    private var controlPanel: some View {
        HStack(spacing: 0) {
            Button { audioManager.toggleShuffle() } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18))
                    .foregroundStyle(.rainTextSecondary)
            }
            .accessibilityLabel("随机播放")
            Button { audioManager.playPrevious() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.rainTextPrimary)
            }
            .accessibilityLabel("上一曲")
            Button { audioManager.togglePlayPause() } label: {
                Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.rainBgDark)
                    .frame(width: 56, height: 56)
                    .background(.rainAccent)
                    .clipShape(Circle())
            }
            .accessibilityLabel(audioManager.isPlaying ? "暂停" : "播放")
            Button { audioManager.playNext() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.rainTextPrimary)
            }
            .accessibilityLabel("下一曲")
            Button { audioManager.cycleRepeatMode() } label: {
                repeatModeIcon
                    .font(.system(size: 18))
                    .foregroundStyle(.rainTextSecondary)
            }
            .accessibilityLabel("循环模式")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(.rainBgPill)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }

    /// 额外操作行：歌词 + 播放列表（横竖屏共用）
    @ViewBuilder
    private var extraActionsRow: some View {
        HStack(spacing: 40) {
            Button {
                withAnimation(.easeInOut) { audioManager.toggleLyrics() }
            } label: {
                Image(systemName: "text.bubble")
                    .font(.system(size: 20))
                    .foregroundStyle(audioManager.showLyrics ? .rainAccent : .rainTextSecondary)
            }
            .accessibilityLabel("歌词")
            Button { } label: {
                Image(systemName: "music.note.list")
                    .font(.system(size: 20))
                    .foregroundStyle(.rainTextSecondary)
            }
            .accessibilityLabel("播放列表")
        }
    }

    // MARK: - Helpers

    private var progressFraction: CGFloat {
        let time = isSeeking ? seekTime : audioManager.currentTime
        let dur = max(audioManager.duration, 1)
        return CGFloat(time / dur)
    }

    @ViewBuilder
    private var repeatModeIcon: some View {
        switch audioManager.repeatMode {
        case .off:
            Image(systemName: "repeat")
        case .all:
            Image(systemName: "repeat")
        case .one:
            Image(systemName: "repeat.1")
        }
    }
}

#Preview {
    PlayerView(showPlayerSheet: .constant(false))
}
