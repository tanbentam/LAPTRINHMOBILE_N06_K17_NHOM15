import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
Future<UserCredential> signUpWithEmailPassword(
  String email, 
  String password, {
  bool isAdmin = false,
}) async {
  try {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Tạo user document và truyền password để lưu vào Firebase
    await _firestoreService.createUserDocument(
      result.user!.uid, 
      email,
      password: password, // Truyền password để lưu vào Firestore
      isAdmin: isAdmin, // Truyền admin flag
    );
    
    print('User created ${isAdmin ? "as ADMIN" : ""} and password saved to Firestore');
    return result;
  } catch (e) {
    print('Error in signUpWithEmailPassword: $e');
    rethrow;
  }
}

  // Sign in with email and password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }
}
