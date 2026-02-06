import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String type; // 'coach' or 'facility'
  final String phoneNumber;
  final String? profileImage;
  final String? profileImageStoragePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final VerificationStatus verification;
  final String? fcmToken;
  final NotificationPreferences notificationPreferences;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.type,
    required this.phoneNumber,
    this.profileImage,
    this.profileImageStoragePath,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.isActive = true,
    required this.verification,
    this.fcmToken,
    required this.notificationPreferences,
  });

  bool get isCoach => type == 'coach';
  bool get isFacilityOwner => type == 'facility';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      type: data['type'] ?? 'coach',
      phoneNumber: data['phoneNumber'] ?? '',
      profileImage: data['profileImage'],
      profileImageStoragePath: data['profileImageStoragePath'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      verification: VerificationStatus.fromMap(data['verification'] ?? {}),
      fcmToken: data['fcmToken'],
      notificationPreferences: NotificationPreferences.fromMap(
        data['notificationPreferences'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'type': type,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'profileImageStoragePath': profileImageStoragePath,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
      'verification': verification.toMap(),
      'fcmToken': fcmToken,
      'notificationPreferences': notificationPreferences.toMap(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? type,
    String? phoneNumber,
    String? profileImage,
    String? profileImageStoragePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isActive,
    VerificationStatus? verification,
    String? fcmToken,
    NotificationPreferences? notificationPreferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      profileImageStoragePath: profileImageStoragePath ?? this.profileImageStoragePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      verification: verification ?? this.verification,
      fcmToken: fcmToken ?? this.fcmToken,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    type,
    phoneNumber,
    profileImage,
    isActive,
  ];
}

class VerificationStatus extends Equatable {
  final bool identity;
  final DateTime? identityVerifiedAt;
  final bool insurance;
  final DateTime? insuranceVerifiedAt;
  final bool license;
  final DateTime? licenseVerifiedAt;
  final bool backgroundCheck;
  final DateTime? backgroundCheckAt;

  const VerificationStatus({
    this.identity = false,
    this.identityVerifiedAt,
    this.insurance = false,
    this.insuranceVerifiedAt,
    this.license = false,
    this.licenseVerifiedAt,
    this.backgroundCheck = false,
    this.backgroundCheckAt,
  });

  bool get isFullyVerified => identity && (insurance || license);

  factory VerificationStatus.fromMap(Map<String, dynamic> map) {
    return VerificationStatus(
      identity: map['identity'] ?? false,
      identityVerifiedAt: (map['identityVerifiedAt'] as Timestamp?)?.toDate(),
      insurance: map['insurance'] ?? false,
      insuranceVerifiedAt: (map['insuranceVerifiedAt'] as Timestamp?)?.toDate(),
      license: map['license'] ?? false,
      licenseVerifiedAt: (map['licenseVerifiedAt'] as Timestamp?)?.toDate(),
      backgroundCheck: map['backgroundCheck'] ?? false,
      backgroundCheckAt: (map['backgroundCheckAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'identity': identity,
      'identityVerifiedAt': identityVerifiedAt != null
          ? Timestamp.fromDate(identityVerifiedAt!)
          : null,
      'insurance': insurance,
      'insuranceVerifiedAt': insuranceVerifiedAt != null
          ? Timestamp.fromDate(insuranceVerifiedAt!)
          : null,
      'license': license,
      'licenseVerifiedAt': licenseVerifiedAt != null
          ? Timestamp.fromDate(licenseVerifiedAt!)
          : null,
      'backgroundCheck': backgroundCheck,
      'backgroundCheckAt': backgroundCheckAt != null
          ? Timestamp.fromDate(backgroundCheckAt!)
          : null,
    };
  }

  @override
  List<Object?> get props => [identity, insurance, license, backgroundCheck];
}

class NotificationPreferences extends Equatable {
  final bool emailNotifications;
  final bool smsNotifications;
  final bool pushNotifications;
  final bool bookingUpdates;
  final bool newMessages;
  final bool reviews;

  const NotificationPreferences({
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.pushNotifications = true,
    this.bookingUpdates = true,
    this.newMessages = true,
    this.reviews = true,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      emailNotifications: map['emailNotifications'] ?? true,
      smsNotifications: map['smsNotifications'] ?? false,
      pushNotifications: map['pushNotifications'] ?? true,
      bookingUpdates: map['bookingUpdates'] ?? true,
      newMessages: map['newMessages'] ?? true,
      reviews: map['reviews'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'pushNotifications': pushNotifications,
      'bookingUpdates': bookingUpdates,
      'newMessages': newMessages,
      'reviews': reviews,
    };
  }

  NotificationPreferences copyWith({
    bool? emailNotifications,
    bool? smsNotifications,
    bool? pushNotifications,
    bool? bookingUpdates,
    bool? newMessages,
    bool? reviews,
  }) {
    return NotificationPreferences(
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      newMessages: newMessages ?? this.newMessages,
      reviews: reviews ?? this.reviews,
    );
  }

  @override
  List<Object> get props => [
    emailNotifications,
    smsNotifications,
    pushNotifications,
    bookingUpdates,
    newMessages,
    reviews,
  ];
}
