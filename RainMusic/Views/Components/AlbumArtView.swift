import SwiftUI

struct AlbumArtView: View {
    let albumArtData: Data?
    var size: CGFloat = 300

    var body: some View {
        Group {
            if let data = albumArtData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // 占位图：音符图标 + 渐变背景
                ZStack {
                    LinearGradient(
                        colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.3))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.06))
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
    }
}

#Preview {
    VStack(spacing: 20) {
        AlbumArtView(albumArtData: nil, size: 200)
        Text("无封面占位")
    }
}
