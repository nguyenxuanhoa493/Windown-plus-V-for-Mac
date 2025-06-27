import SwiftUI
import Cocoa

struct ClipboardHistoryView: View {
    let items: [ClipboardItem]
    let onItemSelected: (ClipboardItem) -> Void
    let onClearAll: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Lịch sử Clipboard")
                    .font(.headline)
                    .padding(.leading)
                
                Spacer()
                
                if !items.isEmpty {
                    Button(action: onClearAll) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Xóa toàn bộ lịch sử")
                }
            }
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor))
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(items) { item in
                        ClipboardItemView(item: item)
                            .onTapGesture {
                                onItemSelected(item)
                            }
                            .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
        .frame(width: 300, height: 450)
        .background(Color(.windowBackgroundColor))
    }
}

struct ClipboardItemView: View {
    let item: ClipboardItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if item.type == .image, let imageData = item.imageData,
               let image = NSImage(data: imageData) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
            } else if let text = item.text {
                Text(text)
                    .lineLimit(3)
                    .font(.system(size: 14))
            }
            
            Text(item.timeString)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .contentShape(Rectangle())
    }
} 