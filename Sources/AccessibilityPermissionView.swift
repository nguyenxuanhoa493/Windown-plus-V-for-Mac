import SwiftUI
import Cocoa

struct AccessibilityPermissionView: View {
    @Environment(\.dismiss) var dismiss
    let onOpenSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 16) {
                    // Icon with background
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 90, height: 90)
                        
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    
                    // Title
                    Text("Yêu cầu quyền Accessibility")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Để Clipboard hoạt động tốt nhất")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.95))
                }
                .padding(.vertical, 30)
            }
            .frame(height: 200)
            
            // Content
            VStack(spacing: 24) {
                // Features
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "doc.on.clipboard.fill",
                        iconColor: .green,
                        title: "Tự động paste",
                        description: "Paste nội dung ngay khi chọn từ lịch sử"
                    )
                    
                    FeatureRow(
                        icon: "cursorarrow.click.2",
                        iconColor: .blue,
                        title: "Phát hiện con trỏ",
                        description: "Hiển thị cửa sổ đúng vị trí đang làm việc"
                    )
                    
                    FeatureRow(
                        icon: "keyboard.fill",
                        iconColor: .orange,
                        title: "Phím tắt thông minh",
                        description: "Giả lập Command+V để paste tự động"
                    )
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Hướng dẫn nhanh:")
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                    
                    InstructionStep(number: "1", text: "Click nút 'Mở System Settings'")
                    InstructionStep(number: "2", text: "Tìm 'Clipboard' và bật toggle")
                    InstructionStep(number: "3", text: "Quay lại app - cửa sổ sẽ tự đóng")
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Buttons
                VStack(spacing: 12) {
                    // Primary button
                    Button(action: onOpenSettings) {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")
                            Text("Mở System Settings")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut(.defaultAction)
                    
                    // Exit button
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle")
                            Text("Thoát ứng dụng")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut(.cancelAction)
                    
                    // Auto check info
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("Cửa sổ này sẽ tự động đóng khi bạn cấp quyền")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    }
                    .padding(.top, 4)
                }
            }
            .padding(24)
        }
        .frame(width: 520, height: 620)
    }
}

// Feature row component
struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(iconColor)
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            }
            
            Spacer()
        }
    }
}

// Instruction step component
struct InstructionStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .cornerRadius(14)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.black)
            
            Spacer()
        }
    }
}

class AccessibilityPermissionWindow: NSWindow {
    static let shared = AccessibilityPermissionWindow()
    private var checkTimer: Timer?
    private var onPermissionGranted: (() -> Void)?
    
    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 620),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.title = "Clipboard - Yêu cầu quyền"
        self.isReleasedWhenClosed = false
        self.center()
        self.level = .floating
        self.titlebarAppearsTransparent = true
        self.backgroundColor = NSColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0)
        
        // Lắng nghe khi app được focus trở lại
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        stopCheckingPermission()
        NotificationCenter.default.removeObserver(self)
    }
    
    func show(onPermissionGranted: @escaping () -> Void) {
        self.onPermissionGranted = onPermissionGranted
        
        let contentView = AccessibilityPermissionView(
            onOpenSettings: {
                self.openAccessibilitySettings()
            }
        )
        
        self.contentView = NSHostingView(rootView: contentView)
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Bắt đầu check quyền định kỳ mỗi 2 giây
        startCheckingPermission()
    }
    
    private func startCheckingPermission() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkPermission()
        }
    }
    
    private func stopCheckingPermission() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    @objc private func appDidBecomeActive() {
        // Khi app được focus lại, check quyền ngay lập tức
        if self.isVisible {
            checkPermission()
        }
    }
    
    private func checkPermission() {
        let hasAccessibility = AXIsProcessTrusted()
        print("DEBUG: Auto checking permission: \(hasAccessibility)")
        
        if hasAccessibility {
            print("DEBUG: Permission granted! Closing window...")
            stopCheckingPermission()
            
            DispatchQueue.main.async {
                // Show alert TRƯỚC khi close window (để app vẫn còn active)
                NSApp.activate(ignoringOtherApps: true)
                
                let alert = NSAlert()
                alert.messageText = "Thành công! ✅"
                alert.informativeText = "Clipboard đã có quyền Accessibility. Bạn có thể bắt đầu sử dụng app."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
                
                // Đóng window sau khi user bấm OK
                self.close()
                
                // Gọi callback nếu có
                self.onPermissionGranted?()
            }
        }
    }
    
    private func openAccessibilitySettings() {
        // Open System Settings to Privacy & Security > Accessibility
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    override func close() {
        stopCheckingPermission()
        super.close()
    }
}
