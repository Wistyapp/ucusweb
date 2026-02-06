import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final String id;
  final String reviewerId;
  final String revieweeId;
  final String bookingId;
  final String reviewType; // 'coach_to_facility' or 'facility_to_coach'
  final double overallRating;
  final String comment;
  final ReviewCategories categories;
  final List<String> photos;
  final bool isVerified;
  final bool isHidden;
  final bool isReported;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Denormalized data
  final String? reviewerName;
  final String? reviewerImage;
  final String? facilityName;

  const ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.revieweeId,
    required this.bookingId,
    required this.reviewType,
    required this.overallRating,
    this.comment = '',
    required this.categories,
    this.photos = const [],
    this.isVerified = false,
    this.isHidden = false,
    this.isReported = false,
    required this.createdAt,
    required this.updatedAt,
    this.reviewerName,
    this.reviewerImage,
    this.facilityName,
  });

  bool get isCoachToFacility => reviewType == 'coach_to_facility';
  bool get isFacilityToCoach => reviewType == 'facility_to_coach';

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      reviewerId: data['reviewerId'] ?? '',
      revieweeId: data['revieweeId'] ?? '',
      bookingId: data['bookingId'] ?? '',
      reviewType: data['reviewType'] ?? 'coach_to_facility',
      overallRating: (data['overallRating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      categories: ReviewCategories.fromMap(
        data['categories'] ?? {},
        data['reviewType'] ?? 'coach_to_facility',
      ),
      photos: List<String>.from(data['photos'] ?? []),
      isVerified: data['isVerified'] ?? false,
      isHidden: data['isHidden'] ?? false,
      isReported: data['isReported'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewerName: data['reviewerName'],
      reviewerImage: data['reviewerImage'],
      facilityName: data['facilityName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'bookingId': bookingId,
      'reviewType': reviewType,
      'overallRating': overallRating,
      'comment': comment,
      'categories': categories.toMap(),
      'photos': photos,
      'isVerified': isVerified,
      'isHidden': isHidden,
      'isReported': isReported,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reviewerName': reviewerName,
      'reviewerImage': reviewerImage,
      'facilityName': facilityName,
    };
  }

  ReviewModel copyWith({
    String? id,
    String? reviewerId,
    String? revieweeId,
    String? bookingId,
    String? reviewType,
    double? overallRating,
    String? comment,
    ReviewCategories? categories,
    List<String>? photos,
    bool? isVerified,
    bool? isHidden,
    bool? isReported,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reviewerName,
    String? reviewerImage,
    String? facilityName,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      revieweeId: revieweeId ?? this.revieweeId,
      bookingId: bookingId ?? this.bookingId,
      reviewType: reviewType ?? this.reviewType,
      overallRating: overallRating ?? this.overallRating,
      comment: comment ?? this.comment,
      categories: categories ?? this.categories,
      photos: photos ?? this.photos,
      isVerified: isVerified ?? this.isVerified,
      isHidden: isHidden ?? this.isHidden,
      isReported: isReported ?? this.isReported,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerImage: reviewerImage ?? this.reviewerImage,
      facilityName: facilityName ?? this.facilityName,
    );
  }

  @override
  List<Object?> get props => [id, reviewerId, revieweeId, bookingId, overallRating];
}

class ReviewCategories extends Equatable {
  // For coach_to_facility reviews
  final double? cleanliness;
  final double? equipmentQuality;
  final double? accessibility;
  final double? atmosphereQuality;
  final double? valueForMoney;

  // For facility_to_coach reviews
  final double? professionalism;
  final double? punctuality;
  final double? respectOfRules;
  final double? communication;
  final double? clientBehavior;

  const ReviewCategories({
    this.cleanliness,
    this.equipmentQuality,
    this.accessibility,
    this.atmosphereQuality,
    this.valueForMoney,
    this.professionalism,
    this.punctuality,
    this.respectOfRules,
    this.communication,
    this.clientBehavior,
  });

  factory ReviewCategories.fromMap(Map<String, dynamic> map, String reviewType) {
    if (reviewType == 'coach_to_facility') {
      return ReviewCategories(
        cleanliness: map['cleanliness']?.toDouble(),
        equipmentQuality: map['equipmentQuality']?.toDouble(),
        accessibility: map['accessibility']?.toDouble(),
        atmosphereQuality: map['atmosphereQuality']?.toDouble(),
        valueForMoney: map['valueForMoney']?.toDouble(),
      );
    } else {
      return ReviewCategories(
        professionalism: map['professionalism']?.toDouble(),
        punctuality: map['punctuality']?.toDouble(),
        respectOfRules: map['respectOfRules']?.toDouble(),
        communication: map['communication']?.toDouble(),
        clientBehavior: map['clientBehavior']?.toDouble(),
      );
    }
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (cleanliness != null) map['cleanliness'] = cleanliness;
    if (equipmentQuality != null) map['equipmentQuality'] = equipmentQuality;
    if (accessibility != null) map['accessibility'] = accessibility;
    if (atmosphereQuality != null) map['atmosphereQuality'] = atmosphereQuality;
    if (valueForMoney != null) map['valueForMoney'] = valueForMoney;
    if (professionalism != null) map['professionalism'] = professionalism;
    if (punctuality != null) map['punctuality'] = punctuality;
    if (respectOfRules != null) map['respectOfRules'] = respectOfRules;
    if (communication != null) map['communication'] = communication;
    if (clientBehavior != null) map['clientBehavior'] = clientBehavior;
    return map;
  }

  @override
  List<Object?> get props => [
    cleanliness,
    equipmentQuality,
    accessibility,
    atmosphereQuality,
    valueForMoney,
    professionalism,
    punctuality,
    respectOfRules,
    communication,
    clientBehavior,
  ];
}

class ReviewSummary extends Equatable {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  const ReviewSummary({
    this.averageRating = 0,
    this.totalReviews = 0,
    this.ratingDistribution = const {},
  });

  factory ReviewSummary.fromReviews(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return const ReviewSummary();
    }

    final totalRating = reviews.fold<double>(
      0,
          (sum, review) => sum + review.overallRating,
    );

    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final review in reviews) {
      final rating = review.overallRating.round();
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }

    return ReviewSummary(
      averageRating: totalRating / reviews.length,
      totalReviews: reviews.length,
      ratingDistribution: distribution,
    );
  }

  double getPercentage(int rating) {
    if (totalReviews == 0) return 0;
    return ((ratingDistribution[rating] ?? 0) / totalReviews) * 100;
  }

  @override
  List<Object> get props => [averageRating, totalReviews, ratingDistribution];
}
