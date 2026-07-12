/// Maps raw error messages to friendly Vietnamese text.
/// Raw errors stay in logs; users see only these.
class ErrorMessages {
  static String friendly(String? raw) {
    if (raw == null || raw.isEmpty) return 'Đã xảy ra lỗi không xác định';

    final lower = raw.toLowerCase();

    // Network
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('no_internet') ||
        lower.contains('connection refused') ||
        lower.contains('connection timed out') ||
        lower.contains('network is unreachable')) {
      return 'Mạng bị lỗi. Kiểm tra lại kết nối và thử lại.';
    }

    // Timeout
    if (lower.contains('timeout') || lower.contains('deadline')) {
      return 'Mất quá lâu để phản hồi. Thử lại sau vài giây.';
    }

    // Auth
    if (lower.contains('401') ||
        lower.contains('unauthorized') ||
        lower.contains('token') ||
        lower.contains('login') ||
        lower.contains('đăng nhập')) {
      return 'Phiên đăng nhập đã hết hạn. Đăng nhập lại để tiếp tục.';
    }

    // Server
    if (lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('server') ||
        lower.contains('internal')) {
      return 'Máy chủ đang gặp sự cố. Thử lại sau vài phút.';
    }

    // 404
    if (lower.contains('404') || lower.contains('not found')) {
      return 'Không tìm thấy dữ liệu. Dữ liệu có thể chưa được cập nhật.';
    }

    // Cache/offline
    if (lower.contains('cache') ||
        lower.contains('offline') ||
        lower.contains('cacheddata')) {
      return 'Đang dùng dữ liệu đã lưu. Kết nối mạng để cập nhật.';
    }

    // Parse
    if (lower.contains('parse') ||
        lower.contains('format') ||
        lower.contains('json')) {
      return 'Dữ liệu trả về bị lỗi. Thử lại sau.';
    }

    // Default
    return 'Không thể tải dữ liệu. Thử lại sau.';
  }
}
