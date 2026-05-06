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
    
    @Published var autoCheckForUpdates: Bool {
        didSet {
            UserDefaults.standard.set(autoCheckForUpdates, forKey: "autoCheckForUpdates")
        }
    }
    
    @Published var themeMode: ThemeMode {
        didSet {
            UserDefaults.standard.set(themeMode.rawValue, forKey: "themeMode")
            applyTheme()
        }
    }

    // MARK: - Feature toggles
    @Published var moveToTopAfterPaste: Bool {
        didSet { UserDefaults.standard.set(moveToTopAfterPaste, forKey: "feature_moveToTopAfterPaste") }
    }
    @Published var enableJSONToTable: Bool {
        didSet { UserDefaults.standard.set(enableJSONToTable, forKey: "feature_enableJSONToTable") }
    }
    @Published var enableJSONToExcel: Bool {
        didSet { UserDefaults.standard.set(enableJSONToExcel, forKey: "feature_enableJSONToExcel") }
    }
    @Published var enableTableToJSON: Bool {
        didSet { UserDefaults.standard.set(enableTableToJSON, forKey: "feature_enableTableToJSON") }
    }
    @Published var enableOpenURLInBrowser: Bool {
        didSet { UserDefaults.standard.set(enableOpenURLInBrowser, forKey: "feature_enableOpenURLInBrowser") }
    }
    @Published var enableTimestampConvert: Bool {
        didSet { UserDefaults.standard.set(enableTimestampConvert, forKey: "feature_enableTimestampConvert") }
    }
    @Published var enableSearch: Bool {
        didSet { UserDefaults.standard.set(enableSearch, forKey: "feature_enableSearch") }
    }
    @Published var enableDragAndDrop: Bool {
        didSet { UserDefaults.standard.set(enableDragAndDrop, forKey: "feature_enableDragAndDrop") }
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
        
        // Auto check for updates (default: true)
        if UserDefaults.standard.object(forKey: "autoCheckForUpdates") == nil {
            self.autoCheckForUpdates = true
        } else {
            self.autoCheckForUpdates = UserDefaults.standard.bool(forKey: "autoCheckForUpdates")
        }
        
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

        // Feature toggles — mặc định bật để giữ behavior cũ.
        // Dùng object(forKey:) để phân biệt "chưa set" vs "đã set false".
        func loadBool(_ key: String, default defaultValue: Bool) -> Bool {
            if UserDefaults.standard.object(forKey: key) == nil { return defaultValue }
            return UserDefaults.standard.bool(forKey: key)
        }
        self.moveToTopAfterPaste = loadBool("feature_moveToTopAfterPaste", default: true)
        self.enableJSONToTable = loadBool("feature_enableJSONToTable", default: true)
        self.enableJSONToExcel = loadBool("feature_enableJSONToExcel", default: true)
        self.enableTableToJSON = loadBool("feature_enableTableToJSON", default: true)
        self.enableOpenURLInBrowser = loadBool("feature_enableOpenURLInBrowser", default: true)
        self.enableTimestampConvert = loadBool("feature_enableTimestampConvert", default: true)
        self.enableSearch = loadBool("feature_enableSearch", default: true)
        self.enableDragAndDrop = loadBool("feature_enableDragAndDrop", default: true)
    }
    
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        AXIsProcessTrustedWithOptions(options)
    }
    
    func saveSettings() {
        UserDefaults.standard.synchronize()
    }
} 