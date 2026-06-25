import Foundation
import AVFoundation

// MARK: - MediaItem Model
// Represents a downloaded or downloading media track in the PremiumPlayer library.

enum MediaType: String, Codable, CaseIterable {
    case audio = "mp3"
    case video = "mp4"
    
    var displayName: String {
        switch self {
        case .audio: return LocalizedStrings.homeQualityAudio
        case .video: return LocalizedStrings.homeQualityVideo
        }
    }
    
    var icon: String {
        switch self {
        case .audio: return "music.note.list"
        case .video: return "film"
        }
    }
}

enum DownloadState: String, Codable {
    case queued
    case downloading
    case extracting
    case completed
    case failed
    
    var displayName: String {
        switch self {
        case .queued: return LocalizedStrings.downloadQueued
        case .downloading: return LocalizedStrings.downloadActive
        case .extracting: return LocalizedStrings.downloadExtracting
        case .completed: return LocalizedStrings.downloadCompleted
        case .failed: return LocalizedStrings.downloadFailed
        }
    }
}

struct MediaItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var artist: String
    var sourceURL: String
    var mediaType: MediaType
    var downloadState: DownloadState
    var downloadProgress: Double          // 0.0 ... 1.0
    var localFileURL: String?             // Path relative to Documents directory
    var fileSizeBytes: Int64?
    var durationSeconds: TimeInterval?
    var thumbnailURL: String?
    var dateAdded: Date
    var dateDownloaded: Date?
    
    // Computed properties
    var isReadyToPlay: Bool {
        downloadState == .completed && localFileURL != nil
    }
    
    var formattedFileSize: String {
        guard let bytes = fileSizeBytes else { return "--" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    var formattedDuration: String {
        guard let duration = durationSeconds else { return "--" }
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedDateAdded: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateAdded)
    }
    
    var localAbsoluteURL: URL? {
        guard let relativePath = localFileURL else { return nil }
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent(relativePath)
    }
    
    // Equatable
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Playlist model
struct Playlist: Identifiable, Codable {
    let id: UUID
    var name: String
    var itemIDs: [UUID]
    var dateCreated: Date
    var coverColor: String // Hex color string for visual distinction
    
    var isEmpty: Bool {
        itemIDs.isEmpty
    }
    
    var itemCount: Int {
        itemIDs.count
    }
}