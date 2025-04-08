import 'package:flutter/material.dart';
import '../models/note.dart';
import '../components/note/note_list_item.dart';
import '../components/note/note_detail_view.dart';
import '../components/note/note_form.dart';
import '../utils/shared_utils.dart';
import '../services/api_service.dart';
import '../components/common/datetime_header.dart';

class NotePage extends StatefulWidget {
  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _username;
  String? _password;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final credentials = await SharedUtils.loadCredentials();
    setState(() {
      _username = credentials['username'];
      _password = credentials['password'];
    });
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    if (_username == null || _password == null) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final notes = await _apiService.fetchNotes(_username!, _password!);
      setState(() {
        _notes = notes;
      });
    } catch (e) {
      // Handle empty notes case gracefully
      if (e.toString().contains('null')) {
        setState(() {
          _notes = []; // Set empty list if null response
        });
      } else {
        SharedUtils.showSnackBar(context, 'Failed to load notes: ${e.toString()}', true);
        // If unauthorized, redirect to login
        if (e.toString().contains('401')) {
          await SharedUtils.clearCredentials();
          Navigator.pushReplacementNamed(context, '/');
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addNote(Note note) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newNote = await _apiService.createNote(_username!, _password!, note);
      setState(() {
        _notes.add(newNote);
      });
      Navigator.pop(context);
      SharedUtils.showSnackBar(context, 'Note added successfully', false);
    } catch (e) {
      SharedUtils.showSnackBar(context, 'Failed to add note: ${e.toString()}', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNote(Note note) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedNote = await _apiService.updateNote(_username!, _password!, note);
      setState(() {
        final index = _notes.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          _notes[index] = updatedNote;
        }
      });
      Navigator.pop(context);
      SharedUtils.showSnackBar(context, 'Note updated successfully', false);
    } catch (e) {
      SharedUtils.showSnackBar(context, 'Failed to update note: ${e.toString()}', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteNote(int index) async {
    final note = _notes[index];
    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.deleteNote(_username!, _password!, note.id!);
      setState(() {
        _notes.removeAt(index);
      });
      SharedUtils.showSnackBar(context, 'Note deleted successfully', false);
    } catch (e) {
      SharedUtils.showSnackBar(context, 'Failed to delete note: ${e.toString()}', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _apiService.logout(_username!, _password!);
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      await SharedUtils.clearCredentials();
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  void _showNewNoteModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0),
            topRight: Radius.circular(25.0),
          ),
        ),
        padding: EdgeInsets.all(24),
        child: NoteForm(
          isEditing: false,
          onSubmit: _addNote,
        ),
      ),
    );
  }

  void _showEditNoteModal(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0),
            topRight: Radius.circular(25.0),
          ),
        ),
        padding: EdgeInsets.all(24),
        child: NoteForm(
          isEditing: true,
          note: _notes[index],
          onSubmit: _updateNote,
        ),
      ),
    );
  }

  void _showNoteDetails(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteDetailView(
        note: _notes[index],
        onEdit: () {
          Navigator.pop(context);
          _showEditNoteModal(index);
        },
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNote(index);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('Notes',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            // DateTimeHeader(
            //   textColor: Colors.white70,
            //   fontSize: 12.0,
            // ),
          ]
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            color: Colors.white,
            onPressed: _fetchNotes,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            color: Colors.white,
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          DateTimeHeader(
            textColor: const Color.fromARGB(179, 47, 33, 244),
            fontSize: 12.0,
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No notes yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap the + button to add a new note',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _notes.length,
                        itemBuilder: (context, index) {
                          return NoteListItem(
                            note: _notes[index],
                            onTap: () => _showNoteDetails(index),
                            onEdit: () => _showEditNoteModal(index),
                            onDelete: () => _showDeleteConfirmation(index),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewNoteModal,
        backgroundColor: Colors.white,
        label: Text("New Note", style: TextStyle(color: Colors.black)),
        icon: Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}