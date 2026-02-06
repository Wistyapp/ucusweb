import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
    required String type,
    required String phoneNumber,
  }) async {
    try {
      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        type: type,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        verification: const VerificationStatus(),
        notificationPreferences: const NotificationPreferences(),
      );

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(credential.user!.uid)
          .set(user.toFirestore());

      // Create initial profile based on type
      if (type == UserTypes.coach) {
        await _createCoachProfile(credential.user!.uid);
      }

      // Send email verification
      await credential.user?.sendEmailVerification();

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create initial coach profile
  Future<void> _createCoachProfile(String userId) async {
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.coachProfiles)
        .doc('default')
        .set({
      'userId': userId,
      'bio': '',
      'specialties': [],
      'certifications': [],
      'hourlyRate': 0,
      'minimumDuration': 1,
      'availableHours': {},
      'totalSessions': 0,
      'rating': 0,
      'reviewsCount': 0,
      'clientsCount': 0,
      'responseTime': 0,
      'acceptanceRate': 0,
      'cancellationRate': 0,
      'preferredFacilityTypes': [],
      'preferredAmenities': [],
      'languages': ['fr'],
      'isVerified': false,
      'isFeatured': false,
      'isSuspended': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(credential.user!.uid)
          .update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Resend email verification
  Future<void> resendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Re-authenticate user (needed before sensitive operations)
  Future<void> reauthenticate(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      // Delete user document (Cloud Function should handle cascading deletes)
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .delete();

      // Delete Firebase Auth account
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get user type
  Future<String?> getUserType() async {
    final uid = currentUserId;
    if (uid == null) return null;

    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();

    return doc.data()?['type'];
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email.';
      case 'invalid-email':
        return 'Format d\'email invalide.';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 8 caractères.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'operation-not-allowed':
        return 'Opération non autorisée.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'requires-recent-login':
        return 'Veuillez vous reconnecter pour effectuer cette opération.';
      default:
        return 'Une erreur s\'est produite: ${e.message}';
    }
  }
}
