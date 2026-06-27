import Foundation
import MediaPlayer
import AVFoundation
import SwiftData
import UIKit

@Observable
final class MusicLibraryManager {
    static let shared = MusicLibraryManager()

    var isScanning: Bool = false
    var scanProgress: Double = 0
    var isImporting: Bool = false
    var importError: String?
    var scanError: String?

    private init() {}

    // MARK: - Permission

    func requestMediaLibraryAccess() async -> Bool {
        let status = await MPMediaLibrary.requestAuthorization()
        return status == .authorized
    }

    // MARK: - Scan iPod Library

    func scanLibrary(modelContext: ModelContext) async {
        await MainActor.run {
            isScanning = true
            scanProgress = 0
            scanError = nil
        }

        do {
            let authorized = await requestMediaLibraryAccess()
            guard authorized else {
                print("⚠️ 未获得媒体库访问权限")
                await MainActor.run {
                    isScanning = false
                    scanError = "未获得媒体库访问权限"
                }
                return
            }

            let query = MPMediaQuery.songs()
            query.addFilterPredicate(
                MPMediaPropertyPredicate(
                    value: MPMediaType.music.rawValue,
                    forProperty: MPMediaItemPropertyMediaType
                )
            )

            guard let items = query.items else {
                await MainActor.run {
                    isScanning = false
                    scanProgress = 1.0
                }
                return
            }

            let total = items.count
            let musicDir = getMusicDirectory()
            let lyricsDir = getLyricsDirectory()

            for (index, item) in items.enumerated() {
                do {
                    // 跳过 DRM 保护的歌曲
                    guard let assetURL = item.value(forProperty: MPMediaItemPropertyAssetURL) as? URL else {
                        continue
                    }

                    let persistentIDRaw = item.value(forProperty: MPMediaItemPropertyPersistentID) as? NSNumber ?? NSNumber(value: 0)
                    let persistentID = persistentIDRaw.stringValue

                    // 检查是否已存在
                    let descriptor = FetchDescriptor<Song>(
                        predicate: #Predicate { $0.mediaLibraryPersistentID == persistentID }
                    )
                    if let _ = try? modelContext.fetch(descriptor) {
                        await MainActor.run {
                            scanProgress = Double(index + 1) / Double(total)
                        }
                        continue
                    }

                    // 导出音频文件到沙盒
                    let title = item.value(forProperty: MPMediaItemPropertyTitle) as? String ?? "未知歌曲"
                    let artist = item.value(forProperty: MPMediaItemPropertyArtist) as? String ?? "未知艺术家"
                    let album = item.value(forProperty: MPMediaItemPropertyAlbumTitle) as? String ?? "未知专辑"
                    let duration = item.value(forProperty: MPMediaItemPropertyPlaybackDuration) as? Double ?? 0

                    let safeFileName = "\(artist)-\(title)".replacingOccurrences(
                        of: "/", with: "_"
                    ).replacingOccurrences(of: ":", with: "_")
                    let destinationURL = musicDir.appendingPathComponent("\(safeFileName).m4a")

                    try await exportMediaItem(assetURL: assetURL, to: destinationURL)

                    // 提取封面
                    var albumArtData: Data? = nil
                    if let artwork = item.value(forProperty: MPMediaItemPropertyArtwork) as? MPMediaItemArtwork {
                        let image = artwork.image(at: CGSize(width: 512, height: 512))
                        albumArtData = image?.pngData()
                    }

                    // 查找歌词文件
                    let lyricsFileURL = findLyricsFile(for: title, in: lyricsDir)

                    let song = Song(
                        title: title,
                        artist: artist,
                        album: album,
                        duration: duration,
                        fileURL: destinationURL,
                        albumArtData: albumArtData,
                        hasLyrics: lyricsFileURL != nil,
                        lyricsFileURL: lyricsFileURL,
                        sourceType: "library",
                        mediaLibraryPersistentID: persistentID
                    )
                    modelContext.insert(song)

                } catch {
                    // 单首歌曲失败不影响整体扫描
                    print("⚠️ 处理歌曲失败: \(error.localizedDescription)")
                }

                await MainActor.run {
                    scanProgress = Double(index + 1) / Double(total)
                }
            }

            try? modelContext.save()

            await MainActor.run {
                isScanning = false
                scanProgress = 1.0
            }

        } catch {
            // 顶层捕获：防止任何未预期的异常导致崩溃
            print("⚠️ 扫描音乐库失败: \(error.localizedDescription)")
            await MainActor.run {
                isScanning = false
                scanError = "扫描失败: \(error.localizedDescription)"
            }
        }
    }

    private func exportMediaItem(assetURL: URL, to destination: URL) async throws {
        // 如果文件已存在，跳过
        if FileManager.default.fileExists(atPath: destination.path()) {
            return
        }

        let asset = AVURLAsset(url: assetURL)

        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetPassthrough
        ) else {
            throw LibraryError.exportFailed
        }

        exportSession.outputURL = destination
        exportSession.outputFileType = .m4a

        await exportSession.export()

        guard exportSession.status == .completed else {
            throw LibraryError.exportFailed
        }
    }

    // MARK: - File Import

    func importFile(from sourceURL: URL, modelContext: ModelContext) async throws -> Song {
        await MainActor.run { isImporting = true }
        defer { Task { @MainActor in isImporting = false } }

        // 需要获取安全访问权限
        let accessingGranted = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessingGranted {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let asset = AVURLAsset(url: sourceURL)

        // 读取元数据
        let title: String
        let artist: String
        let album: String
        let duration: Double

        // 从文件名获取基本信息
        let fileName = sourceURL.deletingPathExtension().lastPathComponent
        title = fileName
        artist = "未知艺术家"
        album = "未知专辑"

        // 获取时长
        let durationCMTime = try await asset.load(.duration)
        duration = CMTimeGetSeconds(durationCMTime)

        // 提取封面
        var albumArtData: Data? = nil
        let metadata = try await asset.load(.commonMetadata)
        for item in metadata {
            if item.commonKey == .commonKeyArtwork {
                if let data = try await item.load(.dataValue) {
                    albumArtData = data
                }
                break
            }
        }

        // 拷贝文件到沙盒
        let musicDir = getMusicDirectory()
        let destinationURL = musicDir.appendingPathComponent(sourceURL.lastPathComponent)

        if !FileManager.default.fileExists(atPath: destinationURL.path()) {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        }

        // 去重：检查是否已存在相同文件路径的歌曲
        let fileURLString = destinationURL.absoluteString
        let existingDescriptor = FetchDescriptor<Song>(
            predicate: #Predicate { $0.fileURL.absoluteString == fileURLString }
        )
        if let existingSong = try? modelContext.fetch(existingDescriptor).first {
            return existingSong
        }

        // 查找歌词文件
        let lyricsDir = getLyricsDirectory()
        let lyricsFileURL = findLyricsFile(for: title, in: lyricsDir)

        let song = Song(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            fileURL: destinationURL,
            albumArtData: albumArtData,
            hasLyrics: lyricsFileURL != nil,
            lyricsFileURL: lyricsFileURL,
            sourceType: "imported"
        )
        modelContext.insert(song)
        try? modelContext.save()

        return song
    }

    func importFiles(from sourceURLs: [URL], modelContext: ModelContext) async {
        for url in sourceURLs {
            do {
                _ = try await importFile(from: url, modelContext: modelContext)
            } catch {
                print("⚠️ 导入失败 [\(url.lastPathComponent)]: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - File Management

    func getMusicDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let musicDir = docs.appendingPathComponent("Music")
        try? FileManager.default.createDirectory(at: musicDir, withIntermediateDirectories: true)
        return musicDir
    }

    func getLyricsDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let lyricsDir = docs.appendingPathComponent("Lyrics")
        try? FileManager.default.createDirectory(at: lyricsDir, withIntermediateDirectories: true)
        return lyricsDir
    }

    func deleteSong(_ song: Song) {
        // 删除音频文件
        try? FileManager.default.removeItem(at: song.fileURL)

        // 删除歌词文件
        if let lyricsURL = song.lyricsFileURL {
            try? FileManager.default.removeItem(at: lyricsURL)
        }
    }

    // MARK: - Helpers

    private func findLyricsFile(for title: String, in directory: URL) -> URL? {
        let lrcName = "\(title).lrc"
        let lrcURL = directory.appendingPathComponent(lrcName)

        if FileManager.default.fileExists(atPath: lrcURL.path()) {
            return lrcURL
        }
        return nil
    }
}

// MARK: - Errors

enum LibraryError: LocalizedError {
    case noAssetURL
    case exportFailed
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .noAssetURL:
            return "无法获取音频资源 URL"
        case .exportFailed:
            return "音频导出失败"
        case .fileNotFound:
            return "文件未找到"
        }
    }
}
