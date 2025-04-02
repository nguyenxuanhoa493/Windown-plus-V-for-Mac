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
} 