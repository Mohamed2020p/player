import SwiftUI

// MARK: - HomeDashboardView
// Premium home screen with:
// - URL input field for video downloads
// - Quality selection (Audio MP3 / Video MP4)
// - Quick stats cards
// - Trending / recent downloads section

struct HomeDashboardView: View {
    @StateObject private var downloadService = DownloadService.shared
    @StateObject private var playerEngine = AudioPlayerEngine.shared
    
    @State private var urlText: String = ""
    @State private var selectedQuality: DownloadQuality = .audioMP3
    @State private var showInvalidURLAlert: Bool = false
    @State private var showSuccessToast: Bool = false
    @FocusState private var isURLFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header
                headerSection
                
                // MARK: - URL Input Card
                urlInputCard
                
                // MARK: - Quality Selector
                qualitySelectorSection
                
                // MARK: - Download Button
                Button {
                    initiateDownload()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.down.to.line.compact")
                            .font(.system(size: 18, weight: .semibold))
                        Text(LocalizedStrings.homeDownloadNow)
                    }
                }
                .neonAccentButtonStyle(disabled: urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
                
                // MARK: - Quick Stats
                quickStatsSection
                
                // MARK: - Recent Downloads
                recentDownloadsSection
                
                Spacer(minLength: 24)
            }
            .padding(.top, 8)
        }
        .background(
            ZStack {
                LuxuryTheme.Gradients.backgroundFade
                LuxuryTheme.Gradients.violetGlowOverlay
            }
            .edgesIgnoringSafeArea(.all)
        )
        .scrollContentBackground(.hidden)
        .alert(LocalizedStrings.urlInvalid, isPresented: $showInvalidURLAlert) {
            Button(LocalizedStrings.commonOK, role: .cancel) { }
        } message: {
            Text(LocalizedStrings.urlInvalidDesc)
        }
        .overlay(
            successToastView
                .opacity(showSuccessToast ? 1 : 0)
                .animation(.easeInOut(duration: 0.4), value: showSuccessToast)
        )
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStrings.homeTitle)
                        .font(LuxuryTheme.Typography.largeTitle(.bold))
                        .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                    
                    Text(LocalizedStrings.homeSubtitle)
                        .font(LuxuryTheme.Typography.body())
                        .foregroundColor(LuxuryTheme.Colors.silverMist)
                }
                
                Spacer()
                
                // Premium badge
                ZStack {
                    Circle()
                        .fill(LuxuryTheme.Gradients.accentPrimary)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .breathingGlow()
            }
            .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
            .padding(.top, 16)
        }
    }
    
    // MARK: - URL Input Card
    private var urlInputCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "link")
                    .font(.system(size: 18))
                    .foregroundColor(LuxuryTheme.Colors.violetGlow)
                
                TextField(LocalizedStrings.homePasteURL, text: $urlText)
                    .font(LuxuryTheme.Typography.body())
                    .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                    .focused($isURLFieldFocused)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .tint(LuxuryTheme.Colors.violetElectric)
                
                // Clear button
                if !urlText.isEmpty {
                    Button {
                        urlText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.6))
                    }
                }
                
                // Paste from clipboard
                Button {
                    if let clipboard = UIPasteboard.general.string {
                        urlText = clipboard
                    }
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 16))
                        .foregroundColor(LuxuryTheme.Colors.violetGlow)
                }
            }
            .padding(LuxuryTheme.Layout.cardPadding)
        }
        .glassmorphicCard()
        .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
    }
    
    // MARK: - Quality Selector
    private var qualitySelectorSection: some View {
        HStack(spacing: 12) {
            ForEach(DownloadQuality.allCases, id: \.self) { quality in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedQuality = quality
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: quality == .audioMP3 ? "music.note" : "film")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(quality.displayName)
                            .font(LuxuryTheme.Typography.body(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundColor(selectedQuality == quality ? .white : LuxuryTheme.Colors.silverMist)
                    .background(
                        RoundedRectangle(cornerRadius: LuxuryTheme.Layout.buttonCornerRadius, style: .continuous)
                            .fill(
                                selectedQuality == quality
                                    ? LuxuryTheme.Gradients.accentPrimary
                                    : LuxuryTheme.Gradients.glassCard
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LuxuryTheme.Layout.buttonCornerRadius, style: .continuous)
                            .stroke(
                                selectedQuality == quality
                                    ? LuxuryTheme.Colors.violetElectric.opacity(0.6)
                                    : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: selectedQuality == quality
                            ? LuxuryTheme.Colors.violetElectric.opacity(0.3)
                            : .clear,
                        radius: 12, x: 0, y: 4
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
    }
    
    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStrings.homeQuickStats)
                .font(LuxuryTheme.Typography.headline(.semibold))
                .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
            
            HStack(spacing: 12) {
                // Total Downloads
                StatCard(
                    icon: "arrow.down.circle.fill",
                    value: "\(downloadService.totalDownloadsCount)",
                    label: LocalizedStrings.homeTotalDownloads,
                    iconColor: LuxuryTheme.Colors.violetElectric
                )
                
                // Storage Used
                StatCard(
                    icon: "externaldrive.fill",
                    value: downloadService.totalStorageUsedFormatted,
                    label: LocalizedStrings.homeStorageUsed,
                    iconColor: LuxuryTheme.Colors.violetGlow
                )
            }
            .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
        }
    }
    
    // MARK: - Recent Downloads
    private var recentDownloadsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedStrings.homeTrending)
                    .font(LuxuryTheme.Typography.headline(.semibold))
                    .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                
                Spacer()
                
                if !completedItems.isEmpty {
                    Button {
                        // Navigate to library
                    } label: {
                        Text("See All")
                            .font(LuxuryTheme.Typography.caption(.semibold))
                            .foregroundColor(LuxuryTheme.Colors.violetGlow)
                    }
                }
            }
            .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
            
            if completedItems.isEmpty {
                emptyRecentView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(completedItems.prefix(5)) { item in
                            RecentMediaCard(item: item)
                        }
                    }
                    .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
                }
            }
        }
    }
    
    private var completedItems: [MediaItem] {
        downloadService.libraryItems.filter { $0.downloadState == .completed }
    }
    
    private var emptyRecentView: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note.list")
                .font(.system(size: 36))
                .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.4))
            
            Text("No downloads yet")
                .font(LuxuryTheme.Typography.body())
                .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .glassmorphicCard()
        .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
    }
    
    // MARK: - Download Initiation
    private func initiateDownload() {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        guard downloadService.validateURL(trimmed) else {
            showInvalidURLAlert = true
            return
        }
        
        downloadService.startDownload(sourceURL: trimmed, quality: selectedQuality)
        urlText = ""
        isURLFieldFocused = false
        
        // Show success toast
        withAnimation {
            showSuccessToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showSuccessToast = false
            }
        }
    }
    
    // MARK: - Toast
    private var successToastView: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(LuxuryTheme.Colors.successEmerald)
                
                Text("Download started")
                    .font(LuxuryTheme.Typography.body(.medium))
                    .foregroundColor(LuxuryTheme.Colors.platinumWhite)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(LuxuryTheme.Colors.obsidianElevated.opacity(0.95))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(LuxuryTheme.Colors.successEmerald.opacity(0.3), lineWidth: 1)
            )
            .padding(.bottom, 120)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Text(value)
                .font(LuxuryTheme.Typography.title(.bold))
                .foregroundColor(LuxuryTheme.Colors.platinumWhite)
            
            Text(label)
                .font(LuxuryTheme.Typography.caption())
                .foregroundColor(LuxuryTheme.Colors.silverMist)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LuxuryTheme.Layout.cardPadding)
        .glassmorphicCard()
    }
}

// MARK: - Recent Media Card
struct RecentMediaCard: View {
    let item: MediaItem
    @StateObject private var playerEngine = AudioPlayerEngine.shared
    
    var body: some View {
        Button {
            if item.isReadyToPlay {
                playerEngine.setQueue([item])
                playerEngine.loadAndPlay(item: item)
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Cover artwork placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    LuxuryTheme.Colors.violetElectric.opacity(0.6),
                                    LuxuryTheme.Colors.violetDeep.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: item.mediaType == .audio ? "music.note" : "play.rectangle")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .shadow(color: LuxuryTheme.Colors.violetElectric.opacity(0.25), radius: 10, x: 0, y: 5)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(LuxuryTheme.Typography.body(.semibold))
                        .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                        .lineLimit(1)
                        .frame(width: 140, alignment: .leading)
                    
                    Text(item.artist)
                        .font(LuxuryTheme.Typography.caption())
                        .foregroundColor(LuxuryTheme.Colors.silverMist)
                        .lineLimit(1)
                        .frame(width: 140, alignment: .leading)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
struct HomeDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        HomeDashboardView()
            .preferredColorScheme(.dark)
            .background(Color.black)
    }
}