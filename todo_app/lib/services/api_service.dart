import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/note.dart';
import '../utils/shared_utils.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000'; // Update with your server address

  // Authentication
  Future<Map<String, dynamic>> authenticate(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    return jsonDecode(response.body);
  }

  Future<void> logout(String username, String password) async {
    await http.post(
      Uri.parse('$baseUrl/api/logout/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
  }

  // Task methods
  Future<List<Task>> fetchTasks(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['tasks'] as List).map((task) => Task.fromJson(task)).toList();
    }
    throw Exception('Failed to load tasks');
  }

  Future<Task> createTask(String username, String password, Task task) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/task/create_task/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'title': task.title,
        'description': task.description,
        'completed': task.isCompleted,
        'deadline': task.deadline?.toIso8601String(),
        'status': task.status,
      }),
    );

    if (response.statusCode == 201) {
      return Task.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create task');
  }

  Future<Task> updateTask(String username, String password, Task task) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/task/manage_task/${task.id}/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'title': task.title,
        'description': task.description,
        'completed': task.isCompleted,
        'deadline': task.deadline?.toIso8601String(),
        'status': task.status,
      }),
    );

    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update task');
  }

  Future<void> deleteTask(String username, String password, int taskId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/task/manage_task/$taskId/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete task');
    }
  }

  // Note methods (assuming similar endpoints exist for notes)
  Future<List<Note>> fetchNotes(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['notes'] == null) {
        return []; // Return empty list if no notes
      }
      return (data['notes'] as List).map((note) => Note.fromJson(note)).toList();
    }
    throw Exception('Failed to load notes');
  }

  Future<Note> createNote(String username, String password, Note note) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/note/create_note/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'title': note.title,
        'content': note.content,
      }),
    );

    if (response.statusCode == 201) {
      return Note.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create note');
  }

  Future<Note> updateNote(String username, String password, Note note) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/note/manage_note/${note.id}/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'title': note.title,
        'content': note.content,
      }),
    );

    if (response.statusCode == 200) {
      return Note.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update note');
  }

  Future<void> deleteNote(String username, String password, int noteId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/note/manage_note/$noteId/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete note');
    }
  }
}