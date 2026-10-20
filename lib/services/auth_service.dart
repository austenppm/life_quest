import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _updateLastActive(credential.user!.uid);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user!.updateDisplayName(displayName);

      // Create user profile in Firestore
      await _createUserProfile(
        credential.user!.uid,
        email,
        displayName,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user profile
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _createUserProfile(
          userCredential.user!.uid,
          userCredential.user!.email ?? '',
          userCredential.user!.displayName ?? 'Adventurer',
          avatarUrl: userCredential.user!.photoURL,
        );
      } else {
        await _updateLastActive(userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Delete user data from Firestore
    await _deleteUserData(user.uid);

    // Delete auth account
    await user.delete();
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(
    String uid,
    String email,
    String displayName, {
    String? avatarUrl,
  }) async {
    final profile = UserProfile.newUser(
      id: uid,
      email: email,
      displayName: displayName,
    );

    await _firestore.collection('users').doc(uid).set(
          profile.copyWith(avatarUrl: avatarUrl).toFirestore(),
        );
  }

  // Update last active timestamp
  Future<void> _updateLastActive(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete user data
  Future<void> _deleteUserData(String uid) async {
    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(uid);

    // Delete subcollections
    final collections = [
      'tasks',
      'quests',
      'workouts',
      'studySessions',
      'workLogs',
      'alarms',
      'achievements',
    ];

    for (final collection in collections) {
      final docs = await userRef.collection(collection).get();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
    }

    // Delete user document
    batch.delete(userRef);

    await batch.commit();
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
