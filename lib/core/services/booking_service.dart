import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/booking_model.dart';
import '../models/facility_model.dart';
import '../constants/app_constants.dart';
import 'firestore_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Calculate booking price
  BookingPriceDetails calculatePrice({
    required double hourlyRate,
    required double durationHours,
    double? peakHourRate,
    bool isPeakTime = false,
  }) {
    final rate = (isPeakTime && peakHourRate != null) ? peakHourRate : hourlyRate;
    final subtotal = rate * durationHours;
    final platformCommission = subtotal * AppConstants.platformCommissionRate;
    final totalPrice = subtotal + platformCommission;

    // Ensure minimum amount
    final finalTotal = totalPrice < AppConstants.minBookingAmountEur
        ? AppConstants.minBookingAmountEur
        : totalPrice;

    return BookingPriceDetails(
      hourlyRate: rate,
      durationHours: durationHours,
      subtotal: subtotal,
      platformCommission: platformCommission,
      totalPrice: finalTotal,
    );
  }

  // Validate booking request
  BookingValidationResult validateBookingRequest(BookingRequest request) {
    final errors = <String>[];

    // Check duration
    if (request.durationHours < AppConstants.minBookingDurationHours) {
      errors.add('La durée minimum est de ${AppConstants.minBookingDurationHours} heure(s).');
    }
    if (request.durationHours > AppConstants.maxBookingDurationHours) {
      errors.add('La durée maximum est de ${AppConstants.maxBookingDurationHours} heures.');
    }

    // Check advance booking
    final now = DateTime.now();
    final minStartTime = now.add(
      const Duration(hours: AppConstants.minAdvanceBookingHours),
    );
    if (request.startTime.isBefore(minStartTime)) {
      errors.add('La réservation doit être effectuée au moins ${AppConstants.minAdvanceBookingHours}h à l\'avance.');
    }

    final maxStartTime = now.add(
      const Duration(days: AppConstants.maxAdvanceBookingDays),
    );
    if (request.startTime.isAfter(maxStartTime)) {
      errors.add('La réservation ne peut pas dépasser ${AppConstants.maxAdvanceBookingDays} jours à l\'avance.');
    }

    // Check end time after start time
    if (request.endTime.isBefore(request.startTime) ||
        request.endTime.isAtSameMomentAs(request.startTime)) {
      errors.add('L\'heure de fin doit être après l\'heure de début.');
    }

    return BookingValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  // Check if time slot is available
  Future<bool> isTimeSlotAvailable({
    required String facilityId,
    required String spaceId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return _firestoreService.isTimeSlotAvailable(
      facilityId,
      spaceId,
      startTime,
      endTime,
    );
  }

  // Create booking via Cloud Function
  Future<CreateBookingResult> createBooking({
    required String coachId,
    required String facilityId,
    required String spaceId,
    required String facilityOwnerId,
    required DateTime startTime,
    required DateTime endTime,
    required double totalPrice,
    required double subtotal,
    required double platformCommission,
    String? notes,
    String? facilityName,
    String? facilityImage,
    String? spaceName,
    String? coachName,
    String? coachImage,
  }) async {
    try {
      // Call Cloud Function for secure booking creation
      final callable = _functions.httpsCallable('createBooking');
      final result = await callable.call({
        'facilityId': facilityId,
        'spaceId': spaceId,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'notes': notes,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return CreateBookingResult(
          success: true,
          bookingId: data['data']['bookingId'],
          clientSecret: data['data']['clientSecret'],
          totalPrice: (data['data']['totalPrice'] as num).toDouble(),
        );
      } else {
        return CreateBookingResult(
          success: false,
          error: data['error']?['message'] ?? 'Erreur lors de la création de la réservation',
        );
      }
    } catch (e) {
      // Fallback: Create booking directly in Firestore (for development)
      final durationHours = endTime.difference(startTime).inMinutes / 60.0;

      final booking = BookingModel(
        id: '',
        coachId: coachId,
        facilityId: facilityId,
        spaceId: spaceId,
        facilityOwnerId: facilityOwnerId,
        startTime: startTime,
        endTime: endTime,
        durationHours: durationHours,
        totalPrice: totalPrice,
        subtotal: subtotal,
        platformCommission: platformCommission,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        reviewDeadline: endTime.add(const Duration(days: AppConstants.reviewDeadlineDays)),
        facilityName: facilityName,
        facilityImage: facilityImage,
        spaceName: spaceName,
        coachName: coachName,
        coachImage: coachImage,
      );

      final docRef = await _firestore
          .collection(FirestoreCollections.bookings)
          .add(booking.toFirestore());

      return CreateBookingResult(
        success: true,
        bookingId: docRef.id,
        totalPrice: totalPrice,
      );
    }
  }

  // Confirm booking (after payment)
  Future<void> confirmBooking(String bookingId) async {
    await _firestore
        .collection(FirestoreCollections.bookings)
        .doc(bookingId)
        .update({
      'status': BookingStatus.confirmed,
      'paymentStatus': PaymentStatus.completed,
      'confirmedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Cancel booking
  Future<CancelBookingResult> cancelBooking({
    required String bookingId,
    required String reason,
    required String cancelledBy,
  }) async {
    try {
      // Call Cloud Function for secure cancellation with refund handling
      final callable = _functions.httpsCallable('cancelBooking');
      final result = await callable.call({
        'bookingId': bookingId,
        'reason': reason,
        'cancelledBy': cancelledBy,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return CancelBookingResult(
          success: true,
          refundAmount: (data['data']['refundAmount'] as num?)?.toDouble() ?? 0,
        );
      } else {
        return CancelBookingResult(
          success: false,
          error: data['error']?['message'] ?? 'Erreur lors de l\'annulation',
        );
      }
    } catch (e) {
      // Fallback: Cancel directly in Firestore
      final bookingDoc = await _firestore
          .collection(FirestoreCollections.bookings)
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        return CancelBookingResult(
          success: false,
          error: 'Réservation non trouvée',
        );
      }

      final booking = BookingModel.fromFirestore(bookingDoc);
      final refundAmount = booking.calculateRefundAmount();

      await _firestore
          .collection(FirestoreCollections.bookings)
          .doc(bookingId)
          .update({
        'status': BookingStatus.cancelled,
        'cancellationReason': reason,
        'cancellationInitiatedBy': cancelledBy,
        'cancelledAt': FieldValue.serverTimestamp(),
        'refundAmount': refundAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return CancelBookingResult(
        success: true,
        refundAmount: refundAmount,
      );
    }
  }

  // Get upcoming bookings count for coach
  Future<int> getUpcomingBookingsCount(String coachId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.bookings)
        .where('coachId', isEqualTo: coachId)
        .where('status', whereIn: [BookingStatus.pending, BookingStatus.confirmed])
        .where('startTime', isGreaterThan: Timestamp.now())
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // Get pending bookings for facility owner
  Future<int> getPendingBookingsCount(String ownerId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.bookings)
        .where('facilityOwnerId', isEqualTo: ownerId)
        .where('status', isEqualTo: BookingStatus.pending)
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}

// Helper classes
class BookingPriceDetails {
  final double hourlyRate;
  final double durationHours;
  final double subtotal;
  final double platformCommission;
  final double totalPrice;

  BookingPriceDetails({
    required this.hourlyRate,
    required this.durationHours,
    required this.subtotal,
    required this.platformCommission,
    required this.totalPrice,
  });

  String get formattedSubtotal => '${subtotal.toStringAsFixed(2)} €';
  String get formattedCommission => '${platformCommission.toStringAsFixed(2)} €';
  String get formattedTotal => '${totalPrice.toStringAsFixed(2)} €';
}

class BookingValidationResult {
  final bool isValid;
  final List<String> errors;

  BookingValidationResult({
    required this.isValid,
    required this.errors,
  });
}

class CreateBookingResult {
  final bool success;
  final String? bookingId;
  final String? clientSecret;
  final double? totalPrice;
  final String? error;

  CreateBookingResult({
    required this.success,
    this.bookingId,
    this.clientSecret,
    this.totalPrice,
    this.error,
  });
}

class CancelBookingResult {
  final bool success;
  final double refundAmount;
  final String? error;

  CancelBookingResult({
    required this.success,
    this.refundAmount = 0,
    this.error,
  });
}
