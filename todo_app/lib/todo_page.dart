import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
// https://todo-qcke.onrender.com/task/login/

class TodoPage extends StatefulWidget {
  @override
  _TodoPageState createState() => _TodoPageState();
}

class Task {
  int? id;
  String title;
  String description;
  DateTime? deadline;
  String status;
  bool isEditing;
  bool isCompleted;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.deadline,
    this.status = 'Pending',
    this.isEditing = false,
    this.isCompleted = false,
  });
}

class _TodoPageState extends State<TodoPage> {
  List<Task> _tasks = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editDescriptionController =
      TextEditingController();
  DateTime? _selectedDeadline;
  DateTime? _editDeadline;
  String _selectedStatus = 'Pending';
  String _editStatus = 'Pending';
  bool _isLoading = false;
  String _errorMessage = '';
  String? _authToken;
  String? _username;
  String? _password;

  final List<String> _statusOptions = [
    'Pending',
    'In Progress',
    'Completed',
    'Urgent',
  ];
  final Map<String, Color> _statusColors = {
    'Pending': Colors.amber.shade100,
    'In Progress': Colors.blue.shade100,
    'Completed': Colors.green.shade100,
    'Urgent': Colors.red.shade100,
  };

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username');
    _password = prefs.getString('password');
    _authToken = prefs.getString('token');
  }

  Map<String, String> _getAuthHeaders() {
    Map<String, String> headers = {'Content-Type': 'application/json'};

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  void _loadTasks() {
    final tasks = ModalRoute.of(context)?.settings.arguments as List<dynamic>?;
    if (tasks != null) {
      setState(() {
        _tasks =
            tasks
                .map(
                  (task) => Task(
                    id: task['id'],
                    title: task['title'] ?? 'Untitled',
                    description: task['description'] ?? '',
                    deadline:
                        task['deadline'] != null
                            ? DateTime.parse(task['deadline'])
                            : null,
                    status: task['status'] ?? 'Pending',
                    isCompleted: task['completed'] ?? false,
                  ),
                )
                .toList();
      });
    } else {
      // If no tasks passed as arguments, fetch them through login
      _fetchTasks();
    }
  }

  Future<void> _fetchTasks() async {
    if (_username == null || _password == null) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // We'll use the login endpoint since it returns tasks
      final response = await http.post(
        Uri.parse('http://localhost:8000/task/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': _username, 'password': _password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Update the valid credentials flag
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isValidCredentials', true);

        setState(() {
          _tasks =
              (data['tasks'] as List)
                  .map(
                    (task) => Task(
                      id: task['id'],
                      title: task['title'] ?? 'Untitled',
                      description: task['description'] ?? '',
                      deadline:
                          task['deadline'] != null
                              ? DateTime.parse(task['deadline'])
                              : null,
                      status: task['status'] ?? 'Pending',
                      isCompleted: task['completed'] ?? false,
                    ),
                  )
                  .toList();
        });
      } else {
        // Invalid credentials - clear and redirect to login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isValidCredentials', false);

        _showSnackBar(
          data['error'] ?? 'Failed to fetch tasks. Please login again.',
          true,
        );

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        });
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isValidCredentials', false);

      _showSnackBar('Connection error. Please try again later.', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAuth() async {
    if (_username == null || _password == null) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/task/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': _username, 'password': _password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save valid credentials indication
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isValidCredentials', true);

        setState(() {
          if (data['tasks'] != null) {
            _tasks =
                (data['tasks'] as List)
                    .map(
                      (task) => Task(
                        id: task['id'],
                        title: task['title'] ?? 'Untitled',
                        description: task['description'] ?? '',
                        deadline:
                            task['deadline'] != null
                                ? DateTime.parse(task['deadline'])
                                : null,
                        status: task['status'] ?? 'Pending',
                        isCompleted: task['completed'] ?? false,
                      ),
                    )
                    .toList();
          }
        });
      } else {
        // Authentication failed - clear stored credentials and redirect to login
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('username');
        await prefs.remove('password');
        await prefs.remove('token');
        await prefs.setBool('isValidCredentials', false);

        // Show error before redirecting
        _showSnackBar('Authentication failed. Please login again.', true);

        // Add a slight delay before redirecting to show the error
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        });
      }
    } catch (e) {
      // Also handle connection errors
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      await prefs.remove('password');
      await prefs.remove('token');

      _showSnackBar('Connection error. Please try again later.', true);

      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      });
    }
  }

  Future<void> _addTask() async {
    String taskTitle = _titleController.text.trim();
    String taskDescription = _descriptionController.text.trim();

    if (taskTitle.isEmpty) {
      _showSnackBar('Please enter a task title', true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/task/tasks/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _username,
          'password': _password,
          'title': taskTitle,
          'description': taskDescription,
          'deadline': _selectedDeadline?.toIso8601String(),
          'status': _selectedStatus,
          'completed': _selectedStatus == 'Completed',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        setState(() {
          _tasks.add(
            Task(
              id: data['id'],
              title: taskTitle,
              description: taskDescription,
              deadline: _selectedDeadline,
              status: _selectedStatus,
              isCompleted: _selectedStatus == 'Completed',
            ),
          );
          _titleController.clear();
          _descriptionController.clear();
          _selectedDeadline = null;
          _selectedStatus = 'Pending';
        });

        Navigator.of(context).pop(); // Close the modal
        _showSnackBar('Task added successfully', false);
      } else if (response.statusCode == 401) {
        // Invalid credentials - clear and redirect to login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isValidCredentials', false);

        _showSnackBar('Authentication failed. Please login again.', true);

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        });
      } else {
        _showSnackBar(
          data['error'] ?? 'Failed to add task. Please try again.',
          true,
        );
      }
    } catch (e) {
      _showSnackBar('Connection error. Please try again later.', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeTask(int index) async {
    final task = _tasks[index];
    if (task.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse(
          'http://localhost:8000/task/manage_task/${task.id}/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': _username, 'password': _password}),
      );

      if (response.statusCode == 204) {
        setState(() {
          _tasks.removeAt(index);
        });
        _showSnackBar('Task deleted successfully', false);
      } else if (response.statusCode == 401) {
        // Invalid credentials - clear and redirect to login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isValidCredentials', false);

        _showSnackBar('Authentication failed. Please login again.', true);

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        });
      } else {
        _showSnackBar('Failed to delete task. Please try again.', true);
      }
    } catch (e) {
      _showSnackBar('Connection error. Please try again later.', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTask(int index) async {
    final task = _tasks[index];
    final newTitle = _editTitleController.text.trim();
    final newDescription = _editDescriptionController.text.trim();

    if (newTitle.isEmpty) {
      _showSnackBar('Please enter a task title', true);
      return;
    }

    if (task.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse(
          'http://localhost:8000/task/manage_task/${task.id}/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _username,
          'password': _password,
          'title': newTitle,
          'description': newDescription,
          'deadline': _editDeadline?.toIso8601String(),
          'status': _editStatus,
          'completed': _editStatus == 'Completed',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _tasks[index].title = newTitle;
          _tasks[index].description = newDescription;
          _tasks[index].deadline = _editDeadline;
          _tasks[index].status = _editStatus;
          _tasks[index].isCompleted = _editStatus == 'Completed';
          _tasks[index].isEditing = false;
        });
        _showSnackBar('Task updated successfully', false);
      } else if (response.statusCode == 401) {
        // Invalid credentials - clear and redirect to login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isValidCredentials', false);

        _showSnackBar('Authentication failed. Please login again.', true);

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        });
      } else {
        _showSnackBar(
          data['error'] ?? 'Failed to update task. Please try again.',
          true,
        );
      }
    } catch (e) {
      _showSnackBar('Connection error. Please try again later.', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTaskCompletion(int index) async {
    final task = _tasks[index];
    if (task.id == null) return;

    final newStatus = task.isCompleted ? 'Pending' : 'Completed';

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse(
          'http://localhost:8000/task/manage_task/${task.id}/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _username,
          'password': _password,
          'title': task.title,
          'description': task.description,
          'deadline':
              task.deadline?.toIso8601String(), // Fixed: Add proper conversion
          'status': newStatus,
          'completed': !task.isCompleted,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _tasks[index].isCompleted = !task.isCompleted;
          _tasks[index].status = newStatus;
        });
        _showSnackBar(
          task.isCompleted
              ? 'Task marked as pending'
              : 'Task marked as completed',
          false,
        );
      } else if (response.statusCode == 401) {
        // Invalid credentials - clear and redirect to login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isValidCredentials', false);

        _showSnackBar('Authentication failed. Please login again.', true);

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        });
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(
          data['error'] ?? 'Failed to update task. Please try again.',
          true,
        );
      }
    } catch (e) {
      _showSnackBar('Connection error. Please try again later.', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await http.post(
        Uri.parse('http://localhost:8000/task/logout/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': _username, 'password': _password}),
      );

      // Clear stored credentials
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      await prefs.remove('password');
      await prefs.remove('token');
      await prefs.setBool('isValidCredentials', false);

      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      // Still clear stored credentials and redirect to login
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      await prefs.remove('password');
      await prefs.remove('token');
      await prefs.setBool('isValidCredentials', false);

      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Urgent':
        return Colors.red.shade400;
      case 'Completed':
        return Colors.green.shade400;
      case 'In Progress':
        return Colors.blue.shade400;
      default:
        return Colors.amber.shade400; // For 'To Do' or any other status
    }
  }

  // New method to show in-app notifications
  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isError ? 4 : 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // New method to show task details
  void _showTaskDetails(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25.0),
                topRight: Radius.circular(25.0),
              ),
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Title with status indicator
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            task.status == 'Urgent'
                                ? Colors.red.shade400
                                : task.status == 'Completed'
                                ? Colors.green.shade400
                                : task.status == 'In Progress'
                                ? Colors.blue.shade400
                                : Colors.amber.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        task.status,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Description section
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.description.isEmpty
                        ? "No description provided"
                        : task.description,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
                SizedBox(height: 20),

                // Deadline section if available
                if (task.deadline != null) ...[
                  Text(
                    'Deadline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color:
                              DateTime.now().isAfter(task.deadline!) &&
                                      !task.isCompleted
                                  ? Colors.red
                                  : Colors.deepPurple,
                        ),
                        SizedBox(width: 12),
                        Text(
                          DateFormat(
                            'EEEE, MMM d, yyyy',
                          ).format(task.deadline!),
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                DateTime.now().isAfter(task.deadline!) &&
                                        !task.isCompleted
                                    ? Colors.red
                                    : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                Spacer(),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          int index = _tasks.indexOf(task);
                          if (index != -1) {
                            _showEditTaskModal(index);
                          }
                        },
                        icon: Icon(Icons.edit, color: Colors.deepPurple),
                        label: Text(
                          'Edit',
                          style: TextStyle(color: Colors.deepPurple),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.deepPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          int index = _tasks.indexOf(task);
                          if (index != -1) {
                            _toggleTaskCompletion(index);
                          }
                        },
                        icon: Icon(
                          task.isCompleted ? Icons.replay : Icons.check,
                          color: Colors.white,
                        ),
                        label: Text(
                          task.isCompleted ? 'Mark Undone' : 'Mark Done',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              task.isCompleted ? Colors.orange : Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void _showNewTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25.0),
                topRight: Radius.circular(25.0),
              ),
            ),
            padding: EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Task',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Title field
                  Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Enter task title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Description field
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter task description (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Deadline picker
                  Text(
                    'Deadline (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDeadline = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDeadline == null
                                ? 'Select date'
                                : DateFormat(
                                  'EEEE, MMM d, yyyy',
                                ).format(_selectedDeadline!),
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  _selectedDeadline == null
                                      ? Colors.grey
                                      : Colors.black,
                            ),
                          ),
                          Icon(Icons.calendar_today, color: Colors.deepPurple),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Status selector
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedStatus,
                        items:
                            _statusOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _statusColors[value],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(value),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedStatus = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isLoading
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                'Add Task',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showEditTaskModal(int index) {
    Task task = _tasks[index];
    _editTitleController.text = task.title;
    _editDescriptionController.text = task.description;
    _editDeadline = task.deadline;
    _editStatus = task.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25.0),
                topRight: Radius.circular(25.0),
              ),
            ),
            padding: EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Task',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Title field
                  Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _editTitleController,
                    decoration: InputDecoration(
                      hintText: 'Enter task title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Description field
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _editDescriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter task description (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Deadline picker
                  Text(
                    'Deadline (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _editDeadline ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _editDeadline = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _editDeadline == null
                                ? 'Select date'
                                : DateFormat(
                                  'EEEE, MMM d, yyyy',
                                ).format(_editDeadline!),
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  _editDeadline == null
                                      ? Colors.grey
                                      : Colors.black,
                            ),
                          ),
                          Icon(Icons.calendar_today, color: Colors.deepPurple),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Status selector
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _editStatus,
                        items:
                            _statusOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _statusColors[value],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(value),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _editStatus = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // Update button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _saveTask(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isLoading
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                'Update Task',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Delete button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                Navigator.pop(context);
                                _showDeleteConfirmation(index);
                              },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete Task',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Task'),
            content: Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _removeTask(index);
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
        title: Text(
          'My Tasks',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            color: Colors.white,
            onPressed: _fetchTasks,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            color: Colors.white,
            onPressed: _logout,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _tasks.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.task_alt, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No tasks yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the + button to add a new task',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () => _showTaskDetails(task),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          color: _getStatusColor(task.status).withOpacity(0.2),
                        ),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: _getStatusColor(task.status),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    task.status,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Colors
                                              .white, // Changed text color to white for better contrast
                                    ),
                                  ),
                                  if (task.deadline != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color:
                                              DateTime.now().isAfter(
                                                        task.deadline!,
                                                      ) &&
                                                      !task.isCompleted
                                                  ? Colors.white70
                                                  : Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          DateFormat(
                                            'MMM d',
                                          ).format(task.deadline!),
                                          style: TextStyle(
                                            color:
                                                DateTime.now().isAfter(
                                                          task.deadline!,
                                                        ) &&
                                                        !task.isCompleted
                                                    ? Colors.white70
                                                    : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Checkbox for completion
                                  InkWell(
                                    onTap: () => _toggleTaskCompletion(index),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              task.isCompleted
                                                  ? Colors.green
                                                  : Colors.grey,
                                          width: 2,
                                        ),
                                        color:
                                            task.isCompleted
                                                ? Colors.green
                                                : Colors.transparent,
                                      ),
                                      child:
                                          task.isCompleted
                                              ? Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                              : null,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  // Task title and description
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                task.isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                            color:
                                                task.isCompleted
                                                    ? Colors.grey
                                                    : Colors.black87,
                                          ),
                                        ),
                                        if (task.description.isNotEmpty) ...[
                                          SizedBox(height: 4),
                                          Text(
                                            task.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Task actions
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditTaskModal(index);
                                      } else if (value == 'delete') {
                                        _showDeleteConfirmation(index);
                                      } else if (value == 'toggle') {
                                        _toggleTaskCompletion(index);
                                      }
                                    },
                                    itemBuilder:
                                        (context) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'toggle',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  task.isCompleted
                                                      ? Icons.replay
                                                      : Icons.check_circle,
                                                  color:
                                                      task.isCompleted
                                                          ? Colors.orange
                                                          : Colors.green,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  task.isCompleted
                                                      ? 'Mark as Undone'
                                                      : 'Mark as Done',
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Delete'),
                                              ],
                                            ),
                                          ),
                                        ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewTaskModal,
        backgroundColor: Colors.white, // Set button color to white
        label: Text(
          "New Task",
          style: TextStyle(color: Colors.black), // Set text color to black
        ),
        icon: Icon(
          Icons.add,
          color: Colors.black, // Set icon color to black
        ),
      ),
    );
  }
}
