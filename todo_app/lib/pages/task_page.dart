import 'package:flutter/material.dart';
import '../models/task.dart';
import '../components/tasks/task_list_item.dart';
import '../components/tasks/task_detail_view.dart';
import '../components/common/datetime_header.dart';
import '../components/tasks/task_form.dart';
import '../utils/shared_utils.dart';
import '../services/api_service.dart';

class TaskPage extends StatefulWidget {
  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  List<Task> _tasks = [];
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
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    if (_username == null || _password == null) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = await _apiService.fetchTasks(_username!, _password!);
      setState(() {
        _tasks = tasks;
      });
    } catch (e) {
      SharedUtils.showSnackBar(context, 'Failed to load tasks: ${e.toString()}', true);
      // If unauthorized, redirect to login
      if (e.toString().contains('401')) {
        await SharedUtils.clearCredentials();
        Navigator.pushReplacementNamed(context, '/');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTask(Task task) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newTask = await _apiService.createTask(_username!, _password!, task);
      setState(() {
        _tasks.add(newTask);
      });
      Navigator.pop(context);
      SharedUtils.showSnackBar(context, 'Task added successfully', false);
    } catch (e) {
      SharedUtils.showSnackBar(context, 'Failed to add task: ${e.toString()}', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTask(Task task) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedTask = await _apiService.updateTask(_username!, _password!, task);
      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = updatedTask;
        }
      });
      Navigator.pop(context);
      SharedUtils.showSnackBar(context, 'Task updated successfully', false);
    } catch (e) {
      SharedUtils.showSnackBar(context, 'Failed to update task: ${e.toString()}', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTask(int index) async {
    final task = _tasks[index];
    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.deleteTask(_username!, _password!, task.id!);
      setState(() {
        _tasks.removeAt(index);
      });
      SharedUtils.showSnackBar(context, 'Task deleted successfully', false);
    } catch (e) {
      SharedUtils.showSnackBar(context, 'Failed to delete task: ${e.toString()}', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTaskCompletion(int index) async {
    final task = _tasks[index];
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedTask = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        deadline: task.deadline,
        status: task.isCompleted ? 'Pending' : 'Completed',
        isCompleted: !task.isCompleted,
      );
      
      final result = await _apiService.updateTask(_username!, _password!, updatedTask);
      setState(() {
        _tasks[index] = result;
      });
      SharedUtils.showSnackBar(
        context,
        result.isCompleted ? 'Task marked as completed' : 'Task marked as pending',
        false,
      );
    } catch (e) {
      SharedUtils.showSnackBar(context, 'Failed to update task: ${e.toString()}', true);
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

  void _showNewTaskModal() {
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
        child: TaskForm(
          isEditing: false,
          onSubmit: _addTask,
        ),
      ),
    );
  }

  void _showEditTaskModal(int index) {
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
        child: TaskForm(
          isEditing: true,
          task: _tasks[index],
          onSubmit: _updateTask,
        ),
      ),
    );
  }

  void _showTaskDetails(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailView(
        task: _tasks[index],
        onEdit: () {
          Navigator.pop(context);
          _showEditTaskModal(index);
        },
        onToggleComplete: () {
          Navigator.pop(context);
          _toggleTaskCompletion(index);
        },
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              _deleteTask(index);
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
          'Tasks',
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
      Column(
        children: [
          DateTimeHeader(
            textColor: Color.fromARGB(179, 47, 33, 244),
            fontSize: 12.0,
          ),
          Expanded(
            child: 
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
                          return TaskListItem(
                            task: _tasks[index],
                            onTap: () => _showTaskDetails(index),
                            onToggleComplete: () => _toggleTaskCompletion(index),
                            onEdit: () => _showEditTaskModal(index),
                            onDelete: () => _showDeleteConfirmation(index),
                          );
                        },
                      ),
          
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewTaskModal,
        backgroundColor: Colors.white,
        label: Text("New Task", style: TextStyle(color: Colors.black)),
        icon: Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}