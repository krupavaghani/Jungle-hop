import 'package:flutter/material.dart';
import '../utils/colors.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const List<Map<String, dynamic>> _entries = [
    {'rank': 1, 'name': 'JungleKing', 'score': 4820, 'emoji': '🐒'},
    {'rank': 2, 'name': 'TigerLeap', 'score': 3650, 'emoji': '🐯'},
    {'rank': 3, 'name': 'PandaRun', 'score': 2990, 'emoji': '🐼'},
    {'rank': 4, 'name': 'You', 'score': 980, 'emoji': '🐒', 'isMe': true},
    {'rank': 5, 'name': 'FoxJump', 'score': 870, 'emoji': '🦊'},
    {'rank': 6, 'name': 'MonkeyG', 'score': 740, 'emoji': '🐒'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: JColors.homeGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '🏆  Leaderboard',
                      style: TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 24,
                        color: JColors.yellow,
                      ),
                    ),
                  ],
                ),
              ),

              // Top 3 podium
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _PodiumItem(entry: _entries[1], height: 80),
                    const SizedBox(width: 12),
                    _PodiumItem(entry: _entries[0], height: 100),
                    const SizedBox(width: 12),
                    _PodiumItem(entry: _entries[2], height: 60),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _LeaderboardRow(entry: _entries[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final Map<String, dynamic> entry;
  final double height;

  const _PodiumItem({required this.entry, required this.height});

  @override
  Widget build(BuildContext context) {
    final isFirst = entry['rank'] == 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(entry['emoji'] as String,
            style: TextStyle(fontSize: isFirst ? 32 : 26)),
        const SizedBox(height: 4),
        Text(
          entry['name'] as String,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: isFirst ? 13 : 11,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: isFirst ? 90 : 70,
          height: height,
          decoration: BoxDecoration(
            color: isFirst
                ? JColors.yellow.withOpacity(0.25)
                : Colors.white.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(
              color: isFirst
                  ? JColors.yellow.withOpacity(0.5)
                  : Colors.white.withOpacity(0.15),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                ['🥇', '🥈', '🥉'][(entry['rank'] as int) - 1],
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                '${entry['score']}',
                style: TextStyle(
                  fontFamily: 'FredokaOne',
                  fontSize: isFirst ? 14 : 12,
                  color: JColors.yellow,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isMe = entry['isMe'] == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? JColors.yellow.withOpacity(0.1)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? JColors.yellow.withOpacity(0.3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${entry['rank']}',
              style: TextStyle(
                fontFamily: 'FredokaOne',
                fontSize: 16,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(entry['emoji'] as String,
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry['name'] as String,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isMe ? JColors.yellow : Colors.white,
              ),
            ),
          ),
          Text(
            '${entry['score']}',
            style: const TextStyle(
              fontFamily: 'FredokaOne',
              fontSize: 18,
              color: JColors.yellow,
            ),
          ),
        ],
      ),
    );
  }
}
