import SwiftUI
import Combine
import Foundation
import Carbon

class ShortcutViewModel: ObservableObject {
    @Published var isCapturing = false
    private var eventMonitor: Any?
    
    func startCaptureShortcut(completion: @escaping (String) -> Void) {
        isCapturing = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if self.isCapturing {
                let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                var shortcutString = ""
                
                if modifiers.contains(.command) { shortcutString += "⌘" }
                if modifiers.contains(.option) { shortcutString += "⌥" }
                if modifiers.contains(.control) { shortcutString += "⌃" }
                if modifiers.contains(.shift) { shortcutString += "⇧" }
                
                if event.type == .keyDown {
                    let key = event.charactersIgnoringModifiers?.uppercased() ?? ""
                    if !key.isEmpty {
                        shortcutString += key
                        completion(shortcutString)
                        self.stopCaptureShortcut()
                    }
                }
            }
            return nil
        }
    }
    
    func stopCaptureShortcut() {
        isCapturing = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

struct SettingsView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var localization = Localization.shared
    @StateObject private var shortcutViewModel = ShortcutViewModel()
    @State private var maxHistoryItems: Int
    @State private var selectedLanguage: Language
    
    init() {
        _maxHistoryItems = State(initialValue: Settings.shared.maxHistoryItems)
        _selectedLanguage = State(initialValue: Localization.shared.currentLanguage)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Phần phím tắt
            VStack(alignment: .leading, spacing: 10) {
                Text("Phím tắt")
                    .font(.headline)
                
                HStack {
                    Text("Mở lịch sử clipboard:")
                    Spacer()
                    Button(action: {
                        shortcutViewModel.startCaptureShortcut { newShortcut in
                            settings.shortcutString = newShortcut
                            settings.shortcutKey = newShortcut
                        }
                    }) {
                        Text(settings.shortcutString ?? "⌃V")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Phần ngôn ngữ
            VStack(alignment: .leading, spacing: 10) {
                Text("Ngôn ngữ")
                    .font(.headline)
                
                Picker("Ngôn ngữ:", selection: $selectedLanguage) {
                    Text("Tiếng Việt").tag(Language.vietnamese)
                    Text("English").tag(Language.english)
                }
                .onChange(of: selectedLanguage) { newValue in
                    localization.currentLanguage = newValue
                    NotificationCenter.default.post(name: .languageChanged, object: nil)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Phần lịch sử
            VStack(alignment: .leading, spacing: 10) {
                Text("Lịch sử")
                    .font(.headline)
                
                HStack {
                    Text("Số lượng mục tối đa:")
                    Spacer()
                    TextField("", value: $maxHistoryItems, formatter: NumberFormatter())
                        .frame(width: 60)
                        .onChange(of: maxHistoryItems) { newValue in
                            settings.maxHistoryItems = newValue
                        }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
        .frame(width: 400, height: 300)
        .onDisappear {
            shortcutViewModel.stopCaptureShortcut()
        }
    }
} 