import Cocoa

class ClipboardManager {
    static let shared = ClipboardManager()
    
    private let pasteboard = NSPasteboard.general
    private var changeCount: Int = 0
    private var timer: Timer?
    private var history: [ClipboardItem] = []
    private let maxHistoryItems = 20
    private var isIgnoringChanges = false
    
    private init() {
        loadHistory()
        startMonitoring()
    }
    
    func startMonitoring() {
        changeCount = pasteboard.changeCount
        
        // Tạo timer để kiểm tra clipboard mỗi 0.5 giây
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    private func checkForChanges() {
        // Bỏ qua nếu đang ignore changes
        if isIgnoringChanges {
            changeCount = pasteboard.changeCount
            return
        }
        
        // Kiểm tra xem clipboard có thay đổi không
        if pasteboard.changeCount != changeCount {
            changeCount = pasteboard.changeCount
            
            // Lấy thông tin app đang active
            let (appName, bundleId) = getActiveApplication()
            
            // Kiểm tra file/folder TRƯỚC (ưu tiên cao nhất)
            if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL], !urls.isEmpty {
                let url = urls[0]
                // Kiểm tra xem là file hay folder
                var isDirectory: ObjCBool = false
                let fileExists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                
                if fileExists {
                    addToHistory(fileURL: url.path, fileName: url.lastPathComponent, isDirectory: isDirectory.boolValue, sourceAppName: appName, appBundleIdentifier: bundleId)
                }
            }
            // Kiểm tra ảnh
            else if let imageData = pasteboard.data(forType: .tiff) {
                addToHistory(imageData: imageData, sourceAppName: appName, appBundleIdentifier: bundleId)
            }
            // Cuối cùng mới check text
            else if let text = pasteboard.string(forType: .string), !text.isEmpty {
                // Lấy tất cả format data để giữ nguyên format
                let rtfData = pasteboard.data(forType: .rtf)
                let htmlData = pasteboard.data(forType: .html)
                addToHistory(text: text, rtfData: rtfData, htmlData: htmlData, sourceAppName: appName, appBundleIdentifier: bundleId)
            }
        }
    }
    
    func ignoreNextChange() {
        isIgnoringChanges = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isIgnoringChanges = false
        }
    }
    
    private func getActiveApplication() -> (name: String?, bundleId: String?) {
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            return (frontApp.localizedName, frontApp.bundleIdentifier)
        }
        return (nil, nil)
    }
    
    private func addToHistory(text: String, rtfData: Data? = nil, htmlData: Data? = nil, sourceAppName: String? = nil, appBundleIdentifier: String? = nil) {
        // Tạo một mục mới
        let newItem = ClipboardItem(text: text, rtfData: rtfData, htmlData: htmlData, timestamp: Date(), sourceAppName: sourceAppName, appBundleIdentifier: appBundleIdentifier)
        
        // Kiểm tra xem text đã tồn tại trong history chưa
        if !history.contains(where: { $0.text == text }) {
            // Thêm vào đầu danh sách
            history.insert(newItem, at: 0)
            
            // Giới hạn số lượng mục trong history
            if history.count > maxHistoryItems {
                history.removeLast()
            }
            
            // Lưu history vào UserDefaults
            saveHistory()
        }
    }
    
    private func addToHistory(imageData: Data, sourceAppName: String? = nil, appBundleIdentifier: String? = nil) {
        // Tạo một mục mới
        let newItem = ClipboardItem(imageData: imageData, timestamp: Date(), sourceAppName: sourceAppName, appBundleIdentifier: appBundleIdentifier)
        
        // Thêm vào đầu danh sách
        history.insert(newItem, at: 0)
        
        // Giới hạn số lượng mục trong history
        if history.count > maxHistoryItems {
            history.removeLast()
        }
        
        // Lưu history vào UserDefaults
        saveHistory()
    }
    
    private func addToHistory(fileURL: String, fileName: String, isDirectory: Bool, sourceAppName: String? = nil, appBundleIdentifier: String? = nil) {
        // Tạo một mục mới
        let newItem = ClipboardItem(fileURL: fileURL, fileName: fileName, isDirectory: isDirectory, timestamp: Date(), sourceAppName: sourceAppName, appBundleIdentifier: appBundleIdentifier)
        
        // Thêm vào đầu danh sách
        history.insert(newItem, at: 0)
        
        // Giới hạn số lượng mục trong history
        if history.count > maxHistoryItems {
            history.removeLast()
        }
        
        // Lưu history vào UserDefaults
        saveHistory()
    }
    
    private func saveHistory() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(history) {
            UserDefaults.standard.set(encoded, forKey: "clipboardHistory")
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "clipboardHistory"),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            history = decoded
        }
    }
    
    func getHistory() -> [ClipboardItem]? {
        // Sắp xếp: pinned items trước, sau đó theo timestamp
        return history.sorted { item1, item2 in
            if item1.isPinned != item2.isPinned {
                return item1.isPinned
            }
            return item1.timestamp > item2.timestamp
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        pasteboard.clearContents()
        
        switch item.type {
        case .text:
            if let text = item.text {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let imageData = item.imageData {
                pasteboard.setData(imageData, forType: .tiff)
            }
        case .file:
            if let urlString = item.fileURL, let url = URL(string: urlString) {
                pasteboard.writeObjects([url as NSPasteboardWriting])
            }
        }
    }
    
    func removeItem(_ item: ClipboardItem) {
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history.remove(at: index)
            saveHistory()
        }
    }
    
    func clearHistory() {
        history.removeAll(where: { !$0.isBookmarked })
        saveHistory()
    }
    
    func clearBookmarks() {
        for index in history.indices {
            history[index].isBookmarked = false
        }
        saveHistory()
    }
    
    func clearByType(_ type: ClipboardItemType) {
        history.removeAll(where: { $0.type == type && !$0.isBookmarked })
        saveHistory()
    }
    
    func toggleBookmark(_ item: ClipboardItem) {
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history[index].isBookmarked.toggle()
            saveHistory()
        }
    }
    
    func moveToTop(_ item: ClipboardItem) {
        // Tìm item trong history
        guard let index = history.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        
        // Nếu item đã ở đầu rồi thì không cần di chuyển
        if index == 0 {
            return
        }
        
        // Di chuyển item lên đầu
        let movedItem = history.remove(at: index)
        history.insert(movedItem, at: 0)
        saveHistory()
    }
    
    func togglePin(_ item: ClipboardItem) {
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history[index].isPinned.toggle()
            saveHistory()
        }
    }
} 