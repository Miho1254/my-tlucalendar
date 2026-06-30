import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tlucalendar/features/schedule/domain/entities/course.dart';
import 'package:tlucalendar/services/notification_service.dart';

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

  String get _storageKey => 'course_note_${widget.course.id}_${widget.classDate.millisecondsSinceEpoch}';
  String get _modeKey => 'course_note_mode_${widget.course.id}_${widget.classDate.millisecondsSinceEpoch}';
  String get _doneKey => 'course_note_done_${widget.course.id}_${widget.classDate.millisecondsSinceEpoch}';

  Future<void> _loadNote() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _noteController.text = prefs.getString(_storageKey) ?? '';
      _isTodoMode = prefs.getBool(_modeKey) ?? false;
      _isDone = prefs.getBool(_doneKey) ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveNote() async {
    final prefs = await SharedPreferences.getInstance();
    final noteText = _noteController.text.trim();
    
    if (noteText.isEmpty) {
      await prefs.remove(_storageKey);
      await prefs.remove(_modeKey);
      await prefs.remove(_doneKey);
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

    await prefs.setString(_storageKey, noteText);
    await prefs.setBool(_modeKey, _isTodoMode);
    await prefs.setBool(_doneKey, _isDone);

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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              const Text(
                'Ghi chú cá nhân',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  const Text('Chế độ Todo', style: TextStyle(fontSize: 13)),
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
                    style: TextStyle(
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
