import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? email;
  int? highScore;
  int? longestCombo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        email = user.email;
        highScore = doc.data()?['highScore'] ?? 0;
        longestCombo = doc.data()?['longestCombo'] ?? 0;
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_circle, size: 100, color: Colors.grey),
                  const SizedBox(height: 20),
                  Text('Email: $email', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Text('Highest Score: $highScore', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Text('Longest Combo: $longestCombo', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 40),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red, size: 32),
                    tooltip: 'Logout',
                  ),
                ],
              ),
            ),
    );
  }
}
