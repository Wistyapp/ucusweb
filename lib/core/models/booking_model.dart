import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../constants/app_constants.dart';

class BookingModel extends Equatable {
  final String id;
  final String coachId;
  final String facilityId;
  final String spaceId;
  final String facilityOwnerId;

  final String conversationId;
  final DateTime startTime;
  final DateTime endTime;
  final double durationHours;
  final String status;
  final double totalPrice;
  final double subtotal;
  final double platformCommission;
  final double platformCommissionPercentage;
  final String paymentStatus;
  final String? paymentMethod;
  final String? stripePaymentIntentId;
  final double? refundAmount;
  final String? refundReason;
  final DateTime? refundDate;
  final String? notes;
  final String? cancellationReason;
  final String? cancellationInitiatedBy;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;
  final bool hasReview;
  final DateTime? reviewDeadline;
  final DateTime? reminderSentAt;

  // Denormalized data for display
  final String? facilityName;
  final String? facilityImage;
  final String? spaceName;
  final String? coachName;
  final String? coachImage;

  const BookingModel({
    required this.id,
    required this.coachId,
    required this.facilityId,
    required this.spaceId,
    required this.facilityOwnerId,
    required this.conversationId,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    this.status = BookingStatus.pending,
    required this.totalPrice,
    required this.subtotal,
    required this.platformCommission,
    this.platformCommissionPercentage = 15,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentMethod,
    this.stripePaymentIntentId,
    this.refundAmount,
    this.refundReason,
    this.refundDate,
    this.notes,
    this.cancellationReason,
    this.cancellationInitiatedBy,
    this.cancelledAt,
    required this.createdAt,
    this.confirmedAt,
    this.completedAt,
    required this.updatedAt,
    this.hasReview = false,
    this.reviewDeadline,
    this.reminderSentAt,
    this.facilityName,
    this.facilityImage,
    this.spaceName,
    this.coachName,
    this.coachImage,
  });

  // Status checks
  bool get isPending => status == BookingStatus.pending;
  bool get isConfirmed => status == BookingStatus.confirmed;
  bool get isInProgress => status == BookingStatus.inProgress;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isCancelled => status == BookingStatus.cancelled;

  bool get isPaid => paymentStatus == PaymentStatus.completed;
  bool get isRefunded => paymentStatus == PaymentStatus.refunded;

  bool get isUpcoming =>
      (isConfirmed || isPending) && startTime.isAfter(DateTime.now());

  bool get isPast => endTime.isBefore(DateTime.now());

  bool get canCancel =>
      (isPending || isConfirmed) && startTime.isAfter(DateTime.now());

  bool get canReview =>
      isCompleted &&
          !hasReview &&
          (reviewDeadline == null || DateTime.now().isBefore(reviewDeadline!));

  // Calculate refund amount based on cancellation policy
  double calculateRefundAmount() {
    final now = DateTime.now();
    final hoursUntilStart = startTime.difference(now).inHours;

    if (hoursUntilStart >= AppConstants.fullRefundHours) {
      return totalPrice; // 100% refund
    } else if (hoursUntilStart >= AppConstants.partialRefundHours) {
      return totalPrice * AppConstants.partialRefundRate; // 25% refund
    }
    return 0; // No refund
  }

  String get refundPolicyText {
    final now = DateTime.now();
    final hoursUntilStart = startTime.difference(now).inHours;

    if (hoursUntilStart >= AppConstants.fullRefundHours) {
      return 'Remboursement intégral (100%)';
    } else if (hoursUntilStart >= AppConstants.partialRefundHours) {
      return 'Remboursement partiel (25%)';
    }
    return 'Aucun remboursement';
  }

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      coachId: data['coachId'] ?? '',
      facilityId: data['facilityId'] ?? '',
      spaceId: data['spaceId'] ?? '',
      facilityOwnerId: data['facilityOwnerId'] ?? '',
      conversationId: data['conversationId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      durationHours: (data['durationHours'] ?? 0).toDouble(),
      status: data['status'] ?? BookingStatus.pending,
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      platformCommission: (data['platformCommission'] ?? 0).toDouble(),
      platformCommissionPercentage: (data['platformCommissionPercentage'] ?? 15).toDouble(),
      paymentStatus: data['paymentStatus'] ?? PaymentStatus.pending,
      paymentMethod: data['paymentMethod'],
      stripePaymentIntentId: data['stripePaymentIntentId'],
      refundAmount: data['refundAmount']?.toDouble(),
      refundReason: data['refundReason'],
      refundDate: (data['refundDate'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      cancellationReason: data['cancellationReason'],
      cancellationInitiatedBy: data['cancellationInitiatedBy'],
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasReview: data['hasReview'] ?? false,
      reviewDeadline: (data['reviewDeadline'] as Timestamp?)?.toDate(),
      reminderSentAt: (data['reminderSentAt'] as Timestamp?)?.toDate(),
      facilityName: data['facilityName'],
      facilityImage: data['facilityImage'],
      spaceName: data['spaceName'],
      coachName: data['coachName'],
      coachImage: data['coachImage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'coachId': coachId,
      'facilityId': facilityId,
      'spaceId': spaceId,
      'facilityOwnerId': facilityOwnerId,
      'conversationId': conversationId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationHours': durationHours,
      'status': status,
      'totalPrice': totalPrice,
      'subtotal': subtotal,
      'platformCommission': platformCommission,
      'platformCommissionPercentage': platformCommissionPercentage,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'stripePaymentIntentId': stripePaymentIntentId,
      'refundAmount': refundAmount,
      'refundReason': refundReason,
      'refundDate': refundDate != null ? Timestamp.fromDate(refundDate!) : null,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'cancellationInitiatedBy': cancellationInitiatedBy,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'hasReview': hasReview,
      'reviewDeadline': reviewDeadline != null
          ? Timestamp.fromDate(reviewDeadline!)
          : null,
      'reminderSentAt': reminderSentAt != null
          ? Timestamp.fromDate(reminderSentAt!)
          : null,
      'facilityName': facilityName,
      'facilityImage': facilityImage,
      'spaceName': spaceName,
      'coachName': coachName,
      'coachImage': coachImage,
    };
  }

  BookingModel copyWith({
    String? id,
    String? coachId,
    String? facilityId,
    String? spaceId,
    String? facilityOwnerId,
    String? conversationId,
    DateTime? startTime,
    DateTime? endTime,
    double? durationHours,
    String? status,
    double? totalPrice,
    double? subtotal,
    double? platformCommission,
    double? platformCommissionPercentage,
    String? paymentStatus,
    String? paymentMethod,
    String? stripePaymentIntentId,
    double? refundAmount,
    String? refundReason,
    DateTime? refundDate,
    String? notes,
    String? cancellationReason,
    String? cancellationInitiatedBy,
    DateTime? cancelledAt,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    bool? hasReview,
    DateTime? reviewDeadline,
    DateTime? reminderSentAt,
    String? facilityName,
    String? facilityImage,
    String? spaceName,
    String? coachName,
    String? coachImage,
  }) {
    return BookingModel(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      facilityId: facilityId ?? this.facilityId,
      spaceId: spaceId ?? this.spaceId,
      facilityOwnerId: facilityOwnerId ?? this.facilityOwnerId,
      conversationId: conversationId ?? this.conversationId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationHours: durationHours ?? this.durationHours,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      subtotal: subtotal ?? this.subtotal,
      platformCommission: platformCommission ?? this.platformCommission,
      platformCommissionPercentage: platformCommissionPercentage ?? this.platformCommissionPercentage,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      refundAmount: refundAmount ?? this.refundAmount,
      refundReason: refundReason ?? this.refundReason,
      refundDate: refundDate ?? this.refundDate,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancellationInitiatedBy: cancellationInitiatedBy ?? this.cancellationInitiatedBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasReview: hasReview ?? this.hasReview,
      reviewDeadline: reviewDeadline ?? this.reviewDeadline,
      reminderSentAt: reminderSentAt ?? this.reminderSentAt,
      facilityName: facilityName ?? this.facilityName,
      facilityImage: facilityImage ?? this.facilityImage,
      spaceName: spaceName ?? this.spaceName,
      coachName: coachName ?? this.coachName,
      coachImage: coachImage ?? this.coachImage,
    );
  }

  @override
  List<Object?> get props => [id, coachId, facilityId, status, startTime, endTime];
}

// Helper class for creating bookings
class BookingRequest {
  final String facilityId;
  final String spaceId;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;

  BookingRequest({
    required this.facilityId,
    required this.spaceId,
    required this.startTime,
    required this.endTime,
    this.notes,
  });

  double get durationHours =>
      endTime.difference(startTime).inMinutes / 60.0;

  bool get isValidDuration =>
      durationHours >= AppConstants.minBookingDurationHours &&
          durationHours <= AppConstants.maxBookingDurationHours;

  bool get isValidAdvanceTime =>
      startTime.isAfter(DateTime.now().add(
        const Duration(hours: AppConstants.minAdvanceBookingHours),
      ));

  bool get isValidMaxAdvance =>
      startTime.isBefore(DateTime.now().add(
        const Duration(days: AppConstants.maxAdvanceBookingDays),
      ));

  bool get isValid => isValidDuration && isValidAdvanceTime && isValidMaxAdvance;

  Map<String, dynamic> toMap() {
    return {
      'facilityId': facilityId,
      'spaceId': spaceId,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'notes': notes,
    };
  }
}
