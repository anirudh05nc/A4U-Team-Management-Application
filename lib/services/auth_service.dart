
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Stream for authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign in with email and password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Consider more specific error handling for production apps
      print('Sign-in error: ${e.message}');
      return null;
    }
  }

  // Sign up with email and password
  Future<User?> signUpWithEmailPassword(String email, String password, String username) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      // You can store the username in Firestore or Realtime Database here if needed
      // For now, we'll just return the user
      return user;
    } on FirebaseAuthException catch (e) {
      // Consider more specific error handling for production apps
      print('Sign-up error: ${e.message}');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
