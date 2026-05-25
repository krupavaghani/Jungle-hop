import 'package:flutter/material.dart';

import '../services/coin_history_service.dart';
import '../services/level_progress_service.dart';
import 'coin_purchase_screen.dart';
import 'game_screen.dart';

enum LevelState { completed, unlocked, locked }

class LevelData {
  final int number;
  final LevelState state;
  final int stars;
  const LevelData(this.number, this.state, {this.stars = 0});
}

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  static const int _gridColumns = 4;
  static const double _levelBoardAspectRatio = 1024 / 1536;

  int _unlockedLevel = 1;
  int _availableCoins = 0;
  Map<int, int> _starsByLevel = {};
  bool _loading = true;

  late final ScrollController _scrollController;

  List<LevelData> get _levels {
    return List.generate(LevelProgressService.maxLevel, (index) {
      final level = index + 1;
      if (level < _unlockedLevel) {
        return LevelData(
          level,
          LevelState.completed,
          stars: _starsByLevel[level] ?? 0,
        );
      }
      if (level == _unlockedLevel) {
        return LevelData(level, LevelState.unlocked);
      }
      return LevelData(level, LevelState.locked);
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadScreenData();
  }

  Future<void> _loadScreenData() async {
    final unlocked = await LevelProgressService.getHighestUnlockedLevel();
    final coins = await CoinHistoryService.getAvailableCoins();
    final stars = await LevelProgressService.getAllLevelStars();
    if (!mounted) return;
    setState(() {
      _unlockedLevel = unlocked;
      _availableCoins = coins;
      _starsByLevel = stars;
      _loading = false;
    });
    _scrollToCurrentLevel();
  }

  void _scrollToCurrentLevel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final row = ((_unlockedLevel - 1) ~/ _gridColumns).clamp(0, 999);
      final rowHeight = _estimatedRowHeight(context);
      final target = (row * rowHeight).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  double _estimatedRowHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = (size.shortestSide / 375).clamp(0.72, 1.25);
    final horizontalPad = (6 * scale).clamp(4.0, 10.0);
    final gridGap = (2 * scale).clamp(1.0, 4.0);
    final cellWidth =
        (size.width - (horizontalPad * 2) - (gridGap * (_gridColumns - 1))) /
        _gridColumns;
    return (cellWidth / _levelBoardAspectRatio) + gridGap;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openLevel(int level) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(level: level)),
    ).then((_) => _loadScreenData());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final levels = _levels;
    final scale = (MediaQuery.sizeOf(context).shortestSide / 375).clamp(0.72, 1.25);
    final horizontalPad = (6 * scale).clamp(4.0, 10.0);
    final titleHeight = (MediaQuery.sizeOf(context).height * 0.11).clamp(72.0, 104.0);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/level-bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _TopBar(
                scale: scale,
                coins: _availableCoins,
                onBack: () => Navigator.pop(context),
                onAddCoins: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CoinStoreScreen()),
                ).then((_) => _loadScreenData()),
              ),
              SizedBox(
                height: titleHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                  child: Image.asset(
                    'assets/images/select-level-title.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridColumns,
                    // mainAxisSpacing: gridGap,
                    // crossAxisSpacing: gridGap,
                    childAspectRatio: _levelBoardAspectRatio,
                  ),
                  itemCount: levels.length,
                  itemBuilder: (context, index) {
                    return _LevelTile(
                      level: levels[index],
                      onTap: _openLevel,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final double scale;
  final int coins;
  final VoidCallback onBack;
  final VoidCallback onAddCoins;

  const _TopBar({
    required this.scale,
    required this.coins,
    required this.onBack,
    required this.onAddCoins,
  });

  @override
  Widget build(BuildContext context) {
     final iconSize = (22 * scale).clamp(18.0, 26.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        (12 * scale).clamp(10.0, 16.0),
        (2 * scale).clamp(0.0, 4.0),
        (12 * scale).clamp(10.0, 16.0),
        (2 * scale).clamp(0.0, 4.0),
      ),
      child: Row(
        children: [
           GestureDetector(
            onTap: onBack,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF9A6535),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      color: const Color(0xFF6B3F1A),
                    ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
       
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  static const double _imageAspectRatio = 1024 / 1536;
  static const double _plaqueTop = 0.2;
  static const double _plaqueHeight = 0.2;
  static const double _plaqueLeft = 0.32;
  static const double _plaqueWidth = 0.36;
  static const double _lockTop = 0.42;
  static const double _lockHeight = 0.32;
  static const double _starsTop = 0.6;

  final LevelData level;
  final ValueChanged<int> onTap;

  const _LevelTile({
    required this.level,
    required this.onTap,
  });

  static Rect _imageRect(Size size) {
    final containerAspect = size.width / size.height;
    late final double width;
    late final double height;

    if (containerAspect > _imageAspectRatio) {
      height = size.height;
      width = height * _imageAspectRatio;
    } else {
      width = size.width;
      height = width / _imageAspectRatio;
    }

    final left = (size.width - width) / 2;
    return Rect.fromLTWH(left, 0, width, height);
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = level.state == LevelState.locked;
    final boardAsset = isLocked
        ? 'assets/images/incomplete-level.png'
        : 'assets/images/complete-level.png';

    return GestureDetector(
      onTap: isLocked ? null : () => onTap(level.number),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageRect = _imageRect(
            Size(constraints.maxWidth, constraints.maxHeight),
          );
          final numberSize = 15.0;
          final starSize = 16.0;
          final lockSize = (imageRect.width * 0.28).clamp(24.0, 44.0);

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fromRect(
                rect: imageRect,
                child: Image.asset(
                  boardAsset,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                left: imageRect.left + imageRect.width * _plaqueLeft,
                top: imageRect.top + imageRect.height * _plaqueTop,
                width: imageRect.width * _plaqueWidth,
                height: imageRect.height * _plaqueHeight,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${level.number}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        fontSize: numberSize,
                        height: 1,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Color(0xAA2B1A0D),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (level.state == LevelState.completed)
                Positioned(
                  left: imageRect.left,
                  top: imageRect.top + imageRect.height * _starsTop,
                  width: imageRect.width,
                  child: Center(
                    child: _StarRow(
                      stars: level.stars,
                      size: starSize,
                    ),
                  ),
                ),
              if (isLocked)
                Positioned(
                  left: imageRect.left,
                  top: imageRect.top + imageRect.height * _lockTop,
                  width: imageRect.width,
                  height: imageRect.height * _lockHeight,
                  child: Center(
                    child: _LockIcon(size: lockSize),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LockIcon extends StatelessWidget {
  final double size;

  const _LockIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF4F7FB),
          Color(0xFFB8C2CE),
          Color(0xFF8D98A8),
        ],
      ).createShader(bounds),
      child: Icon(
        Icons.lock_rounded,
        size: size,
        color: Colors.white,
        shadows: const [
          Shadow(
            color: Color(0x99000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int stars;
  final double size;

  const _StarRow({
    required this.stars,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final filled = index < stars;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.05),
          child: Icon(
            Icons.star_rounded,
            size: size,
            color: filled ? const Color(0xFFFFD54F) : const Color(0xFF2A3328),
            shadows: filled
                ? const [
                    Shadow(
                      color: Color(0x66FF8F00),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
