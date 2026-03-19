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
    @ObservedObject private var updateManager = UpdateManager.shared
    @State private var maxHistoryText: String
    @State private var selectedLanguage: Language
    @State private var selectedTheme: ThemeMode
    @State private var autoCheckForUpdates: Bool
    
    init() {
        _maxHistoryText = State(initialValue: String(Settings.shared.maxHistoryItems))
        _selectedLanguage = State(initialValue: Localization.shared.currentLanguage)
        _selectedTheme = State(initialValue: Settings.shared.themeMode)
        _autoCheckForUpdates = State(initialValue: Settings.shared.autoCheckForUpdates)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // Language & Appearance row
                    HStack(spacing: 12) {
                        settingsCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(localization.localizedString("language"), systemImage: "globe")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 6) {
                                    languageButton(
                                        flag: "🇻🇳",
                                        label: "VI",
                                        language: .vietnamese
                                    )
                                    languageButton(
                                        flag: "🇺🇸",
                                        label: "EN",
                                        language: .english
                                    )
                                }
                            }
                        }
                        
                        settingsCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(localization.localizedString("appearance"), systemImage: "paintbrush")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 6) {
                                    themeButton(icon: "desktopcomputer", mode: .system)
                                    themeButton(icon: "sun.max.fill", mode: .light)
                                    themeButton(icon: "moon.fill", mode: .dark)
                                }
                            }
                        }
                    }
                    
                    // Shortcut
                    settingsCard {
                        HStack {
                            Label(localization.localizedString("shortcut"), systemImage: "keyboard")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                shortcutViewModel.startCaptureShortcut { newShortcut in
                                    settings.shortcutString = newShortcut
                                    settings.shortcutKey = newShortcut
                                }
                            }) {
                                Text(shortcutViewModel.isCapturing ? "..." : (settings.shortcutString ?? "⌃V"))
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.accentColor.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // History
                    settingsCard {
                        HStack {
                            Label(localization.localizedString("history"), systemImage: "clock.arrow.circlepath")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text(localization.localizedString("max_history_items") + ":")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                TextField("", text: $maxHistoryText)
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .multilineTextAlignment(.center)
                                    .frame(width: 50)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit {
                                        if let value = Int(maxHistoryText), value > 0 {
                                            settings.maxHistoryItems = value
                                        } else {
                                            maxHistoryText = String(settings.maxHistoryItems)
                                        }
                                    }
                            }
                        }
                    }
                    
                    // Updates
                    settingsCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label(localization.localizedString("check_for_updates"), systemImage: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("v\(updateManager.currentVersion)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.secondary.opacity(0.1))
                                    )
                            }
                            
                            HStack(spacing: 8) {
                                Toggle(localization.localizedString("update_auto_check"), isOn: $autoCheckForUpdates)
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                                    .font(.system(size: 12))
                                    .onChange(of: autoCheckForUpdates) { newValue in
                                        settings.autoCheckForUpdates = newValue
                                    }
                                
                                Spacer()
                                
                                if updateManager.isChecking {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                } else if updateManager.isDownloading {
                                    ProgressView(value: updateManager.downloadProgress)
                                        .frame(width: 80)
                                } else {
                                    Button(action: { updateManager.checkForUpdates() }) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 11))
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            
                            if updateManager.updateAvailable, let version = updateManager.latestVersion {
                                HStack {
                                    Text("🎉 \(String(format: localization.localizedString("update_new_version"), version, updateManager.currentVersion))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.green)
                                    Spacer()
                                    Button(localization.localizedString("update_download")) {
                                        updateManager.downloadAndInstall()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                            }
                            
                            if let error = updateManager.updateError {
                                Text(error)
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 380, height: 400)
        .onDisappear {
            shortcutViewModel.stopCaptureShortcut()
        }
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 0.5)
            )
    }
    
    private func languageButton(flag: String, label: String, language: Language) -> some View {
        Button(action: {
            selectedLanguage = language
            localization.currentLanguage = language
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }) {
            HStack(spacing: 4) {
                Text(flag)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedLanguage == language ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(selectedLanguage == language ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: selectedLanguage == language ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func themeButton(icon: String, mode: ThemeMode) -> some View {
        Button(action: {
            selectedTheme = mode
            settings.themeMode = mode
        }) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .frame(width: 28, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedTheme == mode ? Color.accentColor.opacity(0.15) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(selectedTheme == mode ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: selectedTheme == mode ? 1.5 : 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}
