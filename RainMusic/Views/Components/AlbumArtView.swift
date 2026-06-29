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
                // 海军蓝渐变占位图
                ZStack {
                    LinearGradient(
                        colors: [.rainCoverNavy1, .rainCoverNavy2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.3))
                        .foregroundStyle(.rainTextSecondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.07))
    }
}

#Preview {
    VStack(spacing: 20) {
        AlbumArtView(albumArtData: nil, size: 200)
        Text("无封面占位")
    }
}
