import Cocoa
import CryptoKit

class ClipboardManager {
    static let shared = ClipboardManager()
    
    private let pasteboard = NSPasteboard.general
    private var changeCount: Int = 0
    private var timer: Timer?
    private var history: [ClipboardItem] = []
    private var maxHistoryItems: Int { Settings.shared.maxHistoryItems }
    private var isIgnoringChanges = false
    
    // URL bất biến → thread-safe khi đọc từ background queue (loadImageFromDisk).
    // Khởi tạo trong init() trước khi expose self ra Timer/background.
    private let imageCacheDirectory: URL = {
        let baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let cacheDir = baseURL.appendingPathComponent("ClipboardImages")
        if !FileManager.default.fileExists(atPath: cacheDir.path) {
            try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700])
        } else {
            // Đảm bảo permission không bị nới lỏng (file ảnh có thể chứa dữ liệu nhạy cảm)
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: cacheDir.path)
        }
        return cacheDir
    }()
    
    private init() {
        loadHistory()
        startMonitoring()
        // Dọn ảnh mồ côi sau 2s khi launch — không chặn UI, không race với khởi tạo.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.cleanupOrphanedImages()
        }
    }

    /// MUST be called on main thread (đọc history). Tự dispatch I/O ra background.
    private func cleanupOrphanedImages() {
        assert(Thread.isMainThread, "cleanupOrphanedImages phải chạy trên main thread để đọc history an toàn")
        // Snapshot trên main
        let referencedNames = Set(history.compactMap { $0.imageFileName })
        let cacheDir = imageCacheDirectory
        // Disk I/O ra background
        DispatchQueue.global(qos: .utility).async {
            guard let files = try? FileManager.default.contentsOfDirectory(atPath: cacheDir.path) else {
                return
            }
            var removed = 0
            for fileName in files where !referencedNames.contains(fileName) {
                let url = cacheDir.appendingPathComponent(fileName)
                if (try? FileManager.default.removeItem(at: url)) != nil {
                    removed += 1
                }
            }
            if removed > 0 {
                print("DEBUG: Đã dọn \(removed) ảnh mồ côi trong cache")
            }
        }
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
    
    /// Lưu ảnh ra disk dùng SHA256 làm filename → 2 lần copy cùng ảnh sẽ reuse cùng 1 file.
    func saveImageToDisk(_ imageData: Data) -> String? {
        let hash = SHA256.hash(data: imageData).map { String(format: "%02x", $0) }.joined()
        let fileName = hash + ".tiff"
        let fileURL = imageCacheDirectory.appendingPathComponent(fileName)
        // Đã có file (cùng nội dung) — không cần ghi lại
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileName
        }
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

    /// Xoá ảnh nếu KHÔNG còn item nào khác trong history reference cùng fileName.
    /// Tránh xoá nhầm file đang được nhiều item dùng chung (sau khi dedup theo hash).
    func deleteImageFromDisk(_ fileName: String?) {
        guard let fileName = fileName else { return }
        // Có thể được gọi giữa lúc đang remove item — kiểm tra trên history mới nhất
        let stillReferenced = history.contains { $0.imageFileName == fileName }
        if stillReferenced { return }
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
            // Capture fileName trước, remove khỏi history, rồi delete (refcount check trong delete)
            let fileName = history[idx].imageFileName
            history.remove(at: idx)
            deleteImageFromDisk(fileName)
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
                let oldFileName = existing.imageFileName
                history.remove(at: existingIndex)
                history.insert(newItem, at: 0)
                deleteImageFromDisk(oldFileName)
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
        guard let data = UserDefaults.standard.data(forKey: "clipboardHistory") else {
            return
        }
        do {
            history = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            // JSON corrupt — backup data trước khi reset để có thể recover thủ công
            print("DEBUG: clipboardHistory JSON bị hỏng (\(error)), backup và reset")
            let timestamp = Int(Date().timeIntervalSince1970)
            let backupURL = imageCacheDirectory
                .deletingLastPathComponent()
                .appendingPathComponent("clipboardHistory.corrupt-\(timestamp).json")
            try? data.write(to: backupURL)
            UserDefaults.standard.removeObject(forKey: "clipboardHistory")
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
            let fileName = history[index].imageFileName
            history.remove(at: index)
            deleteImageFromDisk(fileName)
            saveHistory()
        }
    }

    func clearHistory(includePinned: Bool = false, includeBookmarked: Bool = false) {
        let predicate: (ClipboardItem) -> Bool = { item in
            if !includePinned && item.isPinned { return false }
            if !includeBookmarked && item.isBookmarked { return false }
            return true
        }
        // Capture filenames trước khi remove khỏi history (để refcount check sau)
        let removedFileNames = history.filter(predicate).compactMap { $0.imageFileName }
        history.removeAll(where: predicate)
        for fileName in Set(removedFileNames) {
            deleteImageFromDisk(fileName)
        }
        saveHistory()
    }
    
    func clearBookmarks() {
        for index in history.indices {
            history[index].isBookmarked = false
        }
        saveHistory()
    }
    
    func clearByType(_ type: ClipboardItemType) {
        let removedFileNames = history
            .filter { $0.type == type && !$0.isBookmarked && !$0.isPinned }
            .compactMap { $0.imageFileName }
        history.removeAll(where: { $0.type == type && !$0.isBookmarked && !$0.isPinned })
        for fileName in Set(removedFileNames) {
            deleteImageFromDisk(fileName)
        }
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