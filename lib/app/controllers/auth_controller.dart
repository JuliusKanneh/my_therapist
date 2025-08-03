import 'dart:developer';

import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';
import '../routes/app_routes.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reactive variables
  final Rx<User?> _firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  User? get firebaseUser => _firebaseUser.value;
  UserModel? get userModel => _userModel.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get isLoggedIn => _firebaseUser.value != null;

  // Expose the reactive firebase user for other controllers
  Rx<User?> get firebaseUserStream => _firebaseUser;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    _firebaseUser.bindStream(_auth.authStateChanges());
    // Navigate based on auth state
    ever(_firebaseUser, _handleAuthChanged);
  }

  // Handle authentication state changes
  void _handleAuthChanged(User? user) async {
    if (user != null) {
      // User is signed in, fetch user data
      await _fetchUserData(user.uid);
      Get.offAllNamed(Routes.HOME);
    } else {
      // User is signed out
      _userModel.value = null;
      Get.offAllNamed(Routes.LOGIN);
    }
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel.value = UserModel.fromDocument(doc);
      }
    } catch (e) {
      log('Error fetching user data: $e');
    }
  }

  // Register new user
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Create Firebase user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document in Firestore
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toDocument());

        // Update display name
        await credential.user!.updateDisplayName(displayName);

        Get.snackbar(
          'Success',
          'Account created successfully!',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Sign in existing user
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Get.snackbar(
        'Welcome Back!',
        'Successfully signed in',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      Get.snackbar(
        'Signed Out',
        'See you next time!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _setError('Error signing out. Please try again.');
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      _setLoading(true);
      _clearError();

      await _auth.sendPasswordResetEmail(email: email);

      Get.snackbar(
        'Password Reset',
        'Password reset email sent to $email',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _setError('Error sending password reset email.');
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    Map<String, dynamic>? therapyPreferences,
  }) async {
    try {
      _setLoading(true);

      if (firebaseUser != null && userModel != null) {
        // Update Firebase Auth display name
        if (displayName != null) {
          await firebaseUser!.updateDisplayName(displayName);
        }

        // Update Firestore document
        final updatedUser = userModel!.copyWith(
          displayName: displayName,
          therapyPreferences: therapyPreferences,
          lastActiveAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser!.uid)
            .update(updatedUser.toDocument());

        _userModel.value = updatedUser;

        Get.snackbar(
          'Profile Updated',
          'Your profile has been updated successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      _setError('Error updating profile. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Update last active timestamp
  Future<void> updateLastActive() async {
    if (firebaseUser != null) {
      try {
        await _firestore
            .collection('users')
            .doc(firebaseUser!.uid)
            .update({'lastActiveAt': Timestamp.now()});
      } catch (e) {
        // Silently handle error for background updates
        log('Error updating last active: $e');
      }
    }
  }

  // Helper methods
  void _setLoading(bool value) => _isLoading.value = value;
  void _setError(String message) => _errorMessage.value = message;
  void _clearError() => _errorMessage.value = '';

  // Handle Firebase Auth errors
  void _handleAuthError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email address.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email address.';
        break;
      case 'weak-password':
        message = 'Password should be at least 6 characters.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      default:
        message = 'Authentication failed. Please try again.';
    }
    _setError(message);

    Get.snackbar(
      'Authentication Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }
}
