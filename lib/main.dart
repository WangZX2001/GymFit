import 'package:flutter/material.dart';
import 'package:gymfit/pages/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize theme service
  final themeService = ThemeService();
  await themeService.initializeTheme();

  runApp(MyApp(themeService: themeService));
}

class MyApp extends StatelessWidget {
  final ThemeService themeService;
  
  const MyApp({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => themeService,
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'GymFit',
            theme: themeService.currentTheme.copyWith(
              textTheme: themeService.currentTheme.textTheme.copyWith(
                headlineMedium: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: themeService.isDarkMode ? Colors.white : Colors.black,
                ),
                bodyMedium: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: themeService.isDarkMode ? Colors.white : Colors.black87,
                ),
                labelLarge: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            debugShowCheckedModeBanner: false,
            home: AuthPage(),
          );
        },
      ),
    );
  }
}
