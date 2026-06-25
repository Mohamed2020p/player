import Foundation
import AVFoundation
import MediaPlayer
import Combine
import UIKit

// MARK: - AudioPlayerEngine
// Advanced audio/video playback engine wrapping AVPlayer with:
// - Background playback via Audio/Background Modes
// - Lock-screen controls (Now Playing Info Center)
// - Queue management (play next/previous)
// - Repeat modes (off/all/one)
// - Remote command handling
// - Seek support

enum RepeatMode: String, Codable, CaseIterable {
    case off
    case all
    case one
    
    var icon: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
    
    var displayName: String {
        switch self {
        case .off: return LocalizedStrings.playerRepeatOff
        case .all: return LocalizedStrings.playerRepeatAll
        case .one: return LocalizedStrings.playerRepeatOne
        }
    }
    
    var next: RepeatMode {
        switch self {
        case .off: return .all
        case .all: return .one
        case .one: return .off
        }
    }
}

class AudioPlayerEngine: ObservableObject {
    static let shared = AudioPlayerEngine()
    
    // MARK: - Published State
    @Published var isPlaying: Bool = false
    @Published var currentItem: MediaItem?
    @Published var queue: [MediaItem] = []
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var repeatMode: RepeatMode = .off
    @Published var isShuffled: Bool = false
    @Published var isPlayerVisible: Bool = false
    
    // MARK: - Internal State
    // Exposed as Published so PremiumAudioPlayerView can render the video layer
    @Published var player: AVPlayer?
    private var timeObserverToken: Any?
    private var playerItemEndObserver: NSObjectProtocol?
    private var audioSessionConfigured = false
    private var originalQueueOrder: [MediaItem] = [] // For toggling shuffle
    
    // MARK: - Initialization
    private init() {
        configureAudioSession()
        setupRemoteCommandCenter()
        setupInterruptionHandling()
    }
    
    // MARK: - Audio Session Configuration
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, policy: .longFormAudio)
            try session.setActive(true)
            audioSessionConfigured = true
            print("[AudioPlayerEngine] Audio session configured for playback.")
        } catch {
            print("[AudioPlayerEngine] Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - Remote Command Center Setup
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        // Pause
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        // Next Track
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }
        
        // Previous Track
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
        
        // Change Playback Position (seek)
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: positionEvent.positionTime)
            return .success
        }
        
        // Toggle Play/Pause
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.pause()
            } else {
                self.play()
            }
            return .success
        }
        
        // Enable/disable commands
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward(15)
            return .success
        }
        
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward(15)
            return .success
        }
    }
    
    // MARK: - Interruption Handling
    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            DispatchQueue.main.async {
                self.pause()
            }
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                DispatchQueue.main.async {
                    self.play()
                }
            }
        @unknown default:
            break
        }
    }
    
    // MARK: - Playback Controls
    func loadAndPlay(item: MediaItem) {
        guard item.isReadyToPlay, let fileURL = item.localAbsoluteURL else {
            print("[AudioPlayerEngine] Item not ready to play: \(item.title)")
            return
        }
        
        // Ensure audio session is active
        if !audioSessionConfigured {
            configureAudioSession()
        }
        try? AVAudioSession.sharedInstance().setActive(true)
        
        // Remove previous observer
        removeTimeObserver()
        
        // Create player item and player
        let playerItem = AVPlayerItem(url: fileURL)
        
        // Observe end of playback
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidFinishPlaying(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
            player?.automaticallyWaitsToMinimizeStalling = true
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        
        currentItem = item
        duration = item.durationSeconds ?? 0
        
        addTimeObserver()
        updateNowPlayingInfo(for: item)
        
        player?.play()
        isPlaying = true
        isPlayerVisible = true
        
        print("[AudioPlayerEngine] Playing: \(item.title)")
    }
    
    func play() {
        player?.play()
        isPlaying = true
        updateNowPlayingElapsedTime()
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingElapsedTime()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else if currentItem != nil {
            play()
        }
    }
    
    func playNext() {
        guard let current = currentItem else { return }
        guard let currentIndex = queue.firstIndex(where: { $0.id == current.id }) else {
            // Try loading first item in queue
            if let first = queue.first, first.isReadyToPlay {
                loadAndPlay(item: first)
            }
            return
        }
        
        let nextIndex = currentIndex + 1
        if nextIndex < queue.count {
            let nextItem = queue[nextIndex]
            if nextItem.isReadyToPlay {
                loadAndPlay(item: nextItem)
            }
        } else if repeatMode == .all {
            // Wrap around to first item
            if let first = queue.first, first.isReadyToPlay {
                loadAndPlay(item: first)
            }
        } else {
            pause()
            seek(to: duration)
        }
    }
    
    func playPrevious() {
        guard let current = currentItem else { return }
        guard let currentIndex = queue.firstIndex(where: { $0.id == current.id }) else {
            if let first = queue.first, first.isReadyToPlay {
                loadAndPlay(item: first)
            }
            return
        }
        
        // If we're more than 3 seconds in, restart current track
        if currentTime > 3.0 {
            seek(to: 0)
            return
        }
        
        let prevIndex = currentIndex - 1
        if prevIndex >= 0 {
            let prevItem = queue[prevIndex]
            if prevItem.isReadyToPlay {
                loadAndPlay(item: prevItem)
            }
        } else if repeatMode == .all {
            if let last = queue.last, last.isReadyToPlay {
                loadAndPlay(item: last)
            }
        } else {
            seek(to: 0)
        }
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
        updateNowPlayingElapsedTime()
    }
    
    func skipForward(_ seconds: Double = 15) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    func skipBackward(_ seconds: Double = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    func cycleRepeatMode() {
        repeatMode = repeatMode.next
    }
    
    func toggleShuffle() {
        isShuffled.toggle()
        if isShuffled {
            originalQueueOrder = queue
            queue = queue.shuffled()
        } else {
            queue = originalQueueOrder
            originalQueueOrder = []
        }
    }
    
    // MARK: - Queue Management
    func setQueue(_ items: [MediaItem]) {
        let playableItems = items.filter { $0.isReadyToPlay }
        queue = playableItems
        originalQueueOrder = playableItems
        isShuffled = false
    }
    
    func addToQueue(_ item: MediaItem) {
        if item.isReadyToPlay, !queue.contains(where: { $0.id == item.id }) {
            queue.append(item)
            if !isShuffled {
                originalQueueOrder.append(item)
            }
        }
    }
    
    func removeFromQueue(_ item: MediaItem) {
        queue.removeAll { $0.id == item.id }
        originalQueueOrder.removeAll { $0.id == item.id }
    }
    
    func clearQueue() {
        pause()
        player?.replaceCurrentItem(with: nil)
        removeTimeObserver()
        currentItem = nil
        queue.removeAll()
        originalQueueOrder.removeAll()
        isPlaying = false
        currentTime = 0
        duration = 0
        isPlayerVisible = false
        clearNowPlayingInfo()
    }
    
    // MARK: - Time Observer
    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let currentSeconds = time.seconds
            if currentSeconds.isFinite {
                self.currentTime = currentSeconds
                self.updateNowPlayingElapsedTime()
            }
        }
    }
    
    private func removeTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
    // MARK: - Now Playing Info Center
    private func updateNowPlayingInfo(for item: MediaItem) {
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = item.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = item.artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = item.durationSeconds ?? 0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // Album / source info
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "PremiumPlayer Library"
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateNowPlayingElapsedTime() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    // MARK: - Player Item End Handler
    @objc private func playerItemDidFinishPlaying(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.repeatMode == .one {
                self.seek(to: 0)
                self.play()
            } else {
                self.playNext()
            }
        }
    }
    
    // MARK: - Formatting Helpers
    static func formatTime(_ interval: TimeInterval) -> String {
        guard interval.isFinite && interval >= 0 else { return "0:00" }
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Deinit
    deinit {
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self)
    }
}
