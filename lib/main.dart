import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/responsive_wrapper.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';
import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const QueerVerseApp());
}

class QueerVerseApp extends StatelessWidget {
  const QueerVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QueerVerse',

      theme: AppTheme.darkTheme,

      home: const ResponsiveWrapper(child: AuthWrapper()),
    );
  }
}
