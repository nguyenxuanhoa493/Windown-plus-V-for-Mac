# Windows + V For Mac - Trình quản lý clipboard cho macOS

## Giới thiệu

Clipboard là một ứng dụng macOS nhỏ gọn, hiệu quả giúp bạn quản lý và truy cập nhanh lịch sử clipboard. Ứng dụng được thiết kế để hoạt động một cách im lặng trong thanh menu, luôn sẵn sàng khi bạn cần.


### Giao diện ứng dụng

![Giao diện Clipboard](demo/main.png)

## Tính năng chính

### 📋 Quản lý Clipboard đa dạng
-   **Văn bản**: Lưu trữ và quản lý text đã copy, giữ nguyên format (RTF, HTML), chuyển đổi timestamp
-   **Hình ảnh**: Hiển thị preview ảnh ngay trong lịch sử, lưu ảnh ra file PNG
-   **File & Folder**: 
    - Hiển thị icon file/folder thật từ hệ thống
    - Preview tự động cho file ảnh
    - Drag & drop file/folder như Finder
    - Mở file/folder trực tiếp từ app
    - Copy đường dẫn file
-   **URL**: Tự động phát hiện và mở URL trong trình duyệt

### 🔄 JSON & Excel Converter
-   **JSON → Table**: Tự động nhận diện JSON, chuyển đổi sang dạng bảng để dễ quan sát
-   **JSON → Excel (.xlsx)**: Xuất trực tiếp ra file Excel thực thụ (Native XLSX) với header in đậm, màu nền, tự động căn chỉnh cột
-   **JSON lồng nhau**: Tự động làm phẳng (flatten) cấu trúc JSON phức tạp (vd: `user.address.city`)
-   **Excel → JSON**: Chuyển đổi dữ liệu tab-separated từ Excel sang JSON
-   **Dán như ảnh**: Dán dữ liệu Excel dưới dạng hình ảnh bảng

### 🎯 Bộ lọc thông minh
-   **5 bộ lọc**: Tất cả, Văn bản, Hình ảnh, Tệp tin, Bookmark
-   **Xóa theo loại**: Xóa nhanh các item cùng loại
-   **Tìm kiếm nhanh**: Hỗ trợ tìm kiếm không dấu tiếng Việt, auto-focus khi gõ phím

### 📌 Quản lý Item
-   **Pin**: Ghim item quan trọng lên đầu danh sách
-   **Bookmark**: Đánh dấu item yêu thích để truy cập nhanh
-   **Xóa từng item**: Quản lý item linh hoạt
-   **Sắp xếp thông minh**: Item được pin hiển thị trước, sau đó theo thời gian

### ⚡ Thao tác nhanh
-   **Auto Paste**: Tự động paste khi chọn item từ lịch sử
-   **Context Menu đầy đủ**: Chuột phải để truy cập tất cả chức năng
-   **Phím tắt**: Mở nhanh bằng Control+V (có thể tùy chỉnh)
-   **Hover Actions**: Hiện icon Open, Copy, Export khi hover vào item
-   **Drag & Drop**: Kéo thả file/folder trực tiếp từ lịch sử

### 🔧 Tính năng đặc biệt
-   **Timestamp Converter**: 
    - Tự động nhận diện timestamp (10 hoặc 13 chữ số)
    - Chuyển đổi giữa timestamp và datetime
-   **Kéo để di chuyển**: Kéo vùng filter bar để di chuyển cửa sổ
-   **Multi-language**: Hỗ trợ Tiếng Việt & English
-   **Tùy chỉnh phím tắt**: Cài đặt phím tắt theo ý muốn
-   **Theme**: Hỗ trợ System / Light / Dark mode
-   **Auto Update**: Tự động kiểm tra & cập nhật phiên bản mới từ GitHub
-   **Hiển thị nguồn**: Hiển thị icon & tên ứng dụng nguồn đã copy
-   **Lưu ảnh**: Lưu ảnh từ clipboard ra file PNG

## Yêu cầu hệ thống

-   macOS 12.0 trở lên
-   Khoảng 1MB dung lượng đĩa

## Change log

### Version 3.1 (Latest)

**🐛 Sửa lỗi:**
-   **Fix thông báo cấp quyền**: Hiển thị thông báo thành công sau khi cấp quyền Accessibility

---

### Version 3.0

**🎉 Tính năng mới:**
-   **Hỗ trợ Universal Binary**: Chạy native trên cả chip Apple Silicon (M1/M2/M3/M4) và Intel
-   **Tương thích rộng**: Hỗ trợ macOS 12 Monterey trở lên trên mọi dòng Mac

---

### Version 2.9

**🎉 Tính năng mới:**
-   **Excel ↔ JSON hai chiều**:
    - Chuyển đổi dữ liệu Excel (tab-separated) sang JSON
    - Nhận diện dữ liệu bảng tự động, hiển thị icon phân loại
    - Dán dữ liệu Excel dưới dạng hình ảnh bảng (Paste as Image)
    - Giữ nguyên leading zeros cho số điện thoại, mã số...
-   **Cải tiến xuất Excel**:
    - Xuất JSON → Excel (.xlsx) và tự động mở file
    - Hỗ trợ flatten JSON lồng nhau thành cột phẳng
-   **Lưu ảnh từ clipboard**: Nút Save Image để lưu ảnh ra file PNG
-   **Giữ nguyên format khi copy**: Hỗ trợ RTF, HTML, tab-separated values
-   **Hiển thị nguồn**: Hiển thị icon & tên app nguồn đã copy cho mỗi item

**✨ Cải tiến:**
-   Tối ưu hiệu suất với sorted history cache
-   Debounce save history để giảm I/O
-   Cache file icon và app icon
-   Tối ưu bộ nhớ: lưu ảnh ra disk thay vì giữ trong RAM
-   Hỗ trợ tìm kiếm không dấu tiếng Việt

### Version 2.1

**🎉 Tính năng mới:**
-   **JSON Converter & Native XLSX Export**:
    - Tự động nhận diện dữ liệu JSON trong clipboard
    - Chuyển đổi JSON sang dạng bảng (Table view) để dễ quan sát
    - **Xuất Excel (.xlsx)**: Xuất trực tiếp ra file Excel thực thụ (Native XLSX) thay vì CSV.
    - **Xử lý JSON lồng nhau**: Tự động làm phẳng (flatten) cấu trúc JSON phức tạp thành các cột phẳng (vd: user.address.city).
    - **Định dạng chuyên nghiệp**: Header được in đậm, có màu nền, và tự động căn chỉnh độ rộng cột.
-   **Cải tiến Tìm kiếm**:
    - Thêm border màu accent nổi bật cho ô tìm kiếm
    - Tự động focus vào ô tìm kiếm khi click icon hoặc gõ phím tắt
    - Fix lỗi không kích hoạt được tìm kiếm khi đang bật **Caps Lock**
    - Sửa lỗi nháy UI (flicker) khi mở/đóng ô tìm kiếm bằng cách đồng nhất kích thước icon

**✨ Cải tiến & Sửa lỗi:**
-   Đồng nhất kích thước icon (14px) trên toàn bộ ứng dụng
-   Cải thiện độ trễ khi focus ô tìm kiếm để đảm bảo hoạt động ổn định
-   Fix lỗi cursor nhảy không đúng vị trí khi gõ tìm kiếm nhanh
-   Tích hợp thư viện `libxlsxwriter` chuyên nghiệp để xử lý file Excel.

### Version 2.0

**🎉 Tính năng mới:**
-   **JSON Converter & Excel Export**:
    - Tự động nhận diện dữ liệu JSON trong clipboard
    - Chuyển đổi JSON sang dạng bảng (Table view) để dễ quan sát
    - **Xuất Excel (.csv)**: Xuất dữ liệu JSON ra file Excel với định dạng chuẩn (hỗ trợ xuống dòng, dấu phẩy, quote)
    - Tích hợp nút Export nhanh khi hover vào item JSON
-   **Cải tiến Tìm kiếm**:
    - Thêm border màu accent nổi bật cho ô tìm kiếm
    - Tự động focus vào ô tìm kiếm khi click icon hoặc gõ phím tắt
    - Fix lỗi không kích hoạt được tìm kiếm khi đang bật **Caps Lock**
    - Sửa lỗi nháy UI (flicker) khi mở/đóng ô tìm kiếm bằng cách đồng nhất kích thước icon

**✨ Cải tiến & Sửa lỗi:**
-   Đồng nhất kích thước icon (14px) trên toàn bộ ứng dụng
-   Cải thiện độ trễ khi focus ô tìm kiếm để đảm bảo hoạt động ổn định
-   Fix lỗi cursor nhảy không đúng vị trí khi gõ tìm kiếm nhanh
-   Tối ưu hóa hàm xử lý CSV: hỗ trợ đầy đủ BOM UTF-8 cho Excel, xử lý escape ký tự đặc biệt

### Version 1.9

**⚡ Cải tiến:**
-   **Tối ưu bộ nhớ**: Giảm đáng kể mức sử dụng RAM, ứng dụng chạy nhẹ hơn
-   **Tối ưu tốc độ**: Cải thiện hiệu suất xử lý, phản hồi nhanh hơn

### Version 1.6

**🎉 Tính năng mới:**
-   **Hỗ trợ File & Folder**:
    - Hiển thị icon file/folder thật từ hệ thống macOS
    - Preview tự động cho file ảnh (png, jpg, gif, heic, webp, svg...)
    - Drag & drop file/folder như Finder
    - Open file/folder trực tiếp bằng icon hoặc context menu
    - Copy đường dẫn file vào clipboard
-   **Bộ lọc nâng cao**: 5 bộ lọc (Tất cả, Văn bản, Hình ảnh, Tệp tin, Bookmark)
-   **Quản lý Item**: Pin, Bookmark, xóa từng item
-   **Timestamp Converter**: Chuyển đổi timestamp sang datetime và ngược lại
-   **URL Detection**: Tự động phát hiện URL và mở trong trình duyệt
-   **Context Menu đầy đủ**: Truy cập nhanh tất cả chức năng
-   **Tooltip**: Hiển thị mô tả khi hover vào các icon

**✨ Cải tiến:**
-   Giảm size text xuống 11 để hiển thị nhiều nội dung hơn
-   Cải thiện UI/UX với hover effects
-   Fix bug kéo item không kéo cả cửa sổ
-   Chỉ cho phép kéo cửa sổ ở vùng filter bar
-   Tự động đóng cửa sổ sau khi open file/folder/URL

### Version 1.5

-   Thêm tính năng xóa theo loại
-   Cải thiện hiển thị timestamp
-   Fix các bug nhỏ

### Version 1.4

-   Tự động paste nội dung khi chọn từ lịch sử
-   Tự động di chuyển mục được sử dụng lên đầu danh sách
-   Cải thiện hiệu suất và trải nghiệm người dùng

### Version 1.3

-   Thêm nút xóa toàn bộ lịch sử clipboard
-   Tự động ẩn cửa sổ danh sách khi click ra ngoài

## Cài đặt

1. **Tải xuống**: Download file `Clipboard-3.1.dmg` từ [trang Releases](https://github.com/nguyenxuanhoa493/Windows-plus-V-for-Mac/releases)

2. **Cài đặt app**: 
   - Mở file DMG
   - Kéo ứng dụng Clipboard vào thư mục Applications
   - **QUAN TRỌNG**: Phải copy vào Applications, không chạy trực tiếp từ DMG

3. **Xóa quarantine attribute** (chỉ cần làm 1 lần):
   ```bash
   xattr -cr /Applications/Clipboard.app
   ```

4. **Khởi động lần đầu**:
   - Mở ứng dụng từ Launchpad hoặc thư mục Applications
   - macOS sẽ hỏi xác nhận mở app từ nguồn không xác định → Chọn "Open"

5. **Cấp quyền Accessibility** (bắt buộc để tính năng auto-paste hoạt động):
   - Khi mở app lần đầu, sẽ có popup yêu cầu quyền Accessibility
   - Click "Open System Settings" hoặc vào **System Settings → Privacy & Security → Accessibility**
   - Bật toggle cho Clipboard
   - **Nếu không thấy Clipboard trong list**: Click nút "+" và thêm app từ `/Applications/Clipboard.app`
   
   ![Giao diện cấp quyền](demo/image_2.png)

6. **Khởi động lại app** sau khi cấp quyền để hoạt động bình thường

## Liên hệ & Hỗ trợ

Nếu bạn gặp vấn đề hoặc có câu hỏi, vui lòng:

-   Email: Nguyenxuanhoa493@gmail.com
-   Telegram: [@xuanhoa493](http://t.me/xuanhoa493)

---

Nếu bạn thấy dự án hữu ích, hãy cân nhắc [ủng hộ tác giả một ly cà phê](Sources/Resources/cafe.jpg) ☕
