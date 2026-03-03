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
    let imageFileName: String?
    let fileURL: String?
    let fileName: String?
    let isDirectory: Bool?
    let timestamp: Date
    let sourceAppName: String?
    let appBundleIdentifier: String?
    var isPinned: Bool
    var isBookmarked: Bool
    
    var imageData: Data? {
        guard let fileName = imageFileName else { return nil }
        return ClipboardManager.shared.loadImageFromDisk(fileName)
    }
    
    init(text: String, rtfData: Data? = nil, htmlData: Data? = nil, imageFileName: String? = nil, timestamp: Date, sourceAppName: String? = nil, appBundleIdentifier: String? = nil, isPinned: Bool = false, isBookmarked: Bool = false) {
        self.id = UUID()
        self.type = .text
        self.text = text
        self.rtfData = rtfData
        self.htmlData = htmlData
        self.imageFileName = imageFileName
        self.fileURL = nil
        self.fileName = nil
        self.isDirectory = nil
        self.timestamp = timestamp
        self.sourceAppName = sourceAppName
        self.appBundleIdentifier = appBundleIdentifier
        self.isPinned = isPinned
        self.isBookmarked = isBookmarked
    }
    
    init(imageFileName: String, timestamp: Date, sourceAppName: String? = nil, appBundleIdentifier: String? = nil, isPinned: Bool = false, isBookmarked: Bool = false) {
        self.id = UUID()
        self.type = .image
        self.text = nil
        self.rtfData = nil
        self.htmlData = nil
        self.imageFileName = imageFileName
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
        self.imageFileName = nil
        self.fileURL = fileURL
        self.fileName = fileName
        self.isDirectory = isDirectory
        self.timestamp = timestamp
        self.sourceAppName = sourceAppName
        self.appBundleIdentifier = appBundleIdentifier
        self.isPinned = isPinned
        self.isBookmarked = isBookmarked
    }
    
    private static var appIconCache: [String: NSImage] = [:]
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
    
    var appIcon: NSImage? {
        guard let bundleId = appBundleIdentifier else { return nil }
        if let cached = ClipboardItem.appIconCache[bundleId] {
            return cached
        }
        if let path = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)?.path {
            let icon = NSWorkspace.shared.icon(forFile: path)
            icon.size = NSSize(width: 16, height: 16)
            ClipboardItem.appIconCache[bundleId] = icon
            return icon
        }
        return nil
    }
    
    var timeString: String {
        ClipboardItem.timeFormatter.string(from: timestamp)
    }
    
    // Kiểm tra xem text có phải là timestamp không
    var isTimestamp: Bool {
        guard let text = text?.trimmingCharacters(in: .whitespaces) else { return false }
        // Timestamp 10 chữ số (seconds) hoặc 13 chữ số (milliseconds)
        guard let number = Int64(text) else { return false }
        return (text.count == 10 || text.count == 13) && number > 0
    }
    
    // Kiểm tra xem text có phải là JSON không
    var isJSON: Bool {
        guard let text = text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return false }
        guard text.hasPrefix("{") || text.hasPrefix("[") else { return false }
        
        if let data = text.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data)
                // Chỉ chấp nhận array hoặc dictionary
                return json is [Any] || json is [String: Any]
            } catch {
                return false
            }
        }
        return false
    }
    
    // Kiểm tra xem text có phải là dữ liệu từ Excel không (tab-separated hoặc CSV)
    var isExcelData: Bool {
        guard let text = text, !text.isEmpty else { return false }
        
        // Remove leading/trailing quotes if present
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        
        let lines = cleanedText.components(separatedBy: .newlines).filter { line in
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
                             .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            return !cleaned.isEmpty
        }
        
        guard lines.count >= 2 else { return false } // Cần ít nhất 2 dòng (header + data)
        
        // Kiểm tra tab-separated (phổ biến nhất khi copy từ Excel)
        let firstLine = lines[0].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        let tabCount = firstLine.components(separatedBy: "\t").count
        if tabCount >= 2 {
            // Kiểm tra các dòng khác cũng có số tab tương tự
            let consistentTabs = lines.allSatisfy { line in
                let cleanLine = line.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                let count = cleanLine.components(separatedBy: "\t").count
                return count == tabCount || count == tabCount - 1 || count == tabCount + 1
            }
            if consistentTabs {
                return true
            }
        }
        
        return false
    }
    
    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return f
    }()
    
    func timestampToDateString(_ timestamp: String) -> String? {
        guard let number = Int64(timestamp) else { return nil }
        
        let date: Date
        if timestamp.count == 10 {
            date = Date(timeIntervalSince1970: TimeInterval(number))
        } else if timestamp.count == 13 {
            date = Date(timeIntervalSince1970: TimeInterval(number) / 1000.0)
        } else {
            return nil
        }
        
        return ClipboardItem.dateTimeFormatter.string(from: date)
    }
    
    func dateStringToTimestamp(_ dateString: String, isMilliseconds: Bool) -> String? {
        guard let date = ClipboardItem.dateTimeFormatter.date(from: dateString) else { return nil }
        
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
            
            // Check if textToCopy is tab-separated data (converted from JSON)
            let isTSV = textToCopy.contains("\t") && textToCopy.contains("\n")
            
            // Set tất cả các format có sẵn để giữ nguyên format
            if let htmlData = htmlData, displayText == nil {
                pasteboard.setData(htmlData, forType: .html)
            }
            if let rtfData = rtfData, displayText == nil {
                pasteboard.setData(rtfData, forType: .rtf)
            }
            
            // If it's TSV data, set the proper pasteboard type for Excel
            if isTSV, let tsvData = textToCopy.data(using: .utf8) {
                pasteboard.setData(tsvData, forType: NSPasteboard.PasteboardType(rawValue: "public.utf8-tab-separated-values-text"))
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
            
            // Check if textToCopy is tab-separated data (converted from JSON)
            let isTSV = textToCopy.contains("\t") && textToCopy.contains("\n")
            
            // Set tất cả các format có sẵn để giữ nguyên format
            if let htmlData = htmlData, displayText == nil {
                pasteboard.setData(htmlData, forType: .html)
            }
            if let rtfData = rtfData, displayText == nil {
                pasteboard.setData(rtfData, forType: .rtf)
            }
            
            // If it's TSV data, set the proper pasteboard type for Excel
            if isTSV, let tsvData = textToCopy.data(using: .utf8) {
                pasteboard.setData(tsvData, forType: NSPasteboard.PasteboardType(rawValue: "public.utf8-tab-separated-values-text"))
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
    
    // Convert JSON to Excel - copy to clipboard as tab-separated
    func convertJSONToExcel() {
        guard let text = text, isJSON else { return }
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            var tsvContent = ""
            
            if let array = json as? [[String: Any]] {
                // Array of objects - most common case
                guard let firstItem = array.first else { return }
                let headers = Array(firstItem.keys).sorted() // Sort for consistency
                
                // Write headers
                tsvContent += headers.joined(separator: "\t") + "\n"
                
                // Write data rows
                for item in array {
                    let values = headers.map { key -> String in
                        if let value = item[key] {
                            let stringValue = "\(value)"
                            // Escape tabs and newlines in values
                            return stringValue.replacingOccurrences(of: "\t", with: " ")
                                             .replacingOccurrences(of: "\n", with: " ")
                        }
                        return ""
                    }
                    tsvContent += values.joined(separator: "\t") + "\n"
                }
            } else if let dict = json as? [String: Any] {
                // Single object - convert to 2 columns (key, value)
                tsvContent += "Key\tValue\n"
                for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
                    let stringValue = "\(value)".replacingOccurrences(of: "\t", with: " ")
                                                .replacingOccurrences(of: "\n", with: " ")
                    tsvContent += "\(key)\t\(stringValue)\n"
                }
            } else if let array = json as? [Any] {
                // Array of primitives
                tsvContent += "Value\n"
                for value in array {
                    let stringValue = "\(value)".replacingOccurrences(of: "\t", with: " ")
                                                .replacingOccurrences(of: "\n", with: " ")
                    tsvContent += "\(stringValue)\n"
                }
            }
            
            // Copy to clipboard with proper types for Excel
            ClipboardManager.shared.ignoreNextChange()
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            
            // Set multiple pasteboard types for better Excel compatibility
            if let tsvData = tsvContent.data(using: .utf8) {
                // Set tabular text type - this tells Excel it's tab-separated data
                pasteboard.setData(tsvData, forType: NSPasteboard.PasteboardType(rawValue: "public.utf8-tab-separated-values-text"))
                // Also set as plain text for fallback
                pasteboard.setString(tsvContent, forType: .string)
            } else {
                pasteboard.setString(tsvContent, forType: .string)
            }
            
            // Show notification
            print("✓ Đã copy dữ liệu bảng vào clipboard - Paste vào Excel/Numbers để sử dụng")
            
        } catch {
            print("Error converting JSON to Excel: \(error)")
        }
    }
    
    // Convert Excel data to JSON - copy to clipboard
    func convertExcelToJSON() {
        guard let text = text, isExcelData else { return }
        
        // Remove leading/trailing quotes and clean up
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        
        let lines = cleanedText.components(separatedBy: .newlines).filter { line in
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
                             .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            return !cleaned.isEmpty
        }
        
        guard lines.count >= 2 else { return }
        
        // Parse tab-separated data
        let headerLine = lines[0].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        let headers = headerLine.components(separatedBy: "\t").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        var jsonArray: [[String: Any]] = []
        
        for i in 1..<lines.count {
            let valueLine = lines[i].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            let values = valueLine.components(separatedBy: "\t")
            var dict: [String: Any] = [:]
            
            for j in 0..<min(headers.count, values.count) {
                let header = headers[j]
                let value = values[j].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip empty headers
                if header.isEmpty {
                    continue
                }
                
                // Try to parse as number, but preserve leading zeros and long numbers
                // If string starts with 0 (like "036193011444"), keep as string
                if !value.isEmpty && value.hasPrefix("0") && value.count > 1 {
                    // Keep as string to preserve leading zeros
                    dict[header] = value
                } else if let intValue = Int(value) {
                    dict[header] = intValue
                } else if let doubleValue = Double(value) {
                    dict[header] = doubleValue
                } else {
                    dict[header] = value
                }
            }
            
            if !dict.isEmpty {
                jsonArray.append(dict)
            }
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted, .sortedKeys])
            
            // Copy JSON string to clipboard
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                ClipboardManager.shared.ignoreNextChange()
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(jsonString, forType: .string)
                
                print("✓ Đã copy JSON vào clipboard")
            }
            
        } catch {
            print("Error converting Excel to JSON: \(error)")
        }
    }
} 