import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../widgets/jungle_tree.dart';
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

  @override
  Widget build(BuildContext context) {
    // final paddingTop = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgroundImg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.35,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [JungleTree(), JungleTree(small: true), JungleTree()],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Header: Avatar + Title + Settings
                    Row(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/profileImg.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Jungle Hop',
                            style: TextStyle(
                              fontFamily: 'FredokaOne',
                              fontSize: 24,
                              color: Colors.white,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0,1))],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.25)),
                            ),
                            child: const Icon(Icons.settings, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _Badge(
                          icon: '🪙',
                          label: _availableCoins.toString(),
                          onTapPlus: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ShopScreen()),
                          ),
                        ),
                        
                      ],
                    ),

                    // Character tile with currency/energy badges
                  
                    Image.asset(
                              'assets/images/monkey.png',
                              fit: BoxFit.cover,
                              // keep selected emoji in semantics to avoid lints and for accessibility
                              semanticLabel: _selectedEmoji,
                            ),

                    // const SizedBox(height: 20),
                    // Title and season pill
                    const Center(
                      child: Text(
                        'JUNGLE\nHOP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'FredokaOne',
                          height: 0.95,
                          fontSize: 44,
                          color: JColors.yellow,
                          shadows: [Shadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0,3))],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('•', style: TextStyle(color: JColors.yellow, fontSize: 16)),
                            SizedBox(width: 8),
                            Text('SEASON 1: MOSSY MAYHEM',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontSize: 12,
                                )),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Play button
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
                          );
                        },
                        child: Container(
                          width: 360,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [JColors.yellow, JColors.yellowDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: JColors.yellow.withOpacity(0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '▶  PLAY',
                              style: TextStyle(
                                fontFamily: 'FredokaOne',
                                fontSize: 24,
                                color: Color(0xFF1A2A10),
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Shop + History buttons
                    Row(
                      children: [
                        Expanded(
                          child: _LargeSoftButton(
                            icon: '🎁',
                            label: 'SHOP',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ShopScreen()),
                            ).then((_) => _loadCoins()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _LargeSoftButton(
                            icon: '🗂️',
                            label: 'HISTORY',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CoinHistoryScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),
                    // Footer version
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'VERSION 1.0 • JUNGLE JUMPERS STUDIO',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 2,
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
}


class _Badge extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onTapPlus;
  const _Badge({required this.icon, required this.label, this.onTapPlus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'FredokaOne',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          if (onTapPlus != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onTapPlus,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 14, color: Color(0xFF1A2A10)),
              ),
            )
          ]
        ],
      ),
    );
  }
}

class _LargeSoftButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _LargeSoftButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'FredokaOne',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
