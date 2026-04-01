import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const JungleJumpersApp());
}

class JungleJumpersApp extends StatelessWidget {
  const JungleJumpersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jungle Jumpers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Nunito',
        scaffoldBackgroundColor: const Color(0xFF1A2A10),
      ),
      home: const SplashScreen(),
    );
  }
}
