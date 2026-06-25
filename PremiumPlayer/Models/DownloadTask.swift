import Foundation

// MARK: - DownloadTask Model
// Represents an active or queued download operation with full tracking.
// This is the runtime model used by DownloadService to manage concurrent downloads.

enum DownloadQuality: String, CaseIterable, Codable {
    case audioMP3 = "mp3"
    case videoMP4 = "mp4"
    
    var displayName: String {
        switch self {
        case .audioMP3: return LocalizedStrings.homeQualityAudio
        case .videoMP4: return LocalizedStrings.homeQualityVideo
        }
    }
    
    var fileExtension: String {
        rawValue
    }
    
    var mediaType: MediaType {
        switch self {
        case .audioMP3: return .audio
        case .videoMP4: return .video
        }
    }
}

enum DownloadTaskStatus: String, Codable {
    case pending
    case downloading
    case extracting
    case completed
    case failed
    case cancelled
    
    var isActive: Bool {
        self == .pending || self == .downloading || self == .extracting
    }
    
    var isTerminal: Bool {
        self == .completed || self == .failed || self == .cancelled
    }
}

struct DownloadTask: Identifiable, Codable, Equatable {
    let id: UUID
    let mediaItemID: UUID
    let sourceURL: String
    let quality: DownloadQuality
    var status: DownloadTaskStatus
    var progress: Double                 // 0.0 ... 1.0
    var downloadedBytes: Int64
    var totalBytes: Int64
    var estimatedTimeRemaining: TimeInterval?
    var downloadSpeedBytesPerSecond: Double
    var errorMessage: String?
    var destinationFileName: String
    var destinationSubdirectory: String  // e.g., "downloads" within Documents
    var createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var extractedTitle: String?
    var extractedArtist: String?
    var extractedDuration: TimeInterval?
    var extractedThumbnailData: Data?
    
    // Computed properties
    var formattedProgress: String {
        String(format: "%.0f%%", progress * 100)
    }
    
    var formattedDownloadSpeed: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(downloadSpeedBytesPerSecond)) + "/s"
    }
    
    var formattedETR: String {
        guard let etr = estimatedTimeRemaining, etr > 0 else { return "--" }
        let totalSeconds = Int(etr)
        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        } else if totalSeconds < 3600 {
            let mins = totalSeconds / 60
            let secs = totalSeconds % 60
            return "\(mins)m \(secs)s"
        } else {
            let hours = totalSeconds / 3600
            let mins = (totalSeconds % 3600) / 60
            return "\(hours)h \(mins)m"
        }
    }
    
    var formattedTotalSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }
    
    var relativeFilePath: String {
        "\(destinationSubdirectory)/\(destinationFileName)"
    }
    
    // Equatable
    static func == (lhs: DownloadTask, rhs: DownloadTask) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        mediaItemID: UUID,
        sourceURL: String,
        quality: DownloadQuality,
        title: String? = nil,
        artist: String? = nil
    ) {
        self.id = id
        self.mediaItemID = mediaItemID
        self.sourceURL = sourceURL
        self.quality = quality
        self.status = .pending
        self.progress = 0.0
        self.downloadedBytes = 0
        self.totalBytes = 0
        self.estimatedTimeRemaining = nil
        self.downloadSpeedBytesPerSecond = 0
        self.errorMessage = nil
        self.destinationFileName = "\(UUID().uuidString).\(quality.fileExtension)"
        self.destinationSubdirectory = "downloads"
        self.createdAt = Date()
        self.startedAt = nil
        self.completedAt = nil
        self.extractedTitle = title
        self.extractedArtist = artist
        self.extractedDuration = nil
        self.extractedThumbnailData = nil
    }
    
}

// MARK: - DownloadQueue Manager Observable
class DownloadQueueManager: ObservableObject {
    @Published var activeTasks: [DownloadTask] = []
    @Published var completedTasks: [DownloadTask] = []
    @Published var maxConcurrentDownloads: Int = 2
    
    var pendingTasks: [DownloadTask] {
        activeTasks.filter { $0.status == .pending }
    }
    
    var inProgressTasks: [DownloadTask] {
        activeTasks.filter { $0.status == .downloading || $0.status == .extracting }
    }
    
    var overallProgress: Double {
        guard !activeTasks.isEmpty else { return 0 }
        let total = activeTasks.reduce(0.0) { $0 + $1.progress }
        return total / Double(activeTasks.count)
    }
    
    func taskForMediaItem(id: UUID) -> DownloadTask? {
        activeTasks.first { $0.mediaItemID == id } ?? completedTasks.first { $0.mediaItemID == id }
    }
    
    func addTask(_ task: DownloadTask) {
        activeTasks.append(task)
    }
    
    func updateTask(_ task: DownloadTask) {
        if let index = activeTasks.firstIndex(where: { $0.id == task.id }) {
            activeTasks[index] = task
            
            if task.status.isTerminal {
                // Move to completed list
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.archiveTask(task)
                }
            }
        }
    }
    
    func cancelTask(_ task: DownloadTask) {
        var updated = task
        updated.status = .cancelled
        updated.completedAt = Date()
        updateTask(updated)
    }
    
    private func archiveTask(_ task: DownloadTask) {
        activeTasks.removeAll { $0.id == task.id }
        completedTasks.insert(task, at: 0)
        // Keep only last 100 completed tasks to avoid unbounded growth
        if completedTasks.count > 100 {
            completedTasks = Array(completedTasks.prefix(100))
        }
    }
    
    func clearCompletedTasks() {
        completedTasks.removeAll()
    }
    
    func clearAll() {
        activeTasks.forEach { cancelTask($0) }
        completedTasks.removeAll()
    }
}