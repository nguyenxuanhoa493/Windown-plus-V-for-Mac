import Foundation
import SwiftUI

enum ThemeMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "Hệ thống"
        case .light: return "Sáng"
        case .dark: return "Tối"
        }
    }
}

extension Notification.Name {
    static let shortcutChanged = Notification.Name("shortcutChanged")
}

class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var isAccessibilityEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAccessibilityEnabled, forKey: "isAccessibilityEnabled")
        }
    }
    
    @Published var maxHistoryItems: Int {
        didSet {
            UserDefaults.standard.set(maxHistoryItems, forKey: "maxHistoryItems")
        }
    }
    
    @Published var shortcutKey: String {
        didSet {
            UserDefaults.standard.set(shortcutKey, forKey: "shortcutKey")
            // Cập nhật shortcutString khi shortcutKey thay đổi
            shortcutString = shortcutKey
            // Thông báo để AppDelegate cập nhật phím tắt
            NotificationCenter.default.post(name: .shortcutChanged, object: nil)
        }
    }
    
    @Published var shortcutString: String? {
        didSet {
            UserDefaults.standard.set(shortcutString, forKey: "shortcutString")
        }
    }
    
    @Published var shortcutKeyCode: UInt32 {
        didSet {
            UserDefaults.standard.set(shortcutKeyCode, forKey: "shortcutKeyCode")
        }
    }
    
    @Published var shortcutModifiers: NSEvent.ModifierFlags {
        didSet {
            UserDefaults.standard.set(shortcutModifiers.rawValue, forKey: "shortcutModifiers")
        }
    }
    
    @Published var themeMode: ThemeMode {
        didSet {
            UserDefaults.standard.set(themeMode.rawValue, forKey: "themeMode")
            applyTheme()
        }
    }
    
    func applyTheme() {
        switch themeMode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
    
    init() {
        // Khởi tạo các thuộc tính cơ bản
        self.isAccessibilityEnabled = UserDefaults.standard.bool(forKey: "isAccessibilityEnabled")
        self.shortcutKeyCode = UInt32(UserDefaults.standard.integer(forKey: "shortcutKeyCode"))
        self.shortcutModifiers = NSEvent.ModifierFlags(rawValue: UInt(UserDefaults.standard.integer(forKey: "shortcutModifiers")))
        
        // Khởi tạo maxHistoryItems với giá trị mặc định
        let savedMaxHistoryItems = UserDefaults.standard.integer(forKey: "maxHistoryItems")
        self.maxHistoryItems = savedMaxHistoryItems == 0 ? 50 : savedMaxHistoryItems
        
        // Khởi tạo themeMode
        if let savedTheme = UserDefaults.standard.string(forKey: "themeMode"),
           let mode = ThemeMode(rawValue: savedTheme) {
            self.themeMode = mode
        } else {
            self.themeMode = .system
        }
        
        // Khởi tạo shortcutKey và shortcutString
        self.shortcutKey = UserDefaults.standard.string(forKey: "shortcutKey") ?? "⌘V"
        if let savedString = UserDefaults.standard.string(forKey: "shortcutString") {
            self.shortcutString = savedString
        } else {
            self.shortcutString = "⌃V" // Mặc định Control + V
        }
    }
    
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        AXIsProcessTrustedWithOptions(options)
    }
    
    func saveSettings() {
        UserDefaults.standard.synchronize()
    }
} 