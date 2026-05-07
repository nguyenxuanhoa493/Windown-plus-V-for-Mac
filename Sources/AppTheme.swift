import SwiftUI
import AppKit

/// Bộ màu áp dụng cho toàn bộ UI app:
/// - **preferredAppearance**: ép light/dark mode (override Settings.themeMode trừ khi theme = .system)
/// - **accent**: màu nhấn cho buttons, selection, badges (qua SwiftUI `.tint()`)
/// - **background**: signature window background (override .windowBackgroundColor)
/// - **surface**: signature row/card background (override .controlBackgroundColor cho item rows)
/// - **foreground**: text color chính (nil = dùng .primary)
/// Tham khảo: https://draculatheme.com, https://nordtheme.com, https://ethanschoonover.com/solarized/
enum AppTheme: String, CaseIterable, Codable {
    case system
    case light
    case dark
    case dracula
    case nord
    case solarized
    case tokyoNight = "tokyo_night"
    case catppuccin
    case gruvbox
    case monokai
    case oneDark = "one_dark"
    case github
    case rosePine = "rose_pine"

    var displayName: String {
        switch self {
        case .system: return Localization.shared.localizedString("theme_system")
        case .light: return Localization.shared.localizedString("theme_light")
        case .dark: return Localization.shared.localizedString("theme_dark")
        case .dracula: return "Dracula"
        case .nord: return "Nord"
        case .solarized: return "Solarized"
        case .tokyoNight: return "Tokyo Night"
        case .catppuccin: return "Catppuccin"
        case .gruvbox: return "Gruvbox"
        case .monokai: return "Monokai"
        case .oneDark: return "One Dark"
        case .github: return "GitHub"
        case .rosePine: return "Rosé Pine"
        }
    }

    /// `nil` = follow system appearance; `.aqua` / `.darkAqua` = ép cứng.
    var preferredAppearance: NSAppearance.Name? {
        switch self {
        case .system: return nil
        case .light: return .aqua
        case .dark: return .darkAqua
        case .dracula, .nord, .tokyoNight, .catppuccin, .monokai, .oneDark, .rosePine: return .darkAqua
        case .solarized, .gruvbox: return .darkAqua
        case .github: return .aqua
        }
    }

    /// `nil` = dùng accent của hệ thống.
    var accent: Color? {
        switch self {
        case .system, .light, .dark: return nil
        case .dracula: return Color(red: 0.74, green: 0.58, blue: 0.98)        // #BD93F9 purple
        case .nord: return Color(red: 0.53, green: 0.75, blue: 0.82)            // #88C0D0 frost
        case .solarized: return Color(red: 0.16, green: 0.63, blue: 0.60)       // #2AA198 cyan
        case .tokyoNight: return Color(red: 0.49, green: 0.62, blue: 0.97)      // #7AA2F7 blue
        case .catppuccin: return Color(red: 0.80, green: 0.65, blue: 0.97)      // #CBA6F7 mauve
        case .gruvbox: return Color(red: 0.98, green: 0.74, blue: 0.18)         // #FABD2F yellow
        case .monokai: return Color(red: 0.65, green: 0.89, blue: 0.18)         // #A6E22E green
        case .oneDark: return Color(red: 0.38, green: 0.69, blue: 0.94)         // #61AFEF blue
        case .github: return Color(red: 0.04, green: 0.41, blue: 0.85)          // #0969DA blue
        case .rosePine: return Color(red: 0.92, green: 0.78, blue: 0.78)        // #EBBCBA pink
        }
    }

    /// Signature background của popup window. `nil` = dùng `.windowBackgroundColor` hệ thống.
    var background: Color? {
        switch self {
        case .system, .light, .dark: return nil
        case .dracula: return Color(red: 0.16, green: 0.16, blue: 0.21)         // #282A36
        case .nord: return Color(red: 0.18, green: 0.20, blue: 0.25)            // #2E3440
        case .solarized: return Color(red: 0.00, green: 0.17, blue: 0.21)       // #002B36
        case .tokyoNight: return Color(red: 0.10, green: 0.11, blue: 0.18)      // #1A1B26
        case .catppuccin: return Color(red: 0.12, green: 0.12, blue: 0.18)      // #1E1E2E
        case .gruvbox: return Color(red: 0.16, green: 0.16, blue: 0.16)         // #282828
        case .monokai: return Color(red: 0.15, green: 0.16, blue: 0.13)         // #272822
        case .oneDark: return Color(red: 0.16, green: 0.18, blue: 0.21)         // #282C34
        case .github: return Color(red: 1.00, green: 1.00, blue: 1.00)          // #FFFFFF
        case .rosePine: return Color(red: 0.10, green: 0.09, blue: 0.13)        // #191724
        }
    }

    /// Surface (row/card) — sáng/đậm hơn background 1 bậc.
    var surface: Color? {
        switch self {
        case .system, .light, .dark: return nil
        case .dracula: return Color(red: 0.27, green: 0.28, blue: 0.35)         // #44475A
        case .nord: return Color(red: 0.23, green: 0.26, blue: 0.32)            // #3B4252
        case .solarized: return Color(red: 0.03, green: 0.21, blue: 0.26)       // #073642
        case .tokyoNight: return Color(red: 0.15, green: 0.16, blue: 0.23)      // #24283B
        case .catppuccin: return Color(red: 0.19, green: 0.20, blue: 0.27)      // #313244
        case .gruvbox: return Color(red: 0.24, green: 0.22, blue: 0.21)         // #3C3836
        case .monokai: return Color(red: 0.23, green: 0.24, blue: 0.20)         // #3E3D32
        case .oneDark: return Color(red: 0.20, green: 0.22, blue: 0.25)         // #353B45
        case .github: return Color(red: 0.95, green: 0.95, blue: 0.96)          // #F6F8FA
        case .rosePine: return Color(red: 0.16, green: 0.14, blue: 0.20)        // #26233A
        }
    }

    /// Text color chính. `nil` = dùng `.primary`.
    var foreground: Color? {
        switch self {
        case .system, .light, .dark: return nil
        case .dracula: return Color(red: 0.97, green: 0.97, blue: 0.95)         // #F8F8F2
        case .nord: return Color(red: 0.93, green: 0.94, blue: 0.95)            // #ECEFF4
        case .solarized: return Color(red: 0.51, green: 0.58, blue: 0.59)       // #839496
        case .tokyoNight: return Color(red: 0.78, green: 0.84, blue: 0.97)      // #C0CAF5
        case .catppuccin: return Color(red: 0.80, green: 0.84, blue: 0.96)      // #CDD6F4
        case .gruvbox: return Color(red: 0.92, green: 0.86, blue: 0.70)         // #EBDBB2
        case .monokai: return Color(red: 0.97, green: 0.97, blue: 0.95)         // #F8F8F2
        case .oneDark: return Color(red: 0.67, green: 0.71, blue: 0.78)         // #ABB2BF
        case .github: return Color(red: 0.13, green: 0.16, blue: 0.20)          // #24292F
        case .rosePine: return Color(red: 0.89, green: 0.86, blue: 0.84)        // #E0DEF4
        }
    }

    /// Màu hiển thị trong picker swatch.
    var swatchColor: Color {
        switch self {
        case .system: return .accentColor
        case .light: return Color(red: 0.96, green: 0.96, blue: 0.97)  // off-white
        case .dark: return Color(red: 0.16, green: 0.16, blue: 0.18)   // off-black
        default: return accent ?? .accentColor
        }
    }
}

/// Apply theme cho subtree: tint accent + override background nếu có.
struct ThemeModifier: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        let tinted: AnyView = {
            if let accent = theme.accent {
                return AnyView(content.tint(accent))
            }
            return AnyView(content)
        }()
        if let bg = theme.background {
            return AnyView(tinted.background(bg))
        }
        return AnyView(tinted)
    }
}

extension View {
    func appThemed(_ theme: AppTheme) -> some View {
        modifier(ThemeModifier(theme: theme))
    }
}

/// Apply theme chỉ khi `active = true`. Khi false → không tint, không override → dùng system colors.
struct ConditionalThemeModifier: ViewModifier {
    let theme: AppTheme
    let active: Bool

    func body(content: Content) -> some View {
        if active, let accent = theme.accent {
            content.tint(accent)
        } else {
            content
        }
    }
}
