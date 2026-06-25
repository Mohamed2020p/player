import SwiftUI
import UIKit

// MARK: - Luxury Design System for PremiumPlayer
// Ultra-premium dark theme with Obsidian backgrounds, Electric Violet accents, and glassmorphic gradients

// FIX: Added Color extension so Color.violetElectric resolves in LuxuryTheme.Effects.violetGlow()
extension Color {
    static let violetElectric = Color(red: 0.48, green: 0.24, blue: 1.00)
}

enum LuxuryTheme {
    
    // MARK: - Core Color Palette
    struct Colors {
        static let obsidianDeep = Color(red: 0.04, green: 0.04, blue: 0.08)          // #0A0A14 — Deepest background
        static let obsidianMid = Color(red: 0.08, green: 0.08, blue: 0.14)           // #141424 — Card backgrounds
        static let obsidianElevated = Color(red: 0.10, green: 0.10, blue: 0.18)      // #1A1A2E — Elevated surfaces
        static let violetElectric = Color(red: 0.48, green: 0.24, blue: 1.00)        // #7B3DFF — Primary accent
        static let violetDeep = Color(red: 0.35, green: 0.15, blue: 0.82)            // #5926D1 — Secondary accent
        static let violetGlow = Color(red: 0.60, green: 0.38, blue: 1.00)            // #9960FF — Glow/highlight
        static let platinumWhite = Color(red: 0.92, green: 0.92, blue: 0.96)         // #EBEBF5 — Primary text
        static let silverMist = Color(red: 0.65, green: 0.65, blue: 0.73)            // #A6A6BA — Secondary text
        static let successEmerald = Color(red: 0.18, green: 0.84, blue: 0.44)        // #2ED770
        static let warningAmber = Color(red: 1.00, green: 0.78, blue: 0.20)          // #FFC733
        static let dangerCrimson = Color(red: 0.98, green: 0.26, blue: 0.36)         // #FA425C
        static let cardBorder = Color.white.opacity(0.06)
        static let shimmerHighlight = Color.white.opacity(0.12)
    }
    
    // MARK: - Gradients
    struct Gradients {
        // Main accent gradient — Violet to Deep Purple
        static let accentPrimary = LinearGradient(
            gradient: Gradient(colors: [Colors.violetElectric, Colors.violetDeep]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Glassmorphic card background
        static let glassCard = LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.06),
                Color.white.opacity(0.02)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Deep obsidian fade for backgrounds
        static let backgroundFade = LinearGradient(
            gradient: Gradient(colors: [
                Colors.obsidianDeep,
                Colors.obsidianMid,
                Colors.obsidianDeep
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        
        // Glowing violet overlay
        static let violetGlowOverlay = RadialGradient(
            gradient: Gradient(colors: [
                Colors.violetElectric.opacity(0.15),
                Color.clear
            ]),
            center: .topTrailing,
            startRadius: 80,
            endRadius: 400
        )
        
        // Shimmer gradient for loading states
        static let shimmer = LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.0),
                Color.white.opacity(0.08),
                Color.white.opacity(0.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Typography
    struct Typography {
        static func largeTitle(_ weight: Font.Weight = .bold) -> Font {
            .system(size: 34, weight: weight, design: .rounded)
        }
        
        static func title(_ weight: Font.Weight = .semibold) -> Font {
            .system(size: 22, weight: weight, design: .rounded)
        }
        
        static func headline(_ weight: Font.Weight = .medium) -> Font {
            .system(size: 17, weight: weight, design: .rounded)
        }
        
        static func body(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 15, weight: weight, design: .rounded)
        }
        
        static func caption(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 12, weight: weight, design: .rounded)
        }
        
        static func monoDigit(_ weight: Font.Weight = .medium) -> Font {
            .system(size: 13, weight: weight, design: .monospaced)
        }
    }
    
    // MARK: - Spacing & Layout
    struct Layout {
        static let screenPadding: CGFloat = 20
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 20
        static let buttonCornerRadius: CGFloat = 14
        static let pillCornerRadius: CGFloat = 24
        static let iconSizeSmall: CGFloat = 20
        static let iconSizeMedium: CGFloat = 28
        static let iconSizeLarge: CGFloat = 44
        static let tabBarHeight: CGFloat = 88
    }
    
    // MARK: - Shadows & Effects
    struct Effects {
        // FIX: Color.violetElectric now resolves because of the Color extension above
        static func violetGlow(radius: CGFloat = 20) -> some View {
            Color.violetElectric
                .opacity(0.3)
                .blur(radius: radius)
        }
        
        static let cardShadow = Color.black.opacity(0.4)
        static let elevatedShadow = Color.black.opacity(0.6)
    }
}

// MARK: - Glassmorphic Card Modifier
struct GlassmorphicCard: ViewModifier {
    var cornerRadius: CGFloat = LuxuryTheme.Layout.cardCornerRadius
    var borderOpacity: Double = 0.08
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    LuxuryTheme.Colors.obsidianElevated
                    LuxuryTheme.Gradients.glassCard
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(borderOpacity),
                                Color.white.opacity(0.02)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: LuxuryTheme.Effects.cardShadow, radius: 12, x: 0, y: 6)
    }
}

// MARK: - Neon Accent Button Style
struct NeonAccentButtonStyle: ButtonStyle {
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LuxuryTheme.Typography.headline(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                ZStack {
                    if !isDisabled {
                        LuxuryTheme.Gradients.accentPrimary
                    } else {
                        LuxuryTheme.Colors.obsidianElevated
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: LuxuryTheme.Layout.buttonCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LuxuryTheme.Layout.buttonCornerRadius, style: .continuous)
                    .stroke(LuxuryTheme.Colors.violetElectric.opacity(isDisabled ? 0.2 : 0.5), lineWidth: 1)
            )
            .shadow(color: isDisabled ? .clear : LuxuryTheme.Colors.violetElectric.opacity(0.35), radius: 16, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Secondary Pill Button Style
struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LuxuryTheme.Typography.caption(.semibold))
            .foregroundColor(LuxuryTheme.Colors.violetElectric)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(LuxuryTheme.Colors.violetElectric.opacity(0.12))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(LuxuryTheme.Colors.violetElectric.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Shimmer Loading Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = -1.0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LuxuryTheme.Gradients.shimmer
                    .rotationEffect(.degrees(0))
                    .offset(x: phase * 300)
                    .animation(
                        Animation.linear(duration: 1.8).repeatForever(autoreverses: false),
                        value: phase
                    )
            )
            .onAppear { phase = 1.0 }
    }
}

// MARK: - Breathing Glow Animation
struct BreathingGlowModifier: ViewModifier {
    @State private var isGlowing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: LuxuryTheme.Colors.violetElectric.opacity(isGlowing ? 0.5 : 0.15),
                radius: isGlowing ? 24 : 8
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    func glassmorphicCard(cornerRadius: CGFloat = LuxuryTheme.Layout.cardCornerRadius, borderOpacity: Double = 0.08) -> some View {
        modifier(GlassmorphicCard(cornerRadius: cornerRadius, borderOpacity: borderOpacity))
    }
    
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
    
    func breathingGlow() -> some View {
        modifier(BreathingGlowModifier())
    }
    
    func neonAccentButtonStyle(disabled: Bool = false) -> some View {
        self.buttonStyle(NeonAccentButtonStyle(isDisabled: disabled))
    }
    
    func pillButtonStyle() -> some View {
        self.buttonStyle(PillButtonStyle())
    }
}

// MARK: - Custom Tab Bar View Builder
struct LuxuryTabItem {
    let icon: String
    let title: LocalizedStringKey
    let tag: Int
}

struct LuxuryTabBar: View {
    let items: [LuxuryTabItem]
    @Binding var selection: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { index in
                let item = items[index]
                let isSelected = selection == item.tag
                
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        selection = item.tag
                    }
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            if isSelected {
                                Circle()
                                    .fill(LuxuryTheme.Colors.violetElectric.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                    .blur(radius: 4)
                            }
                            
                            Image(systemName: isSelected ? item.icon + ".fill" : item.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(isSelected ? LuxuryTheme.Colors.violetElectric : LuxuryTheme.Colors.silverMist)
                                .frame(height: 22)
                        }
                        
                        Text(item.title)
                            .font(LuxuryTheme.Typography.caption(isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? LuxuryTheme.Colors.violetElectric : LuxuryTheme.Colors.silverMist)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(
            ZStack {
                LuxuryTheme.Colors.obsidianDeep.opacity(0.95)
                
                // Subtle top border glow
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                LuxuryTheme.Colors.violetElectric.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 1)
            }
            .edgesIgnoringSafeArea(.bottom)
        )
    }
}
