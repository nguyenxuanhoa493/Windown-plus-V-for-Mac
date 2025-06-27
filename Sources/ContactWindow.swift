import AppKit

class ContactWindow {
    static let shared = ContactWindow()
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
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = Localization.shared.localizedString("contact")
        window.center()
        window.level = .floating
        window.isReleasedWhenClosed = false
        
        // Tạo view chứa
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        window.contentView = containerView
        
        // Tạo StackView
        let stackView = NSStackView(frame: NSRect(x: 20, y: 20, width: 360, height: 260))
        stackView.orientation = .vertical
        stackView.spacing = 10
        stackView.alignment = .leading
        containerView.addSubview(stackView)
        
        // Tạo các label
        let titleLabel = NSTextField(labelWithString: "Thông tin tác giả:")
        titleLabel.font = .boldSystemFont(ofSize: 14)
        stackView.addArrangedSubview(titleLabel)
        
        let nameLabel = NSTextField(labelWithString: "Nguyễn Xuân Hoà")
        stackView.addArrangedSubview(nameLabel)
        
        let facebookLabel = NSTextField(labelWithString: "Facebook: @xuanhoa493")
        stackView.addArrangedSubview(facebookLabel)
        
        let phoneLabel = NSTextField(labelWithString: "Phone: 0962369231")
        stackView.addArrangedSubview(phoneLabel)
        
        let telegramLabel = NSTextField(labelWithString: "Telegram: @xuanhoa493")
        stackView.addArrangedSubview(telegramLabel)
        
        // Tạo button Facebook
        let facebookButton = NSButton(frame: .zero)
        facebookButton.title = "https://www.facebook.com/xuanhoa493/"
        facebookButton.bezelStyle = .inline
        facebookButton.target = self
        facebookButton.action = #selector(openFacebook)
        stackView.addArrangedSubview(facebookButton)
        
        // Lưu reference và hiển thị cửa sổ
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        window?.close()
    }
    
    @objc private func openFacebook() {
        if let url = URL(string: "https://www.facebook.com/xuanhoa493/") {
            NSWorkspace.shared.open(url)
        }
    }
} 