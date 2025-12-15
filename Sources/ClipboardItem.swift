import Foundation
import Cocoa

enum ClipboardItemType: String, Codable {
    case text
    case image
    case file
}

struct ClipboardItem: Codable, Identifiable {
    var id: UUID
    let type: ClipboardItemType
    let text: String?
    let rtfData: Data?
    let htmlData: Data?
    let imageData: Data?
    let fileURL: String?
    let fileName: String?
    let isDirectory: Bool?
    let timestamp: Date
    let sourceAppName: String?
    let appBundleIdentifier: String?
    var isPinned: Bool
    var isBookmarked: Bool
    
    init(text: String, rtfData: Data? = nil, htmlData: Data? = nil, timestamp: Date, sourceAppName: String? = nil, appBundleIdentifier: String? = nil, isPinned: Bool = false, isBookmarked: Bool = false) {
        self.id = UUID()
        self.type = .text
        self.text = text
        self.rtfData = rtfData
        self.htmlData = htmlData
        self.imageData = nil
        self.fileURL = nil
        self.fileName = nil
        self.isDirectory = nil
        self.timestamp = timestamp
        self.sourceAppName = sourceAppName
        self.appBundleIdentifier = appBundleIdentifier
        self.isPinned = isPinned
        self.isBookmarked = isBookmarked
    }
    
    init(imageData: Data, timestamp: Date, sourceAppName: String? = nil, appBundleIdentifier: String? = nil, isPinned: Bool = false, isBookmarked: Bool = false) {
        self.id = UUID()
        self.type = .image
        self.text = nil
        self.rtfData = nil
        self.htmlData = nil
        self.imageData = imageData
        self.fileURL = nil
        self.fileName = nil
        self.isDirectory = nil
        self.timestamp = timestamp
        self.sourceAppName = sourceAppName
        self.appBundleIdentifier = appBundleIdentifier
        self.isPinned = isPinned
        self.isBookmarked = isBookmarked
    }
    
    init(fileURL: String, fileName: String, isDirectory: Bool = false, timestamp: Date, sourceAppName: String? = nil, appBundleIdentifier: String? = nil, isPinned: Bool = false, isBookmarked: Bool = false) {
        self.id = UUID()
        self.type = .file
        self.text = nil
        self.rtfData = nil
        self.htmlData = nil
        self.imageData = nil
        self.fileURL = fileURL
        self.fileName = fileName
        self.isDirectory = isDirectory
        self.timestamp = timestamp
        self.sourceAppName = sourceAppName
        self.appBundleIdentifier = appBundleIdentifier
        self.isPinned = isPinned
        self.isBookmarked = isBookmarked
    }
    
    var appIcon: NSImage? {
        guard let bundleId = appBundleIdentifier else { return nil }
        return NSWorkspace.shared.icon(forFile: NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)?.path ?? "")
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
    
    // Kiểm tra xem text có phải là timestamp không
    var isTimestamp: Bool {
        guard let text = text?.trimmingCharacters(in: .whitespaces) else { return false }
        // Timestamp 10 chữ số (seconds) hoặc 13 chữ số (milliseconds)
        guard let number = Int64(text) else { return false }
        return (text.count == 10 || text.count == 13) && number > 0
    }
    
    // Convert timestamp sang datetime string
    func timestampToDateString(_ timestamp: String) -> String? {
        guard let number = Int64(timestamp) else { return nil }
        
        let date: Date
        if timestamp.count == 10 {
            // Timestamp in seconds
            date = Date(timeIntervalSince1970: TimeInterval(number))
        } else if timestamp.count == 13 {
            // Timestamp in milliseconds
            date = Date(timeIntervalSince1970: TimeInterval(number) / 1000.0)
        } else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return formatter.string(from: date)
    }
    
    // Convert datetime string sang timestamp
    func dateStringToTimestamp(_ dateString: String, isMilliseconds: Bool) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        
        guard let date = formatter.date(from: dateString) else { return nil }
        
        let timestamp = Int64(date.timeIntervalSince1970)
        if isMilliseconds {
            return String(timestamp * 1000)
        } else {
            return String(timestamp)
        }
    }
    
    func copyOnly(displayText: String? = nil) {
        // Yêu cầu ClipboardManager ignore change tiếp theo để tránh duplicate
        ClipboardManager.shared.ignoreNextChange()
        
        // Copy nội dung vào clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch type {
        case .text:
            // Nếu có displayText khác (đã convert), dùng nó
            let textToCopy = displayText ?? text ?? ""
            
            // Set tất cả các format có sẵn để giữ nguyên format
            if let htmlData = htmlData {
                pasteboard.setData(htmlData, forType: .html)
            }
            if let rtfData = rtfData {
                pasteboard.setData(rtfData, forType: .rtf)
            }
            pasteboard.setString(textToCopy, forType: .string)
        case .image:
            if let imageData = imageData {
                pasteboard.setData(imageData, forType: .tiff)
            }
        case .file:
            if let urlString = fileURL {
                // Parse URL đúng cách
                let url: URL
                if urlString.hasPrefix("file://") {
                    url = URL(fileURLWithPath: urlString.replacingOccurrences(of: "file://", with: ""))
                } else {
                    url = URL(fileURLWithPath: urlString)
                }
                pasteboard.writeObjects([url as NSURL])
            }
        }
    }
    
    func paste(displayText: String? = nil) {
        // Copy nội dung vào clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch type {
        case .text:
            // Nếu có displayText khác (đã convert), dùng nó
            let textToCopy = displayText ?? text ?? ""
            
            // Set tất cả các format có sẵn để giữ nguyên format
            if let htmlData = htmlData {
                pasteboard.setData(htmlData, forType: .html)
            }
            if let rtfData = rtfData {
                pasteboard.setData(rtfData, forType: .rtf)
            }
            pasteboard.setString(textToCopy, forType: .string)
        case .image:
            if let imageData = imageData {
                pasteboard.setData(imageData, forType: .tiff)
            }
        case .file:
            if let urlString = fileURL {
                // Parse URL đúng cách
                let url: URL
                if urlString.hasPrefix("file://") {
                    url = URL(fileURLWithPath: urlString.replacingOccurrences(of: "file://", with: ""))
                } else {
                    url = URL(fileURLWithPath: urlString)
                }
                pasteboard.writeObjects([url as NSURL])
            }
        }
        
        // Yêu cầu ClipboardManager ignore change tiếp theo để tránh duplicate
        ClipboardManager.shared.ignoreNextChange()
        
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
    
    // Helper function to get file URL
    func getFileURL() -> URL? {
        guard type == .file, let urlString = fileURL else { return nil }
        
        if urlString.hasPrefix("file://") {
            return URL(fileURLWithPath: urlString.replacingOccurrences(of: "file://", with: ""))
        } else {
            return URL(fileURLWithPath: urlString)
        }
    }
    
    // Copy file path to clipboard
    func copyPath() {
        guard let url = getFileURL() else { return }
        
        ClipboardManager.shared.ignoreNextChange()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.path, forType: .string)
    }
} 