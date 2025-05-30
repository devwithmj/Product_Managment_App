import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/database_backup_service.dart'; // Import for navigator key
import 'screens/home_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      navigatorKey: navigatorKey, // Add navigator key for dialogs
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('fa'), // Persian
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: AppFonts.englishFont,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: const CardThemeData(color: AppColors.cardBackground),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
              fontFamily: AppFonts.englishFont,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Default text theme using correct font families
        textTheme: TextTheme(
          headlineLarge: const TextStyle(fontFamily: AppFonts.englishFont),
          headlineMedium: const TextStyle(fontFamily: AppFonts.englishFont),
          headlineSmall: const TextStyle(fontFamily: AppFonts.englishFont),
          titleLarge: const TextStyle(fontFamily: AppFonts.englishFont),
          titleMedium: const TextStyle(fontFamily: AppFonts.englishFont),
          titleSmall: const TextStyle(fontFamily: AppFonts.englishFont),
          bodyLarge: const TextStyle(fontFamily: AppFonts.englishFont),
          bodyMedium: const TextStyle(fontFamily: AppFonts.englishFont),
          bodySmall: const TextStyle(fontFamily: AppFonts.englishFont),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
