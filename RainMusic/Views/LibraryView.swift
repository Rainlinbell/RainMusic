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
    @State private var isSearchActive = false

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
            Color.rainBgDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 自定义 Header
                HStack {
                    Text("我的音乐")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.rainTextPrimary)

                    Spacer()

                    // 搜索按钮
                    Button {
                        isSearchActive.toggle()
                        if !isSearchActive {
                            searchText = ""
                        }
                    } label: {
                        Image(systemName: isSearchActive ? "xmark" : "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                    }

                    // 排序菜单
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
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // 搜索栏
                if isSearchActive {
                    TextField("搜索歌曲、艺术家、专辑", text: $searchText)
                        .font(.system(size: 15))
                        .foregroundStyle(.rainTextPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.rainBgPill)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.rainBgBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                if filteredSongs.isEmpty {
                    emptyStateView
                } else {
                    songListView
                }
            }

            // 播放器全屏过渡动画
            if showPlayerSheet {
                PlayerView(showPlayerSheet: $showPlayerSheet)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }

            // 扫描遮罩
            if isScanning {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.rainAccent)

                        Text("正在扫描音乐库...")
                            .font(.headline)
                            .foregroundStyle(.rainTextPrimary)
                    }
                    .padding(30)
                    .background(.rainBgPill)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .onAppear {
            audioManager.cachedSongs = filteredSongs
        }
        .onChange(of: searchText) { _, _ in
            audioManager.cachedSongs = filteredSongs
        }
        .onChange(of: sortOrder) { _, _ in
            audioManager.cachedSongs = filteredSongs
        }
        .onChange(of: songs) { _, _ in
            audioManager.cachedSongs = filteredSongs
        }
    }

    // MARK: - Subviews

    private var songListView: some View {
        List {
            // 歌曲计数
            Section {
                Text("所有歌曲 · \(filteredSongs.count)首")
                    .font(.system(size: 14))
                    .foregroundStyle(.rainTextSecondary)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // 歌曲列表
            Section {
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
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.bottom, 110)
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
                .foregroundStyle(.rainTextSecondary)

            Text("音乐库为空")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(.rainTextPrimary)

            Text("扫描设备音乐库或导入音频文件")
                .font(.body)
                .foregroundStyle(.rainTextSecondary)

            HStack(spacing: 16) {
                Button {
                    Task { await scanLibrary() }
                } label: {
                    Label("扫描音乐库", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.rainAccent)
                .foregroundStyle(.rainBgDark)
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Actions

    private func scanLibrary() async {
        isScanning = true
        do {
            try await libraryManager.scanLibrary(modelContext: modelContext)
        } catch {
            print("⚠️ 扫描异常: \(error.localizedDescription)")
        }
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
