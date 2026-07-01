<div align="center">
  <h1>TLU Calendar</h1>
  <p><strong>Ứng dụng xem lịch học, lịch thi và quản lý học tập dành riêng cho sinh viên Đại học Thủy Lợi.</strong></p>
  <br />
  <a href="https://github.com/Miho1254/my-tlucalendar/releases/latest">Tải APK mới nhất</a>
  &nbsp;·&nbsp;
  <a href="#tinh-nang-chinh">Tính năng</a>
  &nbsp;·&nbsp;
  <a href="#tu-build-tu">Tự build</a>
  <br /><br />
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/github/actions/workflow/status/Miho1254/my-tlucalendar/release_main.yaml?style=flat-square&label=Build" alt="Build Status">
</div>

---

## Giới thiệu

**TLU Calendar (Miho's Version)** là một bản fork cá nhân, được refactor toàn diện từ ứng dụng TLU Calendar gốc của tác giả [nekkochan0x0007](https://gitlab.com/nekkochan0x0007/tlucalendar).

Bản fork này tập trung vào 3 mục tiêu cốt lõi:

- **Nhanh** — Dữ liệu được cache cục bộ, mở app là có ngay, không cần chờ mạng.
- **Chắc** — Sửa các lỗi phân tích API gốc, đặc biệt là lỗi nhận diện nhầm học kỳ.
- **Đẹp** — Thiết kế lại toàn bộ giao diện theo chuẩn Apple HIG, hỗ trợ hoàn chỉnh Dark Mode.

---

## Showcase

> Chèn ảnh chụp màn hình app ở đây để người đọc thấy ngay sản phẩm trước khi đọc tiếp.

| Màn hình Hôm nay | Lịch học | Phân tích điểm | Cài đặt |
|:---:|:---:|:---:|:---:|
| *(screenshot)* | *(screenshot)* | *(screenshot)* | *(screenshot)* |

---

## Tính năng chính

### Xem lịch học & lịch thi
Đồng bộ thời khóa biểu và lịch thi từ hệ thống TLU. Hỗ trợ xem theo tuần (dạng lưới) và theo ngày (dạng timeline). Có thể gắn ghi chú cá nhân vào từng buổi học.

### Cache & Offline hoàn toàn
Toàn bộ dữ liệu lịch học, lịch thi và điểm số được lưu vào database SQLite cục bộ. Khi mạng TLU "đi ngủ" lúc 12h đêm, app vẫn chạy bình thường.

### Phân tích điểm & Mô phỏng GPA
Xem điểm từng học kỳ, theo dõi GPA tích lũy theo thời gian. Tính năng mô phỏng cho phép bạn đặt mục tiêu tốt nghiệp và tính toán cần đạt bao nhiêu điểm trong các học kỳ còn lại.

### Trải nghiệm hiện đại
Thanh điều hướng dạng Liquid Glass nổi, tự thích ứng màu theo theme hệ thống. Hỗ trợ hoàn chỉnh Light Mode và Dark Mode không có lỗi tương phản.

---

## Những thay đổi nổi bật so với bản gốc

### Giao diện
- Áp dụng bộ component `forui` theo chuẩn Apple HIG.
- Loại bỏ toàn bộ màu sắc hardcode, chuyển sang dùng `Theme.of(context).colorScheme` để Dark Mode không bị lỗi.
- Thiết kế lại card môn học và timeline hiển thị giờ bắt đầu/kết thúc rõ ràng hơn.
- Thêm Setup Wizard 3 bước cho người dùng mới.

### Độ ổn định & Logic
- Sửa lỗi app nhận diện nhầm "Chuẩn đầu ra" thành học kỳ chính khi gọi API.
- Sửa lỗi dấu chấm ghi chú trên lịch bị "bóng ma" (hiển thị sai ngày).
- Sửa lỗi scroll tàng hình do padding cứng quá lớn ở cuối màn hình.
- Fix crash khi chạy trên Linux/Desktop do plugin thông báo không tương thích.

### Công cụ & CI/CD
- Developer Mode ẩn: bấm 5 lần vào số phiên bản trong Cài đặt để mở khóa menu xem logs và quản lý dữ liệu.
- GitHub Actions tự động build và đăng APK lên Releases mỗi khi có commit mới trên nhánh `main`.

---

## Tự build

### Yêu cầu
- Flutter SDK 3.x trở lên
- Dart SDK (đi kèm Flutter)
- Android SDK (để build Android)

### Các bước

```sh
# 1. Clone repo
git clone https://github.com/Miho1254/my-tlucalendar.git
cd my-tlucalendar

# 2. Cài dependency
flutter pub get

# 3. Chạy ở chế độ debug
flutter run

# 4. Build APK release
flutter build apk --release
```

---

## Tác giả

- **Dự án gốc:** [nekkochan0x0007](https://gitlab.com/nekkochan0x0007/tlucalendar)
- **Bản Refactor:** Nguyễn Duy Thành & Đặng Quang Hiển (Miho)
