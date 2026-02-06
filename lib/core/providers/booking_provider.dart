import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../services/firestore_service.dart';
import '../services/booking_service.dart';
import '../services/payment_service.dart';

class BookingProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final BookingService _bookingService = BookingService();
  final PaymentService _paymentService = PaymentService();

  List<BookingModel> _coachBookings = [];
  List<BookingModel> _facilityBookings = [];
  BookingModel? _currentBooking;
  BookingPriceDetails? _priceDetails;
  bool _isLoading = false;
  String? _error;

  List<BookingModel> get coachBookings => _coachBookings;
  List<BookingModel> get facilityBookings => _facilityBookings;
  BookingModel? get currentBooking => _currentBooking;
  BookingPriceDetails? get priceDetails => _priceDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered lists
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

  // Load coach bookings
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

  // Load facility bookings (for facility owner)
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

  // Calculate price for booking
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

  // Validate booking request
  BookingValidationResult validateBooking(BookingRequest request) {
    return _bookingService.validateBookingRequest(request);
  }

  // Check slot availability
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

  // Create booking
  Future<CreateBookingResult> createBooking({
    required String coachId,
    required String facilityId,
    required String spaceId,
    required String facilityOwnerId,
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
      // Calculate price first
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
        // Load the created booking
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

  // Process payment
  Future<PaymentResult> processPayment({
    required String bookingId,
    required double amount,
    String? customerEmail,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Initialize payment sheet
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

      // Present payment sheet
      final paymentResult = await _paymentService.presentPaymentSheet();

      if (paymentResult.success) {
        // Confirm booking
        await _bookingService.confirmBooking(bookingId);

        // Reload booking
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

  // Cancel booking
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
        // Update local lists
        _coachBookings = _coachBookings.map((b) {
          if (b.id == bookingId) {
            return b.copyWith(
              status: 'cancelled',
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
              status: 'cancelled',
              cancellationReason: reason,
              cancellationInitiatedBy: cancelledBy,
              cancelledAt: DateTime.now(),
            );
          }
          return b;
        }).toList();

        if (_currentBooking?.id == bookingId) {
          _currentBooking = _currentBooking?.copyWith(
            status: 'cancelled',
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

  // Load single booking
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

  // Clear current booking
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
