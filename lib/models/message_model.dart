import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderName;
  final String text;
  final Timestamp timestamp;

  Message({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Message(
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp,
    };
  }
}
