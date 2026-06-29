import SwiftUI

struct SongRowView: View {
    let song: Song
    var isCurrentPlaying: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // 封面 48x48 r=6
            AlbumArtView(albumArtData: song.albumArtData, size: 48)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // 歌曲信息
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isCurrentPlaying ? .rainAccent : .rainTextPrimary)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.system(size: 12))
                    .foregroundStyle(.rainTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // 时长
            Text(song.formattedDuration)
                .font(.system(size: 13))
                .foregroundStyle(.rainTextSecondary)
                .monospacedDigit()

            // 竖三点更多按钮
            VStack(spacing: 3) {
                Circle().fill(.rainDotGray).frame(width: 3, height: 3)
                Circle().fill(.rainDotGray).frame(width: 3, height: 3)
                Circle().fill(.rainDotGray).frame(width: 3, height: 3)
            }
            .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
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
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(.rainBgDark)
}
