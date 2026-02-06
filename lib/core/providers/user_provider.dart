import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/coach_profile_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

class UserProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  UserModel? _currentUser;
  CoachProfileModel? _coachProfile;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  CoachProfileModel? get coachProfile => _coachProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isCoach => _currentUser?.type == 'coach';
  bool get isFacilityOwner => _currentUser?.type == 'facility';

  void updateAuth(AuthProvider authProvider) {
    if (authProvider.isAuthenticated && authProvider.userId != null) {
      _loadCurrentUser(authProvider.userId!);
    } else {
      _currentUser = null;
      _coachProfile = null;
      notifyListeners();
    }
  }

  Future<void> _loadCurrentUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _firestoreService.getUser(userId);

      if (_currentUser?.isCoach == true) {
        _coachProfile = await _firestoreService.getCoachProfile(userId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    if (_currentUser?.uid != null) {
      await _loadCurrentUser(_currentUser!.uid);
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? profileImagePath,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};

      if (displayName != null) {
        updates['displayName'] = displayName;
      }

      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber;
      }

      // Upload profile image if provided
      if (profileImagePath != null) {
        final imageFile = await _storageService.pickImageFromGallery();
        if (imageFile != null) {
          final result = await _storageService.uploadProfileImage(
            image: imageFile,
            userId: _currentUser!.uid,
          );
          if (result.success) {
            updates['profileImage'] = result.url;
            updates['profileImageStoragePath'] = result.storagePath;
          }
        }
      }

      if (updates.isNotEmpty) {
        await _firestoreService.updateUser(_currentUser!.uid, updates);
        await refreshUser();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCoachProfile({
    String? bio,
    List<String>? specialties,
    double? hourlyRate,
    List<String>? languages,
    List<String>? preferredFacilityTypes,
    List<String>? preferredAmenities,
  }) async {
    if (_currentUser == null || _coachProfile == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};

      if (bio != null) updates['bio'] = bio;
      if (specialties != null) updates['specialties'] = specialties;
      if (hourlyRate != null) updates['hourlyRate'] = hourlyRate;
      if (languages != null) updates['languages'] = languages;
      if (preferredFacilityTypes != null) {
        updates['preferredFacilityTypes'] = preferredFacilityTypes;
      }
      if (preferredAmenities != null) {
        updates['preferredAmenities'] = preferredAmenities;
      }

      if (updates.isNotEmpty) {
        await _firestoreService.updateCoachProfile(
          _currentUser!.uid,
          _coachProfile!.id,
          updates,
        );
        await refreshUser();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNotificationPreferences(
      NotificationPreferences preferences,
      ) async {
    if (_currentUser == null) return false;

    try {
      await _firestoreService.updateUser(
        _currentUser!.uid,
        {'notificationPreferences': preferences.toMap()},
      );
      await refreshUser();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
