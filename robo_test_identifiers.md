# Firebase Robo Test — Identifier Report

## Tổng quan

Đã thêm **15 `ValueKey` identifiers** trên 3 file để Firebase Test Lab Robo Test có thể tự động navigate và tương tác với app.

---

## Danh sách identifiers

### [login_screen.dart](file:///d:/tlucalendar/lib/screens/login_screen.dart)

| Key | Widget | Mục đích |
|---|---|---|
| `studentCodeField` | `TextField` | Nhập mã sinh viên |
| `passwordField` | `TextField` | Nhập mật khẩu |
| `togglePasswordVisibility` | `IconButton` | Bật/tắt hiện mật khẩu |
| `loginButton` | `FilledButton` | Nút đăng nhập |

---

### [home_shell.dart](file:///d:/tlucalendar/lib/screens/home_shell.dart)

| Key | Widget | Mục đích |
|---|---|---|
| `navToday` | `NavigationDestination` | Tab "Hôm nay" |
| `navSchedule` | `NavigationDestination` | Tab "Lịch học" |
| `navExam` | `NavigationDestination` | Tab "Lịch thi" |
| `navSettings` | `NavigationDestination` | Tab "Cài đặt" |

---

### [settings_screen.dart](file:///d:/tlucalendar/lib/screens/settings_screen.dart)

| Key | Widget | Mục đích |
|---|---|---|
| `settingsLoginButton` | `FilledButton` | Nút đăng nhập (trong settings) |
| `logoutButton` | `OutlinedButton` | Nút đăng xuất |
| `autoRefreshSwitch` | `Switch` | Bật/tắt tự động làm mới |
| `dailyNotificationSwitch` | `Switch` | Bật/tắt thông báo hàng ngày |
| `darkModeSwitch` | `Switch` | Bật/tắt chế độ tối |
| `backupButton` | `ListTile` | Sao lưu dữ liệu |
| `restoreButton` | `ListTile` | Khôi phục dữ liệu |

---

## Sử dụng với Robo Test

Trong Firebase Test Lab, tạo **Robo Script** (JSON) để tự động đăng nhập:

```json
[
  {
    "eventType": "VIEW_TEXT_CHANGED",
    "replacementText": "2151xxxx",
    "elementDescriptors": [
      { "resourceId": "studentCodeField" }
    ]
  },
  {
    "eventType": "VIEW_TEXT_CHANGED", 
    "replacementText": "your_password",
    "elementDescriptors": [
      { "resourceId": "passwordField" }
    ]
  },
  {
    "eventType": "VIEW_CLICKED",
    "elementDescriptors": [
      { "resourceId": "loginButton" }
    ]
  }
]
```

> [!NOTE]
> Vì Flutter render custom canvas (không dùng Android View system), Robo Test có thể cần dùng **coordinate-based** actions thay vì resource ID. Nếu Robo Test không nhận diện `ValueKey`, hãy dùng **Robo Script recorder** trong Android Studio để ghi lại thao tác bằng tọa độ.
