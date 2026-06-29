import SwiftUI

enum TabItem: String, CaseIterable {
    case library = "音乐库"
    case importMusic = "导入音乐"

    var icon: String {
        switch self {
        case .library: return "music.note.list"
        case .importMusic: return "square.and.arrow.down"
        }
    }
}

struct BottomTabBarView: View {
    @Binding var selectedTab: TabItem
    var onOpenPlayer: () -> Void

    private let audioManager = AudioPlayerManager.shared

    var body: some View {
        VStack(spacing: 6) {
            // 迷你播放区域（有歌曲时显示）
            if let song = audioManager.currentSong {
                HStack(spacing: 10) {
                    // 小封面
                    AlbumArtView(albumArtData: song.albumArtData, size: 36)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    // 歌曲标题
                    Text(song.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.rainTextPrimary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // 播放/暂停按钮
                    Button {
                        audioManager.togglePlayPause()
                    } label: {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.rainAccent)
                    }

                    // 下一曲按钮
                    Button {
                        audioManager.playNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.rainTextSecondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.rainBgPill)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .onTapGesture {
                    onOpenPlayer()
                }
            }

            // Tab 栏（药丸形）
            HStack(spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    let isSelected = tab == selectedTab
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: isSelected ? .semibold : .normal))
                    }
                    .foregroundStyle(isSelected ? .rainBgDark : .rainTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(isSelected ? .rainAccent : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .background(.rainBgPill)
            .clipShape(RoundedRectangle(cornerRadius: 36))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack {
        Spacer()
        BottomTabBarView(selectedTab: .constant(.library), onOpenPlayer: {})
    }
    .background(.rainBgDark)
}
