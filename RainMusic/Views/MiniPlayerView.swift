import SwiftUI

struct MiniPlayerView: View {
    @Binding var showPlayerSheet: Bool
    private let audioManager = AudioPlayerManager.shared
    @State private var isPressed = false

    var body: some View {
        if let song = audioManager.currentSong {
            VStack(spacing: 0) {
                TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.rainBgBorder.opacity(0.6))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [.rainAccent, .rainAccent.opacity(0.7)],
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
                                    height: 4
                                )
                        }
                    }
                    .frame(height: 4)
                }
                .padding(.top, 2)

                HStack(spacing: 14) {
                    ZStack {
                        AlbumArtView(albumArtData: song.albumArtData, size: 48)
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.rainTextPrimary)
                            .lineLimit(1)

                        Text(song.artist)
                            .font(.system(size: 12))
                            .foregroundStyle(.rainTextSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            isPressed = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                isPressed = false
                            }
                        }
                        audioManager.togglePlayPause()
                    } label: {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.rainBgDark)
                            .frame(width: 44, height: 44)
                            .background(
                                LinearGradient(
                                    colors: [.rainAccent, .rainAccent.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: .rainAccent.opacity(0.4), radius: 10, y: 4)
                    }
                    .scaleEffect(isPressed ? 0.92 : 1.0)

                    Button {
                        audioManager.playNext()
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.rainTextSecondary)
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPlayerSheet = true
                }
            }
            .shadow(color: .black.opacity(0.12), radius: 20, y: -6)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        MiniPlayerView(showPlayerSheet: .constant(false))
    }
}
