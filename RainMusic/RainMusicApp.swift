import SwiftUI
import SwiftData
import AVFoundation

@main
struct RainMusicApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
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
    var body: some View {
        LibraryView()
    }
}
