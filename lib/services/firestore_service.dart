import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> saveHighScore(int score) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _db.collection('users').doc(user.uid);
    final doc = await userRef.get();

    final prevHighScore = doc.data()?['highScore'] ?? 0;

    if (score > prevHighScore) {
      await userRef.set({'email': user.email, 'highScore': score}, SetOptions(merge: true));
    }
  }

  static Future<int> getHighScore() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data()?['highScore'] ?? 0;
  }
}
