import 'package:assistantforu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateUser(String uid, {String? name, List<String>? skills}) async {
    Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (skills != null) data['skills'] = skills;

    if (data.isNotEmpty) {
      await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}
