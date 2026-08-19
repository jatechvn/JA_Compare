# JA Compare

Ứng dụng Windows Desktop dùng để so sánh hai tài liệu và chỉ ra điểm khác
biệt giữa chúng, hiển thị song song (side-by-side).

## Định dạng hỗ trợ

- Text/Markdown/CSV/JSON/LOG/XML/HTML (`.txt .md .csv .json .log .xml .html .htm .yaml .yml .ini`)
- Word (`.docx`)
- Excel (`.xlsx .xls`)
- PDF (`.pdf`)

## Tính năng

- Chọn file bằng nút bấm hoặc kéo-thả trực tiếp vào cửa sổ.
- Xem khác biệt song song, hai khung cuộn đồng bộ với nhau.
- Tô màu dòng thêm mới / xoá / sửa đổi, kèm thanh tổng kết số lượng thay đổi.
- Chọn và sao chép văn bản trực tiếp trong từng khung, hoặc sao chép toàn bộ
  một bên chỉ bằng một cú bấm.
- Xuất kết quả ra Markdown (khối ```diff) hoặc file Excel tô màu tương ứng,
  để lưu giữ hoặc chia sẻ.
- Lịch sử so sánh — mở lại bất kỳ cặp file nào đã so sánh trước đó chỉ với
  một cú bấm.
- Chuyển đổi ngôn ngữ EN/VI/CN (được lưu lại giữa các lần mở) và nút chuyển
  sáng/tối (mặc định theo giao diện hệ thống Windows).
- Giao diện kính mờ (glassmorphism) tận dụng Acrylic (Windows 11) / Aero Blur
  (Windows 10) của hệ điều hành, có thể tuỳ chỉnh độ mờ/độ trong suốt trong
  Cài đặt.
- Chỉ cho phép một cửa sổ chạy tại một thời điểm (single-instance).

## Chạy dự án

```bash
flutter pub get
flutter run -d windows
```

Hoặc dùng script có sẵn:

```bash
run.bat
```

## Đóng gói bản release

```bash
build_release.bat
```

Kết quả nằm trong `dist/` (bao gồm file `.zip` sẵn sàng phát hành).

## Kiến trúc

Xem cấu trúc thư mục và quy ước module tại `lib/modules/` — tuân theo
blueprint Flutter Desktop chuẩn (`ui/`, `native/`, `extractors/`, `models/`,
`services/`). Theming Windows 10/11 native nằm tại
`windows/runner/theme_win10.*` và `theme_win11.*`.
