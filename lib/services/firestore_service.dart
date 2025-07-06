import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  /// Save the user's high score if it's greater than the current one in Firestore
  static Future<void> saveHighScore(int newScore) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in, skipping high score save');
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();

      final currentHigh = doc.data()?['highScore'] ?? 0;
      print('Current high score: $currentHigh, new score: $newScore');

      if (newScore > currentHigh) {
        await docRef.set({'highScore': newScore}, SetOptions(merge: true));
        print('New high score saved!');
      } else {
        print('New score not higher, no update made');
      }
    } catch (e) {
      print('Error saving high score: $e');
    }
  }

  /// Get the current user's high score from Firestore
  static Future<int> getHighScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      return doc.data()?['highScore'] ?? 0;
    } catch (e) {
      print('Error getting high score: $e');
      return 0;
    }
  }
}
