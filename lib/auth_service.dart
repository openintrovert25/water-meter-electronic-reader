import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Authentication + Firestore profile service.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  Future<String?> register({
    required String username,
    required String password,
    required String name,
    String? email,
  }) async {
    if (username.trim().isEmpty) return 'Username cannot be empty.';
    if (name.trim().isEmpty) return 'Name cannot be empty.';

    final loginEmail = (email != null && email.trim().isNotEmpty)
        ? email.trim()
        : '${username.trim().toLowerCase()}@watermeter.com';

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      await credential.user!.updateDisplayName(name.trim());

      await _db.collection('users').doc(credential.user!.uid).set({
        'name': name.trim(),
        'username': username.trim(),
        'email': email?.trim() ?? '',
        'loginEmail': loginEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> login({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty) return 'Please enter your username.';
    if (password.isEmpty) return 'Please enter your password.';

    final loginEmail = username.trim().contains('@')
        ? username.trim()
        : '${username.trim().toLowerCase()}@watermeter.com';

    try {
      await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Get current user profile from Firestore
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Update name and/or email in Firestore
  Future<void> updateProfile({String? name, String? email}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final updates = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      updates['name'] = name.trim();
      await user.updateDisplayName(name.trim());
    }
    if (email != null) updates['email'] = email.trim();
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(user.uid).update(updates);
    }
  }

  /// Change password — re-authenticates first (Firebase requirement)
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return 'Not logged in.';
    if (newPassword.length < 6) return 'New password must be at least 6 characters.';

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String _friendlyError(String code) {
    return switch (code) {
      'email-already-in-use'   => 'Username already taken. Please choose another.',
      'invalid-email'          => 'Invalid username or email.',
      'weak-password'          => 'Password must be at least 6 characters.',
      'user-not-found'         => 'Username not found.',
      'wrong-password'         => 'Incorrect password.',
      'invalid-credential'     => 'Incorrect username or password.',
      'too-many-requests'      => 'Too many attempts. Please wait a moment.',
      'network-request-failed' => 'No internet connection.',
      _                        => 'Error: $code',
    };
  }

  Future<dynamic> tryAutoLogin() async {}
}
