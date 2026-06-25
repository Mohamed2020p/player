import SwiftUI
import Foundation

// MARK: - PremiumPlayer Localization Engine
// Supports English (en) and Arabic (ar) with seamless RTL layout adaptation

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case arabic = "ar"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .arabic: return "العربية"
        }
    }
    
    var layoutDirection: LayoutDirection {
        switch self {
        case .english: return .leftToRight
        case .arabic: return .rightToLeft
        }
    }
    
    var localeIdentifier: String {
        rawValue
    }
}

// MARK: - Localized String Provider
// A centralized dictionary-based localization system that supports English and Arabic.
// In a production app, this would use .strings / .stringsdict files, but for a
// headless CI/CD build we inline the translations to avoid resource file complexities.

struct LocalizedStrings {
    
    // MARK: - Tab Bar
    static var tabHome: String { lang == .arabic ? "الرئيسية" : "Home" }
    static var tabDownloads: String { lang == .arabic ? "التنزيلات" : "Downloads" }
    static var tabLibrary: String { lang == .arabic ? "المكتبة" : "Library" }
    static var tabSettings: String { lang == .arabic ? "الإعدادات" : "Settings" }
    
    // MARK: - Home Dashboard
    static var homeTitle: String { lang == .arabic ? "PremiumPlayer" : "PremiumPlayer" }
    static var homeSubtitle: String { lang == .arabic ? "مشغل الموسيقى والفيديو الفاخر" : "Luxury Music & Video Player" }
    static var homePasteURL: String { lang == .arabic ? "ألصق رابط الفيديو هنا..." : "Paste video URL here..." }
    static var homeDownloadNow: String { lang == .arabic ? "بدء التنزيل" : "Start Download" }
    static var homeQualityAudio: String { lang == .arabic ? "صوت MP3" : "Audio MP3" }
    static var homeQualityVideo: String { lang == .arabic ? "فيديو MP4" : "Video MP4" }
    static var homeQuickStats: String { lang == .arabic ? "إحصائيات سريعة" : "Quick Stats" }
    static var homeTotalDownloads: String { lang == .arabic ? "إجمالي التنزيلات" : "Total Downloads" }
    static var homeStorageUsed: String { lang == .arabic ? "المساحة المستخدمة" : "Storage Used" }
    static var homeTrending: String { lang == .arabic ? "الشائع" : "Trending" }
    
    // MARK: - Download Manager
    static var downloadTitle: String { lang == .arabic ? "مدير التنزيلات" : "Download Manager" }
    static var downloadActive: String { lang == .arabic ? "نشط" : "Active" }
    static var downloadQueued: String { lang == .arabic ? "في الانتظار" : "Queued" }
    static var downloadCompleted: String { lang == .arabic ? "مكتمل" : "Completed" }
    static var downloadFailed: String { lang == .arabic ? "فشل" : "Failed" }
    static var downloadExtracting: String { lang == .arabic ? "جاري الاستخراج..." : "Extracting..." }
    static var downloadProgress: String { lang == .arabic ? "التقدم" : "Progress" }
    static var downloadNoActive: String { lang == .arabic ? "لا توجد تنزيلات نشطة" : "No active downloads" }
    static var downloadNoActiveDesc: String { lang == .arabic ? "الصق رابط فيديو في الشاشة الرئيسية لبدء التنزيل" : "Paste a video URL on the Home screen to start downloading" }
    static var downloadSpeed: String { lang == .arabic ? "السرعة" : "Speed" }
    static var downloadETA: String { lang == .arabic ? "الوقت المتبقي" : "ETA" }
    static var downloadCancel: String { lang == .arabic ? "إلغاء" : "Cancel" }
    static var downloadRetry: String { lang == .arabic ? "إعادة المحاولة" : "Retry" }
    static var downloadDelete: String { lang == .arabic ? "حذف" : "Delete" }
    static var downloadClearAll: String { lang == .arabic ? "مسح الكل" : "Clear All" }
    
    // MARK: - Local Library
    static var libraryTitle: String { lang == .arabic ? "المكتبة المحلية" : "Local Library" }
    static var libraryAll: String { lang == .arabic ? "الكل" : "All" }
    static var libraryAudio: String { lang == .arabic ? "الصوتيات" : "Audio" }
    static var libraryVideo: String { lang == .arabic ? "الفيديوهات" : "Videos" }
    static var libraryPlaylists: String { lang == .arabic ? "قوائم التشغيل" : "Playlists" }
    static var librarySearch: String { lang == .arabic ? "بحث في المكتبة..." : "Search library..." }
    static var libraryEmpty: String { lang == .arabic ? "المكتبة فارغة" : "Library is Empty" }
    static var libraryEmptyDesc: String { lang == .arabic ? "سيتم حفظ الوسائط التي تم تنزيلها هنا" : "Downloaded media will appear here" }
    static var librarySortByDate: String { lang == .arabic ? "حسب التاريخ" : "By Date" }
    static var librarySortByName: String { lang == .arabic ? "حسب الاسم" : "By Name" }
    static var librarySortBySize: String { lang == .arabic ? "حسب الحجم" : "By Size" }
    static var libraryFileSize: String { lang == .arabic ? "الحجم" : "Size" }
    static var libraryDuration: String { lang == .arabic ? "المدة" : "Duration" }
    static var libraryDownloaded: String { lang == .arabic ? "تم التنزيل" : "Downloaded" }
    
    // MARK: - Audio Player
    static var playerNowPlaying: String { lang == .arabic ? "يتم التشغيل الآن" : "Now Playing" }
    static var playerUnknownTitle: String { lang == .arabic ? "عنوان غير معروف" : "Unknown Title" }
    static var playerUnknownArtist: String { lang == .arabic ? "فنان غير معروف" : "Unknown Artist" }
    static var playerQueue: String { lang == .arabic ? "قائمة الانتظار" : "Queue" }
    static var playerUpNext: String { lang == .arabic ? "التالي" : "Up Next" }
    static var playerRepeatOff: String { lang == .arabic ? "بدون تكرار" : "Repeat Off" }
    static var playerRepeatAll: String { lang == .arabic ? "تكرار الكل" : "Repeat All" }
    static var playerRepeatOne: String { lang == .arabic ? "تكرار واحد" : "Repeat One" }
    static var playerShuffle: String { lang == .arabic ? "عشوائي" : "Shuffle" }
    static var playerPlay: String { lang == .arabic ? "تشغيل" : "Play" }
    static var playerPause: String { lang == .arabic ? "إيقاف مؤقت" : "Pause" }
    static var playerNext: String { lang == .arabic ? "التالي" : "Next" }
    static var playerPrevious: String { lang == .arabic ? "السابق" : "Previous" }
    static var playerForward15: String { lang == .arabic ? "تقدم 15 ثانية" : "Forward 15s" }
    static var playerBack15: String { lang == .arabic ? "تراجع 15 ثانية" : "Back 15s" }
    static var playerMiniPlayer: String { lang == .arabic ? "المشغل المصغر" : "Mini Player" }
    static var playerExpand: String { lang == .arabic ? "توسيع" : "Expand" }
    
    // MARK: - Settings
    static var settingsTitle: String { lang == .arabic ? "الإعدادات" : "Settings" }
    static var settingsLanguage: String { lang == .arabic ? "اللغة" : "Language" }
    static var settingsLanguageDesc: String { lang == .arabic ? "اختر لغة التطبيق" : "Choose app language" }
    static var settingsAppearance: String { lang == .arabic ? "المظهر" : "Appearance" }
    static var settingsAppearanceDesc: String { lang == .arabic ? "الوضع الداكن دائماً" : "Always Dark Mode" }
    static var settingsStorage: String { lang == .arabic ? "التخزين" : "Storage" }
    static var settingsCacheSize: String { lang == .arabic ? "حجم ذاكرة التخزين المؤقت" : "Cache Size" }
    static var settingsClearCache: String { lang == .arabic ? "مسح ذاكرة التخزين المؤقت" : "Clear Cache" }
    static var settingsClearDownloads: String { lang == .arabic ? "مسح جميع التنزيلات" : "Clear All Downloads" }
    static var settingsDownloadsLocation: String { lang == .arabic ? "موقع التنزيلات" : "Downloads Location" }
    static var settingsAbout: String { lang == .arabic ? "حول التطبيق" : "About" }
    static var settingsVersion: String { lang == .arabic ? "الإصدار" : "Version" }
    static var settingsDeveloper: String { lang == .arabic ? "المطور" : "Developer" }
    static var settingsDeveloperName: String { lang == .arabic ? "محمد عناتي" : "Mohamed Annati" }
    static var settingsDeveloperHandle: String { lang == .arabic ? "@c0derz" : "@c0derz" }
    static var settingsAllRightsReserved: String { lang == .arabic ? "جميع الحقوق محفوظة" : "All rights reserved" }
    static var settingsRateApp: String { lang == .arabic ? "تقييم التطبيق" : "Rate App" }
    static var settingsShareApp: String { lang == .arabic ? "مشاركة التطبيق" : "Share App" }
    static var settingsPrivacyPolicy: String { lang == .arabic ? "سياسة الخصوصية" : "Privacy Policy" }
    static var settingsTermsOfService: String { lang == .arabic ? "شروط الخدمة" : "Terms of Service" }
    static var settingsCacheCleared: String { lang == .arabic ? "تم مسح ذاكرة التخزين المؤقت" : "Cache Cleared" }
    static var settingsDownloadsCleared: String { lang == .arabic ? "تم مسح جميع التنزيلات" : "All Downloads Cleared" }
    static var settingsConfirmClear: String { lang == .arabic ? "تأكيد المسح" : "Confirm Clear" }
    static var settingsConfirmClearDownloadsMessage: String { lang == .arabic ? "هل أنت متأكد من مسح جميع التنزيلات؟ لا يمكن التراجع عن هذا الإجراء." : "Are you sure you want to clear all downloads? This cannot be undone." }
    static var settingsConfirm: String { lang == .arabic ? "تأكيد" : "Confirm" }
    static var settingsCancel: String { lang == .arabic ? "إلغاء" : "Cancel" }
    
    // MARK: - Common
    static var commonOK: String { lang == .arabic ? "موافق" : "OK" }
    static var commonDone: String { lang == .arabic ? "تم" : "Done" }
    static var commonBack: String { lang == .arabic ? "رجوع" : "Back" }
    static var commonLoading: String { lang == .arabic ? "جاري التحميل..." : "Loading..." }
    static var commonError: String { lang == .arabic ? "خطأ" : "Error" }
    static var commonSuccess: String { lang == .arabic ? "نجاح" : "Success" }
    static var commonNoResults: String { lang == .arabic ? "لا توجد نتائج" : "No Results" }
    static var commonRetry: String { lang == .arabic ? "إعادة المحاولة" : "Retry" }
    
    // MARK: - URL Input Validation
    static var urlInvalid: String { lang == .arabic ? "الرابط غير صالح" : "Invalid URL" }
    static var urlInvalidDesc: String { lang == .arabic ? "يرجى إدخال رابط فيديو صالح" : "Please enter a valid video URL" }
    static var urlEmpty: String { lang == .arabic ? "الرجاء إدخال رابط" : "Please enter a URL" }
    
    // MARK: - Splash / Branding
    static var splashTagline: String { lang == .arabic ? "مشغل وسائط فاخر" : "Premium Media Player" }
    static var developedBy: String { lang == .arabic ? "تم التطوير بواسطة" : "Developed by" }
}

// MARK: - Observable Language Manager
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            applyLanguage()
        }
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? AppLanguage.english.rawValue
        currentLanguage = AppLanguage(rawValue: saved) ?? .english
        applyLanguage()
    }
    
    func applyLanguage() {
        UserDefaults.standard.set([currentLanguage.localeIdentifier], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
    var layoutDirection: LayoutDirection {
        currentLanguage.layoutDirection
    }
}

// MARK: - Global language accessor used by LocalizedStrings
var lang: AppLanguage {
    LanguageManager.shared.currentLanguage
}

// MARK: - RTL View Modifier
struct RTLModifier: ViewModifier {
    @ObservedObject private var languageManager = LanguageManager.shared
    
    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, languageManager.layoutDirection)
    }
}

extension View {
    func localizedDirection() -> some View {
        modifier(RTLModifier())
    }
}