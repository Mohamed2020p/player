import Foundation
import Combine
import AVFoundation

// MARK: - DownloadServiceError
enum DownloadServiceError: LocalizedError {
    case invalidURL
    case networkError(String)
    case downloadFailed(String)
    case insufficientSpace
    case cancelled
    case fileSystemError
    case serverError(Int)
    case extractionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided."
        case .networkError(let reason):
            return "Network Error: \(reason)"
        case .downloadFailed(let reason):
            return "Download Failed: \(reason)"
        case .insufficientSpace:
            return "Insufficient storage space"
        case .cancelled:
            return "Download Cancelled"
        case .fileSystemError:
            return "File system error"
        case .serverError(let code):
            return "Server returned error \(code)"
        case .extractionFailed(let reason):
            return "Stream extraction failed: \(reason)"
        }
    }
}

// MARK: - DownloadService
class DownloadService: ObservableObject {
    static let shared = DownloadService()

    @Published var queueManager = DownloadQueueManager()
    @Published var libraryItems: [MediaItem] = []

    private let fileManager = FileManager.default
    private let downloadsSubdirectory = "downloads"
    private var urlSession: URLSession!
    private var downloadDelegates: [UUID: DownloadDelegate] = [:]
    private let downloadQueue = DispatchQueue(label: "com.premiumplayer.download", qos: .utility)

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var downloadsDirectoryURL: URL {
        let url = documentsURL.appendingPathComponent(downloadsSubdirectory)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    // MARK: - Library Persistence
    private var libraryStorageURL: URL {
        documentsURL.appendingPathComponent("library_data.json")
    }

    private func loadLibrary() {
        guard fileManager.fileExists(atPath: libraryStorageURL.path) else {
            libraryItems = []
            return
        }
        do {
            let data = try Data(contentsOf: libraryStorageURL)
            libraryItems = try JSONDecoder().decode([MediaItem].self, from: data)
        } catch {
            print("[DownloadService] Failed to load library: \(error)")
            libraryItems = []
        }
    }

    private func saveLibrary() {
        do {
            let data = try JSONEncoder().encode(libraryItems)
            try data.write(to: libraryStorageURL, options: .atomic)
        } catch {
            print("[DownloadService] Failed to save library: \(error)")
        }
    }

    // MARK: - Initialization
    private init() {
        ensureDownloadsDirectoryExists()
        loadLibrary()
        setupURLSession()
    }

    private func setupURLSession() {
        let config = URLSessionConfiguration.background(withIdentifier: "com.premiumplayer.downloads")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 600
        let delegate = SessionDelegate(downloadService: self)
        urlSession = URLSession(configuration: config, delegate: delegate, delegateQueue: OperationQueue())
    }

    private func ensureDownloadsDirectoryExists() {
        let url = documentsURL.appendingPathComponent(downloadsSubdirectory)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }

    // MARK: - URL Validation
    func validateURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return false }
        guard url.host != nil else { return false }
        return true
    }

    private func isYouTubeURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("youtube.com") ||
               host.contains("youtu.be") ||
               host.contains("youtube-nocookie.com") ||
               host.contains("music.youtube.com")
    }

    // MARK: - Start Download
    @discardableResult
    func startDownload(sourceURL: String, quality: DownloadQuality) -> UUID {
        let mediaItemID = UUID()

        let mediaItem = MediaItem(
            id: mediaItemID,
            title: "Extracting...",
            artist: "Unknown",
            sourceURL: sourceURL,
            mediaType: quality.mediaType,
            downloadState: .queued,
            downloadProgress: 0.0,
            localFileURL: nil,
            fileSizeBytes: nil,
            durationSeconds: nil,
            thumbnailURL: nil,
            dateAdded: Date(),
            dateDownloaded: nil
        )
        libraryItems.insert(mediaItem, at: 0)
        saveLibrary()

        let downloadTask = DownloadTask(
            mediaItemID: mediaItemID,
            sourceURL: sourceURL,
            quality: quality,
            title: nil,
            artist: nil
        )
        queueManager.addTask(downloadTask)

        if let url = URL(string: sourceURL), isYouTubeURL(url) {
            beginYouTubeDownload(task: downloadTask, url: url)
        } else {
            beginDirectDownload(task: downloadTask)
        }

        return mediaItemID
    }

    // MARK: - YouTube Download via Python Server
    private func beginYouTubeDownload(task: DownloadTask, url: URL) {
        updateTaskStatus(taskID: task.id, mediaItemID: task.mediaItemID, status: .extracting, progress: 0.0)

        let serverEndpoint = "http://159.89.97.95:5000/extract"
        guard let apiURL = URL(string: serverEndpoint) else {
            finalizeTask(taskID: task.id, mediaItemID: task.mediaItemID, status: .failed, error: .invalidURL)
            return
        }

        var request = URLRequest(url: apiURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // تحقق مما إذا كان المستخدم اختار جودة صوتية
        let preferAudio = task.quality == .audioMP3

        let payload: [String: Any] = [
            "url": url.absoluteString,
            "preferAudio": preferAudio
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            finalizeTask(taskID: task.id, mediaItemID: task.mediaItemID, status: .failed, error: .extractionFailed("Failed to build request body"))
            return
        }
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                self.finalizeTask(taskID: task.id, mediaItemID: task.mediaItemID, status: .failed, error: .networkError(error.localizedDescription))
                return
            }

            guard let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                self.finalizeTask(taskID: task.id, mediaItemID: task.mediaItemID, status: .failed, error: .extractionFailed("Invalid response from server"))
                return
            }

            // التحقق من وجود خطأ قادم من السيرفر
            if let errorMsg = json["error"] as? String {
                self.finalizeTask(taskID: task.id, mediaItemID: task.mediaItemID, status: .failed, error: .extractionFailed(errorMsg))
                return
            }

            // استخراج الرابط المباشر
            guard let streamURLString = json["streamURL"] as? String,
                  let streamURL = URL(string: streamURLString) else {
                self.finalizeTask(taskID: task.id, mediaItemID: task.mediaItemID, status: .failed, error: .extractionFailed("No direct URL found in response"))
                return
            }

            // استخراج التفاصيل
            let title = json["title"] as? String ?? "Unknown Title"
            let artist = json["artist"] as? String ?? "YouTube"
            let duration = json["duration"] as? TimeInterval ?? 0

            // تحديث المكتبة بالعنوان والبيانات الجديدة قبل التحميل الفعلي
            DispatchQueue.main.async {
                if let index = self.libraryItems.firstIndex(where: { $0.id == task.mediaItemID }) {
                    self.libraryItems[index].title = title
                    self.libraryItems[index].artist = artist
                    self.libraryItems[index].durationSeconds = duration
                    self.saveLibrary()
                }
            }

            // بدء التحميل الفعلي للملف المباشر
            self.beginActualDownload(task: task, overrideURL: streamURL)
        }.resume()
    }

    // MARK: - Direct URL Download
    private func beginDirectDownload(task: DownloadTask) {
        guard let url = URL(string: task.sourceURL) else {
            finalizeTask(taskID: task.id, mediaItemID: task.mediaItemID, status: .failed, error: .invalidURL)
            return
        }
        beginActualDownload(task: task, overrideURL: url)
    }

    // MARK: - Actual File Download
    private func beginActualDownload(task: DownloadTask, overrideURL: URL) {
        let destinationFileName = task.destinationFileName
        let destinationURL = downloadsDirectoryURL.appendingPathComponent(destinationFileName)

        let delegate = DownloadDelegate(
            taskID: task.id,
            mediaItemID: task.mediaItemID,
            destinationURL: destinationURL,
            downloadService: self
        )

        DispatchQueue.main.async { [weak self] in
            self?.downloadDelegates[task.id] = delegate
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 600
        
        // استخدام User-Agent قياسي وموثوق لضمان عدم رفض السيرفرات الخاصة بيوتيوب أو غيرها لطلب التحميل
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Accept": "*/*"
        ]

        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: .main)
        var request = URLRequest(url: overrideURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 120)
        request.httpMethod = "GET"

        let downloadTaskSession = session.downloadTask(with: request)
        delegate.session = session
        delegate.downloadTask = downloadTaskSession

        updateTaskStatus(taskID: task.id, mediaItemID: task.mediaItemID, status: .downloading, progress: 0.0)
        downloadTaskSession.resume()
    }

    // MARK: - Progress Handlers
    func handleDownloadProgress(taskID: UUID, mediaItemID: UUID, progress: Double, downloadedBytes: Int64, totalBytes: Int64, speed: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard var task = self.queueManager.activeTasks.first(where: { $0.id == taskID }) else { return }
            task.progress = progress
            task.downloadedBytes = downloadedBytes
            task.totalBytes = totalBytes
            task.downloadSpeedBytesPerSecond = speed
            task.status = .downloading
            if task.startedAt == nil { task.startedAt = Date() }
            self.queueManager.updateTask(task)

            if let index = self.libraryItems.firstIndex(where: { $0.id == mediaItemID }) {
                self.libraryItems[index].downloadProgress = progress
                self.libraryItems[index].downloadState = .downloading
                self.libraryItems[index].fileSizeBytes = totalBytes
                self.saveLibrary()
            }
        }
    }

    func handleDownloadCompletion(taskID: UUID, mediaItemID: UUID, localFileURL: URL, fileSize: Int64) {
        let (extractedTitle, extractedArtist, duration) = extractMetadata(from: localFileURL)

        finalizeDownload(
            taskID: taskID,
            mediaItemID: mediaItemID,
            localFilePath: "\(downloadsSubdirectory)/\(localFileURL.lastPathComponent)",
            fileSize: fileSize,
            title: extractedTitle,
            artist: extractedArtist,
            duration: duration ?? 0
        )

        DispatchQueue.main.async { [weak self] in
            self?.downloadDelegates.removeValue(forKey: taskID)
        }
    }

    func handleDownloadFailure(taskID: UUID, mediaItemID: UUID, error: DownloadServiceError) {
        finalizeTask(taskID: taskID, mediaItemID: mediaItemID, status: .failed, error: error)
        DispatchQueue.main.async { [weak self] in
            self?.downloadDelegates.removeValue(forKey: taskID)
        }
    }

    // MARK: - Metadata Extraction (synchronous, local files only)
    private func extractMetadata(from url: URL) -> (title: String, artist: String, duration: TimeInterval?) {
        let asset = AVAsset(url: url)
        var title: String? = nil
        var artist: String? = nil
        var duration: TimeInterval? = nil

        let metadata = asset.commonMetadata
        for item in metadata {
            if item.commonKey == .commonKeyTitle, let val = item.value as? String { title = val }
            if item.commonKey == .commonKeyArtist, let val = item.value as? String { artist = val }
        }

        let cmDuration = asset.duration
        let secs = CMTimeGetSeconds(cmDuration)
        if secs.isFinite && secs > 0 { duration = secs }

        if title == nil || title!.isEmpty {
            title = url.lastPathComponent
                .replacingOccurrences(of: ".mp4", with: "")
                .replacingOccurrences(of: ".mp3", with: "")
                .replacingOccurrences(of: ".webm", with: "")
                .replacingOccurrences(of: ".m4a", with: "")
                .replacingOccurrences(of: "%20", with: " ")
                .replacingOccurrences(of: "_", with: " ")
        }

        return (title ?? "Premium Download", artist ?? "PremiumPlayer Library", duration)
    }

    // MARK: - Task State Updates
    private func updateTaskStatus(taskID: UUID, mediaItemID: UUID, status: DownloadTaskStatus, progress: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard var task = self.queueManager.activeTasks.first(where: { $0.id == taskID }) else { return }
            task.status = status
            task.progress = progress
            self.queueManager.updateTask(task)

            if let index = self.libraryItems.firstIndex(where: { $0.id == mediaItemID }) {
                self.libraryItems[index].downloadState = self.mapStatusToDownloadState(status)
                self.libraryItems[index].downloadProgress = progress
                self.saveLibrary()
            }
        }
    }

    private func finalizeDownload(taskID: UUID, mediaItemID: UUID, localFilePath: String, fileSize: Int64, title: String, artist: String, duration: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if var task = self.queueManager.activeTasks.first(where: { $0.id == taskID }) {
                task.status = .completed
                task.progress = 1.0
                task.downloadedBytes = fileSize
                task.totalBytes = fileSize
                task.completedAt = Date()
                task.extractedTitle = title
                task.extractedArtist = artist
                task.extractedDuration = duration
                self.queueManager.updateTask(task)
            }

            if let index = self.libraryItems.firstIndex(where: { $0.id == mediaItemID }) {
                let existingTitle = self.libraryItems[index].title
                let existingArtist = self.libraryItems[index].artist
                self.libraryItems[index].downloadState = .completed
                self.libraryItems[index].downloadProgress = 1.0
                self.libraryItems[index].localFileURL = localFilePath
                self.libraryItems[index].fileSizeBytes = fileSize
                self.libraryItems[index].title = (existingTitle != "Extracting..." && !existingTitle.isEmpty) ? existingTitle : title
                self.libraryItems[index].artist = (existingArtist != "Unknown" && !existingArtist.isEmpty) ? existingArtist : artist
                self.libraryItems[index].durationSeconds = self.libraryItems[index].durationSeconds ?? duration
                self.libraryItems[index].dateDownloaded = Date()
                self.saveLibrary()
            }
        }
    }

    private func finalizeTask(taskID: UUID, mediaItemID: UUID, status: DownloadTaskStatus, error: DownloadServiceError) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if var task = self.queueManager.activeTasks.first(where: { $0.id == taskID }) {
                task.status = status
                task.errorMessage = error.localizedDescription
                task.completedAt = Date()
                self.queueManager.updateTask(task)
            }
            if let index = self.libraryItems.firstIndex(where: { $0.id == mediaItemID }) {
                self.libraryItems[index].downloadState = self.mapStatusToDownloadState(status)
                self.saveLibrary()
            }
        }
    }

    private func mapStatusToDownloadState(_ status: DownloadTaskStatus) -> DownloadState {
        switch status {
        case .pending: return .queued
        case .downloading: return .downloading
        case .extracting: return .extracting
        case .completed: return .completed
        case .failed, .cancelled: return .failed
        }
    }

    // MARK: - Cancel Download
    func cancelDownload(mediaItemID: UUID) {
        if let (_, delegate) = downloadDelegates.first(where: { $0.value.mediaItemID == mediaItemID }) {
            delegate.downloadTask?.cancel()
            downloadDelegates.removeValue(forKey: delegate.taskID)
        }
        if let task = queueManager.activeTasks.first(where: { $0.mediaItemID == mediaItemID }) {
            queueManager.cancelTask(task)
        }
        if let index = libraryItems.firstIndex(where: { $0.id == mediaItemID }) {
            libraryItems[index].downloadState = .failed
            saveLibrary()
        }
    }

    // MARK: - Delete
    func deleteMediaItem(_ item: MediaItem) {
        if let absoluteURL = item.localAbsoluteURL {
            try? fileManager.removeItem(at: absoluteURL)
        }
        libraryItems.removeAll { $0.id == item.id }
        saveLibrary()
    }

    // MARK: - Clear All
    func clearAllDownloads() {
        for (_, delegate) in downloadDelegates { delegate.downloadTask?.cancel() }
        downloadDelegates.removeAll()
        for item in libraryItems {
            if let absoluteURL = item.localAbsoluteURL {
                try? fileManager.removeItem(at: absoluteURL)
            }
        }
        queueManager.clearAll()
        libraryItems.removeAll()
        saveLibrary()
    }

    // MARK: - Cache
    func computeCacheSize() -> Int64 {
        var totalSize: Int64 = 0
        guard let enumerator = fileManager.enumerator(at: downloadsDirectoryURL, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        return totalSize
    }

    func clearCache() {
        guard let enumerator = fileManager.enumerator(at: downloadsDirectoryURL, includingPropertiesForKeys: nil) else { return }
        for case let fileURL as URL in enumerator {
            try? fileManager.removeItem(at: fileURL)
        }
    }

    var totalDownloadsCount: Int {
        libraryItems.filter { $0.downloadState == .completed }.count
    }

    var totalStorageUsedFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: computeCacheSize())
    }

    private func processQueue() {}
}

// MARK: - DownloadDelegate
class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let taskID: UUID
    let mediaItemID: UUID
    let destinationURL: URL
    private(set) weak var downloadService: DownloadService?
    var session: URLSession?
    var downloadTask: URLSessionDownloadTask?

    private var lastUpdateTime: Date = Date()
    private var lastDownloadedBytes: Int64 = 0
    private var startTime: Date?

    init(taskID: UUID, mediaItemID: UUID, destinationURL: URL, downloadService: DownloadService) {
        self.taskID = taskID
        self.mediaItemID = mediaItemID
        self.destinationURL = destinationURL
        self.downloadService = downloadService
        super.init()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? Int64) ?? 0
            downloadService?.handleDownloadCompletion(taskID: taskID, mediaItemID: mediaItemID, localFileURL: destinationURL, fileSize: fileSize)
        } catch {
            downloadService?.handleDownloadFailure(taskID: taskID, mediaItemID: mediaItemID, error: .fileSystemError)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if startTime == nil { startTime = Date() }
        let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0.0
        let now = Date()
        let interval = now.timeIntervalSince(lastUpdateTime)
        var speed: Double = 0
        if interval > 0 {
            speed = Double(totalBytesWritten - lastDownloadedBytes) / interval
        }
        lastUpdateTime = now
        lastDownloadedBytes = totalBytesWritten
        downloadService?.handleDownloadProgress(taskID: taskID, mediaItemID: mediaItemID, progress: progress, downloadedBytes: totalBytesWritten, totalBytes: totalBytesExpectedToWrite, speed: speed)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as NSError? {
            if error.code == NSURLErrorCancelled {
                downloadService?.handleDownloadFailure(taskID: taskID, mediaItemID: mediaItemID, error: .cancelled)
            } else {
                downloadService?.handleDownloadFailure(taskID: taskID, mediaItemID: mediaItemID, error: .networkError(error.localizedDescription))
            }
        }
        session.finishTasksAndInvalidate()
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            downloadService?.handleDownloadFailure(taskID: taskID, mediaItemID: mediaItemID, error: .networkError(error.localizedDescription))
        }
    }
}

// MARK: - SessionDelegate
class SessionDelegate: NSObject, URLSessionDelegate {
    private weak var downloadService: DownloadService?
    init(downloadService: DownloadService) {
        self.downloadService = downloadService
        super.init()
    }
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {}
}
