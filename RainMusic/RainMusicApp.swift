import SwiftUI
import SwiftData
import AVFoundation
import MediaPlayer

@main
struct RainMusicApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    MPMediaLibrary.requestAuthorization { _ in }
                }
        }
        .modelContainer(for: Song.self)
    }

    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("⚠️ AVAudioSession 配置失败: \(error.localizedDescription)")
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: TabItem = .library
    @State private var showPlayer = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.rainBgDark
                .ignoresSafeArea()

            if showPlayer {
                PlayerView(showPlayerSheet: .constant(true))
                    .transition(.move(edge: .bottom))
            } else {
                // Tab 内容
                Group {
                    switch selectedTab {
                    case .library:
                        LibraryView()
                    case .importMusic:
                        ImportView()
                    }
                }
                .transition(.opacity)

                // 底部 Tab 栏（常驻）
                BottomTabBarView(
                    selectedTab: $selectedTab,
                    onOpenPlayer: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPlayer = true
                        }
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showPlayer)
        .preferredColorScheme(.dark)
    }
}
