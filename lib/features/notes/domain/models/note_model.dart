import 'dart:convert';

enum NoteType {
  plainText,
  todo,
}

class NoteItem {
  final String id;
  final String text;
  final bool isCompleted;

  NoteItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });

  NoteItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
  }) {
    return NoteItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isCompleted': isCompleted,
    };
  }

  factory NoteItem.fromMap(Map<String, dynamic> map) {
    return NoteItem(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class NoteModel {
  final String id;
  final String referenceId; // e.g. course.id or exam subject code
  final String title;
  final String? content; // for plain text
  final List<NoteItem>? items; // for todo
  final NoteType type;
  final DateTime createdAt;
  final DateTime? reminderDate;
  final bool hasReminder;

  NoteModel({
    required this.id,
    required this.referenceId,
    required this.title,
    this.content,
    this.items,
    required this.type,
    required this.createdAt,
    this.reminderDate,
    this.hasReminder = false,
  });

  NoteModel copyWith({
    String? id,
    String? referenceId,
    String? title,
    String? content,
    List<NoteItem>? items,
    NoteType? type,
    DateTime? createdAt,
    DateTime? reminderDate,
    bool? hasReminder,
  }) {
    return NoteModel(
      id: id ?? this.id,
      referenceId: referenceId ?? this.referenceId,
      title: title ?? this.title,
      content: content ?? this.content,
      items: items ?? this.items,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      reminderDate: reminderDate ?? this.reminderDate,
      hasReminder: hasReminder ?? this.hasReminder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referenceId': referenceId,
      'title': title,
      'content': content,
      'items': items?.map((x) => x.toMap()).toList(),
      'type': type.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'reminderDate': reminderDate?.millisecondsSinceEpoch,
      'hasReminder': hasReminder,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] ?? '',
      referenceId: map['referenceId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'],
      items: map['items'] != null
          ? List<NoteItem>.from(map['items']?.map((x) => NoteItem.fromMap(x)))
          : null,
      type: NoteType.values.firstWhere((e) => e.name == map['type'], orElse: () => NoteType.plainText),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      reminderDate: map['reminderDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['reminderDate']) : null,
      hasReminder: map['hasReminder'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory NoteModel.fromJson(String source) => NoteModel.fromMap(json.decode(source));
}
