import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:tlucalendar/features/notes/domain/models/note_model.dart';
import 'package:tlucalendar/providers/note_provider.dart';
import 'package:tlucalendar/features/schedule/domain/entities/course.dart';

enum CourseStatus { past, current, future }

class TimelineItemOptimized extends StatelessWidget {
  final Course course;
  final bool isLast;
  final CourseStatus status;
  final String startTime;
  final String timeRange;

  const TimelineItemOptimized({
    super.key,
    required this.course,
    required this.isLast,
    required this.status,
    required this.startTime,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color cardColor;
    Color contentColor;
    bool isCurrent = false;

    switch (status) {
      case CourseStatus.past:
        cardColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
        contentColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
        break;
      case CourseStatus.current:
        cardColor = colorScheme.primary.withValues(alpha: 0.1);
        contentColor = colorScheme.onSurface;
        isCurrent = true;
        break;
      case CourseStatus.future:
        cardColor = Colors.transparent;
        contentColor = colorScheme.onSurface;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Column
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(
                  startTime,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCurrent
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: colorScheme.surface, width: 2)
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),

          // Forui-style Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _PulseWrapper(
                isPulsing: isCurrent,
                child: FCard.raw(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      border: isCurrent 
                          ? Border.all(color: colorScheme.primary.withValues(alpha: 0.3), width: 1.5)
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildCardContent(
                        context,
                        colorScheme,
                        contentColor,
                        isCurrent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    ColorScheme colorScheme,
    Color contentColor,
    bool isCurrent,
  ) {
    final theme = Theme.of(context);
    final note = context.watch<NoteProvider>().getNoteFor(course.id.toString());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Name
        Text(
          course.courseName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: contentColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Room Badge (Pastel Badge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: status == CourseStatus.current 
                    ? colorScheme.primary 
                    : colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.room,
                    size: 14,
                    color: status == CourseStatus.current 
                        ? colorScheme.onPrimary 
                        : colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    course.room.isNotEmpty ? course.room : 'Chưa có phòng',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: status == CourseStatus.current 
                          ? colorScheme.onPrimary 
                          : colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Muted Text for Course Code / Instructor
            Expanded(
              child: Text(
                'Mã: ${course.courseCode}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(FLucideIcons.notebookPen, size: 14, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.type == NoteType.plainText
                        ? (note.content?.isNotEmpty == true ? note.content! : 'Có ghi chú')
                        : 'Có ${note.items?.where((i) => !i.isCompleted).length ?? 0} công việc chưa xong',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PulseWrapper extends StatefulWidget {
  final Widget child;
  final bool isPulsing;

  const _PulseWrapper({required this.child, this.isPulsing = false});

  @override
  State<_PulseWrapper> createState() => _PulseWrapperState();
}

class _PulseWrapperState extends State<_PulseWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PulseWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPulsing) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: widget.child,
    );
  }
}
