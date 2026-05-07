# Windows + V For Mac

[English](README.md) · [Tiếng Việt](README.vi.md) · [Changelog](CHANGELOG.vi.md)

Trình quản lý lịch sử clipboard menu-bar gọn nhẹ cho macOS, kèm bộ chuyển JSON/Excel, bộ lọc thông minh và 13 bộ màu theme.

![Giao diện](demo/main.png)

## Điểm nổi bật

- **Đa định dạng clipboard**: text (giữ RTF/HTML), ảnh, file & folder, URL
- **JSON ↔ Table ↔ Excel (.xlsx)**: nhận diện, flatten JSON lồng nhau, xuất file Excel native
- **Bộ lọc thông minh**: Tất cả / Văn bản / Hình ảnh / Tệp tin / Bookmark
- **Tìm kiếm**: không phân biệt dấu tiếng Việt, match cả nội dung text + tên file + tên app nguồn
- **Quản lý item**: pin, bookmark, xoá từng item, kéo thả
- **Phím tắt**: ↑↓ chọn · ⏎ dán · ⌘1–9 dán nhanh · ESC đóng · gõ chữ để tìm kiếm
- **Themes**: 13 bộ màu (System, Sáng, Tối, Dracula, Nord, Solarized, Tokyo Night, Catppuccin, Gruvbox, Monokai, One Dark, GitHub, Rosé Pine)
- **Tuỳ chỉnh phông**: System / Monospaced / Bo tròn / Serif, cỡ 10–16pt
- **Tuỳ chọn UI native**: dạng danh sách gọn với zebra striping + separator
- **Live preview**: mở Cài đặt → popup hiện bên cạnh để xem trực tiếp thay đổi theme
- **Auto-paste**: tự giả lập ⌘V khi chọn item
- **Auto-update**: kiểm tra GitHub Releases, verify integrity khi tải
- **Đa ngôn ngữ**: Tiếng Việt, English
- **Tự khởi động cùng máy** (macOS 13+)

## Yêu cầu hệ thống

- macOS 12.0 Monterey trở lên
- ~1 MB dung lượng đĩa
- Universal binary (Apple Silicon + Intel)

## Cài đặt

1. Tải file `Clipboard-3.4.dmg` từ [Releases](https://github.com/nguyenxuanhoa493/Windows-plus-V-for-Mac/releases)
2. Mở DMG → kéo **Clipboard** vào thư mục **Applications**
3. Xoá quarantine attribute (chỉ cần 1 lần):
   ```bash
   xattr -cr /Applications/Clipboard.app
   ```
4. Chạy app từ Launchpad → bấm "Open" nếu macOS cảnh báo nguồn không xác định
5. Cấp quyền **Accessibility** (bắt buộc để auto-paste hoạt động):
   System Settings → Privacy & Security → Accessibility → bật Clipboard
6. Khởi động lại app

![Cấp quyền](demo/image_2.png)

## Sử dụng

- **Mở popup clipboard**: `⌃V` (chỉnh trong Cài đặt → Chung → Phím tắt)
- **Dán nhanh**: `⌘1`..`⌘9` để dán item theo số thứ tự
- **Kéo thả ảnh/file**: kéo từ row ra Finder, Slack, etc.
- **Right-click row**: context menu đầy đủ (Sao chép, Lưu, Ghim, Bookmark, Chuyển đổi, Xoá)

## Liên hệ

- GitHub: [nguyenxuanhoa493/Windows-plus-V-for-Mac](https://github.com/nguyenxuanhoa493/Windows-plus-V-for-Mac)
- Telegram: [@xuanhoa493](https://t.me/xuanhoa493)
- Email: nguyenxuanhoa493@gmail.com

Nếu app hữu ích, hãy cân nhắc [mời tôi một ly cà phê ☕](Sources/Resources/cafe.jpg)
