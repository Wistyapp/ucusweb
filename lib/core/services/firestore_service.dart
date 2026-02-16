import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/coach_profile_model.dart';
import '../models/facility_model.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';
import '../models/message_model.dart';
import '../constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== Users ====================

  // Get user by ID
  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // Get user stream
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Update user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .update(data);
  }

  // ==================== Coach Profiles ====================

  // Get coach profile
  Future<CoachProfileModel?> getCoachProfile(String userId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.coachProfiles)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return CoachProfileModel.fromFirestore(snapshot.docs.first);
  }

  // Update coach profile
  Future<void> updateCoachProfile(
      String userId,
      String profileId,
      Map<String, dynamic> data,
      ) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.coachProfiles)
        .doc(profileId)
        .update(data);
  }

  // ==================== Facilities ====================

  // Get facility by ID
  Future<FacilityModel?> getFacility(String facilityId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.facilities)
        .doc(facilityId)
        .get();

    if (!doc.exists) return null;
    return FacilityModel.fromFirestore(doc);
  }

  // Get facilities by owner
  Future<List<FacilityModel>> getFacilitiesByOwner(String ownerId) async {
    if(kDebugMode)print('🔍 [FirestoreService] getFacilitiesByOwner called with ownerId: $ownerId');
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.facilities)
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();

      if(kDebugMode)print('📦 [FirestoreService] Query returned ${snapshot.docs.length} documents');

      // Debug: Afficher les données brutes
      for (var doc in snapshot.docs) {
        if(kDebugMode)print('   📄 Doc ID: ${doc.id}');
        if(kDebugMode)print('   📄 Data: ${doc.data()}');
      }

      return snapshot.docs
          .map((doc) => FacilityModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if(kDebugMode)print('❌ [FirestoreService] Error in getFacilitiesByOwner: $e');
      rethrow;
    }
  }

  // Get facilities stream by owner
  Stream<List<FacilityModel>> getFacilitiesByOwnerStream(String ownerId) {
    return _firestore
        .collection(FirestoreCollections.facilities)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FacilityModel.fromFirestore(doc))
        .toList());
  }

  /// Met à jour les disponibilités d'une installation
  Future<void> updateFacilityAvailability(
      String facilityId,
      Map<String, dynamic> availabilityData,
      ) async {
    await _firestore
        .collection(FirestoreCollections.facilities)
        .doc(facilityId)
        .update({
      'availability': availabilityData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }



  /// Récupère toutes les réservations pour un propriétaire de salle (par facilityOwnerId)
  Future<List<BookingModel>> getBookingsByFacilityOwner(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.bookings)
          .where('facilityOwnerId', isEqualTo: ownerId)
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des réservations: $e');
    }
  }



  // Search facilities
  Future<List<FacilityModel>> searchFacilities({
    String? city,
    double? minRating,
    List<String>? amenities,
    double? maxPrice,
    int limit = AppConstants.searchResultsLimit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreCollections.facilities)
        .where('isActive', isEqualTo: true);

    if (city != null && city.isNotEmpty) {
      query = query.where('address.city', isEqualTo: city);
    }

    if (minRating != null) {
      query = query.where('rating', isGreaterThanOrEqualTo: minRating);
    }

    if (maxPrice != null) {
      query = query.where('hourlyRate', isLessThanOrEqualTo: maxPrice);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    var facilities = snapshot.docs
        .map((doc) => FacilityModel.fromFirestore(doc))
        .toList();

    // Client-side filtering for amenities (Firestore doesn't support array-contains-all)
    if (amenities != null && amenities.isNotEmpty) {
      facilities = facilities.where((facility) {
        return amenities.every((amenity) =>
        facility.amenities[amenity] == true);
      }).toList();
    }

    return facilities;
  }

  // Create facility
  Future<String> createFacility(FacilityModel facility) async {
    final docRef = await _firestore
        .collection(FirestoreCollections.facilities)
        .add(facility.toFirestore());
    return docRef.id;
  }

  // Update facility
  Future<void> updateFacility(
      String facilityId,
      Map<String, dynamic> data,
      ) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection(FirestoreCollections.facilities)
        .doc(facilityId)
        .update(data);
  }

  // Delete facility
  Future<void> deleteFacility(String facilityId) async {
    await _firestore
        .collection(FirestoreCollections.facilities)
        .doc(facilityId)
        .delete();
  }

  // ==================== Spaces ====================

  // Get spaces for facility
  Future<List<SpaceModel>> getSpaces(String facilityId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.facilities)
        .doc(facilityId)
        .collection(FirestoreCollections.spaces)
        .get();

    return snapshot.docs
        .map((doc) => SpaceModel.fromFirestore(doc))
        .toList();
  }

  // Create space
  Future<String> createSpace(String facilityId, SpaceModel space) async {
    final docRef = await _firestore
        .collection(FirestoreCollections.facilities)
        .doc(facilityId)
        .collection(FirestoreCollections.spaces)
        .add(space.toFirestore());
    return docRef.id;
  }

  // ==================== Bookings ====================

  // Get booking by ID
  Future<BookingModel?> getBooking(String bookingId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.bookings)
        .doc(bookingId)
        .get();

    if (!doc.exists) return null;
    return BookingModel.fromFirestore(doc);
  }

  // Get bookings for coach
  Future<List<BookingModel>> getCoachBookings(
      String coachId, {
        String? status,
        bool upcoming = false,
      }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreCollections.bookings)
        .where('coachId', isEqualTo: coachId);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (upcoming) {
      query = query.where('startTime', isGreaterThan: Timestamp.now());
    }

    query = query.orderBy('startTime', descending: false);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();
  }

  // Get bookings stream for coach
  Stream<List<BookingModel>> getCoachBookingsStream(String coachId) {
    return _firestore
        .collection(FirestoreCollections.bookings)
        .where('coachId', isEqualTo: coachId)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList());
  }

  // Get bookings for facility
  Future<List<BookingModel>> getFacilityBookings(
      String facilityId, {
        String? status,
        DateTime? fromDate,
        DateTime? toDate,
      }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreCollections.bookings)
        .where('facilityId', isEqualTo: facilityId);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (fromDate != null) {
      query = query.where('startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
    }

    if (toDate != null) {
      query = query.where('startTime',
          isLessThanOrEqualTo: Timestamp.fromDate(toDate));
    }

    query = query.orderBy('startTime', descending: false);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();
  }

  // Get bookings stream for facility owner
  Stream<List<BookingModel>> getFacilityOwnerBookingsStream(String ownerId) {
    return _firestore
        .collection(FirestoreCollections.bookings)
        .where('facilityOwnerId', isEqualTo: ownerId)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList());
  }

  // Check booking availability
  Future<bool> isTimeSlotAvailable(
      String facilityId,
      String spaceId,
      DateTime startTime,
      DateTime endTime,
      ) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.bookings)
        .where('facilityId', isEqualTo: facilityId)
        .where('spaceId', isEqualTo: spaceId)
        .where('status', whereIn: [BookingStatus.pending, BookingStatus.confirmed])
        .get();

    for (final doc in snapshot.docs) {
      final booking = BookingModel.fromFirestore(doc);
      // Check for overlap
      if (startTime.isBefore(booking.endTime) &&
          endTime.isAfter(booking.startTime)) {
        return false;
      }
    }
    return true;
  }

  // Create booking
  Future<String> createBooking(BookingModel booking) async {
    final docRef = await _firestore
        .collection(FirestoreCollections.bookings)
        .add(booking.toFirestore());
    return docRef.id;
  }

  // Update booking
  Future<void> updateBooking(
      String bookingId,
      Map<String, dynamic> data,
      ) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection(FirestoreCollections.bookings)
        .doc(bookingId)
        .update(data);
  }

  // ==================== Reviews ====================

  // Get reviews for user
  Future<List<ReviewModel>> getReviewsForUser(
      String userId, {
        int limit = AppConstants.defaultPageSize,
      }) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.reviews)
        .where('revieweeId', isEqualTo: userId)
        .where('isHidden', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ReviewModel.fromFirestore(doc))
        .toList();
  }

  // Get reviews for facility
  Future<List<ReviewModel>> getReviewsForFacility(
      String facilityId, {
        int limit = AppConstants.defaultPageSize,
      }) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.reviews)
        .where('revieweeId', isEqualTo: facilityId)
        .where('reviewType', isEqualTo: 'coach_to_facility')
        .where('isHidden', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ReviewModel.fromFirestore(doc))
        .toList();
  }

  // Create review
  Future<String> createReview(ReviewModel review) async {
    final docRef = await _firestore
        .collection(FirestoreCollections.reviews)
        .add(review.toFirestore());

    // Update hasReview flag on booking
    await updateBooking(review.bookingId, {'hasReview': true});

    return docRef.id;
  }

  // ==================== Messages ====================

  // Get conversations for user
  Stream<List<ConversationModel>> getConversationsStream(String userId) {
    return _firestore
        .collection(FirestoreCollections.messages)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ConversationModel.fromFirestore(doc))
        .toList());
  }

  // Get or create conversation
  Future<String> getOrCreateConversation(
      String userId1,
      String userId2,
      Map<String, ParticipantInfo> participantsInfo,
      ) async {
    // Check if conversation exists
    final existingQuery = await _firestore
        .collection(FirestoreCollections.messages)
        .where('participants', arrayContains: userId1)
        .get();

    for (final doc in existingQuery.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      if (participants.contains(userId2)) {
        return doc.id;
      }
    }

    // Create new conversation
    final conversation = ConversationModel(
      id: '',
      participants: [userId1, userId2],
      lastMessageTime: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      participantsInfo: participantsInfo,
    );

    final docRef = await _firestore
        .collection(FirestoreCollections.messages)
        .add(conversation.toFirestore());

    return docRef.id;
  }

  // Get messages for conversation
  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _firestore
        .collection(FirestoreCollections.messages)
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.messagesPageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromFirestore(doc))
        .toList());
  }

  // Send message
  Future<void> sendMessage(String conversationId, MessageModel message) async {
    // Add message to subcollection
    await _firestore
        .collection(FirestoreCollections.messages)
        .doc(conversationId)
        .collection('messages')
        .add(message.toFirestore());

    // Update conversation
    await _firestore
        .collection(FirestoreCollections.messages)
        .doc(conversationId)
        .update({
      'lastMessage': message.text.length > 50
          ? '${message.text.substring(0, 50)}...'
          : message.text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': message.senderId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(
      String conversationId,
      String userId,
      ) async {
    await _firestore
        .collection(FirestoreCollections.messages)
        .doc(conversationId)
        .update({
      'unreadCount.$userId': 0,
    });
  }
}
