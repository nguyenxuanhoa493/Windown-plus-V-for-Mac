# Windows + V For Mac

[English](README.md) · [Tiếng Việt](README.vi.md) · [Changelog](CHANGELOG.md)

A lightweight macOS menu-bar clipboard history manager with built-in JSON/Excel converter, smart filters, and 13 color themes.

![Clipboard UI](demo/main.png)

## Highlights

- **Multi-format clipboard**: text (with RTF/HTML), images, files & folders, URLs
- **JSON ↔ Table ↔ Excel (.xlsx)**: detect, flatten nested JSON, export native XLSX
- **Smart filters**: All / Text / Images / Files / Bookmarks
- **Search**: diacritic-insensitive, matches text + filename + source app
- **Item management**: pin, bookmark, per-item delete, drag & drop
- **Keyboard navigation**: ↑↓ select · ⏎ paste · ⌘1–9 quick paste · ESC close · type to search
- **Themes**: 13 color schemes (System, Light, Dark, Dracula, Nord, Solarized, Tokyo Night, Catppuccin, Gruvbox, Monokai, One Dark, GitHub, Rosé Pine)
- **Font customization**: System / Monospaced / Rounded / Serif, size 10–16pt
- **Native UI option**: compact list style with zebra striping + separator
- **Live preview**: Settings opens popup beside it for instant theme preview
- **Auto-paste**: simulates ⌘V on item selection
- **Auto-update**: checks GitHub releases, integrity-verified install
- **Languages**: English, Vietnamese
- **Launch at login** (macOS 13+)

## Requirements

- macOS 12.0 Monterey or later
- ~1 MB disk space
- Universal binary (Apple Silicon + Intel)

## Install

1. Download `Clipboard-3.4.dmg` from [Releases](https://github.com/nguyenxuanhoa493/Windows-plus-V-for-Mac/releases)
2. Open the DMG → drag **Clipboard** into **Applications**
3. Remove quarantine attribute (one-time):
   ```bash
   xattr -cr /Applications/Clipboard.app
   ```
4. Launch from Launchpad → click "Open" if macOS warns about unsigned source
5. Grant **Accessibility** permission (required for auto-paste):
   System Settings → Privacy & Security → Accessibility → enable Clipboard
6. Restart the app

![Permission grant UI](demo/image_2.png)

## Usage

- **Open clipboard popup**: `⌃V` (configurable in Settings → General → Shortcut)
- **Quick paste**: `⌘1`..`⌘9` to paste item by index
- **Drag image/file**: drag from row to Finder, Slack, etc.
- **Right-click row**: full context menu (Copy, Save, Pin, Bookmark, Convert, Delete)

## Contact

- GitHub: [nguyenxuanhoa493/Windows-plus-V-for-Mac](https://github.com/nguyenxuanhoa493/Windows-plus-V-for-Mac)
- Telegram: [@xuanhoa493](https://t.me/xuanhoa493)
- Email: nguyenxuanhoa493@gmail.com

If this app helps you, consider [buying me a coffee ☕](Sources/Resources/cafe.jpg)
