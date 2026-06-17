import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthErrorMapper
//
// Centralized utility to convert Firebase auth exceptions and raw errors
// into human-friendly messages that can be safely shown to users.
//
// Never show raw FirebaseAuthException messages or stack traces to users.
// ─────────────────────────────────────────────────────────────────────────────

class AuthErrorMapper {
  AuthErrorMapper._();

  /// Maps any auth-related error to a user-friendly string.
  static String map(Object error) {
    if (error is FirebaseAuthException) {
      return _mapFirebaseCode(error.code);
    }

    final msg = error.toString().toLowerCase();

    // Google sign-in cancelled
    if (msg.contains('cancelled') || msg.contains('cancel')) {
      return 'Sign in was cancelled.';
    }

    // Network errors
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection')) {
      return 'No internet connection. Please try again.';
    }

    return "Couldn't sign you in. Please try again.";
  }

  static String _mapFirebaseCode(String code) {
    return switch (code) {
      // ── Sign-in errors ──────────────────────────────────────────────────────
      'wrong-password' => 'Incorrect password.',
      'invalid-credential' => 'Incorrect password.',
      'user-not-found' => 'No account found with this email.',
      'invalid-email' => 'Please enter a valid email address.',
      'user-disabled' => 'This account has been disabled. Contact support.',
      'too-many-requests' =>
        'Too many sign-in attempts. Please wait and try again.',

      // ── Sign-up errors ──────────────────────────────────────────────────────
      'email-already-in-use' =>
        'An account already exists with this email.',
      'weak-password' =>
        'Password must be at least 8 characters with uppercase, lowercase, and a number.',
      'operation-not-allowed' =>
        'This sign-in method is not enabled. Please contact support.',

      // ── Network / server ────────────────────────────────────────────────────
      'network-request-failed' =>
        'No internet connection. Please try again.',

      // ── Password reset ──────────────────────────────────────────────────────
      'expired-action-code' =>
        'The reset link has expired. Please request a new one.',
      'invalid-action-code' =>
        'Invalid reset link. Please request a new one.',

      // ── Google sign-in cancelled ────────────────────────────────────────────
      'sign_in_canceled' => 'Sign in was cancelled.',
      'sign_in_failed' => "Couldn't sign you in. Please try again.",

      // ── Fallback ────────────────────────────────────────────────────────────
      _ => "Couldn't sign you in. Please try again.",
    };
  }
}
