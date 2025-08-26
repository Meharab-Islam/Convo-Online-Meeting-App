import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up
  Future<User?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = cred.user;
      if (user != null) {
        // Store user profile in Firestore
        await _firestore.collection("users").doc(user.uid).set({
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "status": "Available",
          "friends": [],
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Sign in
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
