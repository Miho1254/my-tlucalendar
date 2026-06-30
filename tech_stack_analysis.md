# Phân tích và Tóm tắt Tech Stack - TLU Calendar

Dự án **TLU Calendar** là một ứng dụng xem lịch học, lịch thi, và điểm số dành cho sinh viên Đại học Thủy Lợi (TLU). Ứng dụng này nhằm mục đích thay thế cho hệ thống xem lịch cũ (thường chứa nhiều quảng cáo) bằng một ứng dụng mã nguồn mở, miễn phí và không có quảng cáo, hỗ trợ đa nền tảng.

Dưới đây là tóm tắt chi tiết về cấu trúc, tech stack và các luồng chức năng quan trọng của mã nguồn để bạn có thể sẵn sàng bắt tay vào code.

---

## 1. Cấu trúc tổng thể của Repository

Mã nguồn được chia thành 3 phần chính (3 components):
1. **App (Thư mục gốc & `lib/`)**: Ứng dụng client chính, được viết bằng Flutter, hỗ trợ đa nền tảng (Android, iOS, Web, macOS, Linux, Windows).
2. **Proxy Server (`tlu-proxy-node/`)**: Một proxy server bằng Node.js. Thường được sử dụng để trung chuyển (proxy) các request từ client đến server của trường TLU nhằm tránh lỗi CORS trên Web hoặc để thêm lớp caching/xử lý.
3. **Crash/Minidump Server (`server/`)**: Một server nhỏ viết bằng Python (Flask + Gunicorn) chạy qua systemd (`minidump-server.service`), có nhiệm vụ nhận và phân tích các báo cáo lỗi/crash (minidump) từ client gửi về.

---

## 2. Tech Stack Chi Tiết

### A. Ứng dụng Client (Flutter)
- **Ngôn ngữ:** Dart (SDK `^3.11.5`)
- **Framework:** Flutter (`uses-material-design: true`)
- **State Management & Kiến trúc:** 
  - Sử dụng **Provider** (`provider: ^6.1.5+1`) để quản lý state (gồm các provider chính: `ThemeProvider`, `AuthProvider`, `ScheduleProvider`, `ExamProvider`, `SettingsProvider`, `GradeProvider`, `RegistrationProvider`).
  - **Dependency Injection (DI):** Sử dụng **GetIt** (`get_it: ^9.2.1`) được khởi tạo tại `injection_container.dart`.
- **Networking & API:**
  - **HTTP & Dio:** Sử dụng `http` và `dio` kết hợp với `dio_smart_retry` để call API mạnh mẽ và tự động retry khi lỗi mạng.
- **Local Storage & Database:**
  - **SQLite:** Sử dụng `sqlite3` để lưu trữ dữ liệu offline (lịch học, lịch thi, điểm).
  - **Shared Preferences:** Dùng để lưu các cấu hình nhỏ của người dùng (theme, cài đặt thông báo).
  - **Secure Storage & Encryption:** `flutter_secure_storage` và `encrypt` để bảo mật thông tin đăng nhập.
- **Background Tasks & Notifications:**
  - `android_alarm_manager_plus` & `flutter_local_notifications`: Để lên lịch nhắc nhở điểm danh, lịch học hằng ngày (DailyNotificationService).
- **Google Services & Firebase:**
  - **Firebase:** `firebase_core`, `firebase_messaging` (Push notification), `firebase_crashlytics` (Tracking lỗi).
  - **Google Login & Calendar:** `google_sign_in`, `googleapis`, `device_calendar` để đồng bộ lịch học của trường vào Google Calendar hoặc Lịch mặc định của điện thoại.
- **UI/UX & Animations:**
  - **Calendar UI:** Dùng `table_calendar`.
  - **Animations:** `lottie` (ảnh động), `shimmer` (hiệu ứng loading skeleton), `flutter_staggered_animations` (hiệu ứng xuất hiện danh sách).

### B. Node.js Proxy (`tlu-proxy-node/`)
- **Ngôn ngữ:** JavaScript / Node.js
- **File chính:** `api/index.js`
- **Mục đích:** Xử lý việc gọi API nội bộ trường đại học từ môi trường Web/App để bypass chặn CORS hoặc scrape dữ liệu.

### C. Minidump Server (`server/`)
- **Ngôn ngữ:** Python 3
- **Framework:** Flask (`flask==3.0.0`), chạy trên production với `gunicorn`.
- **Mục đích:** Quản lý log lỗi hệ thống (Crash analysis server).

---

## 3. Các Use Case (Chức năng cốt lõi)

Dựa vào các Provider và file cấu hình, đây là các use case chính mà app hỗ trợ:
1. **Xác thực (Authentication):** Đăng nhập vào hệ thống trường TLU (`AuthProvider`). Hỗ trợ lưu trữ an toàn thông tin đăng nhập.
2. **Xem Lịch Học (Schedule):** Lấy dữ liệu lịch học từ trường (`ScheduleProvider`), lưu offline vào SQLite, hiển thị dạng danh sách và dạng Lịch (Table Calendar).
3. **Xem Lịch Thi (Exam):** Theo dõi thời gian, địa điểm, SBD của các môn thi (`ExamProvider`).
4. **Xem Điểm Số (Grade):** Xem điểm các kỳ học (`GradeProvider`).
5. **Đăng ký Tín chỉ (Registration):** Tích hợp chức năng đăng ký môn học (`RegistrationProvider`).
6. **Nhắc nhở & Báo thức (Notifications):** Thiết lập báo thức hằng ngày nhắc nhở môn học, tự động cập nhật dữ liệu ngầm (`AutoRefreshService`).
7. **Đồng bộ Lịch (Sync):** Cho phép xuất lịch học/lịch thi sang ứng dụng Lịch của hệ điều hành hoặc Google Calendar.

---

## 4. Bắt đầu vào Code như thế nào?

- **Điểm bắt đầu (Entry point):** File `lib/main.dart` là trái tim của ứng dụng. Tại đây Firebase, Crashlytics, Notifications, Service Locator (`di.init()`), và toàn bộ các `Providers` được khởi tạo.
- **Quản lý dependencies:** Mở `lib/injection_container.dart` để xem cách các classes, repositories, datasources liên kết với nhau.
- **Chỉnh sửa UI/Màn hình:** Tìm trong thư mục `lib/screens/` và `lib/widgets/`.
- **Giao tiếp API:** Nằm trong thư mục `lib/services/` hoặc các thư mục datasource được đăng ký trong GetIt.

**Để chạy thử dự án:**
- Chạy lệnh `flutter pub get` để tải các thư viện.
- Bạn có thể chạy app trên máy ảo Android / iOS bằng các script có sẵn như `build_and_run.sh` hoặc thông qua IDE (VS Code / Android Studio).

Dự án được cấu trúc khá tốt theo dạng Feature-based hoặc Layer-based (có vẻ kết hợp clean architecture thông qua GetIt & Provider). Chúc bạn code vui vẻ!
