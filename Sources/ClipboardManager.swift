import Cocoa

class ClipboardManager {
    static let shared = ClipboardManager()
    
    private let pasteboard = NSPasteboard.general
    private var changeCount: Int = 0
    private var timer: Timer?
    private var history: [ClipboardItem] = []
    private let maxHistoryItems = 20
    
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
        // Kiểm tra xem clipboard có thay đổi không
        if pasteboard.changeCount != changeCount {
            changeCount = pasteboard.changeCount
            
            // Kiểm tra ảnh trước
            if let imageData = pasteboard.data(forType: .tiff) {
                addToHistory(imageData: imageData)
            }
            // Nếu không có ảnh, kiểm tra text
            else if let text = pasteboard.string(forType: .string) {
                addToHistory(text: text)
            }
        }
    }
    
    private func addToHistory(text: String) {
        // Tạo một mục mới
        let newItem = ClipboardItem(text: text, timestamp: Date())
        
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
    
    private func addToHistory(imageData: Data) {
        // Tạo một mục mới
        let newItem = ClipboardItem(imageData: imageData, timestamp: Date())
        
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
        return history
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
        }
    }
    
    func removeItem(_ item: ClipboardItem) {
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history.remove(at: index)
            saveHistory()
        }
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    func moveToTop(_ item: ClipboardItem) {
        // Tạo một bản sao mới của item với timestamp mới
        let newItem: ClipboardItem
        if let text = item.text {
            newItem = ClipboardItem(text: text, timestamp: Date())
        } else if let imageData = item.imageData {
            newItem = ClipboardItem(imageData: imageData, timestamp: Date())
        } else {
            return
        }
        
        // Xóa item cũ nếu có
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history.remove(at: index)
        }
        
        // Thêm item mới vào đầu danh sách
        history.insert(newItem, at: 0)
        saveHistory()
    }
} 