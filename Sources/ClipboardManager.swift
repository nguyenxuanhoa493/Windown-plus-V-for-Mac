import Cocoa

class ClipboardManager {
    static let shared = ClipboardManager()
    
    private let pasteboard = NSPasteboard.general
    private var changeCount: Int = 0
    private var timer: Timer?
    private var history: [ClipboardItem] = []
    private var maxHistoryItems: Int { Settings.shared.maxHistoryItems }
    private var isIgnoringChanges = false
    
    private lazy var imageCacheDirectory: URL = {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ClipboardImages")
        if !FileManager.default.fileExists(atPath: cacheDir.path) {
            try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
        return cacheDir
    }()
    
    private init() {
        loadHistory()
        startMonitoring()
    }
    
    func startMonitoring() {
        changeCount = pasteboard.changeCount
        
        timer?.invalidate()
        let newTimer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
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
            // Kiểm tra text TRƯỚC image (để Excel data được lưu dưới dạng text, không phải image)
            else if let text = pasteboard.string(forType: .string), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // Lấy tất cả format data để giữ nguyên format
                let rtfData = pasteboard.data(forType: .rtf)
                let htmlData = pasteboard.data(forType: .html)
                // Check if there's also an image (for Excel copy)
                let imageData = pasteboard.data(forType: .tiff)
                addToHistory(text: text, rtfData: rtfData, htmlData: htmlData, imageData: imageData, sourceAppName: appName, appBundleIdentifier: bundleId)
            }
            // Cuối cùng mới check ảnh
            else if let imageData = pasteboard.data(forType: .tiff) {
                addToHistory(imageData: imageData, sourceAppName: appName, appBundleIdentifier: bundleId)
            }
        }
    }
    
    func ignoreNextChange() {
        isIgnoringChanges = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isIgnoringChanges = false
        }
    }
    
    func saveImageToDisk(_ imageData: Data) -> String? {
        let fileName = UUID().uuidString + ".tiff"
        let fileURL = imageCacheDirectory.appendingPathComponent(fileName)
        do {
            try imageData.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving image to disk: \(error)")
            return nil
        }
    }
    
    func loadImageFromDisk(_ fileName: String) -> Data? {
        let fileURL = imageCacheDirectory.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }
    
    func deleteImageFromDisk(_ fileName: String?) {
        guard let fileName = fileName else { return }
        let fileURL = imageCacheDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    private func getActiveApplication() -> (name: String?, bundleId: String?) {
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            return (frontApp.localizedName, frontApp.bundleIdentifier)
        }
        return (nil, nil)
    }
    
    private func removeOldestNonBookmarkedIfNeeded() {
        while history.count > maxHistoryItems {
            // Tìm item non-protected cũ nhất (cuối mảng) để xóa
            var oldestIndex: Int? = nil
            for i in stride(from: history.count - 1, through: 0, by: -1) {
                if !history[i].isBookmarked && !history[i].isPinned {
                    oldestIndex = i
                    break
                }
            }
            
            guard let idx = oldestIndex else { break }
            deleteImageFromDisk(history[idx].imageFileName)
            history.remove(at: idx)
        }
    }
    
    private func addToHistory(text: String, rtfData: Data? = nil, htmlData: Data? = nil, imageData: Data? = nil, sourceAppName: String? = nil, appBundleIdentifier: String? = nil) {
        var imageFileName: String? = nil
        if let imageData = imageData {
            imageFileName = saveImageToDisk(imageData)
        }
        let newItem = ClipboardItem(text: text, rtfData: rtfData, htmlData: htmlData, imageFileName: imageFileName, timestamp: Date(), sourceAppName: sourceAppName, appBundleIdentifier: appBundleIdentifier)
        
        if let existingIndex = history.firstIndex(where: { $0.text == text }) {
            let existing = history[existingIndex]
            if !existing.isPinned {
                deleteImageFromDisk(existing.imageFileName)
                history.remove(at: existingIndex)
                history.insert(newItem, at: 0)
                removeOldestNonBookmarkedIfNeeded()
                saveHistory()
            }
        } else {
            history.insert(newItem, at: 0)
            removeOldestNonBookmarkedIfNeeded()
            saveHistory()
        }
    }
    
    private func addToHistory(imageData: Data, sourceAppName: String? = nil, appBundleIdentifier: String? = nil) {
        guard let imageFileName = saveImageToDisk(imageData) else { return }
        let newItem = ClipboardItem(imageFileName: imageFileName, timestamp: Date(), sourceAppName: sourceAppName, appBundleIdentifier: appBundleIdentifier)
        
        // Thêm vào đầu danh sách
        history.insert(newItem, at: 0)
        
        // Giới hạn số lượng mục trong history, nhưng giữ lại các item đã bookmark
        removeOldestNonBookmarkedIfNeeded()
        
        // Lưu history vào UserDefaults
        saveHistory()
    }
    
    private func addToHistory(fileURL: String, fileName: String, isDirectory: Bool, sourceAppName: String? = nil, appBundleIdentifier: String? = nil) {
        // Tạo một mục mới
        let newItem = ClipboardItem(fileURL: fileURL, fileName: fileName, isDirectory: isDirectory, timestamp: Date(), sourceAppName: sourceAppName, appBundleIdentifier: appBundleIdentifier)
        
        // Thêm vào đầu danh sách
        history.insert(newItem, at: 0)
        
        // Giới hạn số lượng mục trong history, nhưng giữ lại các item đã bookmark
        removeOldestNonBookmarkedIfNeeded()
        
        // Lưu history vào UserDefaults
        saveHistory()
    }
    
    private var saveWorkItem: DispatchWorkItem?
    
    private func saveHistory() {
        invalidateSortCache()
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(self.history) {
                UserDefaults.standard.set(encoded, forKey: "clipboardHistory")
            }
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "clipboardHistory"),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            history = decoded
        }
    }
    
    private var sortedHistoryCache: [ClipboardItem]?
    
    func getHistory() -> [ClipboardItem]? {
        if let cached = sortedHistoryCache {
            return cached
        }
        let sorted = history.sorted { item1, item2 in
            if item1.isPinned != item2.isPinned {
                return item1.isPinned
            }
            return item1.timestamp > item2.timestamp
        }
        sortedHistoryCache = sorted
        return sorted
    }
    
    private func invalidateSortCache() {
        sortedHistoryCache = nil
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        pasteboard.clearContents()
        
        switch item.type {
        case .text:
            if let text = item.text {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let fileName = item.imageFileName, let imageData = loadImageFromDisk(fileName) {
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
            deleteImageFromDisk(history[index].imageFileName)
            history.remove(at: index)
            saveHistory()
        }
    }
    
    func clearHistory() {
        for item in history where !item.isBookmarked && !item.isPinned {
            deleteImageFromDisk(item.imageFileName)
        }
        history.removeAll(where: { !$0.isBookmarked && !$0.isPinned })
        saveHistory()
    }
    
    func clearBookmarks() {
        for index in history.indices {
            history[index].isBookmarked = false
        }
        saveHistory()
    }
    
    func clearByType(_ type: ClipboardItemType) {
        for item in history where item.type == type && !item.isBookmarked && !item.isPinned {
            deleteImageFromDisk(item.imageFileName)
        }
        history.removeAll(where: { $0.type == type && !$0.isBookmarked && !$0.isPinned })
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
        
        // Di chuyển item lên đầu và cập nhật timestamp
        var movedItem = history.remove(at: index)
        movedItem.timestamp = Date()
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