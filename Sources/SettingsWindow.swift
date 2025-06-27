import SwiftUI
import AppKit

class SettingsWindow {
    static let shared = SettingsWindow()
    private var window: NSWindow?
    
    private init() {}
    
    func show() {
        // Nếu cửa sổ đã tồn tại, chỉ cần hiển thị nó
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Tạo cửa sổ mới
        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = Localization.shared.localizedString("settings")
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        
        // Lưu tham chiếu đến cửa sổ
        self.window = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        window?.close()
    }
} 