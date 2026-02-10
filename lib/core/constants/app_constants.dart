import 'package:flutter/material.dart';

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

  /// Liste des équipements disponibles (version simplifiée pour les formulaires)
  static const List<String> availableAmenities = [
    'Parking',
    'WiFi',
    'Douches',
    'Vestiaires',
    'Casiers',
    'Climatisation',
    'Chauffage',
    'Système audio',
    'Miroirs',
    'Tapis de sol',
    'Poids libres',
    'Machines cardio',
    'Accès handicapé',
    'Fontaine à eau',
    'Serviettes',
    'Premiers secours',
  ];
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







class AppUserTypes {
  static const String coach = 'coach';
  static const String facility = 'facility';
}

/// Statuts de réservation


/// Statuts de paiement


/// Liste des équipements disponibles
///


class Amenities {
  static const List<Map<String, dynamic>> all = [
    {'id': 'parking', 'name': 'Parking', 'icon': Icons.local_parking},
    {'id': 'wifi', 'name': 'WiFi', 'icon': Icons.wifi},
    {'id': 'showers', 'name': 'Douches', 'icon': Icons.shower},
    {'id': 'lockers', 'name': 'Casiers', 'icon': Icons.lock},
    {'id': 'air_conditioning', 'name': 'Climatisation', 'icon': Icons.ac_unit},
    {'id': 'heating', 'name': 'Chauffage', 'icon': Icons.thermostat},
    {'id': 'sound_system', 'name': 'Système audio', 'icon': Icons.speaker},
    {'id': 'mirrors', 'name': 'Miroirs', 'icon': Icons.crop_square},
    {'id': 'mats', 'name': 'Tapis', 'icon': Icons.rectangle},
    {'id': 'weights', 'name': 'Poids libres', 'icon': Icons.fitness_center},
    {'id': 'cardio', 'name': 'Équipement cardio', 'icon': Icons.directions_run},
    {'id': 'accessible', 'name': 'Accès handicapé', 'icon': Icons.accessible},
    {'id': 'changing_rooms', 'name': 'Vestiaires', 'icon': Icons.checkroom},
    {'id': 'towels', 'name': 'Serviettes', 'icon': Icons.dry_cleaning},
    {'id': 'water_fountain', 'name': 'Fontaine à eau', 'icon': Icons.water_drop},
    {'id': 'first_aid', 'name': 'Premiers secours', 'icon': Icons.medical_services},
  ];

  static Map<String, dynamic>? getById(String id) {
    try {
      return all.firstWhere((a) => a['id'] == id);
    } catch (_) {
      return null;
    }
  }

  static String getName(String id) {
    return getById(id)?['name'] ?? id;
  }

  static IconData getIcon(String id) {
    return getById(id)?['icon'] ?? Icons.check;
  }
}

/// Types de facilities
class FacilityTypes {
  static const List<Map<String, dynamic>> all = [
    {'id': 'gym', 'name': 'Salle de sport', 'icon': Icons.fitness_center},
    {'id': 'studio', 'name': 'Studio', 'icon': Icons.room},
    {'id': 'outdoor', 'name': 'Espace extérieur', 'icon': Icons.park},
    {'id': 'pool', 'name': 'Piscine', 'icon': Icons.pool},
    {'id': 'court', 'name': 'Terrain', 'icon': Icons.sports_tennis},
    {'id': 'dojo', 'name': 'Dojo', 'icon': Icons.sports_martial_arts},
    {'id': 'crossfit', 'name': 'Box CrossFit', 'icon': Icons.sports_gymnastics},
    {'id': 'yoga', 'name': 'Studio yoga', 'icon': Icons.self_improvement},
    {'id': 'dance', 'name': 'Studio danse', 'icon': Icons.music_note},
    {'id': 'boxing', 'name': 'Salle de boxe', 'icon': Icons.sports_mma},
    {'id': 'pilates', 'name': 'Studio Pilates', 'icon': Icons.accessibility_new},
    {'id': 'climbing', 'name': 'Mur d\'escalade', 'icon': Icons.terrain},
  ];

  static Map<String, dynamic>? getById(String id) {
    try {
      return all.firstWhere((t) => t['id'] == id);
    } catch (_) {
      return null;
    }
  }

  static String getName(String id) {
    return getById(id)?['name'] ?? id;
  }

  static IconData getIcon(String id) {
    return getById(id)?['icon'] ?? Icons.business;
  }
}

/// Spécialités des coachs
class CoachSpecialties {
  static const List<Map<String, dynamic>> all = [
    {'id': 'personal_training', 'name': 'Personal training'},
    {'id': 'weight_loss', 'name': 'Perte de poids'},
    {'id': 'muscle_gain', 'name': 'Prise de masse'},
    {'id': 'cardio', 'name': 'Cardio'},
    {'id': 'strength', 'name': 'Force'},
    {'id': 'hiit', 'name': 'HIIT'},
    {'id': 'crossfit', 'name': 'CrossFit'},
    {'id': 'yoga', 'name': 'Yoga'},
    {'id': 'pilates', 'name': 'Pilates'},
    {'id': 'boxing', 'name': 'Boxe'},
    {'id': 'martial_arts', 'name': 'Arts martiaux'},
    {'id': 'swimming', 'name': 'Natation'},
    {'id': 'running', 'name': 'Course à pied'},
    {'id': 'cycling', 'name': 'Cyclisme'},
    {'id': 'rehabilitation', 'name': 'Rééducation'},
    {'id': 'senior_fitness', 'name': 'Fitness senior'},
    {'id': 'prenatal', 'name': 'Prénatal'},
    {'id': 'postnatal', 'name': 'Postnatal'},
    {'id': 'nutrition', 'name': 'Nutrition'},
    {'id': 'stretching', 'name': 'Stretching'},
  ];
}

/// Configuration de l'application
class AppConfigConstants {
  static const String appName = 'UnCoachUneSalle';
  static const String appVersion = '1.0.0';

  // Commission plateforme (en pourcentage)
  static const double platformCommissionRate = 0.15; // 10%

  // Durées de réservation
  static const int minBookingDurationMinutes = 30;
  static const int maxBookingDurationMinutes = 480; // 8 heures
  static const int bookingSlotIntervalMinutes = 30;

  // Délais
  static const int minAdvanceBookingHours = 2; // Réserver au moins 2h à l'avance
  static const int maxAdvanceBookingDays = 60; // Réserver jusqu'à 60 jours à l'avance
  static const int cancellationDeadlineHours = 24; // Annulation gratuite jusqu'à 24h avant

  // Pagination
  static const int defaultPageSize = 20;

  // Images
  static const int maxFacilityImages = 10;
  static const int maxProfileImageSizeBytes = 5 * 1024 * 1024; // 5 MB
}

/// Messages d'erreur communs
class AppErrorMessages {
  static const String networkError = 'Erreur de connexion. Vérifiez votre connexion internet.';
  static const String unknownError = 'Une erreur inattendue est survenue. Veuillez réessayer.';
  static const String authError = 'Erreur d\'authentification. Veuillez vous reconnecter.';
  static const String permissionDenied = 'Vous n\'avez pas la permission d\'effectuer cette action.';
  static const String notFound = 'Élément non trouvé.';
  static const String invalidData = 'Données invalides.';
}
