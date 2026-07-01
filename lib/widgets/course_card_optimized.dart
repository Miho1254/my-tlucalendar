import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:tlucalendar/features/schedule/domain/entities/course.dart';
import 'package:tlucalendar/providers/note_provider.dart';
import 'package:tlucalendar/widgets/note_bottom_sheet.dart';

class CourseCardOptimized extends StatefulWidget {
  final Course course;
  final String timeRange;
  final DateTime classDate;
  final bool isPast;
  final bool isCurrent;
  final VoidCallback? onTap;

  const CourseCardOptimized({
    super.key,
    required this.course,
    required this.timeRange,
    required this.classDate,
    this.isPast = false,
    this.isCurrent = false,
    this.onTap,
  });

  @override
  State<CourseCardOptimized> createState() => _CourseCardOptimizedState();
}

class _CourseCardOptimizedState extends State<CourseCardOptimized> {
  bool _isSkipped = false;

  void _handleSkip(DismissDirection direction) {
    setState(() {
      _isSkipped = true;
    });

    final messages = [
      "Đã đánh dấu cúp học. Tính sơ sơ vừa bay 150k tiền học phí nha!",
      "Cẩn thận giảng viên điểm danh nhé sếp!",
      "Tôn ngộ không cũng không cứu nổi điểm chuyên cần của bạn."
    ];
    
    messages.shuffle();
    FToaster.of(context).show(
      builder: (context, entry) => FToast(
        title: Text(messages.first),
        variant: FToastVariant.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final referenceId = 'course_${widget.course.id}_${widget.classDate.millisecondsSinceEpoch}';
    final hasNote = context.watch<NoteProvider>().hasNoteFor(referenceId);
    // Use surface color with some elevation styling equivalent
    final bgColor = theme.colorScheme.surface;
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.5);

    // Build the main tile
    Widget content = FTile(
      onPress: widget.onTap,
      title: Text(
        widget.course.courseName,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          decoration: _isSkipped ? TextDecoration.lineThrough : null,
          color: _isSkipped ? Colors.grey : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '${widget.course.room} • ${widget.timeRange}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: widget.isCurrent ? theme.colorScheme.primary : null,
              fontWeight: widget.isCurrent ? FontWeight.bold : null,
            ),
          ),
          if (widget.course.className != null && widget.course.className!.isNotEmpty)
            Text('Lớp: ${widget.course.className}'),
        ],
      ),
      prefix: Icon(
        widget.isCurrent ? Icons.radio_button_checked : Icons.book,
        color: widget.isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        size: 20,
      ),
      suffix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  FLucideIcons.notebookPen,
                  size: 20,
                  color: hasNote ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                if (hasNote)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: bgColor, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => NoteBottomSheet(
                  referenceId: widget.course.id.toString(),
                  title: widget.course.courseName,
                  eventDate: DateTime.fromMillisecondsSinceEpoch(widget.course.startDate),
                ),
              );
            },
          ),
          if (widget.isPast || _isSkipped)
            const Icon(Icons.check_circle_outline, color: Colors.grey, size: 20)
          else
            const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );

    // Apply the container styling
    content = Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Opacity(
        opacity: widget.isPast || _isSkipped ? 0.5 : 1.0,
        child: content,
      ),
    );

    // If it's not past, allow swipe to skip gamification
    if (!widget.isPast && !_isSkipped) {
      return Dismissible(
        key: Key('course_${widget.course.id}_${widget.course.startDate}'),
        direction: DismissDirection.endToStart,
        onDismissed: _handleSkip,
        background: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.person_off, color: Colors.white),
        ),
        child: content,
      );
    }

    return content;
  }
}
