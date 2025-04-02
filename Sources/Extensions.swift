import Cocoa

extension NSPanel {
    // Lưu trữ event monitor để có thể hủy khi cửa sổ đóng
    private struct AssociatedKeys {
        static var eventMonitorKey: UnsafeRawPointer = {
            return UnsafeRawPointer(bitPattern: "eventMonitorKey".hashValue)!
        }()
    }
    
    // Thiết lập event monitor
    func setAccessoryView(_ monitor: Any?) {
        // Lưu trữ event monitor mới
        objc_setAssociatedObject(self, AssociatedKeys.eventMonitorKey, monitor, .OBJC_ASSOCIATION_RETAIN)
        
        // Đặt delegate để xử lý khi cửa sổ đóng
        if delegate == nil {
            delegate = PanelDelegate.shared
        }
    }
    
    // Hủy event monitor
    func cleanupMonitor() {
        if let monitor = objc_getAssociatedObject(self, AssociatedKeys.eventMonitorKey) {
            NSEvent.removeMonitor(monitor)
            objc_setAssociatedObject(self, AssociatedKeys.eventMonitorKey, nil, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

class PanelDelegate: NSObject, NSWindowDelegate {
    static let shared = PanelDelegate()
    
    func windowWillClose(_ notification: Notification) {
        if let panel = notification.object as? NSPanel {
            panel.cleanupMonitor()
        }
    }
} 