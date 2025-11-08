import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final String roomId;
  final List<String> assignedTo;
  final Timestamp dueDate;
  final String status; // "pending" or "completed"
  final Timestamp? completedAt;
  final String? parentTaskTitle; // New field

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.roomId,
    required this.assignedTo,
    required this.dueDate,
    this.status = 'pending',
    this.completedAt,
    this.parentTaskTitle,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] as String?,
      roomId: data['roomId'] ?? '',
      assignedTo: List<String>.from(data['assignedTo'] ?? []),
      dueDate: data['dueDate'] ?? Timestamp.now(),
      status: data['status'] ?? 'pending',
      completedAt: data['completedAt'] as Timestamp?,
      parentTaskTitle: data['parentTaskTitle'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'roomId': roomId,
      'assignedTo': assignedTo,
      'dueDate': dueDate,
      'status': status,
      'completedAt': completedAt,
      'parentTaskTitle': parentTaskTitle,
    };
  }
}
