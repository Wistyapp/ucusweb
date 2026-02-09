import 'package:flutter/material.dart';

// Auth Screens
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/user_type_selection_screen.dart';

// Coach Screens
import '../../features/coach/screens/coach_home_screen.dart';
import '../../features/coach/screens/facility_search_screen.dart';
import '../../features/coach/screens/facility_detail_screen.dart';
import '../../features/coach/screens/booking_screen.dart';
import '../../features/coach/screens/coach_bookings_screen.dart';

// Facility Owner Screens
import '../../features/facility/screens/facility_owner_home_screen.dart' hide MyFacilitiesScreen, ProfileScreen, ConversationsScreen;
import '../../features/facility/screens/my_facilities_screen.dart';
import '../../features/facility/screens/create_facility_screen.dart';
import '../../features/facility/screens/edit_facility_screen.dart';
import '../../features/facility/screens/facility_bookings_screen.dart' as facility_bookings;
import '../../features/facility/screens/availability_management_screen.dart';

// Shared Screens
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/messaging/screens/conversations_screen.dart';
import '../../features/messaging/screens/chat_screen.dart';
import '../../features/reviews/screens/reviews_screen.dart';
import '../../features/reviews/screens/create_review_screen.dart';
import '../../features/shared/screens/booking_detail_screen.dart';
import '../../features/shared/screens/notifications_screen.dart';
import '../../features/shared/screens/settings_screen.dart';

class AppRouter {
  // Auth Routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String userTypeSelection = '/user-type-selection';

  // Coach Routes
  static const String coachHome = '/coach/home';
  static const String facilitySearch = '/coach/search';
  static const String facilityDetail = '/coach/facility';
  static const String booking = '/coach/booking';
  static const String coachBookings = '/coach/bookings';

  // Facility Owner Routes
  static const String facilityHome = '/facility/home';
  static const String myFacilities = '/facility/my-facilities';
  static const String createFacility = '/facility/create';
  static const String editFacility = '/facility/edit';
  static const String facilityManagement = '/facility/manage';
  static const String availability = '/facility/availability';
  static const String facilityBookings = '/facility/bookings';

  // Shared Routes
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String conversations = '/messages';
  static const String chat = '/messages/chat';
  static const String reviews = '/reviews';
  static const String writeReview = '/reviews/write';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String bookingDetail = '/booking-detail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
    // Auth Routes
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case register:
        return _buildRoute(const RegisterScreen(), settings);
      case forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);
      case userTypeSelection:
        return _buildRoute(const UserTypeSelectionScreen(), settings);

    // Coach Routes
      case coachHome:
        return _buildRoute(const CoachHomeScreen(), settings);
      case facilitySearch:
        return _buildRoute(const FacilitySearchScreen(), settings);
      case facilityDetail:
        final facilityId = settings.arguments as String;
        return _buildRoute(FacilityDetailScreen(facilityId: facilityId), settings);
      case booking:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          BookingScreen(
            facilityId: args['facilityId'],
            spaceId: args['spaceId'],
          ),
          settings,
        );
      case coachBookings:
        return _buildRoute(const CoachBookingsScreen(), settings);

    // Facility Owner Routes
      case facilityHome:
        return _buildRoute(const FacilityOwnerHomeScreen(), settings);
      case myFacilities:
        return _buildRoute(const MyFacilitiesScreen(), settings);
      case createFacility:
        return _buildRoute(const CreateFacilityScreen(), settings);
      case editFacility:
        final facilityId = settings.arguments as String;
        return _buildRoute(EditFacilityScreen(facilityId: facilityId), settings);
      case availability:
        final facilityId = settings.arguments as String;
        return _buildRoute(AvailabilityManagementScreen(facilityId: facilityId), settings);
      case facilityBookings:
        return _buildRoute(const facility_bookings.FacilityBookingsScreen(), settings);

    // Shared Routes
      case profile:
        return _buildRoute(const ProfileScreen(), settings);
      case editProfile:
        return _buildRoute(const EditProfileScreen(), settings);
      case conversations:
        return _buildRoute(const ConversationsScreen(), settings);
      case chat:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          ChatScreen(
            conversationId: args['conversationId'],
            otherUserName: args['otherUserName'] ?? 'Contact',
          ),
          settings,
        );
      case reviews:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ReviewsScreen(
            userId: args?['userId'] ?? '',
            userType: args?['userType'] ?? 'coach',
          ),
          settings,
        );
      case writeReview:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          CreateReviewScreen(
            bookingId: args['bookingId'],
            revieweeId: args['revieweeId'],
            reviewType: args['reviewType'],
          ),
          settings,
        );
      case bookingDetail:
        final bookingId = settings.arguments as String;
        return _buildRoute(BookingDetailScreen(bookingId: bookingId), settings);
      case notifications:
        return _buildRoute(const NotificationsScreen(), settings);
      case AppRouter.settings:
        return _buildRoute(const SettingsScreen(), settings);

      default:
        return _buildRoute(
          Scaffold(
            appBar: AppBar(title: const Text('Page non trouvée')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Route non trouvée',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    settings.name ?? 'Unknown',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute _buildRoute(Widget child, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => child,
      settings: settings,
    );
  }
}
