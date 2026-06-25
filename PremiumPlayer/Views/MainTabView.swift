import SwiftUI

// MARK: - MainTabView
// Root navigation container with luxury bottom tab bar.
// Houses all primary screens and the floating mini-player overlay.

struct MainTabView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var downloadService = DownloadService.shared
    @StateObject private var playerEngine = AudioPlayerEngine.shared
    
    @State private var selectedTab: Int = 0
    
    private let tabItems: [LuxuryTabItem] = [
        LuxuryTabItem(icon: "house", title: LocalizedStringKey(LocalizedStrings.tabHome), tag: 0),
        LuxuryTabItem(icon: "arrow.down.circle", title: LocalizedStringKey(LocalizedStrings.tabDownloads), tag: 1),
        LuxuryTabItem(icon: "folder", title: LocalizedStringKey(LocalizedStrings.tabLibrary), tag: 2),
        LuxuryTabItem(icon: "gearshape", title: LocalizedStringKey(LocalizedStrings.tabSettings), tag: 3)
    ]
    
    var body: some View {
        ZStack {
            // Background
            LuxuryTheme.Colors.obsidianDeep
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Content area
                TabView(selection: $selectedTab) {
                    HomeDashboardView()
                        .tag(0)
                    
                    DownloadManagerView()
                        .tag(1)
                    
                    LocalLibraryView()
                        .tag(2)
                    
                    SettingsView()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Mini player spacer (if visible)
                if playerEngine.isPlayerVisible {
                    MiniPlayerBar()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Custom luxury tab bar
                LuxuryTabBar(items: tabItems, selection: $selectedTab)
            }
        }
        .environment(\.layoutDirection, languageManager.layoutDirection)
        .animation(.easeInOut(duration: 0.3), value: languageManager.currentLanguage)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: playerEngine.isPlayerVisible)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Mini Player Bar
struct MiniPlayerBar: View {
    @StateObject private var playerEngine = AudioPlayerEngine.shared
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                // Signal that we want to expand the full player
                playerEngine.isPlayerVisible = true
            }
        } label: {
            HStack(spacing: 12) {
                // Cover art placeholder with glow
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(LuxuryTheme.Gradients.accentPrimary.opacity(0.8))
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: playerEngine.currentItem?.mediaType == .video ? "film" : "music.note")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .breathingGlow()
                
                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    Text(playerEngine.currentItem?.title ?? LocalizedStrings.playerUnknownTitle)
                        .font(LuxuryTheme.Typography.body(.semibold))
                        .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                        .lineLimit(1)
                    
                    Text(playerEngine.currentItem?.artist ?? LocalizedStrings.playerUnknownArtist)
                        .font(LuxuryTheme.Typography.caption())
                        .foregroundColor(LuxuryTheme.Colors.silverMist)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Play/Pause
                Button {
                    playerEngine.togglePlayPause()
                } label: {
                    Image(systemName: playerEngine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(LuxuryTheme.Colors.violetElectric.opacity(0.3))
                        )
                }
                
                // Next
                Button {
                    playerEngine.playNext()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(LuxuryTheme.Colors.silverMist)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    LuxuryTheme.Colors.obsidianMid.opacity(0.95)
                    
                    // Subtle top glow line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    LuxuryTheme.Colors.violetElectric.opacity(0.5),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 1.5)
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .preferredColorScheme(.dark)
    }
}