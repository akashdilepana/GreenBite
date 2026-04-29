import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🌿 Figma Style Theme
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF6FFF2),

        primaryColor: const Color(0xFF2E7D32),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6FFF2),
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      home: const LoginPage(),
    );
  }
}