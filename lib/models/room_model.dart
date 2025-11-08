import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String leaderId;
  final List<String> members;

  Room({required this.id, required this.leaderId, required this.members});

  factory Room.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Room(
      id: doc.id,
      leaderId: data['leaderId'] ?? '',
      members: List<String>.from(data['members'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'leaderId': leaderId,
      'members': members,
    };
  }
}
