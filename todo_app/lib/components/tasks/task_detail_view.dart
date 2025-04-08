// components/task/task_detail_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';

class TaskDetailView extends StatelessWidget {
  final Task task;
  final Function() onEdit;
  final Function() onToggleComplete;

  const TaskDetailView({
    required this.task,
    required this.onEdit,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(task.status),
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
              task.description.isEmpty ? "No description provided" : task.description,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          SizedBox(height: 20),
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
                    color: DateTime.now().isAfter(task.deadline!) && !task.isCompleted
                        ? Colors.red
                        : Colors.deepPurple,
                  ),
                  SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(task.deadline!),
                    style: TextStyle(
                      fontSize: 16,
                      color: DateTime.now().isAfter(task.deadline!) && !task.isCompleted
                          ? Colors.red
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit, color: Colors.deepPurple),
                  label: Text('Edit', style: TextStyle(color: Colors.deepPurple)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.deepPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              ),

              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onToggleComplete,
                  icon: Icon(
                    task.isCompleted ? Icons.replay : Icons.check,
                    color: Colors.white,
                  ),
                  label: Text(
                    task.isCompleted ? 'Mark Undone' : 'Mark Done',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: task.isCompleted ? Colors.orange : Colors.green,
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
    );
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
        return Colors.amber.shade400;
    }
  }
}