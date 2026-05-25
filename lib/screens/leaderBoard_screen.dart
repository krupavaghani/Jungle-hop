import 'package:flutter/material.dart';
import 'package:jungle_jumpping/widgets/top_header.dart';

import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import '../utils/colors.dart';

class CoinHistoryScreen extends StatefulWidget {
  const CoinHistoryScreen({super.key});

  @override
  State<CoinHistoryScreen> createState() => _CoinHistoryScreenState();
}

class _CoinHistoryScreenState extends State<CoinHistoryScreen> {
  static const List<String> _medalAssets = [
    'assets/images/1Rank.png',
    'assets/images/2Rank.png',
    'assets/images/3Rank.png',
  ];

  String? _currentGuestId;
  List<LeaderboardEntry>? _entries;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final guestId = await LeaderboardService.currentGuestId();
      final entries = await LeaderboardService.fetchTopPlayers();
      if (!mounted) return;
      setState(() {
        _currentGuestId = guestId;
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/historyBg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 10),
              child: TopHeader(label: 'LEADERBOARD'),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/leader-Board.png'),
                        fit: BoxFit.fill,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        final padH = (w * 0.07).clamp(12.0, 28.0);
                        final padBottom = (h * 0.04).clamp(8.0, 24.0);
                        final scale = (w / 390).clamp(0.85, 1.15);

                        if (_loading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xff5c3408),
                            ),
                          );
                        }

                        if (_error != null) {
                          return _LeaderboardMessage(
                            message: 'Could not load leaderboard.\n$_error',
                            onRetry: _loadLeaderboard,
                          );
                        }

                        final entries = _entries ?? [];
                        if (entries.isEmpty) {
                          return const _LeaderboardMessage(
                            message:
                                'No players yet.\nPlay levels to earn coins!',
                          );
                        }

                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            padH,
                            35,
                            padH,
                            padBottom,
                          ),
                          child: ListView.separated(
                            padding: EdgeInsets.only(
                              top: 20,
                              left: 10,
                              right: 10,
                            ),
                            physics: const BouncingScrollPhysics(),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: (h * 0.012).clamp(6.0, 12.0)),
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              final isMe = entry.guestId == _currentGuestId;
                              return _LeaderboardRow(
                                rank: index + 1,
                                entry: entry,
                                isMe: isMe,
                                medalAssets: _medalAssets,
                                scale: scale,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _LeaderboardMessage({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xff4a3010),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontFamily: 'FredokaOne',
                    color: Color(0xff5c3408),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;
  final List<String> medalAssets;
  final double scale;

  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.isMe,
    required this.medalAssets,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final rowH = (52 * scale).clamp(44.0, 58.0);
    final medalH = (56 * scale).clamp(48.0, 64.0);
    final rankSlotW = (52 * scale).clamp(46.0, 60.0);
    final nameSize = (16 * scale).clamp(14.0, 18.0);
    final coinTextSize = (15 * scale).clamp(13.0, 17.0);
    final iconSize = (22 * scale).clamp(20.0, 26.0);

    return Material(
      color: Colors.transparent,
      child: Container(
        height: rowH,
        padding: EdgeInsets.symmetric(
          horizontal: (10 * scale).clamp(8.0, 14.0),
        ),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFFFFF3C4).withValues(alpha: 0.95)
              : const Color(0xFFEFE4D2).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular((14 * scale).clamp(12.0, 18.0)),
          border: Border.all(
            color: isMe ? const Color(0xffc9a033) : const Color(0xFFD4C4A8),
            width: isMe ? 3 : 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: rankSlotW,
              height: medalH,
              child: Center(child: _rankLeading(medalH)),
            ),
            SizedBox(width: (6 * scale).clamp(4.0, 10.0)),
            Expanded(
              child: Text(
                isMe ? '${entry.playerName} (You)' : entry.playerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: nameSize,
                  color: const Color(0xff4a3010),
                ),
              ),
            ),
            _CoinPill(
              coins: entry.score,
              iconSize: iconSize,
              textSize: coinTextSize,
              scale: scale,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rankLeading(double medalH) {
    if (rank >= 1 && rank <= 3) {
      final imageH = (medalH * 1.30).clamp(26.0, 120.0);
      final textSize = (medalH * 0.35).clamp(12.0, 24.0);

      return SizedBox(
        width: medalH,
        height: medalH,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Image.asset(
              medalAssets[rank - 1],
              height: imageH,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'FredokaOne',
                fontSize: textSize,
                height: 1,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: Color(0x66000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final d = (medalH * 0.72).clamp(36.0, 46.0);
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff6b4420), Color(0xff4a2c12)],
        ),
        border: Border.all(color: const Color(0xffa67c3d), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontFamily: 'FredokaOne',
            fontSize: (d * 0.38).clamp(14.0, 20.0),
            height: 1,
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Color(0x66000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  final int coins;
  final double iconSize;
  final double textSize;
  final double scale;

  const _CoinPill({
    required this.coins,
    required this.iconSize,
    required this.textSize,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = _formatCoins(coins);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (10 * scale).clamp(8.0, 14.0),
        vertical: (5 * scale).clamp(4.0, 8.0),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8DCC4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFC9A882)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/reward-Icon.png',
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
          ),
          SizedBox(width: (6 * scale).clamp(4.0, 8.0)),
          Text(
            formatted,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: textSize,
              color: JColors.brightGreen,
              height: 1,
              shadows: const [
                Shadow(
                  color: Color(0x442B1A0D),
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCoins(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    if (n >= 1000) {
      final s = (n / 1000).toStringAsFixed(1);
      return s.endsWith('.0') ? '${n ~/ 1000}k' : '${s}k';
    }
    return '$n';
  }
}
