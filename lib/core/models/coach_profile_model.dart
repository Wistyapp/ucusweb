import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CoachProfileModel extends Equatable {
  final String id;
  final String userId;
  final String bio;
  final List<String> specialties;
  final List<Certification> certifications;
  final double hourlyRate;
  final int minimumDuration;
  final Map<String, List<TimeSlot>> availableHours;
  final int totalSessions;
  final double rating;
  final int reviewsCount;
  final int clientsCount;
  final double responseTime;
  final double acceptanceRate;
  final double cancellationRate;
  final List<String> preferredFacilityTypes;
  final List<String> preferredAmenities;
  final List<String> languages;
  final bool isVerified;
  final bool isFeatured;
  final bool isSuspended;
  final String? suspensionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CoachProfileModel({
    required this.id,
    required this.userId,
    this.bio = '',
    this.specialties = const [],
    this.certifications = const [],
    this.hourlyRate = 0,
    this.minimumDuration = 1,
    this.availableHours = const {},
    this.totalSessions = 0,
    this.rating = 0,
    this.reviewsCount = 0,
    this.clientsCount = 0,
    this.responseTime = 0,
    this.acceptanceRate = 0,
    this.cancellationRate = 0,
    this.preferredFacilityTypes = const [],
    this.preferredAmenities = const [],
    this.languages = const ['fr'],
    this.isVerified = false,
    this.isFeatured = false,
    this.isSuspended = false,
    this.suspensionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CoachProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoachProfileModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      bio: data['bio'] ?? '',
      specialties: List<String>.from(data['specialties'] ?? []),
      certifications: (data['certifications'] as List<dynamic>?)
          ?.map((e) => Certification.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
      hourlyRate: (data['hourlyRate'] ?? 0).toDouble(),
      minimumDuration: data['minimumDuration'] ?? 1,
      availableHours: _parseAvailableHours(data['availableHours']),
      totalSessions: data['totalSessions'] ?? 0,
      rating: (data['rating'] ?? 0).toDouble(),
      reviewsCount: data['reviewsCount'] ?? 0,
      clientsCount: data['clientsCount'] ?? 0,
      responseTime: (data['responseTime'] ?? 0).toDouble(),
      acceptanceRate: (data['acceptanceRate'] ?? 0).toDouble(),
      cancellationRate: (data['cancellationRate'] ?? 0).toDouble(),
      preferredFacilityTypes: List<String>.from(data['preferredFacilityTypes'] ?? []),
      preferredAmenities: List<String>.from(data['preferredAmenities'] ?? []),
      languages: List<String>.from(data['languages'] ?? ['fr']),
      isVerified: data['isVerified'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      isSuspended: data['isSuspended'] ?? false,
      suspensionReason: data['suspensionReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, List<TimeSlot>> _parseAvailableHours(dynamic data) {
    if (data == null) return {};
    final Map<String, List<TimeSlot>> result = {};
    (data as Map<String, dynamic>).forEach((key, value) {
      result[key] = (value as List<dynamic>)
          .map((e) => TimeSlot.fromMap(e as Map<String, dynamic>))
          .toList();
    });
    return result;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'bio': bio,
      'specialties': specialties,
      'certifications': certifications.map((e) => e.toMap()).toList(),
      'hourlyRate': hourlyRate,
      'minimumDuration': minimumDuration,
      'availableHours': availableHours.map(
            (key, value) => MapEntry(key, value.map((e) => e.toMap()).toList()),
      ),
      'totalSessions': totalSessions,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'clientsCount': clientsCount,
      'responseTime': responseTime,
      'acceptanceRate': acceptanceRate,
      'cancellationRate': cancellationRate,
      'preferredFacilityTypes': preferredFacilityTypes,
      'preferredAmenities': preferredAmenities,
      'languages': languages,
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'isSuspended': isSuspended,
      'suspensionReason': suspensionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CoachProfileModel copyWith({
    String? id,
    String? userId,
    String? bio,
    List<String>? specialties,
    List<Certification>? certifications,
    double? hourlyRate,
    int? minimumDuration,
    Map<String, List<TimeSlot>>? availableHours,
    int? totalSessions,
    double? rating,
    int? reviewsCount,
    int? clientsCount,
    double? responseTime,
    double? acceptanceRate,
    double? cancellationRate,
    List<String>? preferredFacilityTypes,
    List<String>? preferredAmenities,
    List<String>? languages,
    bool? isVerified,
    bool? isFeatured,
    bool? isSuspended,
    String? suspensionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoachProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bio: bio ?? this.bio,
      specialties: specialties ?? this.specialties,
      certifications: certifications ?? this.certifications,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      minimumDuration: minimumDuration ?? this.minimumDuration,
      availableHours: availableHours ?? this.availableHours,
      totalSessions: totalSessions ?? this.totalSessions,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      clientsCount: clientsCount ?? this.clientsCount,
      responseTime: responseTime ?? this.responseTime,
      acceptanceRate: acceptanceRate ?? this.acceptanceRate,
      cancellationRate: cancellationRate ?? this.cancellationRate,
      preferredFacilityTypes: preferredFacilityTypes ?? this.preferredFacilityTypes,
      preferredAmenities: preferredAmenities ?? this.preferredAmenities,
      languages: languages ?? this.languages,
      isVerified: isVerified ?? this.isVerified,
      isFeatured: isFeatured ?? this.isFeatured,
      isSuspended: isSuspended ?? this.isSuspended,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, rating, reviewsCount, isVerified];
}

class Certification extends Equatable {
  final String name;
  final String issuer;
  final DateTime issueDate;
  final DateTime? expiryDate;
  final String? documentUrl;

  const Certification({
    required this.name,
    required this.issuer,
    required this.issueDate,
    this.expiryDate,
    this.documentUrl,
  });

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  factory Certification.fromMap(Map<String, dynamic> map) {
    return Certification(
      name: map['name'] ?? '',
      issuer: map['issuer'] ?? '',
      issueDate: (map['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      documentUrl: map['documentUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'issuer': issuer,
      'issueDate': Timestamp.fromDate(issueDate),
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'documentUrl': documentUrl,
    };
  }

  @override
  List<Object?> get props => [name, issuer, issueDate, expiryDate];
}

class TimeSlot extends Equatable {
  final String start;
  final String end;

  const TimeSlot({
    required this.start,
    required this.end,
  });

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      start: map['start'] ?? '09:00',
      end: map['end'] ?? '18:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start': start,
      'end': end,
    };
  }

  @override
  List<Object> get props => [start, end];
}
