import 'package:flutter/material.dart';
import '../utils/colors.dart';
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
  late AnimationController _twinkleController;

  late Animation<double> _bounceAnim;
  late Animation<double> _loaderAnim;
  // Removed star twinkle in new design

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1),
    );

    _bounceAnim = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _loaderAnim = Tween<double>(begin: 0.2, end: 0.85).animate(
      CurvedAnimation(parent: _loaderController, curve: Curves.easeInOut),
    );

    // Twinkle removed

    // Navigate after 3 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _loaderController.dispose();
    _twinkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splashBg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Stars (hidden for new design)
            // _buildStars(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Bouncing monkey image
                  AnimatedBuilder(
                    animation: _bounceAnim,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _bounceAnim.value),
                      child: Image.asset(
                        'assets/images/splashMonkey.png',
                        width: 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logo
                  const Text(
                    'JUNGLE\nHOP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'FredokaOne',
                      fontSize: 48,
                      color: JColors.yellow,
                      height: 0.95,
                      shadows: [
                        Shadow(
                          color: Color(0x99000000),
                          offset: Offset(0, 3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(height: 10),
                  const SizedBox(height: 32),

                  // Loading bar
                  Column(
                    children: [
                      Container(
                        width: 280,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: AnimatedBuilder(
                          animation: _loaderAnim,
                          builder: (_, __) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _loaderAnim.value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [JColors.yellow, JColors.lightGreen],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: const Text(
                          'FETCHING JUNGLE GEMS',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom trees
            // Removed for new design
          ],
        ),
      ),
    );
  }

  // Stars removed in new splash design
}
