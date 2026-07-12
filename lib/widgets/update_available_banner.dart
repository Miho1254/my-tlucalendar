import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tlucalendar/services/update_service.dart';

/// Lightweight toast that slides in from top-right when a new version exists.
/// Fires at most once per app session — no persistent widget needed.
class UpdateAvailableBanner {
  static bool _shownThisSession = false;
  static OverlayEntry? _currentEntry;

  /// Check daily + show toast once per session. Call from HomeShell initState.
  static Future<void> checkAndShow(BuildContext context) async {
    if (_shownThisSession) return;

    final result = await UpdateService.checkDaily();
    if (result == null || !result.hasUpdate) return;

    final dismissed = await UpdateService.isDismissed(result.latestVersion);
    if (dismissed) return;

    _shownThisSession = true;
    if (context.mounted) _show(context, result);
  }

  static void _show(BuildContext context, UpdateCheckResult result) {
    _currentEntry?.remove();

    _currentEntry = OverlayEntry(
      builder: (_) => _UpdateToastWidget(
        result: result,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
          UpdateService.dismiss(result.latestVersion);
        },
        onTap: () async {
          _currentEntry?.remove();
          _currentEntry = null;
          UpdateService.dismiss(result.latestVersion);
          final uri = Uri.parse(result.releaseUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }
}

class _UpdateToastWidget extends StatefulWidget {
  final UpdateCheckResult result;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _UpdateToastWidget({
    required this.result,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_UpdateToastWidget> createState() => _UpdateToastWidgetState();
}

class _UpdateToastWidgetState extends State<_UpdateToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.forward();

    _autoDismiss = Timer(const Duration(seconds: 4), () {
      if (mounted) _dismiss();
    });
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topPadding + 8,
      left: 12,
      right: 12,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
          )),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Phiên bản mới sẵn sàng',
                            style: TextStyle(
                              color: Color(0xFFFAFAFA),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'BeVietnamPro',
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'v${widget.result.latestVersion}  ·  Nhấn để cập nhật',
                            style: TextStyle(
                              color: const Color(0xFFA1A1AA).withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'BeVietnamPro',
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _dismiss,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: const Color(0xFFA1A1AA).withValues(alpha: 0.5),
                        ),
                      ),
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
