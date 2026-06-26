import Foundation
import SwiftData
import SwiftUI
import UIKit

@Model
final class Song {
    @Attribute(.unique) var id: UUID
    var title: String
    var artist: String
    var album: String
    var duration: Double
    var fileURL: URL
    var albumArtData: Data?
    var hasLyrics: Bool
    var lyricsFileURL: URL?
    var dateAdded: Date
    var sourceType: String // "library" 或 "imported"
    var mediaLibraryPersistentID: String?

    init(
        id: UUID = UUID(),
        title: String,
        artist: String = "未知艺术家",
        album: String = "未知专辑",
        duration: Double = 0,
        fileURL: URL,
        albumArtData: Data? = nil,
        hasLyrics: Bool = false,
        lyricsFileURL: URL? = nil,
        dateAdded: Date = Date(),
        sourceType: String = "imported",
        mediaLibraryPersistentID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.fileURL = fileURL
        self.albumArtData = albumArtData
        self.hasLyrics = hasLyrics
        self.lyricsFileURL = lyricsFileURL
        self.dateAdded = dateAdded
        self.sourceType = sourceType
        self.mediaLibraryPersistentID = mediaLibraryPersistentID
    }

    var albumArtImage: Image? {
        guard let data = albumArtData, let uiImage = UIImage(data: data) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
