import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class FacilityModel extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final Address address;
  final String description;
  final List<String> images;
  final Map<String, bool> amenities;
  final int capacity;
  final double hourlyRate;
  final double? peakHourRate;
  final PeakHours? peakHours;
  final double rating;
  final int reviewsCount;
  final int totalBookings;
  final bool isActive;
  final bool isVerified;
  final bool isFeatured;
  final String? facilityType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastModifiedBy;

  const FacilityModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    this.description = '',
    this.images = const [],
    this.amenities = const {},
    this.capacity = 0,
    this.hourlyRate = 0,
    this.peakHourRate,
    this.peakHours,
    this.rating = 0,
    this.reviewsCount = 0,
    this.totalBookings = 0,
    this.isActive = true,
    this.isVerified = false,
    this.isFeatured = false,
    this.facilityType,
    required this.createdAt,
    required this.updatedAt,
    this.lastModifiedBy,
  });

  String get primaryImage => images.isNotEmpty ? images.first : '';

  List<String> get amenityList =>
      amenities.entries.where((e) => e.value).map((e) => e.key).toList();

  factory FacilityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FacilityModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      address: Address.fromMap(data['address'] ?? {}),
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      amenities: Map<String, bool>.from(data['amenities'] ?? {}),
      capacity: data['capacity'] ?? 0,
      hourlyRate: (data['hourlyRate'] ?? 0).toDouble(),
      peakHourRate: data['peakHourRate']?.toDouble(),
      peakHours: data['peakHours'] != null
          ? PeakHours.fromMap(data['peakHours'])
          : null,
      rating: (data['rating'] ?? 0).toDouble(),
      reviewsCount: data['reviewsCount'] ?? 0,
      totalBookings: data['totalBookings'] ?? 0,
      isActive: data['isActive'] ?? true,
      isVerified: data['isVerified'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      facilityType: data['facilityType'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastModifiedBy: data['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'address': address.toMap(),
      'description': description,
      'images': images,
      'amenities': amenities,
      'capacity': capacity,
      'hourlyRate': hourlyRate,
      'peakHourRate': peakHourRate,
      'peakHours': peakHours?.toMap(),
      'rating': rating,
      'reviewsCount': reviewsCount,
      'totalBookings': totalBookings,
      'isActive': isActive,
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'facilityType': facilityType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastModifiedBy': lastModifiedBy,
    };
  }

  FacilityModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    Address? address,
    String? description,
    List<String>? images,
    Map<String, bool>? amenities,
    int? capacity,
    double? hourlyRate,
    double? peakHourRate,
    PeakHours? peakHours,
    double? rating,
    int? reviewsCount,
    int? totalBookings,
    bool? isActive,
    bool? isVerified,
    bool? isFeatured,
    String? facilityType,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastModifiedBy,
  }) {
    return FacilityModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      capacity: capacity ?? this.capacity,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      peakHourRate: peakHourRate ?? this.peakHourRate,
      peakHours: peakHours ?? this.peakHours,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      totalBookings: totalBookings ?? this.totalBookings,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      isFeatured: isFeatured ?? this.isFeatured,
      facilityType: facilityType ?? this.facilityType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }

  @override
  List<Object?> get props => [id, ownerId, name, isActive, rating];
}

class Address extends Equatable {
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final GeoPoint? geopoint;

  const Address({
    this.street = '',
    this.city = '',
    this.postalCode = '',
    this.country = 'France',
    this.geopoint,
  });

  String get formatted => '$street, $postalCode $city';
  String get shortFormatted => '$city, $postalCode';

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? 'France',
      geopoint: map['geopoint'] as GeoPoint?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'geopoint': geopoint,
    };
  }

  Address copyWith({
    String? street,
    String? city,
    String? postalCode,
    String? country,
    GeoPoint? geopoint,
  }) {
    return Address(
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      geopoint: geopoint ?? this.geopoint,
    );
  }

  @override
  List<Object?> get props => [street, city, postalCode, country, geopoint];
}

class PeakHours extends Equatable {
  final String startTime;
  final String endTime;
  final List<int> daysOfWeek;
  final double multiplier;

  const PeakHours({
    required this.startTime,
    required this.endTime,
    this.daysOfWeek = const [1, 2, 3, 4, 5],
    this.multiplier = 1.5,
  });

  factory PeakHours.fromMap(Map<String, dynamic> map) {
    return PeakHours(
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

class SpaceModel extends Equatable {
  final String id;
  final String facilityId;
  final String name;
  final String description;
  final int capacity;
  final List<String> images;
  final List<String> equipment;
  final double hourlyRate;
  final double? peakHourRate;
  final double area;
  final bool isAccessible;
  final bool hasParking;
  final bool hasShowers;
  final bool isAvailable;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SpaceModel({
    required this.id,
    required this.facilityId,
    required this.name,
    this.description = '',
    this.capacity = 0,
    this.images = const [],
    this.equipment = const [],
    this.hourlyRate = 0,
    this.peakHourRate,
    this.area = 0,
    this.isAccessible = false,
    this.hasParking = false,
    this.hasShowers = false,
    this.isAvailable = true,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SpaceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpaceModel(
      id: doc.id,
      facilityId: data['facilityId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      capacity: data['capacity'] ?? 0,
      images: List<String>.from(data['images'] ?? []),
      equipment: List<String>.from(data['equipment'] ?? []),
      hourlyRate: (data['hourlyRate'] ?? 0).toDouble(),
      peakHourRate: data['peakHourRate']?.toDouble(),
      area: (data['area'] ?? 0).toDouble(),
      isAccessible: data['isAccessible'] ?? false,
      hasParking: data['hasParking'] ?? false,
      hasShowers: data['hasShowers'] ?? false,
      isAvailable: data['isAvailable'] ?? true,
      lastMaintenanceDate: (data['lastMaintenanceDate'] as Timestamp?)?.toDate(),
      nextMaintenanceDate: (data['nextMaintenanceDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'facilityId': facilityId,
      'name': name,
      'description': description,
      'capacity': capacity,
      'images': images,
      'equipment': equipment,
      'hourlyRate': hourlyRate,
      'peakHourRate': peakHourRate,
      'area': area,
      'isAccessible': isAccessible,
      'hasParking': hasParking,
      'hasShowers': hasShowers,
      'isAvailable': isAvailable,
      'lastMaintenanceDate': lastMaintenanceDate != null
          ? Timestamp.fromDate(lastMaintenanceDate!)
          : null,
      'nextMaintenanceDate': nextMaintenanceDate != null
          ? Timestamp.fromDate(nextMaintenanceDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, facilityId, name, isAvailable];
}
