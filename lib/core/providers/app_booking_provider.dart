import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../services/firestore_service.dart';
import '../services/booking_service.dart';
import '../services/payment_service.dart';
import '../constants/app_constants.dart';

class AppBookingProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final BookingService _bookingService = BookingService();
  final PaymentService _paymentService = PaymentService();

  List<BookingModel> _coachBookings = [];
  List<BookingModel> _facilityBookings = [];
  List<BookingModel> _ownerBookings = []; // ✅ AJOUTÉ: pour les réservations du propriétaire
  BookingModel? _currentBooking;
  BookingPriceDetails? _priceDetails;
  bool _isLoading = false;
  String? _error;

  // Getters existants
  List<BookingModel> get coachBookings => _coachBookings;
  List<BookingModel> get facilityBookings => _facilityBookings;
  BookingModel? get currentBooking => _currentBooking;
  BookingPriceDetails? get priceDetails => _priceDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ AJOUTÉ: Getter générique pour toutes les réservations du propriétaire
  List<BookingModel> get bookings => _ownerBookings;

  List<BookingModel> get upcomingCoachBookings => _coachBookings
      .where((b) => b.isUpcoming)
      .toList();

  List<BookingModel> get pastCoachBookings => _coachBookings
      .where((b) => b.isPast)
      .toList();

  List<BookingModel> get pendingFacilityBookings => _facilityBookings
      .where((b) => b.isPending)
      .toList();

  List<BookingModel> get confirmedFacilityBookings => _facilityBookings
      .where((b) => b.isConfirmed)
      .toList();

  /// ✅ AJOUTÉ: Charge toutes les réservations pour un propriétaire de salle
  Future<void> loadFacilityOwnerBookings(String ownerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ownerBookings = await _firestoreService.getBookingsByFacilityOwner(ownerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ AJOUTÉ: Confirme une réservation (change le statut de pending à confirmed)
  Future<bool> confirmBooking(String bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _bookingService.confirmBooking(bookingId);

      // Mettre à jour localement
      _ownerBookings = _ownerBookings.map((b) {
        if (b.id == bookingId) {
          return b.copyWith(
            status: BookingStatus.confirmed,
            confirmedAt: DateTime.now(),
          );
        }
        return b;
      }).toList();

      _facilityBookings = _facilityBookings.map((b) {
        if (b.id == bookingId) {
          return b.copyWith(
            status: BookingStatus.confirmed,
            confirmedAt: DateTime.now(),
          );
        }
        return b;
      }).toList();

      if (_currentBooking?.id == bookingId) {
        _currentBooking = _currentBooking?.copyWith(
          status: BookingStatus.confirmed,
          confirmedAt: DateTime.now(),
        );
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

  /// Récupère une réservation par son ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final booking = await _firestoreService.getBooking(bookingId);
      _currentBooking = booking;

      _isLoading = false;
      notifyListeners();

      return booking;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadCoachBookings(String coachId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _coachBookings = await _firestoreService.getCoachBookings(coachId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFacilityBookings(String facilityId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _facilityBookings = await _firestoreService.getFacilityBookings(facilityId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void calculatePrice({
    required double hourlyRate,
    required DateTime startTime,
    required DateTime endTime,
    double? peakHourRate,
    bool isPeakTime = false,
  }) {
    final durationHours = endTime.difference(startTime).inMinutes / 60.0;

    _priceDetails = _bookingService.calculatePrice(
      hourlyRate: hourlyRate,
      durationHours: durationHours,
      peakHourRate: peakHourRate,
      isPeakTime: isPeakTime,
    );
    notifyListeners();
  }

  BookingValidationResult validateBooking(BookingRequest request) {
    return _bookingService.validateBookingRequest(request);
  }

  Future<bool> checkAvailability({
    required String facilityId,
    required String spaceId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      return await _bookingService.isTimeSlotAvailable(
        facilityId: facilityId,
        spaceId: spaceId,
        startTime: startTime,
        endTime: endTime,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<CreateBookingResult> createBooking({
    required String coachId,
    required String facilityId,
    required String spaceId,
    required String facilityOwnerId,
    required String conversationId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
    String? facilityName,
    String? facilityImage,
    String? spaceName,
    String? coachName,
    String? coachImage,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_priceDetails == null) {
        _isLoading = false;
        _error = 'Veuillez calculer le prix avant de réserver.';
        notifyListeners();
        return CreateBookingResult(
          success: false,
          error: _error,
        );
      }

      final result = await _bookingService.createBooking(
        coachId: coachId,
        facilityId: facilityId,
        spaceId: spaceId,
        facilityOwnerId: facilityOwnerId,
        conversationId: conversationId,
        startTime: startTime,
        endTime: endTime,
        totalPrice: _priceDetails!.totalPrice,
        subtotal: _priceDetails!.subtotal,
        platformCommission: _priceDetails!.platformCommission,
        notes: notes,
        facilityName: facilityName,
        facilityImage: facilityImage,
        spaceName: spaceName,
        coachName: coachName,
        coachImage: coachImage,
      );

      if (result.success && result.bookingId != null) {
        _currentBooking = await _firestoreService.getBooking(result.bookingId!);
      } else {
        _error = result.error;
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return CreateBookingResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<PaymentResult> processPayment({
    required String bookingId,
    required double amount,
    String? customerEmail,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final initResult = await _paymentService.initializePaymentSheet(
        bookingId: bookingId,
        amount: amount,
        currency: 'EUR',
        customerEmail: customerEmail,
      );

      if (!initResult.success) {
        _error = initResult.error;
        _isLoading = false;
        notifyListeners();
        return PaymentResult(success: false, error: initResult.error);
      }

      final paymentResult = await _paymentService.presentPaymentSheet();

      if (paymentResult.success) {
        await _bookingService.confirmBooking(bookingId);
        _currentBooking = await _firestoreService.getBooking(bookingId);
      } else {
        _error = paymentResult.error;
      }

      _isLoading = false;
      notifyListeners();
      return paymentResult;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return PaymentResult(success: false, error: e.toString());
    }
  }

  Future<CancelBookingResult> cancelBooking({
    required String bookingId,
    required String reason,
    required String cancelledBy,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _bookingService.cancelBooking(
        bookingId: bookingId,
        reason: reason,
        cancelledBy: cancelledBy,
      );

      if (result.success) {
        _coachBookings = _coachBookings.map((b) {
          if (b.id == bookingId) {
            return b.copyWith(
              status: BookingStatus.cancelled,
              cancellationReason: reason,
              cancellationInitiatedBy: cancelledBy,
              cancelledAt: DateTime.now(),
            );
          }
          return b;
        }).toList();

        _facilityBookings = _facilityBookings.map((b) {
          if (b.id == bookingId) {
            return b.copyWith(
              status: BookingStatus.cancelled,
              cancellationReason: reason,
              cancellationInitiatedBy: cancelledBy,
              cancelledAt: DateTime.now(),
            );
          }
          return b;
        }).toList();

        // ✅ AJOUTÉ: Mettre à jour aussi _ownerBookings
        _ownerBookings = _ownerBookings.map((b) {
          if (b.id == bookingId) {
            return b.copyWith(
              status: BookingStatus.cancelled,
              cancellationReason: reason,
              cancellationInitiatedBy: cancelledBy,
              cancelledAt: DateTime.now(),
            );
          }
          return b;
        }).toList();

        if (_currentBooking?.id == bookingId) {
          _currentBooking = _currentBooking?.copyWith(
            status: BookingStatus.cancelled,
            cancellationReason: reason,
          );
        }
      } else {
        _error = result.error;
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return CancelBookingResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadBooking(String bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentBooking = await _firestoreService.getBooking(bookingId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentBooking() {
    _currentBooking = null;
    _priceDetails = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
