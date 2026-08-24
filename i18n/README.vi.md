# JA Compare

Công cụ Windows-first để so sánh tài liệu và thư mục, hiển thị khác biệt
đồng bộ, lưu lịch sử và xuất kết quả.

![Flutter](https://img.shields.io/badge/Flutter-Windows-02569B?logo=flutter)
![Release](https://img.shields.io/badge/Release-v2.0.1-2563EB)
![License](https://img.shields.io/badge/License-MIT-green)

[English](../README.md) · [Website](https://jatechvn.github.io/) · [GitHub](https://github.com/jatechvn/JA_Compare)

## Tổng quan

JA Compare là ứng dụng Windows Desktop dùng để so sánh tài liệu hoặc toàn bộ
cây thư mục. Kết quả được hiển thị song song với thanh cuộn đồng bộ, có lịch
sử cục bộ và hỗ trợ xuất kết quả để lưu trữ hoặc chia sẻ.

## Tính năng

- So sánh file bằng nút chọn file hoặc kéo-thả.
- So sánh thư mục đệ quy, có thể nhóm các file có tên tương tự.
- Hai khung hiển thị song song, cuộn đồng bộ, tô màu thay đổi.
- Hỗ trợ Text, Markdown, CSV, JSON, LOG, XML, HTML, YAML, YML, INI,
  Word (`.docx`), Excel (`.xlsx`) và PDF (`.pdf`).
- Xuất diff ra Markdown hoặc Excel có tô màu.
- Lịch sử cho cả so sánh file và thư mục; có thể mở lại bản ghi thư mục.
  Lịch sử file cũ vẫn tương thích.
- Giao diện tiếng Anh, tiếng Việt, tiếng Trung; lựa chọn được lưu lại.
- Tuỳ chỉnh glassmorphism và hiệu ứng nền native Windows 10/11.
- Single-instance: mở lại ứng dụng sẽ đưa cửa sổ đang chạy lên trước.

## Hướng dẫn nhanh

1. Chọn hoặc kéo file vào hai khung, hoặc chuyển sang **Thư mục** để chọn hai
   thư mục cần so sánh.
2. Bấm **So sánh**.
3. Xem các mục thêm, xoá, sửa đổi và có tên tương tự.
4. Sao chép một bên hoặc xuất kết quả ra Markdown/Excel.
5. Mở **Lịch sử so sánh** để mở lại cặp file hoặc thư mục trước đó.
6. Vào **Cài đặt** để đổi ngôn ngữ, giao diện và thông số glassmorphism.

## Chạy dự án

```bash
flutter pub get
flutter run -d windows
```

Đóng gói bản phát hành:

```bash
build_release.bat
```

File ZIP nằm trong `dist/`, có một thư mục cha duy nhất và không chứa config,
history hoặc log runtime. Dữ liệu người dùng được lưu tại
`%LOCALAPPDATA%\JA Compare`.

## Kiến trúc

Mã nguồn chính nằm trong `lib/modules/`: `extractors/` đọc tài liệu,
`models/` chứa model, `services/` xử lý so sánh/lưu trữ/xuất file,
`i18n/` quản lý ngôn ngữ, `ui/` chứa giao diện, còn `native/` là ranh giới
tích hợp native Windows. Kiểm thử nằm trong `test/` và Windows runner nằm
trong `windows/`.

## Kiểm tra và tài liệu

```bash
dart format lib test
flutter analyze
flutter test
```

Xem [CHANGELOG.md](../CHANGELOG.md), [RELEASE_NOTES.md](../RELEASE_NOTES.md)
và [MIT License](../LICENSE).
