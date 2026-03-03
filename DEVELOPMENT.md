# Development Guide

## Vấn đề: Phải cấp quyền lại mỗi lần build

Khi build app với ad-hoc signing (`codesign --sign -`), mỗi lần build lại app sẽ có signature khác nhau. macOS sẽ coi như app mới và yêu cầu cấp quyền Accessibility lại.

## Giải pháp

### 🔧 Option 1: Dùng Debug Build (RECOMMENDED cho development)

Debug build không cần app bundle và không cần sign. Chạy trực tiếp từ `.build/debug/`.

**Lần đầu tiên:**
```bash
# Build và chạy
./run_debug.sh

# hoặc
swift build
./.build/debug/Clipboard
```

App sẽ hiển thị popup yêu cầu quyền Accessibility. Cấp quyền một lần duy nhất.

**Các lần sau:**
```bash
# Chỉ cần build và chạy lại
./run_debug.sh
```

✅ **KHÔNG phải cấp quyền lại!**

---

### 📦 Option 2: Build Fast (chỉ thay binary)

Nếu muốn dùng app bundle (Clipboard.app):

**Lần đầu:**
```bash
# Tạo app bundle và sign
./create_app.sh

# Chạy app và cấp quyền
open Clipboard.app
```

**Các lần sau:**
```bash
# Chỉ replace binary, không sign lại
./build_fast.sh

# Chạy app (không cần cấp quyền lại)
open Clipboard.app
```

⚠️ **Note:** Nếu app không chạy được (bị macOS block), cần sign lại:
```bash
codesign --force --deep --sign - --entitlements Clipboard.entitlements Clipboard.app
```

Nhưng khi sign lại sẽ phải cấp quyền lại.

---

### 🎯 Option 3: Apple Developer Certificate (cho production)

Nếu có Apple Developer account ($99/year):

1. Tạo Developer ID Application certificate
2. Sign app với certificate thật:
```bash
codesign --force --deep --sign "Developer ID Application: Your Name" \
  --entitlements Clipboard.entitlements \
  Clipboard.app
```

3. Notarize app (optional nhưng recommended)

✅ App signed với certificate thật sẽ **giữ permissions qua các lần build**.

---

## Workflow Recommended

### Khi đang phát triển (development):
```bash
# Build và chạy debug version
./run_debug.sh
```

### Khi muốn test app bundle:
```bash
# Lần đầu: tạo app và cấp quyền
./create_app.sh
open Clipboard.app

# Các lần sau: chỉ thay binary
./build_fast.sh
open Clipboard.app
```

### Khi release cho user:
```bash
# Build DMG để phân phối
./create_app.sh  # hoặc build_fast.sh nếu đã có app
./build_dmg.sh
```

---

## Tóm tắt Scripts

| Script | Mục đích | Sign lại? | Cần cấp quyền lại? |
|--------|----------|-----------|-------------------|
| `run_debug.sh` | Development | ❌ | ❌ Không |
| `build_fast.sh` | Test app bundle nhanh | ❌ | ❌ Không |
| `create_app.sh` | Tạo app bundle mới | ✅ | ✅ Có |
| `build_dmg.sh` | Tạo DMG cho release | ✅ | ✅ Có |

---

## Tips

- **Development:** Dùng `run_debug.sh` - nhanh nhất, không phải cấp quyền lại
- **Testing:** Dùng `build_fast.sh` - test app bundle mà không cần sign lại
- **Release:** Dùng `create_app.sh` + `build_dmg.sh` - tạo DMG cho user

**Lưu ý:** Debug build sẽ không có icon trong Dock và menubar vì thiếu app bundle, nhưng vẫn hoạt động đầy đủ chức năng.
