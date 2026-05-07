# Changelog

[English](CHANGELOG.md) · [Tiếng Việt](CHANGELOG.vi.md)

Tất cả thay đổi của **Windows + V For Mac**.

## 3.4 — Mới nhất

### 🐛 Sửa lỗi
- Filter button (Văn bản / Hình ảnh / Tệp tin / Bookmark) cập nhật list ngay khi click — trước đây gesture xung đột ở parent HStack nuốt mất click, phải click Bookmark trước rồi mới click filter khác mới hoạt động
- Bỏ `.id(index)` thừa trên ClipboardItemView trong ForEach — conflict với `id: \.element.id` làm SwiftUI diff skip update khi đổi filter
- Phạm vi drag-to-move window thu hẹp: chỉ còn ở Spacer giữa filter và search button → filter/search button nhận click đáng tin cậy

### Mang theo từ 3.3
Toàn bộ tính năng 3.3 vẫn còn (theming, sidebar Cài đặt, tuỳ chỉnh font, tab Thông tin, kéo thả ảnh, tự khởi động, hover effects, ...).

---

## 3.3

### 🎨 Tổng cải tổ theme
- **13 bộ màu**: System, Sáng, Tối, Dracula, Nord, Solarized, Tokyo Night, Catppuccin, Gruvbox, Monokai, One Dark, GitHub, Rosé Pine
- Theme custom override toàn UI: window background, thanh tiêu đề, surface row, màu text, màu accent, hover/selected
- Live preview popup hiện bên cạnh Cài đặt — xem trực tiếp thay đổi theme/font ngay tức thì
- Theme áp dụng cho tất cả cửa sổ (popup, Cài đặt, popup cấp quyền)

### ⚙️ Thiết kế lại Cài đặt
- **Sidebar dọc bên trái** (thay tabs ngang): Chung · Giao diện · Tính năng · Thông tin
- Bỏ menu "Liên hệ" + "Mua cà phê" độc lập → gộp vào tab **Thông tin**
- Tab Thông tin mới: tác giả, link GitHub, Telegram, QR ủng hộ
- Toggle **Tự khởi động cùng máy** (macOS 13+ qua SMAppService)
- Tuỳ chỉnh phông: System / Monospaced / Bo tròn / Serif, cỡ 10–16pt (mặc định 13)
- Theme picker chỉ hiện khi chọn Tuỳ chỉnh trong Giao diện

### 📋 UX popup
- Menu "..." (⚙ icon) chuyển từ top filter bar xuống bottom hint bar — top gọn hơn
- Bottom hint bar hiện cheatsheet phím tắt: `↑↓ Chọn · ⏎ Dán · ⌘1-9 Dán nhanh`
- Mở ảnh trực tiếp trong Preview (right-click → Mở, hoặc nút action khi hover)
- Kéo thả ảnh vào Finder/Slack/... — tự xuất file PNG tạm
- Tự ẩn popup sau khi kéo thả (toggle trong Tính năng)
- Chế độ UI native dạng list với zebra striping + separator (toggle trong Giao diện, mặc định tắt)

### 🐛 Sửa lỗi
- Ô search nhận được Delete/Backspace khi đang gõ
- Kéo popup hoạt động trong cursor mode (trước bị mất khi level filter sai)
- Tooltip icon button không còn bị item đầu tiên che
- Tab Cài đặt không bị reset về Chung khi đổi theme
- Top của Cài đặt + popup thẳng hàng khi Cài đặt mở
- Màu hover/selected row dùng accent của theme (không còn dính xanh mặc định)
- QR ảnh hiển thị đúng trong dev build (`Bundle.module` fallback)

### Mang theo từ 3.2
Bao gồm toàn bộ thay đổi của 3.2: tab Tính năng với toggle, Cmd+1..9 shortcuts, vị trí popup thông minh, ESC đóng popup, empty state UI, image thumbnail async, Excel export async, NSCache cho icon, image SHA256 dedup, backup history khi corrupt, verify update zip, detect read-only volume, privacy disclaimer.

---

## 3.2

### Tính năng
- Tab "Tính năng" mới trong Cài đặt với 8 toggle:
  Đưa lên đầu sau dán · JSON→Table · JSON→Excel · Table→JSON · Mở URL · Timestamp · Tìm kiếm · Kéo thả
- Cài đặt chia 2 tab "Chung" + "Tính năng"

### Cải tiến
- Vị trí popup thông minh: hiện ở bottom-right con trỏ, clamp trong màn hình (multi-monitor)
- ESC đóng popup
- Empty state UI khi history trống / search không kết quả
- Search match cả tên file và tên app nguồn
- Thumbnail ảnh load async + downsample — không freeze UI với screenshot 4K
- Excel export chạy nền
- Icon cache dùng `NSCache` (auto-evict dưới memory pressure)
- Hỗ trợ phím tắt mở rộng (F1–F20, mũi tên, Space)
- Auto-detect khi quyền Accessibility bị revoke runtime

### Phím tắt trong popup
- `↑/↓` chọn · `⏎` dán · `Delete` xoá · `ESC` đóng · gõ chữ để search

### Sửa lỗi
- Auto-update giữ quyền Accessibility (không xoá `_CodeSignature`)
- Verify zip update (Content-Length + magic bytes)
- Detect read-only volume (DMG mount → cảnh báo trước khi tải)
- Anti-race khi check update (manual + auto không tạo 2 download)
- Nút Cancel khi đang download update
- Backup history khi JSON corrupt
- Cleanup ảnh mồ côi khi launch
- Image dedup theo SHA256
- Cache directory `chmod 700`
- Fix keyboard monitor leak
- Clamp drag popup trong màn hình
- NSImage copy trước khi mutate
- Privacy disclaimer trong tab Tính năng

---

## 3.1
- Fix thông báo cấp quyền

## 3.0
- Universal Binary (Apple Silicon + Intel)
- Hỗ trợ macOS 12 Monterey trở lên

## 2.9
- Excel ↔ JSON 2 chiều
- Dán dữ liệu Excel dưới dạng ảnh bảng
- Lưu ảnh từ clipboard ra PNG
- Giữ format khi copy (RTF/HTML/TSV)
- Hiển thị icon + tên app nguồn
- Sorted history cache, debounce save, lưu ảnh ra disk thay vì RAM
- Search không dấu tiếng Việt

## 2.1
- Xuất Native XLSX (libxlsxwriter)
- Flatten JSON lồng nhau thành cột phẳng
- Cải tiến UI search (accent border, auto-focus, fix CapsLock)

## 2.0
- JSON converter + xuất Excel CSV
- Cải tiến UX search
- Đồng nhất icon size (14px)

## 1.9
- Tối ưu bộ nhớ
- Tăng tốc xử lý

## 1.6
- Hỗ trợ File & Folder (icon thật, preview ảnh, drag-drop, mở, copy path)
- 5 bộ lọc (Tất cả / Văn bản / Ảnh / File / Bookmark)
- Pin, Bookmark, xoá từng item
- Timestamp converter
- Phát hiện URL
- Context menu đầy đủ, tooltip

## 1.5
- Xoá theo loại
- Cải thiện hiển thị timestamp

## 1.4
- Tự động paste khi chọn
- Move-to-top sau khi dùng

## 1.3
- Nút xoá toàn bộ
- Tự ẩn khi click ngoài
