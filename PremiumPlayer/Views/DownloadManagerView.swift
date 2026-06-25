import SwiftUI

// MARK: - DownloadManagerView
// Displays active downloads with progress bars, extraction states,
// speed/ETA metrics, and completed downloads list.

struct DownloadManagerView: View {
    @StateObject private var downloadService = DownloadService.shared
    @State private var selectedFilter: DownloadFilter = .active
    
    enum DownloadFilter: String, CaseIterable {
        case active
        case completed
        
        var displayName: String {
            switch self {
            case .active: return LocalizedStrings.downloadActive
            case .completed: return LocalizedStrings.downloadCompleted
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            headerSection
            
            // MARK: - Filter Pills
            filterSection
            
            // MARK: - Content
            if selectedFilter == .active {
                activeDownloadsContent
            } else {
                completedDownloadsContent
            }
        }
        .background(
            ZStack {
                LuxuryTheme.Gradients.backgroundFade
                LuxuryTheme.Gradients.violetGlowOverlay
            }
            .edgesIgnoringSafeArea(.all)
        )
    }
    
    // MARK: - Filtered Data
    private var activeTasks: [DownloadTask] {
        downloadService.queueManager.activeTasks.filter { $0.status.isActive }
    }
    
    private var completedTasks: [DownloadTask] {
        downloadService.queueManager.completedTasks
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStrings.downloadTitle)
                    .font(LuxuryTheme.Typography.largeTitle(.bold))
                    .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                
                Text("\(activeTasks.count) \(LocalizedStrings.downloadActive.lowercased())")
                    .font(LuxuryTheme.Typography.body())
                    .foregroundColor(LuxuryTheme.Colors.silverMist)
            }
            
            Spacer()
            
            if !completedTasks.isEmpty {
                Button {
                    downloadService.queueManager.clearCompletedTasks()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(LuxuryTheme.Colors.dangerCrimson)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(LuxuryTheme.Colors.dangerCrimson.opacity(0.12))
                        )
                }
            }
        }
        .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        HStack(spacing: 10) {
            ForEach(DownloadFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.displayName)
                        .font(LuxuryTheme.Typography.caption(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
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
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(
                                    selectedFilter == filter
                                        ? LuxuryTheme.Colors.violetElectric.opacity(0.5)
                                        : Color.white.opacity(0.05),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
        .padding(.bottom, 16)
    }
    
    // MARK: - Active Downloads Content
    private var activeDownloadsContent: some View {
        ScrollView {
            if activeTasks.isEmpty {
                emptyStateView(
                    icon: "arrow.down.circle",
                    title: LocalizedStrings.downloadNoActive,
                    description: LocalizedStrings.downloadNoActiveDesc
                )
            } else {
                VStack(spacing: 16) {
                    ForEach(activeTasks) { task in
                        ActiveDownloadCard(task: task)
                    }
                }
                .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Completed Downloads Content
    private var completedDownloadsContent: some View {
        ScrollView {
            if completedTasks.isEmpty {
                emptyStateView(
                    icon: "checkmark.circle",
                    title: "No completed downloads",
                    description: "Completed downloads will appear here"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(completedTasks) { task in
                        CompletedDownloadCard(task: task)
                    }
                }
                .padding(.horizontal, LuxuryTheme.Layout.screenPadding)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Empty State
    private func emptyStateView(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            
            ZStack {
                Circle()
                    .fill(LuxuryTheme.Colors.violetElectric.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.5))
            }
            
            VStack(spacing: 6) {
                Text(title)
                    .font(LuxuryTheme.Typography.headline(.semibold))
                    .foregroundColor(LuxuryTheme.Colors.silverMist)
                
                Text(description)
                    .font(LuxuryTheme.Typography.body())
                    .foregroundColor(LuxuryTheme.Colors.silverMist.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

// MARK: - Active Download Card
struct ActiveDownloadCard: View {
    @StateObject private var downloadService = DownloadService.shared
    let task: DownloadTask
    
    var body: some View {
        VStack(spacing: 14) {
            // Header row
            HStack(spacing: 12) {
                // Icon with status
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    if task.status == .extracting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: statusColor))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: task.status == .downloading ? "arrow.down" : "clock")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(statusColor)
                    }
                }
                
                // Title and status
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.extractedTitle ?? "Downloading...")
                        .font(LuxuryTheme.Typography.body(.semibold))
                        .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                        .lineLimit(1)
                    
                    Text(statusText)
                        .font(LuxuryTheme.Typography.caption())
                        .foregroundColor(statusColor)
                }
                
                Spacer()
                
                // Cancel button
                Button {
                    downloadService.cancelDownload(mediaItemID: task.mediaItemID)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(LuxuryTheme.Colors.dangerCrimson)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(LuxuryTheme.Colors.dangerCrimson.opacity(0.12))
                        )
                }
            }
            
            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(LuxuryTheme.Colors.obsidianElevated)
                            .frame(height: 6)
                        
                        // Fill
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
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
                            .frame(width: geometry.size.width * CGFloat(task.progress), height: 6)
                            .animation(.easeInOut(duration: 0.3), value: task.progress)
                    }
                }
                .frame(height: 6)
                
                // Stats row
                HStack {
                    Text(task.formattedProgress)
                        .font(LuxuryTheme.Typography.monoDigit(.semibold))
                        .foregroundColor(LuxuryTheme.Colors.violetGlow)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        if task.downloadSpeedBytesPerSecond > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(LuxuryTheme.Colors.silverMist)
                                Text(task.formattedDownloadSpeed)
                                    .font(LuxuryTheme.Typography.caption())
                                    .foregroundColor(LuxuryTheme.Colors.silverMist)
                            }
                        }
                        
                        if task.estimatedTimeRemaining != nil {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 9))
                                    .foregroundColor(LuxuryTheme.Colors.silverMist)
                                Text(task.formattedETR)
                                    .font(LuxuryTheme.Typography.caption())
                                    .foregroundColor(LuxuryTheme.Colors.silverMist)
                            }
                        }
                        
                        Text(task.formattedTotalSize)
                            .font(LuxuryTheme.Typography.caption())
                            .foregroundColor(LuxuryTheme.Colors.silverMist)
                    }
                }
            }
        }
        .padding(LuxuryTheme.Layout.cardPadding)
        .glassmorphicCard()
    }
    
    private var statusColor: Color {
        switch task.status {
        case .pending: return LuxuryTheme.Colors.warningAmber
        case .downloading: return LuxuryTheme.Colors.violetElectric
        case .extracting: return LuxuryTheme.Colors.violetGlow
        case .completed: return LuxuryTheme.Colors.successEmerald
        case .failed, .cancelled: return LuxuryTheme.Colors.dangerCrimson
        }
    }
    
    private var statusText: String {
        switch task.status {
        case .pending: return LocalizedStrings.downloadQueued
        case .downloading: return LocalizedStrings.downloadActive
        case .extracting: return LocalizedStrings.downloadExtracting
        case .completed: return LocalizedStrings.downloadCompleted
        case .failed: return LocalizedStrings.downloadFailed
        case .cancelled: return LocalizedStrings.downloadCancel
        }
    }
}

// MARK: - Completed Download Card
struct CompletedDownloadCard: View {
    let task: DownloadTask
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LuxuryTheme.Colors.successEmerald.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: task.status == .completed ? "checkmark" : "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(
                        task.status == .completed
                            ? LuxuryTheme.Colors.successEmerald
                            : LuxuryTheme.Colors.dangerCrimson
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.extractedTitle ?? "Unknown Download")
                    .font(LuxuryTheme.Typography.body(.semibold))
                    .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Image(systemName: task.quality == .audioMP3 ? "music.note" : "film")
                        .font(.system(size: 10))
                        .foregroundColor(LuxuryTheme.Colors.silverMist)
                    
                    Text(task.quality.displayName)
                        .font(LuxuryTheme.Typography.caption())
                        .foregroundColor(LuxuryTheme.Colors.silverMist)
                    
                    Text("•")
                        .foregroundColor(LuxuryTheme.Colors.silverMist)
                    
                    Text(task.formattedTotalSize)
                        .font(LuxuryTheme.Typography.caption())
                        .foregroundColor(LuxuryTheme.Colors.silverMist)
                }
            }
            
            Spacer()
            
            // Status badge
            Text(task.status == .completed ? LocalizedStrings.downloadCompleted : LocalizedStrings.downloadFailed)
                .font(LuxuryTheme.Typography.caption(.semibold))
                .foregroundColor(
                    task.status == .completed
                        ? LuxuryTheme.Colors.successEmerald
                        : LuxuryTheme.Colors.dangerCrimson
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            (task.status == .completed
                                ? LuxuryTheme.Colors.successEmerald
                                : LuxuryTheme.Colors.dangerCrimson
                            ).opacity(0.12)
                        )
                )
        }
        .padding(LuxuryTheme.Layout.cardPadding)
        .glassmorphicCard()
    }
}

// MARK: - Preview
struct DownloadManagerView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadManagerView()
            .preferredColorScheme(.dark)
    }
}