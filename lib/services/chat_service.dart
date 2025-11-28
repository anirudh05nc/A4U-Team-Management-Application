import 'package:assistantforu/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Message>> getMessages(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  Future<void> sendMessage(String roomId, Message message) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .add(message.toFirestore());
  }
}
