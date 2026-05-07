import SwiftUI
import AppKit

class SettingsWindow {
    static let shared = SettingsWindow()
    private var window: NSWindow?

    private init() {
        NotificationCenter.default.addObserver(
            forName: .themeDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.window?.backgroundColor = NSColor(Settings.shared.themedBackground)
        }
    }
    
    func show() {
        // Nếu cửa sổ đã tồn tại, chỉ cần hiển thị nó (cập nhật màu theme nếu user vừa đổi)
        if let existingWindow = window {
            existingWindow.backgroundColor = NSColor(Settings.shared.themedBackground)
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            NotificationCenter.default.post(name: .settingsWindowDidShow, object: existingWindow)
            return
        }

        // Tạo cửa sổ mới
        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)

        // contentRect phải khớp với SwiftUI body's .frame(580x500) — sidebar + content area
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 580, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = Localization.shared.localizedString("settings")
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(Settings.shared.themedBackground)

        // Lưu tham chiếu đến cửa sổ
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NotificationCenter.default.post(name: .settingsWindowDidShow, object: window)
    }
    
    func close() {
        window?.close()
    }
} 