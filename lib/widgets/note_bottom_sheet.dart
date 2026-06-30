import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:tlucalendar/features/notes/domain/models/note_model.dart';
import 'package:tlucalendar/features/notes/data/services/note_service.dart';
import 'package:tlucalendar/services/notification_service.dart';

class NoteBottomSheet extends StatefulWidget {
  final String referenceId; // Course Code or Exam Id
  final String title;
  final DateTime? eventDate;

  const NoteBottomSheet({
    super.key,
    required this.referenceId,
    required this.title,
    this.eventDate,
  });

  @override
  State<NoteBottomSheet> createState() => _NoteBottomSheetState();
}

class _NoteBottomSheetState extends State<NoteBottomSheet> {
  final _noteService = NoteService();
  bool _isLoading = true;
  NoteModel? _note;
  
  final _textController = TextEditingController();
  final _todoController = TextEditingController();
  
  NoteType _currentType = NoteType.plainText;
  List<NoteItem> _todoItems = [];
  bool _enableReminder = false;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final notes = await _noteService.getNotesForReference(widget.referenceId);
    if (notes.isNotEmpty) {
      _note = notes.first;
      _currentType = _note!.type;
      _enableReminder = _note!.hasReminder;
      if (_currentType == NoteType.plainText) {
        _textController.text = _note!.content ?? '';
      } else {
        _todoItems = List.from(_note!.items ?? []);
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveNote() async {
    HapticFeedback.mediumImpact();
    
    final newNote = NoteModel(
      id: _note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      referenceId: widget.referenceId,
      title: widget.title,
      type: _currentType,
      content: _currentType == NoteType.plainText ? _textController.text : null,
      items: _currentType == NoteType.todo ? _todoItems : null,
      createdAt: _note?.createdAt ?? DateTime.now(),
      hasReminder: _enableReminder,
    );

    await _noteService.saveNote(newNote);

    if (_enableReminder && widget.eventDate != null) {
      final notiService = NotificationService();
      await notiService.scheduleReminder(
        widget.eventDate!,
        'Nhắc nhở: ${widget.title}',
        _currentType == NoteType.plainText 
          ? (_textController.text.isNotEmpty ? _textController.text : 'Bạn có ghi chú cho môn học này')
          : 'Bạn có ${_todoItems.where((i) => !i.isCompleted).length} công việc cần hoàn thành!',
        'note_${widget.referenceId}',
        dayBefore: true,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  void _addTodoItem() {
    final text = _todoController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _todoItems.add(NoteItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
        ));
        _todoController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Icon(FLucideIcons.notebookPen, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ghi chú',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FButton.icon(
                  onPress: () => Navigator.pop(context),
                  variant: FButtonVariant.outline,
                  child: const Icon(FLucideIcons.x, size: 20),
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  FTabs(
                    control: FTabControl.lifted(
                      index: _currentType == NoteType.plainText ? 0 : 1,
                      onChange: (idx) {
                        setState(() {
                          _currentType = idx == 0 ? NoteType.plainText : NoteType.todo;
                        });
                      },
                    ),
                    children: [
                      FTabEntry(
                        label: const Text('Văn bản'),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: FTextField(
                            control: FTextFieldControl.managed(controller: _textController),
                            maxLines: 8,
                            hint: 'Nhập nội dung ghi chú...',
                          ),
                        ),
                      ),
                      FTabEntry(
                        label: const Text('Checklist'),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: FTextField(
                                      control: FTextFieldControl.managed(controller: _todoController),
                                      hint: 'Thêm mục mới...',
                                      onSubmit: (_) => _addTodoItem(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FButton.icon(
                                    onPress: _addTodoItem,
                                    child: const Icon(FLucideIcons.plus, size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ..._todoItems.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      FCheckbox(
                                        value: item.isCompleted,
                                        onChange: (val) {
                                          setState(() {
                                            _todoItems[idx] = item.copyWith(isCompleted: val);
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item.text,
                                          style: TextStyle(
                                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                            color: item.isCompleted ? colorScheme.outline : colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      FButton.icon(
                                        onPress: () {
                                          setState(() {
                                            _todoItems.removeAt(idx);
                                          });
                                        },
                                        variant: FButtonVariant.outline,
                                        child: Icon(FLucideIcons.trash2, size: 18, color: colorScheme.error),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  
                  if (widget.eventDate != null)
                    FTileGroup(
                      children: [
                        FTile(
                          title: const Text('Nhắc nhở'),
                          subtitle: const Text('1 ngày trước lúc 20:00'),
                          prefix: Icon(FLucideIcons.bellRing, color: colorScheme.primary),
                          suffix: FSwitch(
                            value: _enableReminder,
                            onChange: (val) {
                              setState(() {
                                _enableReminder = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

          Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).padding.bottom + 24,
              top: 16,
            ),
            child: FButton(
              onPress: _saveNote,
              child: const Text('Lưu Ghi Chú'),
            ),
          ),
        ],
      ),
    );
  }
}
