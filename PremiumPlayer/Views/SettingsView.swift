import SwiftUI

// MARK: - SettingsView
// Premium settings screen with:
// - Language Selection (English / Arabic with RTL support)
// - Storage Management (cache size, clear cache & downloads)
// - About Section with Author Credits (@c0derz / Mohamed Annati)
// - Premium branding touchpoints

struct SettingsView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var downloadService = DownloadService.shared
    @StateObject private var playerEngine = AudioPlayerEngine.shared
    
    @State private var showClearCacheConfirmation: Bool = false
    @State private var showClearDownloadsConfirmation: Bool = false
    @State private var showCacheClearedToast: Bool = false
    @State private var showDownloadsClearedToast: Bool = false
    @State private var languageDropdownExpanded: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // MARK: - Header
                headerSection
                
                // MARK: - Language Section
                languageSection
                
                // MARK: - Appearance Section
                appearanceSection
                
                // MARK: - Storage Section
                storageSection
                
                // MARK: - About Section
                aboutSection
                
                Spacer(minLength: 40)
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
        .alert(LocalizedStrings.settingsConfirmClear, isPresented: $showClearCacheConfirmation) {
            Button(LocalizedStrings.settingsCancel, role: .cancel) { }
            Button(LocalizedStrings.settingsConfirm, role: .destructive) {
                performClearCache()
            }
        } message: {
            Text(LocalizedStrings.settingsConfirmClearDownloadsMessage)
        }
        .alert(LocalizedStrings.settingsConfirmClear, isPresented: $showClearDownloadsConfirmation) {
            Button(LocalizedStrings.settingsCancel, role: .cancel) { }
            Button(LocalizedStrings.settingsConfirm, role: .destructive) {
                performClearDownloads()
            }
        } message: {
            Text(LocalizedStrings.settingsConfirmClearDownloadsMessage)
        }
        .overlay(
            toastOverlay
                .opacity(showCacheClearedToast || showDownloadsClearedToast ? 1 : 0)
                .animation(.easeInOut(duration: 0.4), value: showCacheClearedToast || showDownloadsClearedToast)
        )
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStrings.settingsTitle)
                    .font(LuxuryTheme.Typography.largeTitle(.bold))
                    .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                
                Text("PremiumPlayer")
                    .font(LuxuryTheme.Typography.body())
                    .foregroundColor(LuxuryTheme.Colors.violetGlow)
            }
            
            Spacer()
        }
        .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Language Section
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "globe", title: LocalizedStrings.settingsLanguage)
                .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
            
            VStack(spacing: 4) {
                ForEach(AppLanguage.allCases, id: \.self) { langOption in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            languageManager.currentLanguage = langOption
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Text(langOption.displayName)
                                .font(LuxuryTheme.Typography.body(.medium))
                                .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                            
                            Spacer()
                            
                            if languageManager.currentLanguage == langOption {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(LuxuryTheme.Colors.violetElectric)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle()
                                            .fill(LuxuryTheme.Colors.violetElectric.opacity(0.15))
                                    )
                            }
                        }
                        .padding(.horizontal, LuxuryTheme.Layout.cardPadding)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .background(
                        languageManager.currentLanguage == langOption
                            ? LuxuryTheme.Colors.violetElectric.opacity(0.08)
                            : Color.clear
                    )
                    
                    if langOption != AppLanguage.allCases.last {
                        Divider()
                            .padding(.horizontal, LuxuryTheme.Layout.cardPadding)
                            .background(LuxuryTheme.Colors.obsidianDeep)
                    }
                }
            }
            .glassmorphicCard()
            .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
            
            .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "paintbrush", title: LocalizedStrings.settingsAppearance)
                .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
            
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LuxuryTheme.Gradients.accentPrimary.opacity(0.3))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "moon.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(LuxuryTheme.Colors.violetElectric)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStrings.settingsAppearanceDesc)
                        .font(LuxuryTheme.Typography.body(.medium))
                        .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                    
                    Text("Deep obsidian with electric violet accents")
                        .font(LuxuryTheme.Typography.caption())
                        .foregroundColor(LuxuryTheme.Colors.silverMist)
                }
                
                Spacer()
                
                // Toggle for dark mode (always on in this build)
                ZStack {
                    Capsule()
                        .fill(LuxuryTheme.Colors.violetElectric.opacity(0.3))
                        .frame(width: 50, height: 28)
                    
                    Capsule()
                        .fill(LuxuryTheme.Colors.violetElectric)
                        .frame(width: 24, height: 24)
                        .offset(x: 11)
                }
            }
            .padding(LuxuryTheme.Layout.cardPadding)
            .glassmorphicCard()
            .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
        }
    }
    
    // MARK: - Storage Section
    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "externaldrive", title: LocalizedStrings.settingsStorage)
                .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
            
            VStack(spacing: 4) {
                // Cache size row
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LuxuryTheme.Colors.warningAmber.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "archivebox")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(LuxuryTheme.Colors.warningAmber)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStrings.settingsCacheSize)
                            .font(LuxuryTheme.Typography.body(.medium))
                            .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                        
                        Text(downloadService.totalStorageUsedFormatted)
                            .font(LuxuryTheme.Typography.caption())
                            .foregroundColor(LuxuryTheme.Colors.silverMist)
                    }
                    
                    Spacer()
                }
                .padding(LuxuryTheme.Layout.cardPadding)
                
                Divider()
                    .padding(.horizontal, LuxuryTheme.Layout.cardPadding)
                    .background(LuxuryTheme.Colors.obsidianDeep)
                
                // Clear cache button
                Button {
                    showClearCacheConfirmation = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(LuxuryTheme.Colors.dangerCrimson.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "trash")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(LuxuryTheme.Colors.dangerCrimson)
                        }
                        
                        Text(LocalizedStrings.settingsClearCache)
                            .font(LuxuryTheme.Typography.body(.medium))
                            .foregroundColor(LuxuryTheme.Colors.dangerCrimson)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.4))
                    }
                    .padding(LuxuryTheme.Layout.cardPadding)
                }
                .buttonStyle(.plain)
                
                Divider()
                    .padding(.horizontal, LuxuryTheme.Layout.cardPadding)
                    .background(LuxuryTheme.Colors.obsidianDeep)
                
                // Clear all downloads button
                Button {
                    showClearDownloadsConfirmation = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(LuxuryTheme.Colors.dangerCrimson.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(LuxuryTheme.Colors.dangerCrimson)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStrings.settingsClearDownloads)
                                .font(LuxuryTheme.Typography.body(.medium))
                                .foregroundColor(LuxuryTheme.Colors.dangerCrimson)
                            
                            Text("Removes all media from library")
                                .font(LuxuryTheme.Typography.caption())
                                .foregroundColor(LuxuryTheme.Colors.silverMist)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.4))
                    }
                    .padding(LuxuryTheme.Layout.cardPadding)
                }
                .buttonStyle(.plain)
            }
            .glassmorphicCard()
            .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "info.circle", title: LocalizedStrings.settingsAbout)
                .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
            
            VStack(spacing: 16) {
                // Branding / Developer Card
                VStack(alignment: .center, spacing: 14) {
                    // App icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(LuxuryTheme.Gradients.accentPrimary)
                            .frame(width: 80, height: 80)
                            .shadow(color: LuxuryTheme.Colors.violetElectric.opacity(0.4), radius: 20, x: 0, y: 8)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }
                    .breathingGlow()
                    
                    VStack(spacing: 4) {
                        Text("PremiumPlayer")
                            .font(LuxuryTheme.Typography.title(.bold))
                            .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                        
                        Text("v1.0.0")
                            .font(LuxuryTheme.Typography.caption())
                            .foregroundColor(LuxuryTheme.Colors.violetGlow)
                    }
                    
                    // Author Credit
                    VStack(spacing: 2) {
                        Text(LocalizedStrings.developedBy)
                            .font(LuxuryTheme.Typography.caption())
                            .foregroundColor(LuxuryTheme.Colors.silverMist)
                        
                        Text(LocalizedStrings.settingsDeveloperHandle)
                            .font(LuxuryTheme.Typography.body(.semibold))
                            .foregroundColor(LuxuryTheme.Colors.violetElectric)
                        
                        Text(LocalizedStrings.settingsDeveloperName)
                            .font(LuxuryTheme.Typography.headline(.semibold))
                            .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                    }
                    .padding(.top, 6)
                    
                    // Social / Brand tagline
                    Text(LocalizedStrings.settingsAllRightsReserved)
                        .font(LuxuryTheme.Typography.caption())
                        .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                
                // Info rows
                VStack(spacing: 14) {
                    InfoRow(icon: "person.fill", label: LocalizedStrings.settingsDeveloper, value: LocalizedStrings.settingsDeveloperName)
                    InfoRow(icon: "at", label: "Social", value: LocalizedStrings.settingsDeveloperHandle)
                }
                .padding(.horizontal, LuxuryTheme.Layout.cardPadding)
                
                Divider()
                    .background(LuxuryTheme.Colors.obsidianElevated)
                
                // Compact links section
                HStack(spacing: 8) {
                    LinkButton(icon: "globe", text: "Website")
                    LinkButton(icon: "star.fill", text: LocalizedStrings.settingsRateApp)
                    LinkButton(icon: "square.and.arrow.up", text: LocalizedStrings.settingsShareApp)
                }
                .padding(.horizontal, LuxuryTheme.Layout.cardPadding)
                .padding(.bottom, 12)
            }
            .glassmorphicCard()
            .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
        }
    }
    
    // MARK: - Toast Overlay
    private var toastOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(LuxuryTheme.Colors.successEmerald)
                
                Text(
                    showCacheClearedToast
                        ? LocalizedStrings.settingsCacheCleared
                        : LocalizedStrings.settingsDownloadsCleared
                )
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
    
    // MARK: - Actions
    private func performClearCache() {
        downloadService.clearCache()
        withAnimation {
            showCacheClearedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showCacheClearedToast = false
            }
        }
    }
    
    private func performClearDownloads() {
        // Stop playback
        playerEngine.clearQueue()
        // Delete all
        downloadService.clearAllDownloads()
        withAnimation {
            showDownloadsClearedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showDownloadsClearedToast = false
            }
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(LuxuryTheme.Colors.violetGlow)
            
            Text(title)
                .font(LuxuryTheme.Typography.caption(.semibold))
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundColor(LuxuryTheme.Colors.violetGlow)
            
            Spacer()
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(LuxuryTheme.Colors.silverMist)
                .frame(width: 24)
            
            Text(label)
                .font(LuxuryTheme.Typography.body())
                .foregroundColor(LuxuryTheme.Colors.platinumWhite)
            
            Spacer()
            
            Text(value)
                .font(LuxuryTheme.Typography.body(.medium))
                .foregroundColor(LuxuryTheme.Colors.silverMist)
                .lineLimit(1)
        }
    }
}

// MARK: - Link Button
struct LinkButton: View {
    let icon: String
    let text: String
    
    var body: some View {
        Button {
            // Action handled where needed
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(text)
                    .font(LuxuryTheme.Typography.caption(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .foregroundColor(LuxuryTheme.Colors.platinumWhite)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .preferredColorScheme(.dark)
    }
}