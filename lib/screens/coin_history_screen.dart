import 'package:flutter/material.dart';
import '../services/coin_history_service.dart';
import '../utils/colors.dart';

class CoinHistoryScreen extends StatefulWidget {
  const CoinHistoryScreen({super.key});

  @override
  State<CoinHistoryScreen> createState() => _CoinHistoryScreenState();
}

class _CoinHistoryScreenState extends State<CoinHistoryScreen> {
  bool _loading = true;
  List<int> _coinsByLevel = const [];
  int _visible = 10;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await CoinHistoryService.getAllLevelCoins();
    if (!mounted) return;
    setState(() {
      _coinsByLevel = data;
      _loading = false;
      _visible = (_coinsByLevel.length < 10) ? _coinsByLevel.length : 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalCoins = _coinsByLevel.fold<int>(0, (sum, e) => sum + e);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/historyBg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Coin History',
                        style: TextStyle(
                          fontFamily: 'FredokaOne',
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F12).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Row(children: [
                        const Text('🪙', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          '$totalCoins',
                          style: const TextStyle(
                            fontFamily: 'FredokaOne',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Wealth big number
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xff3f4920).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENT WEALTH',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 2,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(
                            '$totalCoins',
                            style: const TextStyle(
                              fontFamily: 'FredokaOne',
                              fontSize: 36,
                              color: JColors.yellow,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'COINS',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Recent earnings list
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ..._buildRecentTiles(totalCoins),
                          const SizedBox(height: 10),
                          if (_visible < _coinsByLevel.length)
                            Center(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _visible = (_visible + 10).clamp(0, _coinsByLevel.length);
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color: Colors.greenAccent.withOpacity(0.6)),
                                  ),
                                  child: const Text(
                                    'Load More History',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRecentTiles(int totalCoins) {
    final indices = List<int>.generate(_coinsByLevel.length, (i) => i);
    final tiles = <Widget>[];
    int count = 0;
    for (final i in indices) {
      if (count >= _visible) break;
      final level = i + 1;
      final coins = _coinsByLevel[i];
      final isEarned = coins > 0;
      tiles.add(Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xff3f4920).withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isEarned ? Colors.green.withOpacity(0.25) : Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(isEarned ? '⭐' : '🔒', style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEarned ? 'Level ${level.toString().padLeft(2, '0')}' : 'Level ${level.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    isEarned ? 'Completed • Recent' : 'Incomplete • Locked',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isEarned ? Colors.yellow.withOpacity(0.2) : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isEarned ? Colors.yellow.withOpacity(0.5) : Colors.white.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '${coins.abs()}',
                    style: TextStyle(
                      fontFamily: 'FredokaOne',
                      fontSize: 14,
                      color: isEarned ? JColors.yellow : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
      count++;
    }
    return tiles;
  }
}
