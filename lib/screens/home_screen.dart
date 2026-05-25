import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'level_select_screen.dart';
import 'leaderBoard_screen.dart';
import 'shop_screen.dart';
import 'coin_purchase_screen.dart';
import 'settings_screen.dart';
import '../services/coin_history_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _availableCoins = 0;

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    final coins = await CoinHistoryService.getAvailableCoins();
    if (!mounted) return;
    setState(() => _availableCoins = coins);
  }

  static double _responsiveScale(double shortestSide) =>
      (shortestSide / 375).clamp(0.72, 1.25);

  void _openPlay() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
    ).then((_) => _loadCoins());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/home-bg.png',
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mq = MediaQuery.sizeOf(context);
                final shortest = mq.shortestSide;
                final scale = _responsiveScale(shortest);
                final maxH = constraints.maxHeight;
                final vCompress =
                    maxH < 520 ? (maxH / 520).clamp(0.5, 1.0) : 1.0;
                final horizontalPad = (16 * scale).clamp(10.0, 24.0);
                final settingsSize = (52 * scale).clamp(44.0, 60.0);
                final titleHeight = (55 * scale).clamp(40.0, 64.0);
                final coinBarHeight = (40 * scale).clamp(34.0, 48.0);
                final logoHeight = (145 * scale).clamp(70.0, 160.0);
                final actionSize = (100 * scale).clamp(80.0, 120.0);
                final gapSm = ((6 * scale).clamp(4.0, 10.0)) * vCompress;
                final gapMd = ((12 * scale).clamp(8.0, 16.0)) * vCompress;
                final playWidth = min(300.0, constraints.maxWidth - horizontalPad * 2);

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: (8 * scale).clamp(4.0, 12.0) * vCompress),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Image.asset(
                              'assets/images/person-name.png',
                              height: titleHeight,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                          SizedBox(width: (8 * scale).clamp(4.0, 12.0)),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            ),
                            child: Image.asset(
                              'assets/images/setting.png',
                              width: settingsSize,
                              height: settingsSize,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: gapSm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _CoinBar(
                          coins: _availableCoins,
                          height: coinBarHeight,
                          scale: scale,
                          onTapPlus: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CoinStoreScreen(),
                            ),
                          ).then((_) => _loadCoins()),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: (4 * scale).clamp(0.0, 8.0),
                                ),
                                child: Image.asset(
                                  'assets/images/monkey.png',
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            Image.asset(
                              'assets/images/logo.png',
                              height: logoHeight,
                              fit: BoxFit.cover,
                            ),
                            SizedBox(height: gapSm),
                          ],
                        ),
                      ),
                      SizedBox(height: gapSm),
                      Center(
                        child: GestureDetector(
                          onTap: _openPlay,
                          child: Image.asset(
                            'assets/images/play-button.png',
                            width: playWidth,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: gapMd),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _HomeMenuButton(
                            asset: 'assets/images/leaderboard-logo.png',
                            size: actionSize,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CoinHistoryScreen(),
                              ),
                            ),
                          ),
                          _HomeMenuButton(
                            asset: 'assets/images/characterChange.png',
                            size: actionSize,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ShopScreen(),
                              ),
                            ).then((_) => _loadCoins()),
                          ),
                          _HomeMenuButton(
                            asset: 'assets/images/getCoin.png',
                            size: actionSize,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CoinStoreScreen(),
                              ),
                            ).then((_) => _loadCoins()),
                          ),
                        ],
                      ),
                      SizedBox(height: gapMd),
                    
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinBar extends StatelessWidget {
  final int coins;
  final double height;
  final double scale;
  final VoidCallback onTapPlus;

  const _CoinBar({
    required this.coins,
    required this.height,
    required this.scale,
    required this.onTapPlus,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = (16 * scale).clamp(13.0, 18.0);
    final plusSize = (26 * scale).clamp(22.0, 30.0);
    final coinIcon = (30 * scale).clamp(18.0, 35.0);

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/cost-board.png',
            height: height,
            width: 140,
            fit: BoxFit.fill,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: (14 * scale).clamp(10.0, 18.0)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/coin.png',
                  height: coinIcon,
                  fit: BoxFit.fill,
                ),
                SizedBox(width: (6 * scale).clamp(4.0, 8.0)),
                Text(
                  coins.toString(),
                  style: TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: fontSize,
                    color: const Color(0xFF5C3408),
                    height: 1,
                  ),
                ),
                SizedBox(width: (10 * scale).clamp(6.0, 14.0)),
                GestureDetector(
                  onTap: onTapPlus,
                  child: Container(
                    width: plusSize,
                    height: plusSize,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: (16 * scale).clamp(14.0, 18.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _HomeMenuButton extends StatelessWidget {
  final String asset;
  final double size;
  final VoidCallback onTap;

  const _HomeMenuButton({
    required this.asset,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.fill,
      ),
    );
  }
}
