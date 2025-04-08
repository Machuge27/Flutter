// components/note/note_detail_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/note.dart';

class NoteDetailView extends StatelessWidget {
  final Note note;
  final Function() onEdit;

  const NoteDetailView({
    required this.note,
    required this.onEdit,
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
                  note.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Created: ${DateFormat('EEEE, MMM d, yyyy - hh:mm a').format(note.createdAt)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          if (note.updatedAt != null)
            Text(
              'Updated: ${DateFormat('EEEE, MMM d, yyyy - hh:mm a').format(note.updatedAt!)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          SizedBox(height: 20),
          Text(
            'Content',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  note.content.isEmpty ? "No content provided" : note.content,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onEdit,
              icon: Icon(Icons.edit, color: Colors.white),
              label: Text(
                'Edit Note',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}