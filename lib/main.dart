import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/app_open_ad_service.dart';
import 'services/premium_service.dart';
import 'services/coin_purchase_service.dart';
import 'services/remove_ads_purchase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await PremiumService.instance.initialize();
  await RemoveAdsPurchaseService.instance.initialize();
  await CoinPurchaseService.instance.initialize();
  await MobileAds.instance.initialize();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const JungleJumpersApp());
}

class JungleJumpersApp extends StatefulWidget {
  const JungleJumpersApp({super.key});

  @override
  State<JungleJumpersApp> createState() => _JungleJumpersAppState();
}

class _JungleJumpersAppState extends State<JungleJumpersApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppOpenAdService.instance.attach();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (AppOpenAdService.instance.isFullscreenAdShowing) return;

    if (state == AppLifecycleState.paused) {
      print('onAppPaused--------------------------------'); 
      AppOpenAdService.instance.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      print('onAppResumed--------------------------------');
      AppOpenAdService.instance.onAppResumed();
    }
  }

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
