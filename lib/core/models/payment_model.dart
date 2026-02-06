import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PaymentModel extends Equatable {
  final String id;
  final String bookingId;
  final String userId;
  final String facilityOwnerId;
  final double amount;
  final String currency;
  final double platformCommission;
  final double facilityAmount;
  final String status;
  final String? stripePaymentIntentId;
  final String? stripeChargeId;
  final String? stripeReceiptUrl;
  final String? paymentMethod;
  final String? cardLast4;
  final String? cardBrand;
  final String refundStatus;
  final String? refundReason;
  final double? refundAmount;
  final DateTime? refundDate;
  final String? stripeRefundId;
  final String? failureReason;
  final DateTime? receiptSentAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.facilityOwnerId,
    required this.amount,
    this.currency = 'EUR',
    required this.platformCommission,
    required this.facilityAmount,
    this.status = 'pending',
    this.stripePaymentIntentId,
    this.stripeChargeId,
    this.stripeReceiptUrl,
    this.paymentMethod,
    this.cardLast4,
    this.cardBrand,
    this.refundStatus = 'none',
    this.refundReason,
    this.refundAmount,
    this.refundDate,
    this.stripeRefundId,
    this.failureReason,
    this.receiptSentAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isSucceeded => status == 'succeeded';
  bool get isFailed => status == 'failed';
  bool get isRefunded => status == 'refunded';

  bool get hasRefund => refundStatus != 'none';

  String get formattedAmount => '${amount.toStringAsFixed(2)} €';
  String get formattedFacilityAmount => '${facilityAmount.toStringAsFixed(2)} €';
  String get formattedCommission => '${platformCommission.toStringAsFixed(2)} €';

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'succeeded':
        return 'Réussi';
      case 'failed':
        return 'Échoué';
      case 'refunded':
        return 'Remboursé';
      default:
        return status;
    }
  }

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      userId: data['userId'] ?? '',
      facilityOwnerId: data['facilityOwnerId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'EUR',
      platformCommission: (data['platformCommission'] ?? 0).toDouble(),
      facilityAmount: (data['facilityAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      stripePaymentIntentId: data['stripePaymentIntentId'],
      stripeChargeId: data['stripeChargeId'],
      stripeReceiptUrl: data['stripeReceiptUrl'],
      paymentMethod: data['paymentMethod'],
      cardLast4: data['cardLast4'],
      cardBrand: data['cardBrand'],
      refundStatus: data['refundStatus'] ?? 'none',
      refundReason: data['refundReason'],
      refundAmount: data['refundAmount']?.toDouble(),
      refundDate: (data['refundDate'] as Timestamp?)?.toDate(),
      stripeRefundId: data['stripeRefundId'],
      failureReason: data['failureReason'],
      receiptSentAt: (data['receiptSentAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'facilityOwnerId': facilityOwnerId,
      'amount': amount,
      'currency': currency,
      'platformCommission': platformCommission,
      'facilityAmount': facilityAmount,
      'status': status,
      'stripePaymentIntentId': stripePaymentIntentId,
      'stripeChargeId': stripeChargeId,
      'stripeReceiptUrl': stripeReceiptUrl,
      'paymentMethod': paymentMethod,
      'cardLast4': cardLast4,
      'cardBrand': cardBrand,
      'refundStatus': refundStatus,
      'refundReason': refundReason,
      'refundAmount': refundAmount,
      'refundDate': refundDate != null ? Timestamp.fromDate(refundDate!) : null,
      'stripeRefundId': stripeRefundId,
      'failureReason': failureReason,
      'receiptSentAt': receiptSentAt != null ? Timestamp.fromDate(receiptSentAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? bookingId,
    String? userId,
    String? facilityOwnerId,
    double? amount,
    String? currency,
    double? platformCommission,
    double? facilityAmount,
    String? status,
    String? stripePaymentIntentId,
    String? stripeChargeId,
    String? stripeReceiptUrl,
    String? paymentMethod,
    String? cardLast4,
    String? cardBrand,
    String? refundStatus,
    String? refundReason,
    double? refundAmount,
    DateTime? refundDate,
    String? stripeRefundId,
    String? failureReason,
    DateTime? receiptSentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      facilityOwnerId: facilityOwnerId ?? this.facilityOwnerId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      platformCommission: platformCommission ?? this.platformCommission,
      facilityAmount: facilityAmount ?? this.facilityAmount,
      status: status ?? this.status,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      stripeChargeId: stripeChargeId ?? this.stripeChargeId,
      stripeReceiptUrl: stripeReceiptUrl ?? this.stripeReceiptUrl,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cardLast4: cardLast4 ?? this.cardLast4,
      cardBrand: cardBrand ?? this.cardBrand,
      refundStatus: refundStatus ?? this.refundStatus,
      refundReason: refundReason ?? this.refundReason,
      refundAmount: refundAmount ?? this.refundAmount,
      refundDate: refundDate ?? this.refundDate,
      stripeRefundId: stripeRefundId ?? this.stripeRefundId,
      failureReason: failureReason ?? this.failureReason,
      receiptSentAt: receiptSentAt ?? this.receiptSentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, bookingId, amount, status];
}

class AvailabilityModel extends Equatable {
  final String id;
  final String facilityId;
  final String? spaceId;
  final Map<int, DaySchedule> recurringSchedule;
  final List<BlockedDate> blockedDates;
  final List<PeakHourConfig> peakHours;
  final List<SpecialRate> specialRates;
  final int minAdvanceBooking;
  final int maxAdvanceBooking;
  final int bufferBetweenBookings;
  final int minBookingDuration;
  final int maxBookingDuration;
  final DateTime lastUpdated;
  final String? updatedBy;

  const AvailabilityModel({
    required this.id,
    required this.facilityId,
    this.spaceId,
    this.recurringSchedule = const {},
    this.blockedDates = const [],
    this.peakHours = const [],
    this.specialRates = const [],
    this.minAdvanceBooking = 24,
    this.maxAdvanceBooking = 90,
    this.bufferBetweenBookings = 0,
    this.minBookingDuration = 1,
    this.maxBookingDuration = 8,
    required this.lastUpdated,
    this.updatedBy,
  });

  bool isOpenOn(int dayOfWeek) {
    return recurringSchedule[dayOfWeek]?.isOpen ?? false;
  }

  DaySchedule? getScheduleFor(int dayOfWeek) {
    return recurringSchedule[dayOfWeek];
  }

  bool isDateBlocked(DateTime date) {
    return blockedDates.any((blocked) =>
    blocked.date.year == date.year &&
        blocked.date.month == date.month &&
        blocked.date.day == date.day);
  }

  factory AvailabilityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final recurringScheduleData = data['recurringSchedule'] as Map<String, dynamic>? ?? {};
    final recurringSchedule = <int, DaySchedule>{};
    recurringScheduleData.forEach((key, value) {
      recurringSchedule[int.parse(key)] = DaySchedule.fromMap(value);
    });

    return AvailabilityModel(
      id: doc.id,
      facilityId: data['facilityId'] ?? '',
      spaceId: data['spaceId'],
      recurringSchedule: recurringSchedule,
      blockedDates: (data['blockedDates'] as List<dynamic>?)
          ?.map((e) => BlockedDate.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
      peakHours: (data['peakHours'] as List<dynamic>?)
          ?.map((e) => PeakHourConfig.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
      specialRates: (data['specialRates'] as List<dynamic>?)
          ?.map((e) => SpecialRate.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
      minAdvanceBooking: data['minAdvanceBooking'] ?? 24,
      maxAdvanceBooking: data['maxAdvanceBooking'] ?? 90,
      bufferBetweenBookings: data['bufferBetweenBookings'] ?? 0,
      minBookingDuration: data['minBookingDuration'] ?? 1,
      maxBookingDuration: data['maxBookingDuration'] ?? 8,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: data['updatedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'facilityId': facilityId,
      'spaceId': spaceId,
      'recurringSchedule': recurringSchedule.map(
            (key, value) => MapEntry(key.toString(), value.toMap()),
      ),
      'blockedDates': blockedDates.map((e) => e.toMap()).toList(),
      'peakHours': peakHours.map((e) => e.toMap()).toList(),
      'specialRates': specialRates.map((e) => e.toMap()).toList(),
      'minAdvanceBooking': minAdvanceBooking,
      'maxAdvanceBooking': maxAdvanceBooking,
      'bufferBetweenBookings': bufferBetweenBookings,
      'minBookingDuration': minBookingDuration,
      'maxBookingDuration': maxBookingDuration,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'updatedBy': updatedBy,
    };
  }

  @override
  List<Object?> get props => [id, facilityId, spaceId, lastUpdated];
}

class DaySchedule extends Equatable {
  final bool isOpen;
  final String openTime;
  final String closeTime;

  const DaySchedule({
    this.isOpen = true,
    this.openTime = '09:00',
    this.closeTime = '21:00',
  });

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    return DaySchedule(
      isOpen: map['isOpen'] ?? true,
      openTime: map['openTime'] ?? '09:00',
      closeTime: map['closeTime'] ?? '21:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
    };
  }

  @override
  List<Object> get props => [isOpen, openTime, closeTime];
}

class BlockedDate extends Equatable {
  final DateTime date;
  final String reason;

  const BlockedDate({
    required this.date,
    this.reason = '',
  });

  factory BlockedDate.fromMap(Map<String, dynamic> map) {
    return BlockedDate(
      date: (map['date'] as Timestamp).toDate(),
      reason: map['reason'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'reason': reason,
    };
  }

  @override
  List<Object> get props => [date, reason];
}

class PeakHourConfig extends Equatable {
  final String startTime;
  final String endTime;
  final List<int> daysOfWeek;
  final double multiplier;

  const PeakHourConfig({
    required this.startTime,
    required this.endTime,
    this.daysOfWeek = const [1, 2, 3, 4, 5],
    this.multiplier = 1.5,
  });

  factory PeakHourConfig.fromMap(Map<String, dynamic> map) {
    return PeakHourConfig(
      startTime: map['startTime'] ?? '18:00',
      endTime: map['endTime'] ?? '21:00',
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? [1, 2, 3, 4, 5]),
      multiplier: (map['multiplier'] ?? 1.5).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'daysOfWeek': daysOfWeek,
      'multiplier': multiplier,
    };
  }

  @override
  List<Object> get props => [startTime, endTime, daysOfWeek, multiplier];
}

class SpecialRate extends Equatable {
  final DateTime date;
  final String startTime;
  final String endTime;
  final double rate;
  final String reason;

  const SpecialRate({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.rate,
    this.reason = '',
  });

  factory SpecialRate.fromMap(Map<String, dynamic> map) {
    return SpecialRate(
      date: (map['date'] as Timestamp).toDate(),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      rate: (map['rate'] ?? 0).toDouble(),
      reason: map['reason'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'rate': rate,
      'reason': reason,
    };
  }

  @override
  List<Object> get props => [date, startTime, endTime, rate, reason];
}
