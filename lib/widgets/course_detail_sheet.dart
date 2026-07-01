import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:tlucalendar/features/schedule/domain/entities/course.dart';
import 'package:tlucalendar/services/notification_service.dart';
import 'package:tlucalendar/providers/note_provider.dart';
import 'package:tlucalendar/features/notes/domain/models/note_model.dart';

class CourseDetailSheet extends StatefulWidget {
  final Course course;
  final DateTime classDate;
  final String timeRange;

  const CourseDetailSheet({
    super.key,
    required this.course,
    required this.classDate,
    required this.timeRange,
  });

  @override
  State<CourseDetailSheet> createState() => _CourseDetailSheetState();
}

class _CourseDetailSheetState extends State<CourseDetailSheet> {
  final TextEditingController _noteController = TextEditingController();
  bool _isTodoMode = false;
  bool _isDone = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  String get _referenceId => 'course_${widget.course.id}_${widget.classDate.millisecondsSinceEpoch}';

  Future<void> _loadNote() async {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final note = noteProvider.getNoteFor(_referenceId);
    if (note != null) {
      setState(() {
        _isTodoMode = note.type == NoteType.todo;
        if (_isTodoMode && note.items != null && note.items!.isNotEmpty) {
          final item = note.items!.first;
          _noteController.text = item.text;
          _isDone = item.isCompleted;
        } else {
          _noteController.text = note.content ?? '';
          _isDone = false;
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _noteController.text = '';
        _isTodoMode = false;
        _isDone = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNote() async {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final noteText = _noteController.text.trim();
    
    if (noteText.isEmpty) {
      final existingNote = noteProvider.getNoteFor(_referenceId);
      if (existingNote != null) {
        await noteProvider.deleteNote(existingNote.id);
      }
      await NotificationService().cancelCourseNoteNotification(widget.course, widget.classDate);
      if (mounted) {
        FToaster.of(context).show(
          builder: (context, entry) => FToast(
            title: const Text('Đã xoá ghi chú'),
            variant: FToastVariant.primary,
          ),
        );
      }
      return;
    }

    final existingNote = noteProvider.getNoteFor(_referenceId);
    final id = existingNote?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final note = NoteModel(
      id: id,
      referenceId: _referenceId,
      title: 'Ghi chú: ${widget.course.courseName}',
      type: _isTodoMode ? NoteType.todo : NoteType.plainText,
      content: _isTodoMode ? null : noteText,
      items: _isTodoMode ? [NoteItem(id: '1', text: noteText, isCompleted: _isDone)] : null,
      createdAt: existingNote?.createdAt ?? DateTime.now(),
    );

    await noteProvider.saveNote(note);

    // Schedule notification 24h before if it's not done
    if (!_isDone) {
      await NotificationService().scheduleCourseNoteNotification(
        widget.course,
        widget.classDate,
        noteText,
      );
    } else {
      await NotificationService().cancelCourseNoteNotification(widget.course, widget.classDate);
    }

    if (mounted) {
      FToaster.of(context).show(
        builder: (context, entry) => FToast(
          title: const Text('Đã lưu ghi chú & Hẹn giờ nhắc nhở!'),
          variant: FToastVariant.primary,
        ),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Text(
            widget.course.courseName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          FTileGroup(
            children: [
              FTile(
                title: const Text('Thời gian'),
                subtitle: Text(widget.timeRange),
                prefix: const Icon(Icons.access_time, size: 20),
              ),
              FTile(
                title: const Text('Phòng học'),
                subtitle: Text(widget.course.room),
                prefix: const Icon(Icons.location_on_outlined, size: 20),
              ),
              if (widget.course.lecturerName != null && widget.course.lecturerName!.isNotEmpty)
                FTile(
                  title: const Text('Giảng viên'),
                  subtitle: Text(widget.course.lecturerName!),
                  prefix: const Icon(Icons.person_outline, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ghi chú cá nhân',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Text('Chế độ Todo', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 8),
                  FSwitch(
                    value: _isTodoMode,
                    onChange: (val) {
                      setState(() {
                        _isTodoMode = val;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_isTodoMode)
            Row(
              children: [
                FCheckbox(
                  value: _isDone,
                  onChange: (val) {
                    setState(() {
                      _isDone = val;
                    });
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration: _isDone ? TextDecoration.lineThrough : null,
                      color: _isDone ? Colors.grey : null,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập công việc cần làm...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            )
          else
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú cho buổi học này...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
            
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: FButton(
              onPress: () {
                _saveNote();
                Navigator.pop(context);
              },
              child: const Text('Lưu ghi chú & Đóng'),
            ),
          ),
        ],
      ),
    );
  }
}
