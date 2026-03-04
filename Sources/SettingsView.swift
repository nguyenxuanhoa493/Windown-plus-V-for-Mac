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
    @State private var selectedTheme: ThemeMode
    
    init() {
        _maxHistoryItems = State(initialValue: Settings.shared.maxHistoryItems)
        _selectedLanguage = State(initialValue: Localization.shared.currentLanguage)
        _selectedTheme = State(initialValue: Settings.shared.themeMode)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Phần phím tắt
            VStack(alignment: .leading, spacing: 10) {
                Text(localization.localizedString("shortcut"))
                    .font(.headline)
                
                HStack {
                    Text(localization.localizedString("open_clipboard_history"))
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
                Text(localization.localizedString("language"))
                    .font(.headline)
                
                Picker(localization.localizedString("language") + ":", selection: $selectedLanguage) {
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
            
            // Phần giao diện
            VStack(alignment: .leading, spacing: 10) {
                Text(localization.localizedString("appearance"))
                    .font(.headline)
                
                Picker(localization.localizedString("theme"), selection: $selectedTheme) {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        Text(localization.localizedString("theme_\(mode.rawValue)")).tag(mode)
                    }
                }
                .onChange(of: selectedTheme) { newValue in
                    settings.themeMode = newValue
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Phần lịch sử
            VStack(alignment: .leading, spacing: 10) {
                Text(localization.localizedString("history"))
                    .font(.headline)
                
                HStack {
                    Text(localization.localizedString("max_history_items") + ":")
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
        .frame(width: 400, height: 400)
        .onDisappear {
            shortcutViewModel.stopCaptureShortcut()
        }
    }
} 