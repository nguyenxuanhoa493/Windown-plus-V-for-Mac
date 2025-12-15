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
    let item: ClipboardItem
    let onItemSelected: (ClipboardItem) -> Void
    let onCopyOnly: ((ClipboardItem) -> Void)?
    let onTogglePin: ((ClipboardItem) -> Void)?
    let onDeleteItem: ((ClipboardItem) -> Void)?
    let onToggleBookmark: ((ClipboardItem) -> Void)?
    @State private var isHovered = false
    @State private var showAsDateTime = false
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
                            // Hiển thị icon từ hệ thống
                            let url = URL(fileURLWithPath: fileURL)
                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
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
                } else if let text = item.text {
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
                return NSItemProvider(object: url as NSURL)
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
            // Pass displayText khi paste
            if item.type == .text && displayText != item.text {
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
} 