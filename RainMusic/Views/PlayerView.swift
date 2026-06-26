import SwiftUI
import PhotosUI

struct PlayerView: View {
    @Binding var showPlayerSheet: Bool
    @State private var viewModel = PlayerViewModel()
    @State private var isSeeking = false
    @State private var seekTime: Double = 0
    @State private var showPhotosPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    private let audioManager = AudioPlayerManager.shared

    var body: some View {
        GeometryReader { geometry in
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部拖拽条
                    Capsule()
                        .fill(.secondary)
                        .frame(width: 40, height: 5)
                        .padding(.top, 8)

                    // 封面/歌词切换区域
                    if viewModel.showLyrics {
                        LyricsView(
                            lyrics: viewModel.lyrics,
                            currentIndex: viewModel.currentLyricIndex
                        )
                        .frame(height: 350)
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                viewModel.toggleLyrics()
                            }
                        }
                    } else {
                        AlbumArtView(
                            albumArtData: viewModel.currentSong?.albumArtData,
                            size: min(geometry.size.width * 0.75, 320)
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                viewModel.toggleLyrics()
                            }
                        }
                        .onLongPressGesture {
                            showPhotosPicker = true
                        }
                        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhotoItem, matching: .images)
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let newItem, let data = try? await newItem.loadTransferable(type: Data.self) {
                                    viewModel.updateAlbumArt(data: data)
                                }
                                selectedPhotoItem = nil
                            }
                        }
                    }

                    // 切换提示
                    Button {
                        withAnimation(.easeInOut) {
                            viewModel.toggleLyrics()
                        }
                    } label: {
                        Text(viewModel.showLyrics ? "显示封面" : "显示歌词")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("长按封面可更换图片")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    // 歌曲信息
                    VStack(spacing: 4) {
                        Text(viewModel.currentSong?.title ?? "未在播放")
                            .font(.title2)
                            .fontWeight(.bold)
                            .lineLimit(1)

                        Text(viewModel.currentSong?.artist ?? "")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(viewModel.currentSong?.album ?? "")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 32)

                    // 进度条
                    VStack(spacing: 4) {
                        Slider(
                            value: Binding(
                                get: { isSeeking ? seekTime : viewModel.currentTime },
                                set: { newValue in
                                    if isSeeking {
                                        seekTime = newValue
                                    } else {
                                        audioManager.seek(to: newValue)
                                    }
                                }
                            ),
                            in: 0...max(viewModel.duration, 1),
                            onEditingChanged: { editing in
                                isSeeking = editing
                                if editing {
                                    seekTime = viewModel.currentTime
                                } else {
                                    audioManager.seek(to: seekTime)
                                }
                            }
                        )
                        .tint(.accentColor)

                        HStack {
                            Text(viewModel.currentTimeFormatted)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()

                            Spacer()

                            Text(viewModel.durationFormatted)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    .padding(.horizontal, 24)

                    // 主控制按钮
                    HStack(spacing: 32) {
                        // 随机模式
                        Button {
                            viewModel.toggleShuffle()
                        } label: {
                            Image(systemName: viewModel.shuffleMode == .on ? "shuffle.circle.fill" : "shuffle")
                                .font(.title2)
                                .foregroundStyle(viewModel.shuffleMode == .on ? .accentColor : .secondary)
                        }

                        // 上一曲
                        Button {
                            viewModel.playPrevious()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.title)
                                .foregroundStyle(.primary)
                        }

                        // 播放/暂停
                        Button {
                            viewModel.togglePlayPause()
                        } label: {
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(.primary)
                        }

                        // 下一曲
                        Button {
                            viewModel.playNext()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.title)
                                .foregroundStyle(.primary)
                        }

                        // 循环模式
                        Button {
                            viewModel.cycleRepeatMode()
                        } label: {
                            repeatModeIcon
                                .font(.title2)
                                .foregroundStyle(viewModel.repeatMode != .off ? .accentColor : .secondary)
                        }
                    }

                    // 音量控制
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.fill")
                            .foregroundStyle(.secondary)

                        Slider(
                            value: Binding(
                                get: { Double(viewModel.volume) },
                                set: { viewModel.volume = Float($0) }
                            ),
                            in: 0...1
                        )
                        .tint(.accentColor)

                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 16)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPlayerSheet = false
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                }
            }
        }
        } // GeometryReader
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            // 定时更新歌词
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                viewModel.update()
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private var repeatModeIcon: some View {
        switch viewModel.repeatMode {
        case .off:
            Image(systemName: "repeat")
        case .all:
            Image(systemName: "repeat.circle.fill")
        case .one:
            Image(systemName: "repeat.1.circle.fill")
        }
    }
}

#Preview {
    PlayerView(showPlayerSheet: .constant(false))
}
