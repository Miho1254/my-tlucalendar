import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tlucalendar/features/notes/domain/models/note_model.dart';

class NoteService {
  static const String _storageKey = 'tlucalendar_notes';
  
  // Singleton
  static final NoteService _instance = NoteService._internal();
  factory NoteService() => _instance;
  NoteService._internal();

  Future<List<NoteModel>> getAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];
    return jsonList.map((jsonStr) => NoteModel.fromJson(jsonStr)).toList();
  }

  Future<List<NoteModel>> getNotesForReference(String referenceId) async {
    final allNotes = await getAllNotes();
    return allNotes.where((note) => note.referenceId == referenceId).toList();
  }

  Future<void> saveNote(NoteModel note) async {
    final prefs = await SharedPreferences.getInstance();
    final allNotes = await getAllNotes();
    
    final index = allNotes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      allNotes[index] = note; // Update
    } else {
      allNotes.add(note); // Insert
    }
    
    final jsonList = allNotes.map((n) => n.toJson()).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  Future<void> deleteNote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final allNotes = await getAllNotes();
    
    allNotes.removeWhere((n) => n.id == id);
    
    final jsonList = allNotes.map((n) => n.toJson()).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  Future<void> toggleTodoItem(String noteId, String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final allNotes = await getAllNotes();
    
    final noteIndex = allNotes.indexWhere((n) => n.id == noteId);
    if (noteIndex >= 0) {
      final note = allNotes[noteIndex];
      if (note.type == NoteType.todo && note.items != null) {
        final items = List<NoteItem>.from(note.items!);
        final itemIndex = items.indexWhere((i) => i.id == itemId);
        if (itemIndex >= 0) {
          items[itemIndex] = items[itemIndex].copyWith(isCompleted: !items[itemIndex].isCompleted);
          allNotes[noteIndex] = note.copyWith(items: items);
          
          final jsonList = allNotes.map((n) => n.toJson()).toList();
          await prefs.setStringList(_storageKey, jsonList);
        }
      }
    }
  }
}
