import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showFilePicker = false
    @State private var importedFiles: [ImportStatus] = []
    @State private var isImporting = false

    private let libraryManager = MusicLibraryManager.shared

    struct ImportStatus: Identifiable {
        let id = UUID()
        let fileName: String
        var status: Status
        var errorMessage: String?

        enum Status {
            case pending
            case importing
            case success
            case failed
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 导入按钮
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down.on.square")
                        .font(.system(size: 50))
                        .foregroundStyle(.accentColor)

                    Text("导入音频文件")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("支持 MP3、M4A、WAV、AIFF 格式")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Button {
                        showFilePicker = true
                    } label: {
                        Label("选择文件", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isImporting)
                }
                .padding(.top, 40)

                // 导入状态列表
                if !importedFiles.isEmpty {
                    List {
                        ForEach(importedFiles) { item in
                            importStatusRow(item)
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("导入音乐")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [
                    .mp3,
                    .mpeg4Audio,
                    UTType(importedAs: "com.microsoft.waveform-audio"),
                    UTType(importedAs: "public.aiff-audio"),
                    .audio
                ],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func importStatusRow(_ item: ImportStatus) -> some View {
        HStack {
            Image(systemName: statusIcon(item.status))
                .foregroundStyle(statusColor(item.status))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.fileName)
                    .font(.body)
                    .lineLimit(1)

                if let error = item.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Text(statusText(item.status))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if item.status == .importing {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }

    // MARK: - Helpers

    private func statusIcon(_ status: ImportStatus.Status) -> String {
        switch status {
        case .pending: return "clock"
        case .importing: return "arrow.down.circle"
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    private func statusColor(_ status: ImportStatus.Status) -> Color {
        switch status {
        case .pending: return .secondary
        case .importing: return .accentColor
        case .success: return .green
        case .failed: return .red
        }
    }

    private func statusText(_ status: ImportStatus.Status) -> String {
        switch status {
        case .pending: return "等待导入"
        case .importing: return "正在导入..."
        case .success: return "导入成功"
        case .failed: return "导入失败"
        }
    }

    // MARK: - Actions

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            // 添加待导入列表
            for url in urls {
                importedFiles.append(ImportStatus(
                    fileName: url.lastPathComponent,
                    status: .pending
                ))
            }

            // 开始导入
            Task {
                for (index, url) in urls.enumerated() {
                    await MainActor.run {
                        importedFiles[index].status = .importing
                    }

                    do {
                        _ = try await libraryManager.importFile(from: url, modelContext: modelContext)
                        await MainActor.run {
                            importedFiles[index].status = .success
                        }
                    } catch {
                        await MainActor.run {
                            importedFiles[index].status = .failed
                            importedFiles[index].errorMessage = error.localizedDescription
                        }
                    }
                }
            }

        case .failure(let error):
            print("⚠️ 文件选择失败: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ImportView()
}
