# TLU Calendar (Miho's Version)

Đây là dự án cá nhân được refactor lại từ ứng dụng TLU Calendar gốc theo sở thích và nhu cầu cá nhân, vì một số tính năng của phiên bản gốc chưa đáp ứng được mong muốn của mình.

## Tác giả gốc

🙏 Rất cảm ơn tác giả gốc của ứng dụng đã tạo ra một nền tảng tuyệt vời để mình có thể dựa vào và phát triển thêm.
* **Tác giả:** nekkochan0x0007
* **Source code gốc:** [https://gitlab.com/nekkochan0x0007/tlucalendar](https://gitlab.com/nekkochan0x0007/tlucalendar)

## Những thay đổi chính trong phiên bản này

Trong quá trình refactor, mình đã tập trung vào việc tối ưu hóa giao diện (UI) và trải nghiệm người dùng (UX), đặc biệt là:

1.  **Cải thiện Dark Mode & Độ Tương Phản:**
    *   Sửa lỗi hiển thị màu sắc trên các thẻ lịch thi (Exam Cards) trong Dark Mode để tăng độ tương phản.
    *   Tối ưu hóa màu chữ, bỏ các lớp `Opacity` làm mờ chữ không cần thiết, giúp văn bản sắc nét và dễ đọc hơn trên cả White Mode và Dark Mode.
2.  **Làm mới giao diện Lịch (Calendar UI):**
    *   Thay đổi cách nhận diện ngày hiện tại (Today): Bỏ gạch chân khó nhìn, thay bằng vòng tròn nổi bật.
    *   Thay đổi màu sắc và kích thước của các dấu chấm (dots) báo hiệu có lịch học/lịch thi để dễ nhận diện hơn, đặc biệt trên nền sáng.
3.  **Tinh chỉnh Bố cục (Layout):**
    *   Loại bỏ các sticky header (tiêu đề bám dính) không cần thiết ở màn hình Lịch thi và Cài đặt, giúp không gian cuộn mượt mà và liền mạch hơn.
4.  **Cập nhật thông tin:**
    *   Cập nhật phiên bản ứng dụng thành `2026.07.01`.
    *   Thêm thông tin tác giả bản refactor.

## Tác giả bản Refactor

* Nguyễn Duy Thành & Đặng Quang Hiển (Miho)
