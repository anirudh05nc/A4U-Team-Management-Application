import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? name;
  final List<String>? skills;

  UserModel({
    required this.uid,
    this.email,
    this.name,
    this.skills,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String?,
      name: data['name'] as String?,
      skills: data['skills'] != null ? List<String>.from(data['skills']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'skills': skills,
    };
  }
}
