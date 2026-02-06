import 'package:flutter/foundation.dart';
import '../models/facility_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

class FacilityProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  List<FacilityModel> _searchResults = [];
  List<FacilityModel> _myFacilities = [];
  FacilityModel? _selectedFacility;
  List<SpaceModel> _selectedFacilitySpaces = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  List<FacilityModel> get searchResults => _searchResults;
  List<FacilityModel> get myFacilities => _myFacilities;
  FacilityModel? get selectedFacility => _selectedFacility;
  List<SpaceModel> get selectedFacilitySpaces => _selectedFacilitySpaces;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;

  // Search facilities
  Future<void> searchFacilities({
    String? city,
    double? minRating,
    List<String>? amenities,
    double? maxPrice,
  }) async {
    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _firestoreService.searchFacilities(
        city: city,
        minRating: minRating,
        amenities: amenities,
        maxPrice: maxPrice,
      );
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isSearching = false;
      notifyListeners();
    }
  }

  // Load facility details
  Future<void> loadFacility(String facilityId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedFacility = await _firestoreService.getFacility(facilityId);
      if (_selectedFacility != null) {
        _selectedFacilitySpaces = await _firestoreService.getSpaces(facilityId);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load my facilities (for facility owners)
  Future<void> loadMyFacilities(String ownerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myFacilities = await _firestoreService.getFacilitiesByOwner(ownerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create facility
  Future<String?> createFacility({
    required String ownerId,
    required String name,
    required String description,
    required Address address,
    required Map<String, bool> amenities,
    required int capacity,
    required double hourlyRate,
    double? peakHourRate,
    String? facilityType,
    List<XFile>? images,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Upload images first
      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        // Create a temporary ID for storage
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        final results = await _storageService.uploadFacilityImages(
          images: images,
          facilityId: tempId,
        );
        imageUrls = results
            .where((r) => r.success && r.url != null)
            .map((r) => r.url!)
            .toList();
      }

      final facility = FacilityModel(
        id: '',
        ownerId: ownerId,
        name: name,
        description: description,
        address: address,
        amenities: amenities,
        capacity: capacity,
        hourlyRate: hourlyRate,
        peakHourRate: peakHourRate,
        facilityType: facilityType,
        images: imageUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final facilityId = await _firestoreService.createFacility(facility);

      // Refresh facilities list
      await loadMyFacilities(ownerId);

      _isLoading = false;
      notifyListeners();
      return facilityId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update facility
  Future<bool> updateFacility({
    required String facilityId,
    String? name,
    String? description,
    Map<String, bool>? amenities,
    int? capacity,
    double? hourlyRate,
    double? peakHourRate,
    bool? isActive,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (amenities != null) updates['amenities'] = amenities;
      if (capacity != null) updates['capacity'] = capacity;
      if (hourlyRate != null) updates['hourlyRate'] = hourlyRate;
      if (peakHourRate != null) updates['peakHourRate'] = peakHourRate;
      if (isActive != null) updates['isActive'] = isActive;

      if (updates.isNotEmpty) {
        await _firestoreService.updateFacility(facilityId, updates);

        // Reload facility
        await loadFacility(facilityId);
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

  // Add facility images
  Future<bool> addFacilityImages({
    required String facilityId,
    required List<XFile> images,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _storageService.uploadFacilityImages(
        images: images,
        facilityId: facilityId,
      );

      final newUrls = results
          .where((r) => r.success && r.url != null)
          .map((r) => r.url!)
          .toList();

      if (newUrls.isNotEmpty && _selectedFacility != null) {
        final allImages = [..._selectedFacility!.images, ...newUrls];
        await _firestoreService.updateFacility(
          facilityId,
          {'images': allImages},
        );
        await loadFacility(facilityId);
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

  // Create space within facility
  Future<String?> createSpace({
    required String facilityId,
    required String name,
    required String description,
    required int capacity,
    required double hourlyRate,
    double? peakHourRate,
    double? area,
    List<String>? equipment,
    bool isAccessible = false,
    bool hasParking = false,
    bool hasShowers = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final space = SpaceModel(
        id: '',
        facilityId: facilityId,
        name: name,
        description: description,
        capacity: capacity,
        hourlyRate: hourlyRate,
        peakHourRate: peakHourRate,
        area: area ?? 0,
        equipment: equipment ?? [],
        isAccessible: isAccessible,
        hasParking: hasParking,
        hasShowers: hasShowers,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final spaceId = await _firestoreService.createSpace(facilityId, space);

      // Reload spaces
      _selectedFacilitySpaces = await _firestoreService.getSpaces(facilityId);

      _isLoading = false;
      notifyListeners();
      return spaceId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Delete facility
  Future<bool> deleteFacility(String facilityId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.deleteFacility(facilityId);
      _myFacilities.removeWhere((f) => f.id == facilityId);

      if (_selectedFacility?.id == facilityId) {
        _selectedFacility = null;
        _selectedFacilitySpaces = [];
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

  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // Clear selected facility
  void clearSelectedFacility() {
    _selectedFacility = null;
    _selectedFacilitySpaces = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
