import 'dart:async';

import 'package:flutter/material.dart';

/// Data toast states — each maps to a dot color and default message.
enum DataToastState {
  success,
  offline,
  error,
  reconnecting,
}

class DataToast extends StatefulWidget {
  final String message;
  final DataToastState state;
  final Duration duration;
  final VoidCallback? onTap;

  const DataToast({
    super.key,
    required this.message,
    this.state = DataToastState.success,
    this.duration = const Duration(seconds: 3),
    this.onTap,
  });

  @override
  State<DataToast> createState() => _DataToastState();

  // ── Static API ──────────────────────────────────────────────────────────────

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    DataToastState state = DataToastState.success,
    String? message,
    Duration? duration,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final resolvedMessage = message ?? _defaultMessage(state);
    final resolvedDuration = duration ?? _defaultDuration(state);

    final entry = OverlayEntry(
      builder: (_) => DataToast(
        message: resolvedMessage,
        state: state,
        duration: resolvedDuration,
        onTap: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );
    _currentEntry = entry;
    Overlay.of(context).insert(entry);
  }

  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static String _defaultMessage(DataToastState state) {
    switch (state) {
      case DataToastState.success:
        return 'Dữ liệu đã được cập nhật';
      case DataToastState.offline:
        return 'Đang dùng dữ liệu offline';
      case DataToastState.error:
        return 'Không thể cập nhật dữ liệu';
      case DataToastState.reconnecting:
        return 'Đang kết nối lại...';
    }
  }

  static Duration _defaultDuration(DataToastState state) {
    switch (state) {
      case DataToastState.success:
        return const Duration(seconds: 3);
      case DataToastState.offline:
        return const Duration(seconds: 4);
      case DataToastState.error:
        return const Duration(seconds: 5);
      case DataToastState.reconnecting:
        return const Duration(seconds: 4);
    }
  }
}

class _DataToastState extends State<DataToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  Timer? _dismissTimer;

  Color get _dotColor {
    switch (widget.state) {
      case DataToastState.success:
        return const Color(0xFF6366F1); // indigo
      case DataToastState.offline:
        return const Color(0xFFA1A1AA); // zinc-400
      case DataToastState.error:
        return const Color(0xFFEF4444); // red
      case DataToastState.reconnecting:
        return const Color(0xFF6366F1); // indigo
    }
  }

  Color get _borderColor {
    switch (widget.state) {
      case DataToastState.success:
        return const Color(0xFF6366F1).withValues(alpha: 0.25);
      case DataToastState.offline:
        return const Color(0xFFA1A1AA).withValues(alpha: 0.2);
      case DataToastState.error:
        return const Color(0xFFEF4444).withValues(alpha: 0.25);
      case DataToastState.reconnecting:
        return const Color(0xFF6366F1).withValues(alpha: 0.2);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          DataToast._currentEntry?.remove();
          DataToast._currentEntry = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _borderColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // State indicator dot
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Message
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Color(0xFFFAFAFA),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'BeVietnamPro',
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dismiss icon
                    Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: const Color(0xFFA1A1AA).withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
