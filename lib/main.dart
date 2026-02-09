import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/app_auth_provider.dart';
import 'core/providers/app_user_provider.dart';
import 'core/providers/app_facility_provider.dart';
import 'core/providers/app_booking_provider.dart';
import 'core/providers/app_message_provider.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';

// Firebase (décommenter quand prêt)
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Initialiser les locales pour les dates en français
  await initializeDateFormatting('fr_FR', null);

  // Load environment variables
  // await dotenv.load(fileName: ".env");

  // Initialize Firebase
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const UnCoachUneSalleApp());
}

class UnCoachUneSalleApp extends StatelessWidget {
  const UnCoachUneSalleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProxyProvider<AppAuthProvider, AppUserProvider>(
          create: (_) => AppUserProvider(),
          update: (_, auth, userProvider) => userProvider!..updateAuth(auth),
        ),
        ChangeNotifierProvider(create: (_) => AppFacilityProvider()),
        ChangeNotifierProvider(create: (_) => AppBookingProvider()),
        ChangeNotifierProvider(create: (_) => AppMessageProvider()),
      ],
      child: Consumer<AppAuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'UnCoachUneSalle',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: AppRouter.splash,
          );
        },
      ),
    );
  }
}
