import SwiftUI
import AVKit

// MARK: - PremiumAudioPlayerView
// Full-screen immersive audio player with:
// - Animated waveform visualization
// - Cover art with blurred background OR Video Player for MP4s
// - Playback controls (play/pause, skip, seek)
// - Queue display
// - Repeat & Shuffle controls

struct PremiumAudioPlayerView: View {
    @StateObject private var playerEngine = AudioPlayerEngine.shared
    
    @State private var showQueue: Bool = false
    @State private var isDraggingSlider: Bool = false
    @State private var dragProgress: Double = 0.0
    
    var body: some View {
        ZStack {
            // MARK: - Background
            backgroundLayer
            
            // MARK: - Content
            VStack(spacing: 0) {
                // Handle bar
                handleBar
                
                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Cover art or Video Player
                        coverArtSection
                            .padding(.top, 16)
                        
                        // Track info
                        trackInfoSection
                        
                        // Seek bar
                        seekBarSection
                        
                        // Main playback controls
                        playbackControlsSection
                        
                        // Secondary controls
                        secondaryControlsSection
                        
                        // Queue toggle
                        queueToggleSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
        .sheet(isPresented: $showQueue) {
            QueueSheetView()
        }
    }
    
    // MARK: - Background Layer
    private var backgroundLayer: some View {
        ZStack {
            // Deep obsidian base
            LuxuryTheme.Colors.obsidianDeep
                .edgesIgnoringSafeArea(.all)
            
            // Violet glow overlay
            LuxuryTheme.Gradients.violetGlowOverlay
                .edgesIgnoringSafeArea(.all)
            
            // Animated cover art blur
            if let _ = playerEngine.currentItem {
                Circle()
                    .fill(LuxuryTheme.Gradients.accentPrimary.opacity(0.3))
                    .frame(width: 350, height: 350)
                    .blur(radius: 80)
                    .offset(y: -100)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: playerEngine.isPlaying)
            }
        }
    }
    
    // MARK: - Handle Bar
    private var handleBar: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(LuxuryTheme.Colors.silverMist.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            
            Text(LocalizedStrings.playerNowPlaying)
                .font(LuxuryTheme.Typography.caption(.semibold))
                .foregroundColor(LuxuryTheme.Colors.silverMist)
                .textCase(.uppercase)
                .tracking(2)
        }
    }
    
    // MARK: - Cover Art & Video Player
    private var coverArtSection: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(LuxuryTheme.Colors.violetElectric.opacity(0.2))
                .frame(width: 240, height: 240)
                .blur(radius: 40)
            
            // Check if it's a video and we have an active player
            if playerEngine.currentItem?.mediaType == .video, let activePlayer = playerEngine.player {
                // Actual Video Player
                VideoPlayer(player: activePlayer)
                    .frame(width: UIScreen.main.bounds.width - 40, height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(
                        color: LuxuryTheme.Colors.violetElectric.opacity(0.4),
                        radius: 30, x: 0, y: 10
                    )
            } else {
                // Cover art placeholder for Audio MP3s
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                LuxuryTheme.Colors.violetElectric.opacity(0.7),
                                LuxuryTheme.Colors.violetDeep.opacity(0.9)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    )
                    .shadow(
                        color: LuxuryTheme.Colors.violetElectric.opacity(0.4),
                        radius: 30, x: 0, y: 10
                    )
                    .scaleEffect(playerEngine.isPlaying ? 1.0 : 0.95)
                    .animation(.easeInOut(duration: 0.4), value: playerEngine.isPlaying)
            }
        }
    }
    
    // MARK: - Track Info
    private var trackInfoSection: some View {
        VStack(spacing: 6) {
            Text(playerEngine.currentItem?.title ?? LocalizedStrings.playerUnknownTitle)
                .font(LuxuryTheme.Typography.title(.bold))
                .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(playerEngine.currentItem?.artist ?? LocalizedStrings.playerUnknownArtist)
                .font(LuxuryTheme.Typography.body())
                .foregroundColor(LuxuryTheme.Colors.silverMist)
            
            if let item = playerEngine.currentItem {
                HStack(spacing: 6) {
                    Image(systemName: item.mediaType == .audio ? "music.note" : "film")
                        .font(.system(size: 10))
                    Text(item.mediaType.displayName)
                        .font(LuxuryTheme.Typography.caption())
                }
                .foregroundColor(LuxuryTheme.Colors.violetGlow.opacity(0.7))
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Seek Bar
    private var seekBarSection: some View {
        VStack(spacing: 10) {
            // Slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(LuxuryTheme.Colors.obsidianElevated)
                        .frame(height: 5)
                    
                    // Progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    LuxuryTheme.Colors.violetElectric,
                                    LuxuryTheme.Colors.violetGlow
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(playerEngine.duration > 0 ? playerEngine.currentTime / playerEngine.duration : 0), height: 5)
                    
                    // Thumb
                    Circle()
                        .fill(LuxuryTheme.Colors.platinumWhite)
                        .frame(width: 16, height: 16)
                        .shadow(color: LuxuryTheme.Colors.violetElectric.opacity(0.5), radius: 6)
                        .offset(x: geometry.size.width * CGFloat(playerEngine.duration > 0 ? playerEngine.currentTime / playerEngine.duration : 0) - 8)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDraggingSlider = true
                            let fraction = max(0, min(1, value.location.x / geometry.size.width))
                            dragProgress = fraction * playerEngine.duration
                        }
                        .onEnded { _ in
                            playerEngine.seek(to: dragProgress)
                            isDraggingSlider = false
                        }
                )
            }
            .frame(height: 20)
            
            // Time labels
            HStack {
                Text(AudioPlayerEngine.formatTime(isDraggingSlider ? dragProgress : playerEngine.currentTime))
                    .font(LuxuryTheme.Typography.monoDigit())
                    .foregroundColor(LuxuryTheme.Colors.silverMist)
                
                Spacer()
                
                Text("-" + AudioPlayerEngine.formatTime(playerEngine.duration - (isDraggingSlider ? dragProgress : playerEngine.currentTime)))
                    .font(LuxuryTheme.Typography.monoDigit())
                    .foregroundColor(LuxuryTheme.Colors.silverMist)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Playback Controls
    private var playbackControlsSection: some View {
        HStack(spacing: 28) {
            // Shuffle
            Button {
                playerEngine.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(playerEngine.isShuffled ? LuxuryTheme.Colors.violetElectric : LuxuryTheme.Colors.silverMist)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Previous
            Button {
                playerEngine.playPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 26))
                    .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                    .frame(width: 44, height: 44)
            }
            
            // Play/Pause
            Button {
                playerEngine.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(LuxuryTheme.Gradients.accentPrimary)
                        .frame(width: 72, height: 72)
                        .shadow(color: LuxuryTheme.Colors.violetElectric.opacity(0.5), radius: 20, x: 0, y: 6)
                    
                    Image(systemName: playerEngine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(playerEngine.isPlaying ? 1.0 : 1.03)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: playerEngine.isPlaying)
            
            // Next
            Button {
                playerEngine.playNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 26))
                    .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Repeat
            Button {
                playerEngine.cycleRepeatMode()
            } label: {
                ZStack {
                    Image(systemName: playerEngine.repeatMode.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(
                            playerEngine.repeatMode != .off
                                ? LuxuryTheme.Colors.violetElectric
                                : LuxuryTheme.Colors.silverMist
                        )
                    
                    if playerEngine.repeatMode == .one {
                        Text("1")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(LuxuryTheme.Colors.violetElectric)
                            .offset(y: -8)
                    }
                }
                .frame(width: 44, height: 44)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Secondary Controls
    private var secondaryControlsSection: some View {
        HStack(spacing: 40) {
            // Back 15s
            Button {
                playerEngine.skipBackward(15)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 22))
                        .foregroundColor(LuxuryTheme.Colors.silverMist)
                    Text("15")
                        .font(LuxuryTheme.Typography.caption())
                        .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.6))
                }
            }
            
            // Speed (placeholder)
            Button {
                // Speed control would go here
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "tortoise")
                        .font(.system(size: 22))
                        .foregroundColor(LuxuryTheme.Colors.silverMist)
                    Text("1x")
                        .font(LuxuryTheme.Typography.caption())
                        .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.6))
                }
            }
            
            // Forward 15s
            Button {
                playerEngine.skipForward(15)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 22))
                        .foregroundColor(LuxuryTheme.Colors.silverMist)
                    Text("15")
                        .font(LuxuryTheme.Typography.caption())
                        .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.6))
                }
            }
        }
    }
    
    // MARK: - Queue Toggle
    private var queueToggleSection: some View {
        Button {
            showQueue = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 14, weight: .medium))
                Text(LocalizedStrings.playerQueue)
                    .font(LuxuryTheme.Typography.body(.medium))
                
                Spacer()
                
                Text("\(playerEngine.queue.count)")
                    .font(LuxuryTheme.Typography.monoDigit())
                    .foregroundColor(LuxuryTheme.Colors.silverMist)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(LuxuryTheme.Colors.silverMist)
            }
            .padding(LuxuryTheme.Layout.cardPadding)
            .foregroundColor(LuxuryTheme.Colors.platinumWhite)
        }
        .glassmorphicCard()
    }
}

// MARK: - Queue Sheet
struct QueueSheetView: View {
    @StateObject private var playerEngine = AudioPlayerEngine.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LuxuryTheme.Colors.obsidianDeep.edgesIgnoringSafeArea(.all)
                
                if playerEngine.queue.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.4))
                        Text("Queue is empty")
                            .font(LuxuryTheme.Typography.body())
                            .foregroundColor(LuxuryTheme.Colors.silverMist)
                    }
                } else {
                    List {
                        Section(LocalizedStrings.playerNowPlaying) {
                            if let current = playerEngine.currentItem {
                                QueueItemRow(item: current, isNowPlaying: true)
                            }
                        }
                        
                        Section(LocalizedStrings.playerUpNext) {
                            ForEach(playerEngine.queue.filter { $0.id != playerEngine.currentItem?.id }) { item in
                                QueueItemRow(item: item, isNowPlaying: false)
                            }
                            .onDelete { _ in }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(LocalizedStrings.playerQueue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.commonDone) {
                        dismiss()
                    }
                    .foregroundColor(LuxuryTheme.Colors.violetElectric)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct QueueItemRow: View {
    let item: MediaItem
    let isNowPlaying: Bool
    @StateObject private var playerEngine = AudioPlayerEngine.shared
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LuxuryTheme.Colors.violetElectric.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                if isNowPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: item.mediaType == .audio ? "music.note" : "film")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(LuxuryTheme.Typography.body(.semibold))
                    .foregroundColor(isNowPlaying ? LuxuryTheme.Colors.violetGlow : LuxuryTheme.Colors.platinumWhite)
                    .lineLimit(1)
                
                Text(item.artist)
                    .font(LuxuryTheme.Typography.caption())
                    .foregroundColor(LuxuryTheme.Colors.silverMist)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(item.formattedDuration)
                .font(LuxuryTheme.Typography.monoDigit())
                .foregroundColor(LuxuryTheme.Colors.silverMist)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct PremiumAudioPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumAudioPlayerView()
            .preferredColorScheme(.dark)
    }
}
