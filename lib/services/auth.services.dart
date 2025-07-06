import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!credential.user!.emailVerified) {
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Email is not verified. Please check your inbox.',
        );
      }

      return credential.user;
    } 
  on FirebaseAuthException catch (e) {
    // Rethrow error to handle it in UI
    throw FirebaseAuthException(
      code: e.code,
      message: _getFriendlyMessage(e.code),
    );
  } 
  catch (e) {
    throw FirebaseAuthException(
      code: 'unknown',
      message: 'An unexpected error occurred. Please try again later.',
    );
  }
}

  String _getFriendlyMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'email-not-verified':
        return 'Please verify your email before logging in.';
      default:
        return 'Login failed. Please check your credentials.';
    }
  }
  
  // Sign out
  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<User?> register(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print("Error registering: $e");
      return null;
    }
  }
}