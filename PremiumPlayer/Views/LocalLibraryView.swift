import SwiftUI

// MARK: - LocalLibraryView
// Organized library of downloaded media with filtering (All/Audio/Video),
// search capability, sorting options, and play/pause integration.

struct LocalLibraryView: View {
    @StateObject private var downloadService = DownloadService.shared
    @StateObject private var playerEngine = AudioPlayerEngine.shared
    
    @State private var selectedFilter: LibraryFilter = .all
    @State private var searchText: String = ""
    @State private var sortOrder: SortOrder = .dateDesc
    
    enum LibraryFilter: String, CaseIterable {
        case all
        case audio
        case video
        
        var displayName: String {
            switch self {
            case .all: return LocalizedStrings.libraryAll
            case .audio: return LocalizedStrings.libraryAudio
            case .video: return LocalizedStrings.libraryVideo
            }
        }
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .audio: return "music.note"
            case .video: return "film"
            }
        }
    }
    
    enum SortOrder: String, CaseIterable {
        case dateDesc
        case dateAsc
        case nameAsc
        case nameDesc
        case sizeDesc
        
        var displayName: String {
            switch self {
            case .dateDesc: return LocalizedStrings.librarySortByDate + " ↓"
            case .dateAsc: return LocalizedStrings.librarySortByDate + " ↑"
            case .nameAsc: return LocalizedStrings.librarySortByName + " A–Z"
            case .nameDesc: return LocalizedStrings.librarySortByName + " Z–A"
            case .sizeDesc: return LocalizedStrings.librarySortBySize + " ↓"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            headerSection
            
            // MARK: - Search Bar
            searchBar
            
            // MARK: - Filter & Sort
            filterAndSortSection
            
            // MARK: - Library Content
            libraryContent
        }
        .background(
            ZStack {
                LuxuryTheme.Gradients.backgroundFade
                LuxuryTheme.Gradients.violetGlowOverlay
            }
            .edgesIgnoringSafeArea(.all)
        )
    }
    
    // MARK: - Computed Items
    private var allCompletedItems: [MediaItem] {
        downloadService.libraryItems.filter { $0.downloadState == .completed }
    }
    
    private var filteredItems: [MediaItem] {
        var items = allCompletedItems
        
        // Filter by type
        switch selectedFilter {
        case .all: break
        case .audio: items = items.filter { $0.mediaType == .audio }
        case .video: items = items.filter { $0.mediaType == .video }
        }
        
        // Filter by search
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchText.lowercased()
            items = items.filter {
                $0.title.lowercased().contains(query) ||
                $0.artist.lowercased().contains(query)
            }
        }
        
        // Sort
        switch sortOrder {
        case .dateDesc: items.sort { $0.dateAdded > $1.dateAdded }
        case .dateAsc: items.sort { $0.dateAdded < $1.dateAdded }
        case .nameAsc: items.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .nameDesc: items.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .sizeDesc: items.sort { ($0.fileSizeBytes ?? 0) > ($1.fileSizeBytes ?? 0) }
        }
        
        return items
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStrings.libraryTitle)
                    .font(LuxuryTheme.Typography.largeTitle(.bold))
                    .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                
                Text("\(filteredItems.count) \(filteredItems.count == 1 ? "item" : "items")")
                    .font(LuxuryTheme.Typography.body())
                    .foregroundColor(LuxuryTheme.Colors.silverMist)
            }
            
            Spacer()
            
            // Play all button
            if !filteredItems.isEmpty {
                Button {
                    playerEngine.setQueue(filteredItems)
                    if let first = filteredItems.first {
                        playerEngine.loadAndPlay(item: first)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Play All")
                            .font(LuxuryTheme.Typography.caption(.semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .pillButtonStyle()
            }
        }
        .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(LuxuryTheme.Colors.silverMist)
            
            TextField(LocalizedStrings.librarySearch, text: $searchText)
                .font(LuxuryTheme.Typography.body())
                .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                .tint(LuxuryTheme.Colors.violetElectric)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassmorphicCard(cornerRadius: 14, borderOpacity: 0.05)
        .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
        .padding(.bottom, 12)
    }
    
    // MARK: - Filter & Sort
    private var filterAndSortSection: some View {
        VStack(spacing: 8) {
            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LibraryFilter.allCases, id: \.self) { filter in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedFilter = filter
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: filter.icon)
                                    .font(.system(size: 12))
                                Text(filter.displayName)
                                    .font(LuxuryTheme.Typography.caption(.semibold))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .foregroundColor(
                                selectedFilter == filter
                                    ? .white
                                    : LuxuryTheme.Colors.silverMist
                            )
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        selectedFilter == filter
                                            ? LuxuryTheme.Gradients.accentPrimary
                                            : LuxuryTheme.Gradients.glassCard
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
            }
            
            // Sort picker
            HStack {
                Spacer()
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            HStack {
                                Text(order.displayName)
                                if sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 12))
                        Text(sortOrder.displayName)
                            .font(LuxuryTheme.Typography.caption())
                            .lineLimit(1)
                    }
                    .foregroundColor(LuxuryTheme.Colors.violetGlow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(LuxuryTheme.Colors.violetElectric.opacity(0.12))
                    )
                }
            }
            .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Library Content
    private var libraryContent: some View {
        ScrollView {
            if filteredItems.isEmpty {
                emptyLibraryView
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredItems) { item in
                        LibraryItemRow(item: item)
                    }
                }
                .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
                .padding(.bottom, 24)
            }
        }
    }
    
    private var emptyLibraryView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            
            ZStack {
                Circle()
                    .fill(LuxuryTheme.Colors.violetElectric.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "folder")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.5))
            }
            
            VStack(spacing: 6) {
                Text(LocalizedStrings.libraryEmpty)
                    .font(LuxuryTheme.Typography.headline(.semibold))
                    .foregroundColor(LuxuryTheme.Colors.silverMist)
                
                Text(LocalizedStrings.libraryEmptyDesc)
                    .font(LuxuryTheme.Typography.body())
                    .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

// MARK: - Library Item Row
struct LibraryItemRow: View {
    let item: MediaItem
    @StateObject private var playerEngine = AudioPlayerEngine.shared
    @StateObject private var downloadService = DownloadService.shared
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail / Icon
            Button {
                playItem()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    LuxuryTheme.Colors.violetElectric.opacity(0.5),
                                    LuxuryTheme.Colors.violetDeep.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    // Show play overlay if this is the current item
                    if playerEngine.currentItem?.id == item.id && playerEngine.isPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: item.mediaType == .audio ? "music.note" : "play.rectangle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            playerEngine.currentItem?.id == item.id
                                ? LuxuryTheme.Colors.violetElectric
                                : Color.clear,
                            lineWidth: 2
                        )
                )
            }
            .buttonStyle(.plain)
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(LuxuryTheme.Typography.body(.semibold))
                    .foregroundColor(
                        playerEngine.currentItem?.id == item.id
                            ? LuxuryTheme.Colors.violetGlow
                            : LuxuryTheme.Colors.platinumWhite
                    )
                    .lineLimit(1)
                
                Text(item.artist)
                    .font(LuxuryTheme.Typography.caption())
                    .foregroundColor(LuxuryTheme.Colors.silverMist)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(item.formattedDuration, systemImage: "clock")
                        .font(LuxuryTheme.Typography.caption())
                        .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.7))
                    
                    Label(item.formattedFileSize, systemImage: "doc")
                        .font(LuxuryTheme.Typography.caption())
                        .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                // Play/Pause
                if playerEngine.currentItem?.id == item.id {
                    Button {
                        playerEngine.togglePlayPause()
                    } label: {
                        Image(systemName: playerEngine.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(LuxuryTheme.Colors.violetElectric)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(LuxuryTheme.Colors.violetElectric.opacity(0.15))
                            )
                    }
                }
                
                // Delete
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(LuxuryTheme.Colors.dangerCrimson.opacity(0.6))
                        .frame(width: 36, height: 36)
                }
            }
        }
        .padding(LuxuryTheme.Layout.cardPadding)
        .glassmorphicCard(borderOpacity: 0.04)
        .alert(LocalizedStrings.settingsConfirmClear, isPresented: $showDeleteConfirmation) {
            Button(LocalizedStrings.settingsCancel, role: .cancel) { }
            Button(LocalizedStrings.downloadDelete, role: .destructive) {
                // Stop playback if deleting the current item
                if playerEngine.currentItem?.id == item.id {
                    playerEngine.clearQueue()
                }
                downloadService.deleteMediaItem(item)
            }
        } message: {
            Text("Delete \"\(item.title)\"? This cannot be undone.")
        }
    }
    
    private func playItem() {
        guard item.isReadyToPlay else { return }
        playerEngine.setQueue([item])
        playerEngine.loadAndPlay(item: item)
    }
}

// MARK: - Preview
struct LocalLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LocalLibraryView()
            .preferredColorScheme(.dark)
    }
}