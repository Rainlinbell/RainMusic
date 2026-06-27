import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \Song.dateAdded, order: .reverse) private var songs: [Song]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .dateAdded
    @State private var showFileImporter = false
    @State private var showImportView = false
    @State private var isScanning = false
    @State private var showPlayerSheet = false
    @State private var listDragOffsetY: CGFloat = 0
    @State private var lastSongSwitchTime: Date = .distantPast

    private let audioManager = AudioPlayerManager.shared
    private let libraryManager = MusicLibraryManager.shared

    enum SortOrder: String, CaseIterable {
        case dateAdded = "添加时间"
        case title = "歌曲名"
        case artist = "艺术家"
        case album = "专辑"
    }

    var filteredSongs: [Song] {
        let filtered = searchText.isEmpty ? songs : songs.filter { song in
            song.title.localizedCaseInsensitiveContains(searchText) ||
            song.artist.localizedCaseInsensitiveContains(searchText) ||
            song.album.localizedCaseInsensitiveContains(searchText)
        }

        switch sortOrder {
        case .dateAdded:
            return filtered.sorted { $0.dateAdded > $1.dateAdded }
        case .title:
            return filtered.sorted { $0.title < $1.title }
        case .artist:
            return filtered.sorted { $0.artist < $1.artist }
        case .album:
            return filtered.sorted { $0.album < $1.album }
        }
    }

    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    if filteredSongs.isEmpty {
                        emptyStateView
                    } else {
                        songListView
                    }

                    // 底部迷你播放器
                    VStack {
                        Spacer()
                        if audioManager.currentSong != nil {
                            MiniPlayerView(showPlayerSheet: $showPlayerSheet)
                        }
                    }
                }
                .navigationTitle("音乐库")
                .searchable(text: $searchText, prompt: "搜索歌曲、艺术家、专辑")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        sortMenu
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                Task { await scanLibrary() }
                            } label: {
                                Label("扫描音乐库", systemImage: "magnifyingglass")
                            }

                            Button {
                                showImportView = true
                            } label: {
                                Label("导入文件", systemImage: "square.and.arrow.down")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showImportView) {
                    ImportView()
                }
                .overlay {
                    if isScanning {
                        scanningOverlay
                    }
                }
            }

            // 播放器全屏过渡动画
            if showPlayerSheet {
                PlayerView(showPlayerSheet: $showPlayerSheet)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showPlayerSheet)
    }

    // MARK: - Subviews

    private var songListView: some View {
        List {
            ForEach(filteredSongs) { song in
                SongRowView(
                    song: song,
                    isCurrentPlaying: audioManager.currentSong?.id == song.id
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    audioManager.setPlaylist(filteredSongs, startIndex: filteredSongs.firstIndex(where: { $0.id == song.id }) ?? 0)
                    showPlayerSheet = true
                }
                .contextMenu {
                    Button {
                        audioManager.play(song: song)
                        showPlayerSheet = true
                    } label: {
                        Label("播放", systemImage: "play")
                    }

                    Button(role: .destructive) {
                        deleteSong(song)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .padding(.bottom, audioManager.currentSong != nil ? 70 : 0)
        .offset(y: listDragOffsetY)
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    if Date().timeIntervalSince(lastSongSwitchTime) < 1.5 { return }
                    listDragOffsetY = value.translation.height * 0.3
                }
                .onEnded { value in
                    let threshold: CGFloat = 100
                    let now = Date()
                    guard now.timeIntervalSince(lastSongSwitchTime) > 1.5 else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            listDragOffsetY = 0
                        }
                        return
                    }

                    if value.translation.height < -threshold {
                        // 上滑 → 下一曲
                        lastSongSwitchTime = now
                        withAnimation(.easeInOut(duration: 0.25)) {
                            listDragOffsetY = -80
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            audioManager.playNext()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                listDragOffsetY = 0
                            }
                        }
                    } else if value.translation.height > threshold {
                        // 下滑 → 上一曲
                        lastSongSwitchTime = now
                        withAnimation(.easeInOut(duration: 0.25)) {
                            listDragOffsetY = 80
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            audioManager.playPrevious()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                listDragOffsetY = 0
                            }
                        }
                    } else {
                        // 未达阈值，平滑回弹
                        withAnimation(.easeInOut(duration: 0.3)) {
                            listDragOffsetY = 0
                        }
                    }
                }
        )
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("音乐库为空")
                .font(.title2)
                .fontWeight(.medium)

            Text("扫描设备音乐库或导入音频文件")
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button {
                    Task { await scanLibrary() }
                } label: {
                    Label("扫描音乐库", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    showImportView = true
                } label: {
                    Label("导入文件", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 40)
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(SortOrder.allCases, id: \.self) { order in
                Button {
                    sortOrder = order
                } label: {
                    if sortOrder == order {
                        Label(order.rawValue, systemImage: "checkmark")
                    } else {
                        Text(order.rawValue)
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }

    private var scanningOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("正在扫描音乐库...")
                    .font(.headline)

                ProgressView(value: libraryManager.scanProgress)
                    .frame(width: 200)
            }
            .padding(30)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Actions

    private func scanLibrary() async {
        isScanning = true
        await libraryManager.scanLibrary(modelContext: modelContext)
        isScanning = false
        if let error = libraryManager.scanError {
            print("⚠️ 扫描结果: \(error)")
        }
    }

    private func deleteSong(_ song: Song) {
        libraryManager.deleteSong(song)
        modelContext.delete(song)
        try? modelContext.save()
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: Song.self, inMemory: true)
}
