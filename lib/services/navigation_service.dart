import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Đẩy màn hình mới có thể truy xuất từ mọi nơi (kể cả hàm tĩnh)
  static Future<dynamic> navigateTo(Widget page) {
    if (navigatorKey.currentState != null) {
      return navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (context) => page),
      );
    }
    return Future.value(null);
  }

  /// Đẩy màn hình mới đè lên và xoá history màn hình trước (ví dụ cho lúc start app)
  static Future<dynamic> navigateAndRemoveUntil(Widget page) {
    if (navigatorKey.currentState != null) {
      return navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => page),
        (route) => false,
      );
    }
    return Future.value(null);
  }
}
