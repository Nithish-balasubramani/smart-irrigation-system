import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Authentication Service using Firebase Auth
/// Handles user login, signup, and authentication state
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      if (credential.user != null) {
        await _upsertUserInFirestore(
          credential.user!,
          fallbackName: name,
          isNewUser: true,
        );
      }

      if (credential.user != null) {
        return UserModel(
          id: credential.user!.uid,
          email: email,
          name: name,
          createdAt: DateTime.now(),
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An error occurred during sign up';
    }
  }

  /// Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _upsertUserInFirestore(credential.user!);
      }

      if (credential.user != null) {
        return UserModel(
          id: credential.user!.uid,
          email: email,
          name: credential.user!.displayName ?? 'User',
          createdAt: DateTime.now(),
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An error occurred during sign in';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Error signing out';
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This user account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  /// Get current user model
  UserModel? getCurrentUserModel() {
    final user = currentUser;
    if (user != null) {
      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'User',
        phoneNumber: user.phoneNumber,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
      );
    }
    return null;
  }

  /// Create or update user profile in Firestore under users/{uid}
  Future<void> _upsertUserInFirestore(
    User user, {
    String? fallbackName,
    bool isNewUser = false,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);

      final payload = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? '',
        'name': (user.displayName ?? fallbackName ?? 'User').trim(),
        'phoneNumber': user.phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isNewUser) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await userRef.set(payload, SetOptions(merge: true));
    } catch (e) {
      // Do not block authentication flow if profile sync fails.
      print('Firestore user sync failed: $e');
    }
  }
}
