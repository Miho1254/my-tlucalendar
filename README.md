# TLU Calendar (Miho's Version)

Đây là dự án cá nhân được refactor lại từ ứng dụng TLU Calendar gốc theo sở thích và nhu cầu cá nhân, vì một số tính năng của phiên bản gốc chưa đáp ứng được mong muốn của mình.

## Tác giả gốc

🙏 Rất cảm ơn tác giả gốc của ứng dụng đã tạo ra một nền tảng tuyệt vời để mình có thể dựa vào và phát triển thêm.
* **Tác giả:** nekkochan0x0007
* **Source code gốc:** [https://gitlab.com/nekkochan0x0007/tlucalendar](https://gitlab.com/nekkochan0x0007/tlucalendar)

## Những thay đổi chính trong phiên bản này

Trong quá trình refactor, mình đã tập trung vào việc tối ưu hóa giao diện (UI) và trải nghiệm người dùng (UX), đặc biệt là:

1.  **Thiết kế lại toàn diện Cài đặt (Settings):**
    *   Áp dụng ngôn ngữ thiết kế chuẩn Apple HIG kết hợp với hệ thống component của `forui`.
    *   Bổ sung tính năng Backup/Restore dữ liệu, và ẩn tính năng System Logs vào Developer Mode (nhấn 5 lần vào phiên bản để mở khóa).
2.  **Cải tiến Tiện ích & Trải nghiệm:**
    *   Chuyển các tính năng "Tra cứu điểm" và "Đăng ký học" ra màn hình "Hôm nay" để tiện truy cập ngay lập tức.
    *   Bổ sung luồng Setup Wizard (Trình thiết lập 3 bước) cho người dùng mới khi khởi chạy ứng dụng lần đầu.
    *   Redesign nút bấm mở bộ lọc lịch thi đẹp mắt hơn, có haptic feedback mang lại cảm giác phản hồi tự nhiên.
3.  **Hỗ trợ hoàn chỉnh Light/Dark Mode:**
    *   Loại bỏ hoàn toàn các màu nền cứng (hardcode colors), chuyển đổi toàn bộ sang dùng semantic colors (`colorScheme`) giúp app thích ứng tự nhiên với cả giao diện sáng và tối.
    *   Sửa lỗi tương phản trên các thẻ lịch thi (Exam Cards) trong Dark Mode.
    *   Tối ưu hóa màu chữ, bỏ các lớp `Opacity` làm mờ chữ không cần thiết, giúp văn bản cực kì sắc nét.
4.  **Làm mới giao diện Lịch (Calendar UI):**
    *   Thay đổi cách nhận diện ngày hiện tại (Today): Bỏ gạch chân khó nhìn, thay bằng vòng tròn nổi bật.
    *   Thay đổi màu sắc và kích thước của các dấu chấm (dots) báo hiệu có lịch học/lịch thi để dễ nhận diện hơn, đặc biệt trên nền sáng.
5.  **Tinh chỉnh Bố cục & Fix Bug:**
    *   Loại bỏ các sticky header (tiêu đề bám dính) không cần thiết ở màn hình Lịch thi và Cài đặt, giúp cuộn mượt mà hơn.
    *   Fix triệt để lỗi crash app trên nền tảng Linux do thiếu cấu hình `flutter_local_notifications`.
    *   Cập nhật thông tin tác giả bản refactor và version mới nhất (`2026.07.01`).

## Tác giả bản Refactor

* Nguyễn Duy Thành & Đặng Quang Hiển (Miho)
