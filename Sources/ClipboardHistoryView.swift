import SwiftUI
import Cocoa

enum ContentFilter: String, CaseIterable {
    case all = "Tất cả"
    case text = "Văn bản"
    case image = "Hình ảnh"
    case file = "Tệp tin"
    case bookmark = "Bookmark"
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .text: return "doc.text"
        case .image: return "photo"
        case .file: return "doc"
        case .bookmark: return "bookmark"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .primary
        case .text: return .blue
        case .image: return .green
        case .file: return .orange
        case .bookmark: return .blue
        }
    }
}

struct ClipboardHistoryView: View {
    let items: [ClipboardItem]
    let onItemSelected: (ClipboardItem) -> Void
    let onClearAll: () -> Void
    let onCopyOnly: ((ClipboardItem) -> Void)?
    let onTogglePin: ((ClipboardItem) -> Void)?
    let onDeleteItem: ((ClipboardItem) -> Void)?
    let onToggleBookmark: ((ClipboardItem) -> Void)?
    let onClearBookmarks: (() -> Void)?
    let onClearByType: ((ClipboardItemType) -> Void)?
    @State private var selectedFilter: ContentFilter = .all
    
    // Helper để check file có phải ảnh không
    private func isImageFile(_ item: ClipboardItem) -> Bool {
        guard item.type == .file, let fileURL = item.fileURL else { return false }
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "tif", "heic", "heif", "webp", "svg"]
        let fileExtension = URL(fileURLWithPath: fileURL).pathExtension.lowercased()
        return imageExtensions.contains(fileExtension)
    }
    
    var filteredItems: [ClipboardItem] {
        switch selectedFilter {
        case .all:
            return items
        case .text:
            return items.filter { $0.type == .text }
        case .image:
            // Hiển thị cả item image và file ảnh
            return items.filter { $0.type == .image || isImageFile($0) }
        case .file:
            return items.filter { $0.type == .file }
        case .bookmark:
            return items.filter { $0.isBookmarked }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter bar - có thể kéo để move window
            HStack(spacing: 8) {
                ForEach(ContentFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                    }) {
                        Image(systemName: filter.icon)
                            .font(.system(size: 14))
                            .frame(width: 32, height: 28)
                            .background(selectedFilter == filter ? Color.accentColor : Color(.controlBackgroundColor))
                            .foregroundColor(selectedFilter == filter ? .white : filter.color)
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(filter.rawValue)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                
                Spacer()
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Kéo window
                                if let window = NSApp.windows.first(where: { $0.isVisible && $0.level == .floating }) {
                                    let currentLocation = NSEvent.mouseLocation
                                    let newOrigin = NSPoint(
                                        x: currentLocation.x - value.startLocation.x,
                                        y: currentLocation.y + value.startLocation.y - window.frame.height
                                    )
                                    window.setFrameOrigin(newOrigin)
                                }
                            }
                    )
                
                if !filteredItems.isEmpty {
                    Button(action: {
                        switch selectedFilter {
                        case .all:
                            onClearAll()
                        case .text:
                            onClearByType?(.text)
                        case .image:
                            onClearByType?(.image)
                        case .file:
                            onClearByType?(.file)
                        case .bookmark:
                            onClearBookmarks?()
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Xóa \(selectedFilter.rawValue.lowercased())")
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Kéo window
                        if let window = NSApp.windows.first(where: { $0.isVisible && $0.level == .floating }) {
                            let currentLocation = NSEvent.mouseLocation
                            let newOrigin = NSPoint(
                                x: currentLocation.x - value.startLocation.x,
                                y: currentLocation.y + value.startLocation.y - window.frame.height
                            )
                            window.setFrameOrigin(newOrigin)
                        }
                    }
            )
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(filteredItems) { item in
                        ClipboardItemView(item: item, onItemSelected: onItemSelected, onCopyOnly: onCopyOnly, onTogglePin: onTogglePin, onDeleteItem: onDeleteItem, onToggleBookmark: onToggleBookmark)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
        }
        .frame(width: 300, height: 450)
        .background(Color(.windowBackgroundColor))
    }
}

struct ClipboardItemView: View {
    private static var fileIconCache: [String: NSImage] = [:]
    
    static func cachedFileIcon(for path: String) -> NSImage {
        if let cached = fileIconCache[path] {
            return cached
        }
        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: 32, height: 32)
        fileIconCache[path] = icon
        return icon
    }
    
    let item: ClipboardItem
    let onItemSelected: (ClipboardItem) -> Void
    let onCopyOnly: ((ClipboardItem) -> Void)?
    let onTogglePin: ((ClipboardItem) -> Void)?
    let onDeleteItem: ((ClipboardItem) -> Void)?
    let onToggleBookmark: ((ClipboardItem) -> Void)?
    @State private var isHovered = false
    @State private var showAsDateTime = false
    @State private var showAsTable = false
    @State private var showAsJSON = false
    @State private var displayText: String = ""
    
    var typeIcon: String {
        switch item.type {
        case .text: return "doc.text"
        case .image: return "photo"
        case .file:
            if item.isDirectory == true {
                return "folder"
            } else {
                return "doc"
            }
        }
    }
    
    var typeColor: Color {
        switch item.type {
        case .text: return .blue
        case .image: return .green
        case .file:
            if item.isDirectory == true {
                return .blue
            } else {
                return .orange
            }
        }
    }
    
    // Check if file is an image
    private func isImageFile(_ fileURL: String) -> Bool {
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "tif", "heic", "heif", "webp", "svg"]
        let fileExtension = URL(fileURLWithPath: fileURL).pathExtension.lowercased()
        return imageExtensions.contains(fileExtension)
    }
    
    // Check if text is a URL
    private func isURL(_ text: String) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmedText),
           let scheme = url.scheme,
           (scheme == "http" || scheme == "https") {
            return true
        }
        return false
    }
    
    // Get URL from text
    private func getURL() -> URL? {
        guard let text = item.text else { return nil }
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return URL(string: trimmedText)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 6) {
                if item.type == .image, let imageData = item.imageData,
                   let image = NSImage(data: imageData) {
                    let imageHeight = min(image.size.height, 125)
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: imageHeight)
                } else if item.type == .file, let fileName = item.fileName, let fileURL = item.fileURL {
                    // Nếu file là ảnh, hiển thị preview
                    if isImageFile(fileURL), let image = NSImage(contentsOfFile: fileURL) {
                        let imageHeight = min(image.size.height, 125)
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: imageHeight)
                    } else {
                        // Hiển thị file info cho file thường và folder
                        HStack(spacing: 8) {
                            Image(nsImage: ClipboardItemView.cachedFileIcon(for: fileURL))
                                .resizable()
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fileName)
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                                
                                Text(URL(fileURLWithPath: fileURL).deletingLastPathComponent().path)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                } else if item.text != nil {
                    HStack(spacing: 8) {
                        Text(displayText)
                            .lineLimit(3)
                            .font(.system(size: 11))
                        
                        if item.isTimestamp {
                            Button(action: {
                                toggleTimestampDisplay()
                            }) {
                                Image(systemName: showAsDateTime ? "clock.arrow.circlepath" : "calendar.badge.clock")
                                    .font(.system(size: 12))
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help(showAsDateTime ? "Hiển thị timestamp" : "Hiển thị ngày giờ")
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                    }
                }
                
                HStack(spacing: 6) {
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    
                    if item.isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                    
                    if item.isJSON {
                        Image(systemName: "curlybraces")
                            .font(.system(size: 10))
                            .foregroundColor(.purple)
                    }
                    
                    if item.isExcelData {
                        Image(systemName: "tablecells")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                    
                    Image(systemName: typeIcon)
                        .font(.system(size: 10))
                        .foregroundColor(typeColor)
                    
                    if let icon = item.appIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 12, height: 12)
                    }
                    
                    Text(item.timeString)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    if let appName = item.sourceAppName {
                        Text("• \(appName)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            
            if isHovered {
                HStack(spacing: 4) {
                    // Open button cho file/folder/URL
                    if item.type == .file, let fileURL = item.fileURL {
                        Button(action: {
                            NSWorkspace.shared.open(URL(fileURLWithPath: fileURL))
                            // Đóng window
                            if let window = NSApp.windows.first(where: { $0.isVisible && $0.level == .floating }) {
                                window.close()
                            }
                        }) {
                            Image(systemName: "arrow.up.forward.square")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.green)
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Mở")
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    } else if item.type == .text, let text = item.text, isURL(text), let url = getURL() {
                        Button(action: {
                            NSWorkspace.shared.open(url)
                            // Đóng window
                            if let window = NSApp.windows.first(where: { $0.isVisible && $0.level == .floating }) {
                                window.close()
                            }
                        }) {
                            Image(systemName: "arrow.up.forward.square")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.green)
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Mở URL trong trình duyệt")
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    }
                    
                    // Conversion button for JSON data
                    if item.type == .text && item.isJSON {
                        Button(action: {
                            toggleJSONDisplay()
                        }) {
                            Image(systemName: showAsTable ? "curlybraces" : "tablecells")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.purple)
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(showAsTable ? "Hiển thị JSON" : "Hiển thị dạng bảng")
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    }
                    
                    // Conversion button for Excel data
                    if item.type == .text && item.isExcelData {
                        Button(action: {
                            toggleExcelDisplay()
                        }) {
                            Image(systemName: showAsJSON ? "tablecells" : "curlybraces")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.green)
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(showAsJSON ? "Hiển thị dạng bảng" : "Hiển thị JSON")
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    }
                    
                    // Copy button
                    Button(action: {
                        item.copyOnly(displayText: displayText)
                        onCopyOnly?(item)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.accentColor)
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Sao chép")
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                .padding(8)
            }
        }
        .background(isHovered ? Color(.selectedControlColor).opacity(0.3) : Color(.controlBackgroundColor))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .contextMenu {
            // Copy
            Button(action: {
                item.copyOnly(displayText: displayText)
                onCopyOnly?(item)
            }) {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Sao chép")
                }
            }
            
            // Open
            if item.type == .file, let fileURL = item.fileURL {
                Button(action: {
                    NSWorkspace.shared.open(URL(fileURLWithPath: fileURL))
                    // Đóng window
                    if let window = NSApp.windows.first(where: { $0.isVisible && $0.level == .floating }) {
                        window.close()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.up.forward.square")
                        Text("Mở")
                    }
                }
            } else if item.type == .text, let text = item.text, isURL(text), let url = getURL() {
                Button(action: {
                    NSWorkspace.shared.open(url)
                    // Đóng window
                    if let window = NSApp.windows.first(where: { $0.isVisible && $0.level == .floating }) {
                        window.close()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.up.forward.square")
                        Text("Mở trong trình duyệt")
                    }
                }
            }
            
            Divider()
            
            // JSON/Excel conversion menu items
            if item.isJSON {
                Button(action: {
                    toggleJSONDisplay()
                }) {
                    HStack {
                        Image(systemName: showAsTable ? "curlybraces" : "tablecells")
                        Text(showAsTable ? "Hiển thị JSON" : "Hiển thị dạng bảng")
                    }
                }
                
                Divider()
            }
            
            if item.isExcelData {
                Button(action: {
                    toggleExcelDisplay()
                }) {
                    HStack {
                        Image(systemName: showAsJSON ? "tablecells" : "curlybraces")
                        Text(showAsJSON ? "Hiển thị dạng bảng" : "Hiển thị JSON")
                    }
                }
                
                Button(action: {
                    // Paste Excel data as image
                    if let imageData = generateExcelImageData() {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setData(imageData, forType: .tiff)
                        
                        // Trigger paste
                        ClipboardManager.shared.ignoreNextChange()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
                        
                        // Close window
                        if let window = NSApp.windows.first(where: { $0.isVisible && $0.level == .floating }) {
                            window.close()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Dán như ảnh")
                    }
                }
                
                Divider()
            }
            
            Button(action: {
                onTogglePin?(item)
            }) {
                HStack {
                    Image(systemName: item.isPinned ? "pin.slash" : "pin")
                    Text(item.isPinned ? "Bỏ ghim" : "Ghim")
                }
            }
            
            Button(action: {
                onToggleBookmark?(item)
            }) {
                HStack {
                    Image(systemName: item.isBookmarked ? "bookmark.slash" : "bookmark")
                    Text(item.isBookmarked ? "Bỏ bookmark" : "Bookmark")
                }
            }
            
            if item.type == .file {
                Divider()
                
                Button(action: {
                    item.copyPath()
                }) {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                        Text("Copy đường dẫn")
                    }
                }
            }
            
            Divider()
            
            Button(action: {
                onDeleteItem?(item)
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Xóa")
                }
            }
        }
        .onDrag {
            // Chỉ cho phép drag file/folder items
            if item.type == .file, let url = item.getFileURL() {
                // Để force copy (không phải move), ta copy file vào temp location
                // với tên unique, sau đó drag từ temp location
                let uniqueID = UUID().uuidString
                let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ClipboardDrag-\(uniqueID)")
                let tempURL = tempDir.appendingPathComponent(url.lastPathComponent)
                
                do {
                    // Tạo temp directory
                    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                    
                    // Copy file vào temp
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    
                    // Drag từ temp location - destination sẽ copy/move file này
                    // Khi drag từ temp location, macOS thường copy thay vì move
                    return NSItemProvider(object: tempURL as NSURL)
                } catch {
                    print("Error preparing file for drag: \(error)")
                    // Fallback: drag original file (có thể move)
                    return NSItemProvider(object: url as NSURL)
                }
            }
            return NSItemProvider()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onTapGesture {
            // If item has been converted (JSON→Table, Excel→JSON, or Timestamp→DateTime), paste and close
            if showAsTable || showAsJSON || showAsDateTime {
                item.paste(displayText: displayText)
                if let window = NSApp.windows.first(where: { $0.isVisible && $0.level == .floating }) {
                    window.close()
                }
            } else if item.type == .text && displayText != item.text {
                // Fallback: if displayText is different, paste it
                item.paste(displayText: displayText)
                if let window = NSApp.windows.first(where: { $0.isVisible && $0.level == .floating }) {
                    window.close()
                }
            } else {
                onItemSelected(item)
            }
        }
        .onAppear {
            updateDisplayText()
        }
    }
    
    private func updateDisplayText() {
        if let text = item.text {
            displayText = text
        }
    }
    
    private func toggleTimestampDisplay() {
        showAsDateTime.toggle()
        
        if showAsDateTime {
            // Convert timestamp to datetime
            if let text = item.text?.trimmingCharacters(in: .whitespaces),
               let dateString = item.timestampToDateString(text) {
                displayText = dateString
            }
        } else {
            // Show original timestamp
            if let text = item.text {
                displayText = text
            }
        }
    }
    
    private func toggleJSONDisplay() {
        showAsTable.toggle()
        
        if showAsTable {
            // Convert JSON to table format (TSV) for display only
            guard let text = item.text, item.isJSON else { return }
            guard let data = text.data(using: .utf8) else { return }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data)
                var tsvContent = ""
                
                if let array = json as? [[String: Any]] {
                    guard let firstItem = array.first else { return }
                    let headers = Array(firstItem.keys).sorted()
                    
                    tsvContent += headers.joined(separator: "\t") + "\n"
                    
                    for item in array {
                        let values = headers.map { key -> String in
                            if let value = item[key] {
                                let stringValue = "\(value)"
                                return stringValue.replacingOccurrences(of: "\t", with: " ")
                                                 .replacingOccurrences(of: "\n", with: " ")
                            }
                            return ""
                        }
                        tsvContent += values.joined(separator: "\t") + "\n"
                    }
                } else if let dict = json as? [String: Any] {
                    tsvContent += "Key\tValue\n"
                    for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
                        let stringValue = "\(value)".replacingOccurrences(of: "\t", with: " ")
                                                    .replacingOccurrences(of: "\n", with: " ")
                        tsvContent += "\(key)\t\(stringValue)\n"
                    }
                } else if let array = json as? [Any] {
                    tsvContent += "Value\n"
                    for value in array {
                        let stringValue = "\(value)".replacingOccurrences(of: "\t", with: " ")
                                                    .replacingOccurrences(of: "\n", with: " ")
                        tsvContent += "\(stringValue)\n"
                    }
                }
                
                displayText = tsvContent
            } catch {
                print("Error converting JSON to table: \(error)")
            }
        } else {
            // Show original JSON
            if let text = item.text {
                displayText = text
            }
        }
    }
    
    private func toggleExcelDisplay() {
        showAsJSON.toggle()
        
        if showAsJSON {
            // Convert Excel to JSON for display only (don't copy to clipboard yet)
            guard let text = item.text, item.isExcelData else { return }
            
            let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            
            let lines = cleanedText.components(separatedBy: .newlines).filter { line in
                let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
                                 .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                return !cleaned.isEmpty
            }
            
            guard lines.count >= 2 else { return }
            
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
                    
                    if header.isEmpty { continue }
                    
                    if !value.isEmpty && value.hasPrefix("0") && value.count > 1 {
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
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    displayText = jsonString
                }
            } catch {
                print("Error converting Excel to JSON: \(error)")
            }
        } else {
            // Show original Excel data
            if let text = item.text {
                displayText = text
            }
        }
    }
    
    private func generateExcelImageData() -> Data? {
        guard let text = item.text, item.isExcelData else { return nil }
        
        // If we have the original image from Excel copy, use it
        if let imageData = item.imageData {
            return imageData
        }
        
        // Otherwise, render the table as image
        // Parse Excel data
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        
        let lines = cleanedText.components(separatedBy: .newlines).filter { line in
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
                             .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            return !cleaned.isEmpty
        }
        
        guard !lines.isEmpty else { return nil }
        
        // Create table image
        let cellPadding: CGFloat = 8
        let fontSize: CGFloat = 11
        let font = NSFont.systemFont(ofSize: fontSize)
        let headerFont = NSFont.boldSystemFont(ofSize: fontSize)
        
        // Calculate column widths
        var columnWidths: [CGFloat] = []
        let maxColumns = lines.map { $0.components(separatedBy: "\t").count }.max() ?? 0
        
        for colIndex in 0..<maxColumns {
            var maxWidth: CGFloat = 0
            for (rowIndex, line) in lines.enumerated() {
                let cells = line.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    .components(separatedBy: "\t")
                if colIndex < cells.count {
                    let cellText = cells[colIndex]
                    let cellFont = rowIndex == 0 ? headerFont : font
                    let size = (cellText as NSString).size(withAttributes: [.font: cellFont])
                    maxWidth = max(maxWidth, size.width)
                }
            }
            columnWidths.append(maxWidth + cellPadding * 2)
        }
        
        let totalWidth = columnWidths.reduce(0, +)
        let rowHeight: CGFloat = fontSize + cellPadding * 2
        let totalHeight = CGFloat(lines.count) * rowHeight
        
        // Create image
        let imageSize = NSSize(width: totalWidth, height: totalHeight)
        let image = NSImage(size: imageSize)
        
        image.lockFocus()
        
        // Draw background
        NSColor.white.setFill()
        NSRect(origin: .zero, size: imageSize).fill()
        
        // Draw cells (from top to bottom, accounting for flipped coordinates)
        for (rowIndex, line) in lines.enumerated() {
            let cells = line.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                .components(separatedBy: "\t")
            
            // Calculate Y position from top (flip coordinate system)
            let yOffset = totalHeight - CGFloat(rowIndex + 1) * rowHeight
            
            var xOffset: CGFloat = 0
            for (colIndex, cell) in cells.enumerated() {
                let cellWidth = colIndex < columnWidths.count ? columnWidths[colIndex] : 100
                let cellRect = NSRect(x: xOffset, y: yOffset, width: cellWidth, height: rowHeight)
                
                // Draw cell border
                NSColor.gray.setStroke()
                let path = NSBezierPath(rect: cellRect)
                path.lineWidth = 0.5
                path.stroke()
                
                // Draw header background
                if rowIndex == 0 {
                    NSColor(white: 0.9, alpha: 1.0).setFill()
                    cellRect.fill()
                    NSColor.gray.setStroke()
                    path.stroke()
                }
                
                // Draw text
                let cellFont = rowIndex == 0 ? headerFont : font
                let textColor = NSColor.black
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: cellFont,
                    .foregroundColor: textColor,
                    .paragraphStyle: paragraphStyle
                ]
                
                let textRect = NSRect(
                    x: xOffset + cellPadding,
                    y: yOffset + cellPadding,
                    width: cellWidth - cellPadding * 2,
                    height: rowHeight - cellPadding * 2
                )
                
                (cell as NSString).draw(in: textRect, withAttributes: attributes)
                
                xOffset += cellWidth
            }
        }
        
        image.unlockFocus()
        
        return image.tiffRepresentation
    }
} 