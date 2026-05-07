# Changelog

[English](CHANGELOG.md) · [Tiếng Việt](CHANGELOG.vi.md)

All notable changes to **Windows + V For Mac**.

## 3.4 — Latest

### 🐛 Fixes
- Filter buttons (Text / Image / File / Bookmark) now update the list immediately when clicked — previously a gesture conflict on the parent HStack swallowed the tap and required clicking Bookmark first to "unlock" filtering
- Removed redundant `.id(index)` view modifier inside ForEach — was conflicting with `id: \.element.id`, causing SwiftUI diffing to skip updates when filter changed
- Drag-to-move window scope narrowed: gesture only attached to the empty Spacer between filters and search, so filter/search buttons receive clicks reliably

### Carry-over from 3.3
All 3.3 features remain (theming, sidebar settings, font customization, info tab, drag image, launch at login, hover effects, ...).

---

## 3.3

### 🎨 Theming overhaul
- **13 color themes**: System, Light, Dark, Dracula, Nord, Solarized, Tokyo Night, Catppuccin, Gruvbox, Monokai, One Dark, GitHub, Rosé Pine
- Custom themes override window background, titlebar, row surface, foreground text, accent color, and selection/hover state
- Live preview popup beside Settings — see theme/font changes in real time
- Theme persists across all windows (popup, Settings, Accessibility prompt)

### ⚙️ Settings redesign
- **Vertical sidebar** (replaces top tabs): General · Appearance · Features · Info
- Removed standalone "Contact" + "Buy me a coffee" menu items → consolidated into **Info** tab
- New Info tab includes author, GitHub link, Telegram, Buy-me-coffee QR
- **Launch at login** toggle (macOS 13+ via SMAppService)
- Font customization: System / Monospaced / Rounded / Serif, size 10–16pt (default 13)
- Custom theme picker shows when Appearance = Custom

### 📋 Popup UX
- More menu (⚙ icon) moved from top filter bar to bottom hint bar — cleaner top
- Bottom hint bar shows shortcut cheatsheet: `↑↓ Navigate · ⏎ Paste · ⌘1-9 Quick paste`
- Open image item directly in Preview app (right-click → Open, or hover action button)
- Drag image item to Finder/Slack/etc. — exports as PNG temp file
- Auto-hide popup after drag (toggle in Features)
- Native UI list mode with zebra striping + separator (toggle in Appearance, default off)

### 🐛 Fixes
- Search field can now receive Delete/Backspace while typing
- Drag popup window now works in cursor mode (was broken when level filter mismatched)
- Tooltip on icon buttons no longer hidden behind first row
- Settings tab no longer resets to General when changing theme
- Tops of Settings + popup now align when Settings is open
- Hover/selected row colors now use theme accent (no longer stuck blue)
- Image preview QR loads correctly in dev build (`Bundle.module` fallback)

### Carry-over from 3.2
Includes everything shipped in 3.2: Features tab toggles, Cmd+1..9 shortcuts, smart cursor positioning, ESC closes popup, empty state UI, async image thumbnail load, async Excel export, NSCache for icons, image SHA256 dedup, JSON corruption backup, update integrity verification, read-only volume detection, password-storage privacy disclaimer.

---

## 3.2

### Features
- New "Features" tab in Settings to toggle individual features:
  Move-to-top after paste · JSON→Table · JSON→Excel · Table→JSON · Open URL in browser · Timestamp converter · Search · Drag-and-drop
- Settings organized into "General" and "Features" tabs

### Improvements
- Smart popup positioning: appears bottom-right of cursor, clamps to screen on multi-monitor setups
- ESC closes popup
- Empty state UI for empty history / no search results
- Search now matches filenames and source app names too
- Async + downsampled image thumbnails — no more UI freeze with 4K screenshots
- Excel export runs in background queue
- Icon cache uses `NSCache` (auto-evicts under memory pressure)
- Extended hotkey support (F1–F20, arrows, Space)
- Auto-detect when Accessibility permission is revoked at runtime

### Keyboard shortcuts in popup
- `↑/↓` navigate · `⏎` paste · `Delete` remove · `ESC` close · type to instant-search

### Fixes
- Auto-update preserves Accessibility permission (no more `_CodeSignature` deletion)
- Update zip integrity check (Content-Length + magic bytes)
- Read-only volume detection (DMG mounted → warn before download)
- Atomic update check guard (manual + auto no longer race)
- Cancel button on update download
- JSON corruption backup before reset
- Orphan image cleanup on launch
- SHA256-based image dedup
- Cache directory `chmod 700`
- Keyboard monitor leak fixed
- Drag popup clamped to screen
- NSImage copy-on-mutation
- Privacy disclaimer in Features tab

---

## 3.1
- Fixed permission grant notification

## 3.0
- Universal Binary (Apple Silicon + Intel)
- Wider macOS compatibility (12 Monterey+)

## 2.9
- Excel ↔ JSON two-way conversion
- Paste-as-image for tabular data
- Save image from clipboard
- Preserve format when copying (RTF/HTML/TSV)
- Source app icon + name display
- Sorted history cache, debounced save, optimized RAM (image-on-disk)
- Diacritic-insensitive Vietnamese search

## 2.1
- Native XLSX export (libxlsxwriter)
- Flatten nested JSON to flat columns
- Search field UI improvements (accent border, auto-focus, CapsLock fix)

## 2.0
- JSON converter + Excel CSV export
- Search field UX improvements
- Unified icon sizing (14px)

## 1.9
- Memory optimization
- Performance improvements

## 1.6
- File & folder support (real macOS icons, image preview, drag-drop, open, copy path)
- 5 filters (All / Text / Image / File / Bookmark)
- Pin, Bookmark, per-item delete
- Timestamp converter
- URL detection
- Full context menu, tooltips

## 1.5
- Clear by type
- Improved timestamp display

## 1.4
- Auto-paste on selection
- Move-to-top after use

## 1.3
- Clear-all button
- Auto-hide on click outside
