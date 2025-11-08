import 'package:assistantforu/models/task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _tasksCollection = FirebaseFirestore.instance.collection('tasks');

  Future<DocumentReference> addTask(Task task) async {
    return await _tasksCollection.add(task.toFirestore());
  }

  Stream<List<Task>> getTasksForRoom(String roomId) {
    return _tasksCollection
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    final Map<String, dynamic> updateData = {'status': status};
    if (status == 'completed') {
      updateData['completedAt'] = Timestamp.now();
    }
    await _tasksCollection.doc(taskId).update(updateData);
  }

  Stream<List<Task>> getAllTasksForUser(String userId) {
    return _tasksCollection.where('assignedTo', arrayContains: userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }
}
