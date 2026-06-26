import SwiftUI

struct SongRowView: View {
    let song: Song
    var isCurrentPlaying: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // 封面缩略图
            AlbumArtView(albumArtData: song.albumArtData, size: 44)
                .frame(width: 44, height: 44)

            // 歌曲信息
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.body)
                    .fontWeight(isCurrentPlaying ? .semibold : .regular)
                    .foregroundStyle(isCurrentPlaying ? Color.accentColor : .primary)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // 正在播放标识
            if isCurrentPlaying {
                Image(systemName: "waveform")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                    .symbolEffect(.variableColor.iterative, isActive: true)
            }

            // 时长
            Text(song.formattedDuration)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    List {
        SongRowView(
            song: Song(
                title: "测试歌曲",
                artist: "测试艺术家",
                duration: 234,
                fileURL: URL(fileURLWithPath: "/test.mp3")
            ),
            isCurrentPlaying: true
        )
    }
}
