import 'package:flutter/material.dart';
import '../services/app_update_service.dart';
import 'force_update_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _loaderController;

  late Animation<double> _bounceAnim;
  late Animation<double> _loaderAnim;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0, end: -14).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _loaderAnim = Tween<double>(begin: 0.12, end: 0.78).animate(
      CurvedAnimation(parent: _loaderController, curve: Curves.easeInOut),
    );

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final results = await Future.wait([
      Future<void>.delayed(const Duration(seconds: 3)),
      AppUpdateService.checkForUpdate(),
    ]);

    if (!mounted) return;

    final updateResult = results[1] as AppUpdateCheckResult;
    final nextScreen = updateResult.requiresUpdate
        ? ForceUpdateScreen(
            message: updateResult.message,
            storeUrl: updateResult.storeUrl,
            currentVersion: updateResult.currentVersion,
            minVersion: updateResult.minVersion,
          )
        : const HomeScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final monkeySize = size.width * 0.75;
    final logoWidth = size.width * 0.75;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash-bg.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: size.height * 0.06),
                AnimatedBuilder(
                  animation: _bounceAnim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _bounceAnim.value),
                    child: Image.asset(
                      'assets/images/splashMonkey.png',
                      width: monkeySize,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                Image.asset(
                  'assets/images/logo.png',
                  width: logoWidth,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: size.height * 0.028),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
                  child: AnimatedBuilder(
                    animation: _loaderAnim,
                    builder: (_, __) => _JungleProgressBar(
                      progress: _loaderAnim.value,
                      width: size.width * 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(bottom: size.height * 0.04),
                  child: const _LoadingBanner(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JungleProgressBar extends StatelessWidget {
  const _JungleProgressBar({
    required this.progress,
    required this.width,
  });

  final double progress;
  final double width;

  static const _trackBrown = Color(0xFF2E1A0C);
  static const _frameBrown = Color(0xFF4A3219);
  static const _vineGreen = Color(0xFF3D6B1A);

  @override
  Widget build(BuildContext context) {
    const barHeight = 20.0;

    return Container(
      width: width,
      height: barHeight + 8,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6B4A2A), _frameBrown, Color(0xFF2A1808)],
        ),
        border: Border.all(color: _vineGreen.withValues(alpha: 0.65), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _trackBrown,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFF1A0F06), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fillWidth = constraints.maxWidth * progress.clamp(0.0, 1.0);
              return Stack(
                children: [
                  if (fillWidth > 0)
                    SizedBox(
                      width: fillWidth,
                      height: constraints.maxHeight,
                      child: CustomPaint(
                        painter: const _ProgressStripesPainter(),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFE566),
                                Color(0xFFFFB82B),
                                Color(0xFFE87800),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProgressStripesPainter extends CustomPainter {
  const _ProgressStripesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 2;

    const spacing = 10.0;
    for (var x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * 0.55, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoadingBanner extends StatelessWidget {
  const _LoadingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7A5430), Color(0xFF4A3219), Color(0xFF3A2614)],
        ),
        border: Border.all(color: Color(0xFF2A1808), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Text(
        'FETCHING JUNGLE GEMS...',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 1.2,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Color(0x99000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
