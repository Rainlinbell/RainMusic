import SwiftUI

struct LyricsView: View {
    let lyrics: [LyricLine]
    let currentIndex: Int

    var body: some View {
        if lyrics.isEmpty {
            // 无歌词占位
            VStack {
                Spacer()
                Image(systemName: "text.bubble")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("暂无歌词")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        // 顶部留白
                        Color.clear.frame(height: 100)

                        ForEach(Array(lyrics.enumerated()), id: \.element.id) { index, line in
                            Text(line.text)
                                .id(index)
                                .font(index == currentIndex ? .title3 : .body)
                                .fontWeight(index == currentIndex ? .bold : .regular)
                                .foregroundStyle(index == currentIndex ? .primary : .secondary)
                                .opacity(index == currentIndex ? 1.0 : 0.6)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 4)
                                .scaleEffect(index == currentIndex ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentIndex)
                        }

                        // 底部留白
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                }
                .onChange(of: currentIndex) { _, newValue in
                    guard newValue >= 0 else { return }

                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }
}

#Preview {
    let sampleLyrics = [
        LyricLine(time: 0, text: "第一句歌词"),
        LyricLine(time: 5, text: "第二句歌词"),
        LyricLine(time: 10, text: "第三句歌词"),
        LyricLine(time: 15, text: "第四句歌词"),
        LyricLine(time: 20, text: "第五句歌词")
    ]

    return LyricsView(lyrics: sampleLyrics, currentIndex: 2)
}
