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
        "shortcut": [.english: "Shortcut", .vietnamese: "Phím tắt"],
        "open_clipboard_history": [.english: "Open clipboard history:", .vietnamese: "Mở lịch sử clipboard:"],
        "language": [.english: "Language", .vietnamese: "Ngôn ngữ"],
        "appearance": [.english: "Appearance", .vietnamese: "Giao diện"],
        "theme": [.english: "Theme:", .vietnamese: "Chủ đề:"],
        "theme_system": [.english: "System", .vietnamese: "Hệ thống"],
        "theme_light": [.english: "Light", .vietnamese: "Sáng"],
        "theme_dark": [.english: "Dark", .vietnamese: "Tối"],
        "history": [.english: "History", .vietnamese: "Lịch sử"],
        "save_and_close": [.english: "Save & Close", .vietnamese: "Lưu & Đóng"],
        "buy_coffee": [.english: "Buy me a coffee", .vietnamese: "Mua cho tôi một ly cà phê"],
        "contact": [.english: "Contact & Feedback", .vietnamese: "Liên hệ & góp ý"],
        "quit": [.english: "Quit", .vietnamese: "Thoát"],
        "check_for_updates": [.english: "Check for Updates", .vietnamese: "Kiểm tra cập nhật"],
        "update_available": [.english: "Update Available", .vietnamese: "Có bản cập nhật mới"],
        "update_new_version": [.english: "Version %@ is available (current: %@)", .vietnamese: "Phiên bản %@ đã có (hiện tại: %@)"],
        "update_download": [.english: "Download & Install", .vietnamese: "Tải & Cài đặt"],
        "update_later": [.english: "Later", .vietnamese: "Để sau"],
        "update_no_update": [.english: "No Update Available", .vietnamese: "Không có bản cập nhật"],
        "update_current_version": [.english: "You are using the latest version (%@)", .vietnamese: "Bạn đang dùng phiên bản mới nhất (%@)"],
        "update_ready": [.english: "Update Ready", .vietnamese: "Sẵn sàng cập nhật"],
        "update_restart_message": [.english: "The app needs to restart to complete the update. Your permissions will be preserved.", .vietnamese: "Ứng dụng cần khởi động lại để hoàn tất cập nhật. Quyền truy cập sẽ được giữ nguyên."],
        "update_restart_now": [.english: "Restart Now", .vietnamese: "Khởi động lại ngay"],
        "update_checking": [.english: "Checking for updates...", .vietnamese: "Đang kiểm tra cập nhật..."],
        "update_downloading": [.english: "Downloading update...", .vietnamese: "Đang tải bản cập nhật..."],
        "update_version": [.english: "Version", .vietnamese: "Phiên bản"],
        "update_auto_check": [.english: "Check for updates on launch", .vietnamese: "Tự động kiểm tra khi khởi động"],
        // Tabs
        "tab_general": [.english: "General", .vietnamese: "Chung"],
        "tab_features": [.english: "Features", .vietnamese: "Tính năng"],
        // Feature toggles
        "feature_move_to_top": [.english: "Move item to top after paste", .vietnamese: "Đưa mục lên đầu sau khi dán"],
        "feature_json_to_table": [.english: "Convert JSON to table view", .vietnamese: "Chuyển JSON sang dạng bảng"],
        "feature_json_to_excel": [.english: "Convert JSON to Excel (.xlsx)", .vietnamese: "Chuyển JSON sang Excel"],
        "feature_table_to_json": [.english: "Convert table to JSON", .vietnamese: "Chuyển dạng bảng sang JSON"],
        "feature_open_url": [.english: "Open URL in browser", .vietnamese: "Mở URL trong trình duyệt"],
        "feature_timestamp": [.english: "Convert timestamp ↔ datetime", .vietnamese: "Chuyển đổi timestamp"],
        "feature_search": [.english: "Search by keyword", .vietnamese: "Tìm kiếm theo từ khóa"],
        "feature_drag_drop": [.english: "Drag-and-drop file", .vietnamese: "Kéo thả file"]
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