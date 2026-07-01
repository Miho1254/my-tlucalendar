import 'package:flutter/foundation.dart';
import 'package:tlucalendar/features/notes/domain/models/note_model.dart';
import 'package:tlucalendar/features/notes/data/services/note_service.dart';

class NoteProvider extends ChangeNotifier {
  final NoteService _noteService;
  
  NoteProvider({NoteService? noteService}) : _noteService = noteService ?? NoteService();
  
  List<NoteModel> _notes = [];
  bool _isLoaded = false;
  
  List<NoteModel> get notes => _notes;
  bool get isLoaded => _isLoaded;
  
  Future<void> loadNotes() async {
    _notes = await _noteService.getAllNotes();
    _isLoaded = true;
    notifyListeners();
  }
  
  bool hasNoteFor(String referenceId) {
    return _notes.any((note) => note.referenceId == referenceId);
  }
  
  NoteModel? getNoteFor(String referenceId) {
    try {
      return _notes.firstWhere((note) => note.referenceId == referenceId);
    } catch (e) {
      return null;
    }
  }
  
  Future<void> saveNote(NoteModel note) async {
    await _noteService.saveNote(note);
    
    // Update local cache
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note;
    } else {
      _notes.add(note);
    }
    notifyListeners();
  }
  
  Future<void> deleteNote(String id) async {
    await _noteService.deleteNote(id);
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }
  
  Future<void> toggleTodoItem(String noteId, String itemId) async {
    await _noteService.toggleTodoItem(noteId, itemId);
    
    // Update local cache
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index >= 0) {
      final note = _notes[index];
      if (note.type == NoteType.todo && note.items != null) {
        final items = List<NoteItem>.from(note.items!);
        final itemIndex = items.indexWhere((i) => i.id == itemId);
        if (itemIndex >= 0) {
          items[itemIndex] = items[itemIndex].copyWith(isCompleted: !items[itemIndex].isCompleted);
          _notes[index] = note.copyWith(items: items);
          notifyListeners();
        }
      }
    }
  }
}
