class AppConstants {
  // App Info
  static const String appName = 'UnCoachUneSalle';
  static const String appVersion = '1.0.0';

  // Platform Commission
  static const double platformCommissionRate = 0.15; // 15%

  // Booking Rules
  static const int minAdvanceBookingHours = 24;
  static const int maxAdvanceBookingDays = 90;
  static const int minBookingDurationHours = 1;
  static const int maxBookingDurationHours = 8;
  static const double minBookingAmountEur = 15.0;
  static const double maxBookingAmountEur = 5000.0;

  // Cancellation Policy (hours before start)
  static const int fullRefundHours = 48;     // 100% refund
  static const int partialRefundHours = 24;  // 25% refund
  static const double partialRefundRate = 0.25;

  // Review Rules
  static const int reviewDeadlineDays = 30;
  static const int minReviewChars = 20;
  static const int maxReviewChars = 1000;
  static const int maxReviewPhotos = 5;

  // Search Settings
  static const int defaultSearchRadius = 10; // km
  static const int maxSearchRadius = 50;     // km
  static const int searchResultsLimit = 20;

  // Pagination
  static const int defaultPageSize = 20;
  static const int messagesPageSize = 50;

  // Image Sizes
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int thumbnailSize = 200;
  static const int maxImagesPerFacility = 10;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxDisplayNameLength = 50;
  static const int minBioLength = 10;
  static const int maxBioLength = 500;
  static const int maxDescriptionLength = 1000;

  // Rate Limiting
  static const int maxLoginAttemptsPerHour = 5;
  static const int maxBookingsPerDay = 5;
  static const int maxMessagesPerDay = 50;
  static const int maxReviewsPerMonth = 10;
}

class FirestoreCollections {
  static const String users = 'users';
  static const String coachProfiles = 'coachProfiles';
  static const String facilityProfiles = 'facilityProfiles';
  static const String facilities = 'facilities';
  static const String spaces = 'spaces';
  static const String bookings = 'bookings';
  static const String reviews = 'reviews';
  static const String messages = 'messages';
  static const String conversations = 'conversations';
  static const String payments = 'payments';
  static const String availability = 'availability';
  static const String analytics = 'analytics';
}

class StoragePaths {
  static const String facilityImages = 'facility-images';
  static const String coachProfiles = 'coach-profiles';
  static const String facilityDocuments = 'facility-documents';
  static const String reviewPhotos = 'review-photos';
  static const String messageAttachments = 'message-attachments';
}

class UserTypes {
  static const String coach = 'coach';
  static const String facility = 'facility';
}

class BookingStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

class PaymentStatus {
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String refunded = 'refunded';
}

class Amenities {
  static const List<Map<String, dynamic>> all = [
    {'id': 'wifi', 'name': 'WiFi', 'icon': 'wifi'},
    {'id': 'parking', 'name': 'Parking', 'icon': 'local_parking'},
    {'id': 'shower', 'name': 'Douches', 'icon': 'shower'},
    {'id': 'locker', 'name': 'Casiers', 'icon': 'lock'},
    {'id': 'ac', 'name': 'Climatisation', 'icon': 'ac_unit'},
    {'id': 'heating', 'name': 'Chauffage', 'icon': 'whatshot'},
    {'id': 'mirror', 'name': 'Miroirs', 'icon': 'crop_square'},
    {'id': 'sound_system', 'name': 'Système audio', 'icon': 'speaker'},
    {'id': 'water_fountain', 'name': 'Fontaine à eau', 'icon': 'water_drop'},
    {'id': 'accessible', 'name': 'Accès PMR', 'icon': 'accessible'},
    {'id': 'changing_room', 'name': 'Vestiaires', 'icon': 'checkroom'},
    {'id': 'towels', 'name': 'Serviettes', 'icon': 'dry'},
  ];
}

class Specialties {
  static const List<String> all = [
    'yoga',
    'pilates',
    'fitness',
    'crossfit',
    'boxe',
    'arts_martiaux',
    'danse',
    'musculation',
    'cardio',
    'stretching',
    'meditation',
    'natation',
    'tennis',
    'basketball',
    'football',
    'gymnastique',
    'escalade',
    'cycling',
    'running',
    'nutrition',
  ];

  static String getDisplayName(String specialty) {
    final names = {
      'yoga': 'Yoga',
      'pilates': 'Pilates',
      'fitness': 'Fitness',
      'crossfit': 'CrossFit',
      'boxe': 'Boxe',
      'arts_martiaux': 'Arts Martiaux',
      'danse': 'Danse',
      'musculation': 'Musculation',
      'cardio': 'Cardio',
      'stretching': 'Stretching',
      'meditation': 'Méditation',
      'natation': 'Natation',
      'tennis': 'Tennis',
      'basketball': 'Basketball',
      'football': 'Football',
      'gymnastique': 'Gymnastique',
      'escalade': 'Escalade',
      'cycling': 'Cycling',
      'running': 'Running',
      'nutrition': 'Nutrition',
    };
    return names[specialty] ?? specialty;
  }
}

class FacilityTypes {
  static const List<String> all = [
    'gym',
    'studio',
    'dojo',
    'crossfit_box',
    'pool',
    'court',
    'outdoor',
    'wellness_center',
    'community_center',
  ];

  static String getDisplayName(String type) {
    final names = {
      'gym': 'Salle de sport',
      'studio': 'Studio',
      'dojo': 'Dojo',
      'crossfit_box': 'Box CrossFit',
      'pool': 'Piscine',
      'court': 'Terrain',
      'outdoor': 'Espace extérieur',
      'wellness_center': 'Centre de bien-être',
      'community_center': 'Centre communautaire',
    };
    return names[type] ?? type;
  }
}
