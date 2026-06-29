import SwiftUI

struct MiniPlayerView: View {
    @Binding var showPlayerSheet: Bool
    private let audioManager = AudioPlayerManager.shared

    var body: some View {
        if let song = audioManager.currentSong {
            VStack(spacing: 0) {
                // 进度条（渐变）— 使用 TimelineView 驱动刷新
                TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 3)

                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(
                                    LinearGradient(
                                        colors: [.rainAccent, .rainAccent.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geo.size.width * CGFloat(
                                        audioManager.duration > 0
                                        ? audioManager.currentTime / audioManager.duration
                                        : 0
                                    ),
                                    height: 3
                                )
                        }
                    }
                    .frame(height: 3)
                }

                HStack(spacing: 12) {
                    // 封面
                    AlbumArtView(albumArtData: song.albumArtData, size: 50)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // 歌曲信息
                    VStack(alignment: .leading, spacing: 3) {
                        Text(song.title)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .lineLimit(1)

                        Text(song.artist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // 播放/暂停按钮（主色圆形 + 阴影）
                    Button {
                        audioManager.togglePlayPause()
                    } label: {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.rainBgDark)
                            .frame(width: 42, height: 42)
                            .background(.rainAccent)
                            .clipShape(Circle())
                            .shadow(color: .rainAccent.opacity(0.3), radius: 6, y: 2)
                    }

                    // 下一曲按钮
                    Button {
                        audioManager.playNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPlayerSheet = true
                }
            }
            .shadow(color: .black.opacity(0.06), radius: 16, y: -4)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        MiniPlayerView(showPlayerSheet: .constant(false))
    }
}
