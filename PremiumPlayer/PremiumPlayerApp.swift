import SwiftUI

// MARK: - PremiumPlayerApp
// Entry point with full-screen player overlay, splash branding,
// and premium dark theme initialization.

@main
struct PremiumPlayerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            RootContainerView()
        }
    }
}

// MARK: - Root Container
// Manages the full-screen player overlay state on top of the tab bar.
struct RootContainerView: View {
    @StateObject private var playerEngine = AudioPlayerEngine.shared
    @State private var showSplash: Bool = true
    
    var body: some View {
        ZStack {
            MainTabView()
            
            // Full-screen player presentation
            if playerEngine.isPlayerVisible {
                PremiumAudioPlayerView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
            
            // Splash screen on first launch
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(2)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                showSplash = false
                            }
                        }
                    }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Splash Screen
struct SplashScreenView: View {
    @State private var scale = 0.8
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            LuxuryTheme.Colors.obsidianDeep
                .edgesIgnoringSafeArea(.all)
            
            // Animated background
            LuxuryTheme.Gradients.violetGlowOverlay
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Spacer()
                
                // App icon
                ZStack {
                    Circle()
                        .fill(LuxuryTheme.Gradients.accentPrimary)
                        .frame(width: 100, height: 100)
                        .shadow(color: LuxuryTheme.Colors.violetElectric.opacity(0.5), radius: 30, x: 0, y: 10)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                }
                
                VStack(spacing: 6) {
                    Text("PremiumPlayer")
                        .font(LuxuryTheme.Typography.title(.bold))
                        .foregroundColor(LuxuryTheme.Colors.platinumWhite)
                    
                    Text(LocalizedStrings.splashTagline)
                        .font(LuxuryTheme.Typography.body())
                        .foregroundColor(LuxuryTheme.Colors.violetGlow)
                        .opacity(0.8)
                }
                .opacity(opacity)
                
                Spacer()
                
                // Developer credit at bottom of splash
                VStack(spacing: 2) {
                    Text(LocalizedStrings.developedBy)
                        .font(LuxuryTheme.Typography.caption())
                        .foregroundColor(LuxuryTheme.Colors.silverMist)
                    
                    Text("@c0derz / Mohamed Annati")
                        .font(LuxuryTheme.Typography.caption(.semibold))
                        .foregroundColor(LuxuryTheme.Colors.violetElectric)
                }
                .padding(.bottom, 24)
                .opacity(opacity)
            }
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Audio Session for background playback
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("[AppDelegate] Audio session setup failed: \(error)")
        }
        return true
    }
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        return config
    }
}