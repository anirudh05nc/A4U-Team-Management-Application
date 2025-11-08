import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assistantforu/models/room_model.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _chars = 'abcdefghijklmnopqrstuvwxyz1234567890';

  String _getRandomString(int length) =>
      String.fromCharCodes(Iterable.generate(length, (_) => _chars.codeUnitAt(Random().nextInt(_chars.length))));

  Future<Room?> createRoom(String leaderId) async {
    try {
      String roomId = _getRandomString(6);
      Room newRoom = Room(id: roomId, leaderId: leaderId, members: [leaderId]);
      await _firestore.collection('rooms').doc(roomId).set(newRoom.toFirestore());
      return newRoom;
    } catch (e) {
      print('Error creating room: $e');
      return null;
    }
  }

  Future<Room?> joinRoom(String roomId, String memberId) async {
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(roomRef);
        if (!snapshot.exists) {
          throw Exception("Room does not exist!");
        }
        Room room = Room.fromFirestore(snapshot);
        if (!room.members.contains(memberId)) {
          List<String> updatedMembers = List.from(room.members)..add(memberId);
          transaction.update(roomRef, {'members': updatedMembers});
        }
      });
      return getRoom(roomId);
    } catch (e) {
      print('Error joining room: $e');
      return null;
    }
  }

  Future<void> exitRoom(String roomId, String memberId) async {
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(roomRef);
        if (!snapshot.exists) {
          throw Exception("Room does not exist!");
        }
        Room room = Room.fromFirestore(snapshot);
        List<String> updatedMembers = List.from(room.members)..remove(memberId);

        if (updatedMembers.isEmpty) {
          transaction.delete(roomRef);
        } else {
          if (room.leaderId == memberId) {
            // Assign a new leader
            String newLeaderId = updatedMembers.first;
            transaction.update(roomRef, {'members': updatedMembers, 'leaderId': newLeaderId});
          } else {
            transaction.update(roomRef, {'members': updatedMembers});
          }
        }
      });
    } catch (e) {
      print('Error exiting room: $e');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await _firestore.collection('rooms').doc(roomId).delete();
    } catch (e) {
      print('Error deleting room: $e');
    }
  }

  Future<void> removeUserFromRoomOnAccountDeletion(String userId) async {
    Room? room = await getRoomForUser(userId);
    if (room != null) {
      await exitRoom(room.id, userId);
    }
  }

  Future<Room?> getRoom(String roomId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('rooms').doc(roomId).get();
      if (doc.exists) {
        return Room.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting room: $e');
      return null;
    }
  }

  Stream<Room?> getRoomStream(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? Room.fromFirestore(snapshot) : null);
  }

  Future<Room?> getRoomForUser(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('rooms')
          .where('members', arrayContains: userId)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return Room.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting room for user: $e');
      return null;
    }
  }
}
