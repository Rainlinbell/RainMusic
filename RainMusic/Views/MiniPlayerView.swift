import SwiftUI

struct MiniPlayerView: View {
    @Binding var showPlayerSheet: Bool
    private let audioManager = AudioPlayerManager.shared

    var body: some View {
        if let song = audioManager.currentSong {
            VStack(spacing: 0) {
                // 进度条
                ProgressView(value: audioManager.currentTime, total: max(audioManager.duration, 1))
                    .frame(height: 2)
                    .tint(.accentColor)

                HStack(spacing: 12) {
                    // 封面
                    AlbumArtView(albumArtData: song.albumArtData, size: 40)
                        .frame(width: 40, height: 40)

                    // 歌曲信息
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        Text(song.artist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // 播放/暂停按钮
                    Button {
                        audioManager.togglePlayPause()
                    } label: {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }

                    // 下一曲按钮
                    Button {
                        audioManager.playNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPlayerSheet = true
                }
            }
            .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        MiniPlayerView(showPlayerSheet: .constant(false))
    }
}
