import Foundation
import SwiftUI

enum Language: String {
    case english = "en"
    case vietnamese = "vi"
}

class Localization: ObservableObject {
    static let shared = Localization()
    
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "currentLanguage")
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }
    
    private var translations: [String: [Language: String]] = [
        "settings": [.english: "Settings", .vietnamese: "Cài đặt"],
        "access_permissions": [.english: "Access Permissions", .vietnamese: "Quyền truy cập"],
        "accessibility_status": [.english: "Accessibility Status", .vietnamese: "Trạng thái quyền truy cập"],
        "allow_access": [.english: "Allow Access", .vietnamese: "Cho phép truy cập"],
        "history_settings": [.english: "History Settings", .vietnamese: "Cài đặt lịch sử"],
        "max_history_items": [.english: "Maximum History Items", .vietnamese: "Số lượng mục tối đa"],
        "shortcut_settings": [.english: "Shortcut Settings", .vietnamese: "Cài đặt phím tắt"],
        "current_shortcut": [.english: "Current Shortcut", .vietnamese: "Phím tắt hiện tại"],
        "recording": [.english: "Recording...", .vietnamese: "Đang ghi..."],
        "change": [.english: "Change", .vietnamese: "Thay đổi"],
        "language_settings": [.english: "Language Settings", .vietnamese: "Cài đặt ngôn ngữ"],
        "select_language": [.english: "Select Language", .vietnamese: "Chọn ngôn ngữ"],
        "save_and_close": [.english: "Save & Close", .vietnamese: "Lưu & Đóng"],
        "buy_coffee": [.english: "Buy me a coffee", .vietnamese: "Mua cho tôi một ly cà phê"],
        "contact": [.english: "Contact & Feedback", .vietnamese: "Liên hệ & góp ý"],
        "quit": [.english: "Quit", .vietnamese: "Thoát"]
    ]
    
    init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "currentLanguage"),
           let language = Language(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .english
        }
    }
    
    func localizedString(_ key: String) -> String {
        return translations[key]?[currentLanguage] ?? key
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
} 