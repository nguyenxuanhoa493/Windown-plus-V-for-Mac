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
    var popover: NSPopover?
    var virtualWindow: NSPanel?
    var eventMonitor: Any?
    var hotKey: HotKey?
    private var clipboardManager = ClipboardManager.shared
    private var settingsWindow: NSWindow?
    private var contactWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ẩn cửa sổ chính của ứng dụng
        if let window = NSApplication.shared.windows.first {
            window.setFrame(NSRect(x: 0, y: 0, width: 0, height: 0), display: false)
            window.orderOut(nil)
        }
        NSApp.setActivationPolicy(.accessory)
        
        print("DEBUG: Ứng dụng đang khởi động...")
        
        // Kiểm tra quyền truy cập trợ năng
        print("DEBUG: Trạng thái quyền truy cập: \(AXIsProcessTrusted())")
        
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
        
        print("DEBUG: Ứng dụng đã khởi động xong")
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard")
            button.target = self
            button.action = #selector(statusItemClicked(_:))
        }
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent {
            if event.type == .rightMouseUp {
                statusItem?.menu?.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
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
        
        let quitItem = NSMenuItem(title: Localization.shared.localizedString("quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        
        // Đăng ký lắng nghe sự kiện thay đổi ngôn ngữ
        NotificationCenter.default.addObserver(self, selector: #selector(languageChanged), name: .languageChanged, object: nil)
    }
    
    @objc private func languageChanged() {
        setupMenu() // Cập nhật lại menu khi ngôn ngữ thay đổi
    }
    
    @objc private func shortcutChanged() {
        setupHotKey() // Cập nhật lại phím tắt khi có thay đổi
    }
    
    func setupPopover() {
        popover = NSPopover()
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentSize = NSSize(width: 300, height: 450)
        
        let items = clipboardManager.getHistory() ?? []
        let view = ClipboardHistoryView(items: items, onItemSelected: { item in
            self.handleItemSelected(item)
        }, onClearAll: {
            self.clipboardManager.clearHistory()
            self.setupPopover() // Cập nhật lại popover sau khi xóa toàn bộ
        })
        popover?.contentViewController = NSHostingController(rootView: view)
    }
    
    func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.popover?.close()
        }
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
    
    @objc func openFacebook() {
        if let url = URL(string: "https://www.facebook.com/xuanhoa493/") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func showClipboardHistoryAtCursor() {
        print("DEBUG: Đang hiển thị clipboard history tại vị trí con trỏ...")
        
        // Đóng cửa sổ ảo cũ nếu có
        if let window = virtualWindow, window.isVisible {
            window.close()
            return
        }
        
        // Lấy vị trí chuột hiện tại
        let mouseLocation = NSEvent.mouseLocation
        print("DEBUG: Vị trí chuột: \(mouseLocation)")
        
        // Lấy kích thước màn hình
        guard let screen = NSScreen.main else { return }
        let screenHeight = screen.frame.height
        print("DEBUG: Chiều cao màn hình: \(screenHeight)")
        
        // Tính toán vị trí Y (trong macOS, tọa độ Y tính từ dưới lên)
        let cursorY = mouseLocation.y
        print("DEBUG: Vị trí Y của con trỏ: \(cursorY)")
        
        // Kích thước của popover
        let popoverSize = NSSize(width: 300, height: 450)
        
        // Kiểm tra xem có đủ không gian ở dưới con trỏ không
        let displayBelow = cursorY > popoverSize.height + 20
        
        // Hiển thị popover ở phía dưới hoặc phía trên con trỏ
        var popoverOriginY: CGFloat
        
        if displayBelow {
            print("DEBUG: Hiển thị dưới con trỏ")
            popoverOriginY = cursorY
        } else {
            print("DEBUG: Hiển thị trên con trỏ")
            popoverOriginY = cursorY - popoverSize.height
        }
        
        // Điều chỉnh vị trí X để popover hiển thị đúng
        let popoverOriginX = mouseLocation.x - 150 // Canh giữa
        
        print("DEBUG: Vị trí đã tính toán - X: \(popoverOriginX), Y: \(popoverOriginY)")
        
        // Lấy danh sách clipboard
        print("DEBUG: Đang lấy danh sách clipboard...")
        let items = clipboardManager.getHistory() ?? []
        print("DEBUG: Đã lấy được \(items.count) mục từ clipboard")
        
        // Tạo cửa sổ ảo
        let panel = NSPanel(
            contentRect: NSRect(x: popoverOriginX, y: popoverOriginY, width: popoverSize.width, height: popoverSize.height),
            styleMask: [.titled, .resizable, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.title = "Lịch sử Clipboard"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .clear
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = false
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Tạo view
        let clipboardView = ClipboardHistoryView(items: items, onItemSelected: { [weak self] item in
            self?.handleItemSelected(item)
            panel.close()
        }, onClearAll: { [weak self] in
            self?.clipboardManager.clearHistory()
            panel.close()
        })
        
        let hostingView = NSHostingView(rootView: clipboardView)
        hostingView.frame = NSRect(origin: .zero, size: popoverSize)
        
        panel.contentView = hostingView
        panel.makeKeyAndOrderFront(nil)
        
        // Thêm monitor cho sự kiện click chuột bên ngoài
        let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak panel] event in
            if let panel = panel, panel.isVisible {
                let location = event.locationInWindow
                if !panel.frame.contains(location) {
                    panel.close()
                }
            }
        }
        
        // Lưu monitor để có thể remove sau
        eventMonitor = monitor
        virtualWindow = panel
    }
    
    private func handleItemSelected(_ item: ClipboardItem) {
        print("DEBUG: Đã chọn một mục từ lịch sử")
        
        // Copy nội dung vào clipboard
        clipboardManager.copyToClipboard(item)
        
        // Đóng cửa sổ
        if let window = virtualWindow {
            window.close()
        }
        
        // Đợi một chút để clipboard được cập nhật
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Giả lập phím Command + V
            if let source = CGEventSource(stateID: .hidSystemState) {
                let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
                let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
                let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
                let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
                
                vDown?.flags = .maskCommand
                vUp?.flags = .maskCommand
                
                cmdDown?.post(tap: .cghidEventTap)
                vDown?.post(tap: .cghidEventTap)
                vUp?.post(tap: .cghidEventTap)
                cmdUp?.post(tap: .cghidEventTap)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Đóng tất cả các cửa sổ khi ứng dụng kết thúc
        BuyMeCoffeeWindow.shared.close()
        ContactWindow.shared.close()
    }
    
    func showVirtualWindow() {
        // Kích thước của cửa sổ
        let windowSize = NSSize(width: 300, height: 450)
        
        // Tạo cửa sổ ảo
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height),
                           styleMask: [.borderless],
                           backing: .buffered,
                           defer: false)
        
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.hasShadow = true
        
        // Lấy vị trí của menu bar icon
        if let statusItem = statusItem, let button = statusItem.button {
            let buttonFrame = button.window?.frame ?? .zero
            let screenFrame = NSScreen.main?.frame ?? .zero
            
            // Đặt vị trí cửa sổ ngay dưới menu bar icon
            let windowFrame = NSRect(x: buttonFrame.minX - 150 + buttonFrame.width/2,
                                   y: buttonFrame.minY - windowSize.height,
                                   width: windowSize.width,
                                   height: windowSize.height)
            panel.setFrame(windowFrame, display: true)
        }
        
        // Tạo view
        let items = clipboardManager.getHistory() ?? []
        let clipboardView = ClipboardHistoryView(items: items, onItemSelected: { [weak self] item in
            self?.handleItemSelected(item)
            panel.close()
        }, onClearAll: { [weak self] in
            self?.clipboardManager.clearHistory()
            panel.close()
        })
        
        let hostingView = NSHostingView(rootView: clipboardView)
        hostingView.frame = NSRect(origin: .zero, size: windowSize)
        
        panel.contentView = hostingView
        panel.makeKeyAndOrderFront(nil)
        
        // Thêm monitor cho sự kiện click chuột bên ngoài
        let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak panel] event in
            if let panel = panel, panel.isVisible {
                let location = event.locationInWindow
                if !panel.frame.contains(location) {
                    panel.close()
                }
            }
        }
        
        // Lưu monitor để có thể remove sau
        eventMonitor = monitor
        virtualWindow = panel
    }
} 