import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/user_model.dart';
import '../../data/datasources/firestore_datasource.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    firebaseAuth: FirebaseAuth.instance,
    firestoreDatasource: ref.watch(firestoreDatasourceProvider),
  );
}

@riverpod
Stream<User?> authStateChanges(Ref ref) {
  return FirebaseAuth.instance.authStateChanges();
}

// ─────────────────────────────────────────────────────────────────────────────
// currentUserProvider — THE CRITICAL FIX
//
// Previously this was a static snapshot:
//   return FirebaseAuth.instance.currentUser;  ← captured once, never updated
//
// This meant ALL downstream providers (subjectsStreamProvider, userProfileProvider,
// timetableRepositoryProvider, dashboardNotifier) continued to stream Account A's
// Firestore data even after switching to Account B, because they all read _uid from
// this provider.
//
// The fix: derive currentUser from the reactive authStateChangesProvider.
// Now whenever Firebase auth state changes (login OR logout), this provider
// emits the new user, which cascades to rebuild every dependent provider
// automatically — no manual ref.invalidate() calls needed.
// ─────────────────────────────────────────────────────────────────────────────
@riverpod
User? currentUser(Ref ref) {
  return ref.watch(authStateChangesProvider).valueOrNull;
}

class AuthRepository {
  final FirebaseAuth _auth;
  final FirestoreDatasource _db;

  AuthRepository({
    required FirebaseAuth firebaseAuth,
    required FirestoreDatasource firestoreDatasource,
  })  : _auth = firebaseAuth,
        _db = firestoreDatasource;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name);

    // Create Firestore profile
    final userModel = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      photoUrl: credential.user?.photoURL,
    );
    await _db.createUserProfile(userModel);
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    // Force the Google account chooser to appear even for returning users.
    // This is the critical fix for account switching — without signOut() here,
    // Google returns the previously-used account silently without showing the picker.
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut(); // clear cached account → forces picker

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google Sign-In cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);

    // Create or update Firestore profile
    final user = userCredential.user!;
    final existing = await _db.getUserProfile(user.uid);
    if (existing == null) {
      await _db.createUserProfile(UserModel(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL,
      ));
    }
    return userCredential;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
