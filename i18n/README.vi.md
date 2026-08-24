# JA Compare

Công cụ Windows-first để so sánh tài liệu và thư mục, hiển thị khác biệt
đồng bộ, lưu lịch sử và xuất kết quả.

![Flutter](https://img.shields.io/badge/Flutter-Windows-02569B?logo=flutter)
![Release](https://img.shields.io/badge/Release-v2.0.2-2563EB)
![License](https://img.shields.io/badge/License-MIT-green)

[English](../README.md) · [Website](https://jatechvn.github.io/) · [GitHub](https://github.com/jatechvn/JA_Compare)

## Tổng quan

JA Compare là ứng dụng Windows Desktop dùng để so sánh tài liệu hoặc toàn bộ
cây thư mục. Kết quả được hiển thị song song với thanh cuộn đồng bộ, có lịch
sử cục bộ và hỗ trợ xuất kết quả để lưu trữ hoặc chia sẻ.

## Tính năng

- So sánh file bằng nút chọn file hoặc kéo-thả.
- Kéo thả cùng lúc 2 file hoặc 2 thư mục ở bất kỳ vị trí nào trong phần mềm để
  tự động điền hai phía so sánh.
- So sánh thư mục đệ quy, có thể nhóm các file có tên tương tự.
- Hai khung hiển thị song song, cuộn đồng bộ, tô màu thay đổi.
- Hiển thị banner xanh rõ ràng khi hai file hoàn toàn giống nhau.
- Hỗ trợ Text, Markdown, CSV, JSON, LOG, XML, HTML, YAML, YML, INI,
  Word (`.docx`), Excel (`.xlsx`) và PDF (`.pdf`).
- Xuất diff ra Markdown hoặc Excel có tô màu.
- Lịch sử cho cả so sánh file và thư mục; có thể mở lại bản ghi thư mục.
  Lịch sử file cũ vẫn tương thích.
- Giao diện tiếng Anh, tiếng Việt, tiếng Trung; lựa chọn được lưu lại.
- Tuỳ chỉnh glassmorphism và hiệu ứng nền native Windows 10/11.
- Log thường và log debug được ghi cạnh file `.exe` trong thư mục `logs/`.
- Single-instance: mở lại ứng dụng sẽ đưa cửa sổ đang chạy lên trước.

## Hướng dẫn nhanh

1. Chọn từng file, hoặc kéo thả cùng lúc 2 file / 2 thư mục vào phần mềm để tự
   động điền hai phía.
2. Bấm **So sánh**.
3. Nếu hai file giống nhau, thanh kết quả hiện **Hai tệp giống hệt nhau**; nếu
   có khác biệt, xem các mục thêm, xoá, sửa đổi và có tên tương tự.
4. Sao chép một bên hoặc xuất kết quả ra Markdown/Excel.
5. Mở **Lịch sử so sánh** để mở lại cặp file hoặc thư mục trước đó.
6. Vào **Cài đặt** để đổi ngôn ngữ, giao diện và thông số glassmorphism.
7. Chạy `debug.bat` khi cần chẩn đoán; log nằm trong thư mục `logs/` cạnh app.

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
history hoặc log runtime. Cài đặt, ngôn ngữ và lịch sử nằm tại
`%LOCALAPPDATA%\JA Compare`; log runtime nằm trong `logs/` cạnh file `.exe`.

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
