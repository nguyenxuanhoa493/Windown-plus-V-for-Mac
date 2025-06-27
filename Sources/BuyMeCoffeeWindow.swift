import AppKit

class BuyMeCoffeeWindow {
    static let shared = BuyMeCoffeeWindow()
    private var window: NSWindow?
    
    private init() {}
    
    func show() {
        // Nếu cửa sổ đã tồn tại, chỉ cần hiển thị nó
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Load ảnh từ bundle
        let bundle = Bundle.main
        let imagePath = bundle.path(forResource: "cafe", ofType: "jpg")
        let image = imagePath != nil ? NSImage(contentsOfFile: imagePath!) : nil
        
        // Tính toán kích thước cửa sổ dựa trên kích thước ảnh
        let imageSize = image?.size ?? NSSize(width: 400, height: 300)
        let windowSize = NSSize(
            width: imageSize.width + 40,  // Thêm padding
            height: imageSize.height + 40
        )
        
        // Tạo cửa sổ mới
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Buy me a coffee"
        window.center()
        window.level = .floating
        window.isReleasedWhenClosed = false
        
        // Tạo view chứa
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height))
        window.contentView = containerView
        
        // Tạo ImageView
        let imageView = NSImageView(frame: NSRect(x: 20, y: 20, width: imageSize.width, height: imageSize.height))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        containerView.addSubview(imageView)
        
        // Lưu reference và hiển thị cửa sổ
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        window?.close()
    }
} 