import Cocoa
import SwiftUI
import Carbon
import HotKey

@main
struct ClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var virtualWindow: NSPanel?
    var eventMonitor: Any?
    var hotKey: HotKey?
    private var clipboardManager = ClipboardManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ẩn cửa sổ chính của ứng dụng
        if let window = NSApplication.shared.windows.first {
            window.setFrame(NSRect(x: 0, y: 0, width: 0, height: 0), display: false)
            window.orderOut(nil)
        }
        NSApp.setActivationPolicy(.accessory)
        
        print("DEBUG: Ứng dụng đang khởi động...")
        
        // Kiểm tra quyền truy cập trợ năng
        let hasAccessibility = AXIsProcessTrusted()
        print("DEBUG: Trạng thái quyền truy cập: \(hasAccessibility)")
        
        if !hasAccessibility {
            // Hiển thị popup yêu cầu quyền
            print("DEBUG: Không có quyền Accessibility, hiển thị popup...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showAccessibilityPermissionWindow()
            }
        }
        
        // Áp dụng theme đã lưu
        Settings.shared.applyTheme()
        
        // Khởi tạo clipboard manager
        clipboardManager.startMonitoring()
        
        // Tạo menu trên thanh trạng thái
        setupStatusItem()
        
        // Thiết lập menu
        setupMenu()
        
        // Thiết lập phím tắt
        setupHotKey()
        
        // Lưu phím tắt mặc định
        if UserDefaults.standard.string(forKey: "shortcutKey") == nil {
            UserDefaults.standard.set("Control + V", forKey: "shortcutKey")
        }
        
        // Đăng ký lắng nghe sự kiện thay đổi ngôn ngữ và phím tắt
        NotificationCenter.default.addObserver(self, selector: #selector(languageChanged), name: .languageChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shortcutChanged), name: .shortcutChanged, object: nil)
        
        // Tự động kiểm tra cập nhật (silent)
        if Settings.shared.autoCheckForUpdates {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                UpdateManager.shared.checkForUpdates(silent: true)
            }
        }
        
        print("DEBUG: Ứng dụng đã khởi động xong")
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard")
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent {
            if event.type == .rightMouseUp {
                let menu = statusItem?.menu
                statusItem?.menu = menu
                menu?.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
            } else {
                showClipboardHistoryAtCursor()
            }
        }
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = true
        
        let settingsItem = NSMenuItem(title: Localization.shared.localizedString("settings"), action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let buyMeACoffeeItem = NSMenuItem(title: Localization.shared.localizedString("buy_coffee"), action: #selector(showBuyMeACoffee), keyEquivalent: "")
        buyMeACoffeeItem.target = self
        menu.addItem(buyMeACoffeeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let contactItem = NSMenuItem(title: Localization.shared.localizedString("contact"), action: #selector(showContact), keyEquivalent: "")
        contactItem.target = self
        menu.addItem(contactItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let updateItem = NSMenuItem(title: Localization.shared.localizedString("check_for_updates"), action: #selector(checkForUpdates), keyEquivalent: "u")
        updateItem.target = self
        menu.addItem(updateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: Localization.shared.localizedString("quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func languageChanged() {
        setupMenu() // Cập nhật lại menu khi ngôn ngữ thay đổi
    }
    
    @objc private func shortcutChanged() {
        setupHotKey() // Cập nhật lại phím tắt khi có thay đổi
    }
    
    
    func setupHotKey() {
        // Hủy phím tắt cũ nếu có
        hotKey = nil
        
        // Lấy phím tắt từ Settings
        let shortcutKey = Settings.shared.shortcutKey
        print("DEBUG: Đang thiết lập phím tắt: \(shortcutKey)")
        
        // Phân tích phím tắt
        var modifiers: NSEvent.ModifierFlags = []
        var key = ""
        
        if shortcutKey.contains("⌘") { modifiers.insert(.command) }
        if shortcutKey.contains("⌥") { modifiers.insert(.option) }
        if shortcutKey.contains("⌃") { modifiers.insert(.control) }
        if shortcutKey.contains("⇧") { modifiers.insert(.shift) }
        
        // Lấy ký tự cuối cùng làm key
        key = String(shortcutKey.last ?? "V")
        
        print("DEBUG: Modifiers: \(modifiers), Key: \(key)")
        
        // Chuyển đổi key
        if let keyCode = keyToKeyCode(key) {
            print("DEBUG: Đã tìm thấy keyCode: \(keyCode) cho key: \(key)")
            if let key = Key(carbonKeyCode: UInt32(keyCode)) {
                hotKey = HotKey(key: key, modifiers: modifiers)
                
                hotKey?.keyDownHandler = { [weak self] in
                    print("DEBUG: Phím tắt được kích hoạt")
                    DispatchQueue.main.async {
                        self?.showClipboardHistoryAtCursor()
                    }
                }
            }
        } else {
            print("DEBUG: Không tìm thấy keyCode cho key: \(key)")
        }
    }
    
    func keyToKeyCode(_ key: String) -> UInt16? {
        let keyMap: [String: UInt16] = [
            "A": 0x00, "S": 0x01, "D": 0x02, "F": 0x03, "H": 0x04,
            "G": 0x05, "Z": 0x06, "X": 0x07, "C": 0x08, "V": 0x09,
            "B": 0x0B, "Q": 0x0C, "W": 0x0D, "E": 0x0E, "R": 0x0F,
            "Y": 0x10, "T": 0x11, "1": 0x12, "2": 0x13, "3": 0x14,
            "4": 0x15, "6": 0x16, "5": 0x17, "=": 0x18, "9": 0x19,
            "7": 0x1A, "-": 0x1B, "8": 0x1C, "0": 0x1D, "]": 0x1E,
            "O": 0x1F, "U": 0x20, "[": 0x21, "I": 0x22, "P": 0x23,
            "L": 0x25, "J": 0x26, "'": 0x27, "K": 0x28, ";": 0x29,
            "\\": 0x2A, ",": 0x2B, "/": 0x2C, "N": 0x2D, "M": 0x2E,
            ".": 0x2F
        ]
        return keyMap[key]
    }
    
    @objc func openSettings() {
        print("DEBUG: Đang mở cửa sổ cài đặt...")
        SettingsWindow.shared.show()
        print("DEBUG: Cửa sổ cài đặt đã được mở")
    }
    
    @objc func showBuyMeACoffee() {
        print("DEBUG: Đang mở cửa sổ Buy me a coffee...")
        BuyMeCoffeeWindow.shared.show()
    }
    
    @objc func showContact() {
        print("DEBUG: Đang mở cửa sổ Liên hệ & góp ý...")
        ContactWindow.shared.show()
    }
    
    @objc func checkForUpdates() {
        UpdateManager.shared.checkForUpdates()
    }
    
    @objc func openFacebook() {
        if let url = URL(string: "https://www.facebook.com/xuanhoa493/") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func createPanel() -> NSPanel {
        let popoverSize = NSSize(width: 300, height: 450)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: popoverSize.width, height: popoverSize.height),
            styleMask: [.titled, .resizable, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Clipboard"
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .clear
        panel.isMovableByWindowBackground = false
        panel.titlebarAppearsTransparent = false
        panel.standardWindowButton(.closeButton)?.isHidden = false
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        return panel
    }
    
    @objc func showClipboardHistoryAtCursor() {
        // Đóng cửa sổ cũ + cleanup monitor
        if let window = virtualWindow, window.isVisible {
            window.close()
        }
        removeEventMonitor()
        
        let mouseLocation = NSEvent.mouseLocation
        let popoverSize = NSSize(width: 300, height: 450)

        // Mặc định: cửa sổ nằm ngay bên dưới và bên phải con trỏ
        // (NSWindow origin = góc bottom-left → top-left = cursor)
        var popoverOriginX = mouseLocation.x
        var popoverOriginY = mouseLocation.y - popoverSize.height

        // Giới hạn trong màn hình chứa con trỏ (dùng visibleFrame để tránh đè menu bar / dock)
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main
        if let visibleFrame = screen?.visibleFrame {
            if popoverOriginX + popoverSize.width > visibleFrame.maxX {
                popoverOriginX = visibleFrame.maxX - popoverSize.width
            }
            if popoverOriginX < visibleFrame.minX {
                popoverOriginX = visibleFrame.minX
            }
            if popoverOriginY < visibleFrame.minY {
                popoverOriginY = visibleFrame.minY
            }
            if popoverOriginY + popoverSize.height > visibleFrame.maxY {
                popoverOriginY = visibleFrame.maxY - popoverSize.height
            }
        }
        
        // Tái sử dụng panel hoặc tạo mới
        let panel = virtualWindow ?? createPanel()
        virtualWindow = panel
        
        panel.setFrame(
            NSRect(x: popoverOriginX, y: popoverOriginY, width: popoverSize.width, height: popoverSize.height),
            display: false
        )
        
        // Refresh view
        func refreshPanelView() {
            let items = self.clipboardManager.getHistory() ?? []
            let clipboardView = ClipboardHistoryView(items: items, onItemSelected: { [weak self] item in
                self?.handleItemSelected(item)
                panel.close()
            }, onClearAll: { [weak self] in
                self?.clipboardManager.clearHistory()
                refreshPanelView()
            }, onCopyOnly: { item in
                panel.close()
            }, onTogglePin: { [weak self] item in
                self?.clipboardManager.togglePin(item)
                refreshPanelView()
            }, onDeleteItem: { [weak self] item in
                self?.clipboardManager.removeItem(item)
                refreshPanelView()
            }, onToggleBookmark: { [weak self] item in
                self?.clipboardManager.toggleBookmark(item)
                refreshPanelView()
            }, onClearBookmarks: { [weak self] in
                self?.clipboardManager.clearBookmarks()
                refreshPanelView()
            }, onClearByType: { [weak self] type in
                self?.clipboardManager.clearByType(type)
                refreshPanelView()
            })
            
            let hostingView = NSHostingView(rootView: clipboardView)
            hostingView.frame = NSRect(origin: .zero, size: popoverSize)
            panel.contentView = hostingView
        }
        
        refreshPanelView()
        panel.makeKeyAndOrderFront(nil)
        
        let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self, weak panel] event in
            if let panel = panel, panel.isVisible {
                let mouseLocation = NSEvent.mouseLocation
                if !panel.frame.contains(mouseLocation) {
                    panel.close()
                    self?.removeEventMonitor()
                }
            }
        }
        eventMonitor = monitor
    }
    
    private func handleItemSelected(_ item: ClipboardItem) {
        // Đóng cửa sổ trước
        removeEventMonitor()
        if let window = virtualWindow {
            window.close()
        }
        
        // Đợi window đóng và app ban đầu được focus trở lại
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // Ignore clipboard change do paste gây ra
            self.clipboardManager.ignoreNextChange()
            // Paste nội dung
            item.paste()
            
            // Move item lên đầu sau khi paste xong (nếu user bật)
            if Settings.shared.moveToTopAfterPaste {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.clipboardManager.moveToTop(item)
                }
            }
        }
    }
    
    func showAccessibilityPermissionWindow() {
        AccessibilityPermissionWindow.shared.show {
            // Callback khi quyền được cấp
            print("DEBUG: Permission granted callback")
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Đóng tất cả các cửa sổ khi ứng dụng kết thúc
        BuyMeCoffeeWindow.shared.close()
        ContactWindow.shared.close()
        AccessibilityPermissionWindow.shared.close()
    }
    

} 