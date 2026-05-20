import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import 'level_select_screen.dart';
import 'coin_history_screen.dart';
import 'shop_screen.dart';
import 'settings_screen.dart';
import '../services/coin_history_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const String _usingCharacterKey = 'shop_using_character';
  static const Map<String, String> _characterEmojiMap = {
    'Monkey': '🐒',
    'Panda': '🐼',
    'Koala': '🐨',
    'Frog': '🐸',
    'Fox': '🦊',
    'Tiger': '🐯',
    'Rabbit': '🐰',
    'Deer': '🦌',
    'Zebra': '🦓',
    'Bear': '🐻',
    'Lion': '🦁',
    'Wolf': '🐺',
    'Gorilla': '🦍',
    'Elephant': '🐘',
  };

  late AnimationController _bounceController;
  // Animation kept for potential subtle micro-motions; currently unused.
  // late Animation<double> _bounceAnim;
  // bool _musicOn = true;
  String _selectedEmoji = '🐒';
  int _availableCoins = 0;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    // _bounceAnim = Tween<double>(begin: 0, end: -8).animate(
    //   CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    // );
    _loadSelectedCharacter();
    _loadCoins();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh selected character when returning from shop.
    _loadSelectedCharacter();
    _loadCoins();
  }

  Future<void> _loadSelectedCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    final usingName = prefs.getString(_usingCharacterKey) ?? 'Monkey';
    final emoji = _characterEmojiMap[usingName] ?? '🐒';
    if (!mounted) return;
    if (_selectedEmoji != emoji) {
      setState(() => _selectedEmoji = emoji);
    }
  }

  Future<void> _loadCoins() async {
    final coins = await CoinHistoryService.getAvailableCoins();
    if (!mounted) return;
    setState(() => _availableCoins = coins);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  /// Responsive scale from shortest side (reference ~phone width 375).
  static double _responsiveScale(double shortestSide) =>
      (shortestSide / 375).clamp(0.72, 1.25);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgroundImg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final mq = MediaQuery.sizeOf(context);
              final shortest = mq.shortestSide;
              final scale = _responsiveScale(shortest);
              // Short viewports (landscape / small phones): tighten vertical gaps.
              final maxH = constraints.maxHeight;
              final vCompress =
                  maxH < 520 ? (maxH / 520).clamp(0.5, 1.0) : 1.0;
              final horizontalPad = (20 * scale).clamp(12.0, 28.0);
              final avatar = (44 * scale).clamp(36.0, 56.0);
              final headerTitle = (24 * scale).clamp(18.0, 30.0);
              final settingsBtn = (40 * scale).clamp(36.0, 48.0);
              final jungleTitle = (44 * scale).clamp(26.0, 52.0);
              final seasonFont = (12 * scale).clamp(10.0, 14.0);
              final seasonDot = (16 * scale).clamp(12.0, 18.0);
              final playFont = (24 * scale).clamp(16.0, 28.0);
              final playVPad = (15 * scale).clamp(10.0, 18.0);
              final footerFont = (11 * scale).clamp(9.0, 12.0);
              final gapSm = ((8 * scale).clamp(4.0, 12.0)) * vCompress;
              final gapMd = ((16 * scale).clamp(8.0, 22.0)) * vCompress;
              final gapLg = ((24 * scale).clamp(12.0, 28.0)) * vCompress;
              final playWidth = min(360.0, constraints.maxWidth);

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                        height: ((12 * scale).clamp(6.0, 16.0)) * vCompress),
                    Row(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/profileImg.png',
                            width: avatar,
                            height: avatar,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: (12 * scale).clamp(8.0, 16.0)),
                        Expanded(
                          child: Text(
                            'Jungle Hop',
                            style: TextStyle(
                              fontFamily: 'FredokaOne',
                              fontSize: headerTitle,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 6,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                          child: Container(
                            width: settingsBtn,
                            height: settingsBtn,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: (22 * scale).clamp(18.0, 26.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: (18 * scale).clamp(10.0, 22.0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _Badge(
                          icon: '🪙',
                          label: _availableCoins.toString(),
                          scale: scale,
                          onTapPlus: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ShopScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: (4 * scale).clamp(0.0, 12.0),
                              ),
                              child: Image.asset(
                                'assets/images/monkey.png',
                                fit: BoxFit.contain,
                                width: double.infinity,
                                semanticLabel: _selectedEmoji,
                              ),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'JUNGLE\nHOP',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'FredokaOne',
                                height: 0.95,
                                fontSize: jungleTitle,
                                color: JColors.yellow,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x66000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: gapSm),
                          Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: (14 * scale).clamp(10.0, 18.0),
                                vertical: (6 * scale).clamp(4.0, 10.0),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      color: JColors.yellow,
                                      fontSize: seasonDot,
                                    ),
                                  ),
                                  SizedBox(width: (8 * scale).clamp(4.0, 12.0)),
                                  Text(
                                    'SEASON 1: MOSSY MAYHEM',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      fontSize: seasonFont,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: gapLg),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LevelSelectScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: playWidth,
                          padding: EdgeInsets.symmetric(vertical: playVPad),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                JColors.yellow,
                                JColors.yellowDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: JColors.yellow.withOpacity(0.35),
                                blurRadius: (24 * scale).clamp(16.0, 32.0),
                                offset: Offset(0, (10 * scale).clamp(6.0, 14.0)),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '▶  PLAY',
                              style: TextStyle(
                                fontFamily: 'FredokaOne',
                                fontSize: playFont,
                                color: const Color(0xFF1A2A10),
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: gapMd),
                    Row(
                      children: [
                        Expanded(
                          child: _LargeSoftButton(
                            icon: '🎁',
                            label: 'SHOP',
                            scale: scale,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ShopScreen(),
                              ),
                            ).then((_) => _loadCoins()),
                          ),
                        ),
                        SizedBox(width: (16 * scale).clamp(10.0, 22.0)),
                        Expanded(
                          child: _LargeSoftButton(
                            icon: '🗂️',
                            label: 'HISTORY',
                            scale: scale,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CoinHistoryScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                        height: ((10 * scale).clamp(6.0, 14.0)) * vCompress),
                    Center(
                      child: Text(
                        'VERSION 1.0 • JUNGLE HOP STUDIO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: footerFont,
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: (2 * scale).clamp(1.0, 2.5),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String icon;
  final String label;
  final double scale;
  final VoidCallback? onTapPlus;
  const _Badge({
    required this.icon,
    required this.label,
    required this.scale,
    this.onTapPlus,
  });

  @override
  Widget build(BuildContext context) {
    final padH = (10 * scale).clamp(8.0, 14.0);
    final padV = (6 * scale).clamp(4.0, 10.0);
    final font = (14 * scale).clamp(11.0, 16.0);
    final plus = (20 * scale).clamp(18.0, 24.0);
    final iconPlus = (14 * scale).clamp(12.0, 16.0);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: font)),
          SizedBox(width: (6 * scale).clamp(4.0, 8.0)),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'FredokaOne',
              fontSize: font,
              color: Colors.white,
            ),
          ),
          if (onTapPlus != null) ...[
            SizedBox(width: (8 * scale).clamp(6.0, 12.0)),
            GestureDetector(
              onTap: onTapPlus,
              child: Container(
                width: plus,
                height: plus,
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  size: iconPlus,
                  color: const Color(0xFF1A2A10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LargeSoftButton extends StatelessWidget {
  final String icon;
  final String label;
  final double scale;
  final VoidCallback onTap;
  const _LargeSoftButton({
    required this.icon,
    required this.label,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vPad = (16 * scale).clamp(10.0, 20.0);
    final emoji = (18 * scale).clamp(14.0, 22.0);
    final labelSize = (16 * scale).clamp(12.0, 18.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: vPad),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6FD680), Color(0xFF1F8D4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: (12 * scale).clamp(8.0, 16.0),
              offset: Offset(0, (6 * scale).clamp(4.0, 8.0)),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: emoji)),
            SizedBox(width: (8 * scale).clamp(4.0, 10.0)),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'FredokaOne',
                fontSize: labelSize,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
