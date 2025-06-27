import Foundation
import Cocoa

enum ClipboardItemType: String, Codable {
    case text
    case image
}

struct ClipboardItem: Codable, Identifiable {
    var id: UUID
    let type: ClipboardItemType
    let text: String?
    let imageData: Data?
    let timestamp: Date
    
    init(text: String, timestamp: Date) {
        self.id = UUID()
        self.type = .text
        self.text = text
        self.imageData = nil
        self.timestamp = timestamp
    }
    
    init(imageData: Data, timestamp: Date) {
        self.id = UUID()
        self.type = .image
        self.text = nil
        self.imageData = imageData
        self.timestamp = timestamp
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
    
    func paste() {
        // Copy nội dung vào clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch type {
        case .text:
            if let text = text {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let imageData = imageData {
                pasteboard.setData(imageData, forType: .tiff)
            }
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
} 