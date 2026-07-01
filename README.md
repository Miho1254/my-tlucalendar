<div align="center">
  <h1>TLU Calendar</h1>
  <p><strong>Ứng dụng mã nguồn mở giúp sinh viên Đại học Thủy Lợi theo dõi lịch học, lịch thi và quá trình học tập.</strong></p>
  <br />
  <a href="https://github.com/Miho1254/my-tlucalendar/releases/latest">Tải APK mới nhất</a>
  &nbsp;&middot;&nbsp;
  <a href="#tinh-nang">Tính năng</a>
  &nbsp;&middot;&nbsp;
  <a href="#tu-build">Tự build</a>
  &nbsp;&middot;&nbsp;
  <a href="#dong-gop">Đóng góp</a>
  <br /><br />
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/github/actions/workflow/status/Miho1254/my-tlucalendar/release_main.yaml?style=flat-square&label=Release" alt="Release workflow">
  <img src="https://img.shields.io/badge/platform-Android-green?style=flat-square&logo=android" alt="Android">
</div>

---

## <a id="gioi-thieu"></a>Giới thiệu

**TLU Calendar** là một bản fork cộng đồng từ dự án [TLU Calendar gốc](https://gitlab.com/nekkochan0x0007/tlucalendar), tập trung vào trải nghiệm sử dụng hằng ngày cho sinh viên Đại học Thủy Lợi.

Bản fork này không phải ứng dụng chính thức của nhà trường. Mục tiêu của dự án là cung cấp một client mở, dễ kiểm tra, dễ tự build và có thể hoạt động ổn định hơn trong các tình huống mạng trường chập chờn hoặc API trả dữ liệu không nhất quán.

Các hướng nâng cấp chính:

- Giao diện mới dựa trên `forui`, nhất quán hơn giữa Light Mode và Dark Mode.
- Hệ thống cố vấn học tập, phân tích điểm và mô phỏng mục tiêu tốt nghiệp.
- Cải thiện UX/UI cho các luồng thường dùng như xem lịch, đổi học kỳ, lọc lịch thi và kéo để làm mới.
- Offline mode và quản lý cache thông minh hơn, giúp app vẫn dùng được với dữ liệu đã đồng bộ.
- Sửa các lỗi còn sót lại từ bản gốc, đặc biệt ở phần nhận diện học kỳ, lịch học, lịch thi và trạng thái kết nối.

---

## <a id="tinh-nang"></a>Tính năng

### Lịch học và lịch thi

- Đồng bộ thời khóa biểu và lịch thi theo học kỳ.
- Xem lịch học theo ngày hoặc theo tuần.
- Đổi học kỳ trực tiếp trong màn lịch học.
- Lọc lịch thi theo học kỳ, đợt học và lần thi.
- Ghi chú cá nhân cho từng buổi học hoặc môn thi.

### Phân tích học tập

- Xem điểm theo từng học kỳ.
- Theo dõi GPA và xu hướng học tập.
- Mô phỏng điểm cần đạt để hướng tới mục tiêu tốt nghiệp.
- Cố vấn học tập hiển thị các nhận xét thực dụng dựa trên dữ liệu điểm hiện có.

### Offline và cache

- Lưu dữ liệu lịch học, lịch thi và điểm số vào SQLite cục bộ.
- Mở app nhanh hơn nhờ ưu tiên dữ liệu cache trước khi đồng bộ lại.
- Pull-to-refresh để chủ động cập nhật dữ liệu mới.
- Trạng thái offline/refresh được tách rõ để tránh báo nhầm mất kết nối khi đang tải dữ liệu.

### Giao diện và trải nghiệm

- UI được refactor theo hệ component `forui`.
- Hỗ trợ Light Mode và Dark Mode bằng semantic color thay vì màu hardcode.
- Setup Wizard cho người dùng mới.
- Thanh điều hướng và các màn chính được tinh chỉnh để giảm scroll thừa, lỗi padding và các trạng thái rỗng khó hiểu.

---

## <a id="khac-biet-so-voi-ban-goc"></a>Khác biệt so với bản gốc

Bản fork này giữ lại ý tưởng và nền tảng của dự án gốc, nhưng refactor lại nhiều phần để phục vụ việc bảo trì lâu dài hơn.

| Nhóm thay đổi | Nội dung |
| --- | --- |
| Giao diện | Chuyển dần sang `forui`, làm lại các màn chính, cải thiện spacing, typography, trạng thái rỗng và Dark Mode. |
| Học tập | Bổ sung phân tích quá trình học, mô phỏng GPA và cố vấn học tập. |
| Lịch học | Sửa lỗi chọn nhầm học kỳ khi API trả nhiều kỳ `isCurrent=true`, ví dụ "Chuẩn đầu ra ngoại ngữ". |
| Lịch thi | Cải thiện bộ lọc học kỳ/đợt/lần thi và hạn chế reset filter không cần thiết. |
| Offline | Cải thiện cache local, luồng refresh và trạng thái kết nối. |
| Ổn định | Sửa các lỗi UI/logic nhỏ còn sót lại từ bản gốc, bao gồm lỗi hiển thị ghi chú, scroll, init dữ liệu sau login và một số crash nền tảng. |

---

## <a id="cai-dat"></a>Cài đặt

### Tải APK

APK release được đăng tại trang [GitHub Releases](https://github.com/Miho1254/my-tlucalendar/releases/latest).

Mỗi release mới nên có:

- File APK để cài đặt trên Android.
- Checksum SHA-256 để kiểm tra artifact.
- Source archive do GitHub tự tạo theo tag.

Ứng dụng cũng có thể kiểm tra bản mới từ GitHub Releases trong màn Cài đặt. Để giảm cảnh báo không cần thiết từ Android/Play Protect, app chỉ mở trang release trong trình duyệt và không tự xin quyền cài APK trong nền.

### <a id="tu-build"></a>Tự build

Yêu cầu:

- Flutter SDK 3.x trở lên.
- Android SDK nếu muốn chạy hoặc build APK Android.
- JDK phù hợp với cấu hình Gradle của dự án.

```sh
git clone https://github.com/Miho1254/my-tlucalendar.git
cd my-tlucalendar
flutter pub get
flutter run
```

Build APK release:

```sh
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### Signing release

APK phát hành cần được ký bằng cùng một keystore qua mọi phiên bản để Android cho phép cài đè. GitHub Actions dùng các secret sau:

- `KEYSTORE_BASE64`: file `rel.jks` encode base64.
- `KEY_ALIAS`: alias của key.
- `KEY_PASSWORD`: mật khẩu key.
- `STORE_PASSWORD`: mật khẩu keystore.

Không dùng keystore tạm cho release công khai. Nếu đổi signing key, người dùng đang cài bản cũ sẽ phải gỡ app trước khi cài bản mới.

---

## <a id="cau-truc-du-an"></a>Cấu trúc dự án

```text
lib/
  core/          Core error, network, native parser
  features/      Auth, schedule, exam, grades, registration
  providers/     App state providers
  screens/       Main app screens
  services/      Database, notifications, refresh, backup
  widgets/       Shared UI widgets
android/         Android host project
.github/         Release workflow
```

---

## <a id="quyen-rieng-tu"></a>Quyền riêng tư

Ứng dụng cần tài khoản sinh viên để đồng bộ dữ liệu từ hệ thống đào tạo. Token và thông tin đăng nhập phục vụ auto-login được lưu trên thiết bị bằng local storage/secure storage của app.

Dự án không vận hành server riêng để thu thập dữ liệu học tập của người dùng. Khi tự build từ source, bạn có thể kiểm tra trực tiếp luồng đăng nhập, cache và đồng bộ trong mã nguồn.

---

## <a id="dong-gop"></a>Đóng góp

Issue và pull request đều được hoan nghênh. Các đóng góp phù hợp nhất hiện tại:

- Sửa lỗi đồng bộ dữ liệu với API trường.
- Cải thiện cache/offline mode.
- Bổ sung test cho provider, repository và parser.
- Cải thiện accessibility, responsive layout và trạng thái rỗng.
- Viết tài liệu cài đặt, release và troubleshooting rõ hơn.

Trước khi gửi PR, nên chạy:

```sh
dart format .
flutter analyze
```

---

## <a id="trang-thai-license"></a>Trạng thái license

Repository hiện chưa có file `LICENSE`. Nếu bạn muốn dùng, phân phối lại hoặc đóng gói bản build riêng, hãy kiểm tra license của dự án gốc và thêm license rõ ràng cho bản fork trước khi phát hành công khai.

---

## <a id="ghi-nhan"></a>Ghi nhận

- Dự án gốc: [nekkochan0x0007/tlucalendar](https://gitlab.com/nekkochan0x0007/tlucalendar)
- Bản fork/refactor: Đặng Quang Hiển (Miho)
