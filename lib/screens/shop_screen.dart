import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/coin_history_service.dart';

class CharacterItem {
  final String name;
  final String description;
  final int stars;
  final int price;
  final String imagePath;

  const CharacterItem({
    required this.name,
    required this.description,
    required this.stars,
    required this.price,
    required this.imagePath,
  });
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const String _ownedKey = 'shop_owned_characters';
  static const String _usingKey = 'shop_using_character';

  // int _selectedTab = 0;
  int _coins = 0;
  Set<String> _ownedCharacters = {'Monkey'};
  String _usingCharacter = 'Monkey';

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    final available = await CoinHistoryService.getAvailableCoins();
    final prefs = await SharedPreferences.getInstance();
    final owned = prefs.getStringList(_ownedKey);
    final using = prefs.getString(_usingKey);

    if (!mounted) return;
    setState(() {
      _coins = available;
      if (owned != null && owned.isNotEmpty) {
        _ownedCharacters = owned.toSet();
      }
      if (using != null && using.isNotEmpty) {
        _usingCharacter = using;
      }
    });
  }

  Future<void> _saveCharacterState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_ownedKey, _ownedCharacters.toList());
    await prefs.setString(_usingKey, _usingCharacter);
  }

  final List<CharacterItem> _characters = const [
    CharacterItem(
      name: 'Monkey',
      description: 'Default jungle hero',
      stars: 3,
      price: 0,
      imagePath: 'assets/images/monkeyPlayer.png',
    ),
    CharacterItem(
      name: 'Panda',
      description: 'Bamboo jumper',
      stars: 4,
      price: 20,
      imagePath: 'assets/images/panda.webp',
    ),
    CharacterItem(
      name: 'Koala',
      description: 'Calm tree climber',
      stars: 3,
      price: 3500,
      imagePath: 'assets/images/koala.png',
    ),
    CharacterItem(
      name: 'Frog',
      description: 'Spring jump master',
      stars: 4,
      price: 4500,
      imagePath: 'assets/images/frog.png',
    ),
    CharacterItem(
      name: 'Fox',
      description: 'Agile leaper',
      stars: 4,
      price: 8000,
      imagePath: 'assets/images/fox.webp',
    ),
    CharacterItem(
      name: 'Tiger',
      description: 'Fastest runner',
      stars: 5,
      price: 10000,
      imagePath: 'assets/images/tiger.png',
    ),
    CharacterItem(
      name: 'Rabbit',
      description: 'Ultra quick hops',
      stars: 4,
      price: 15000,
      imagePath: 'assets/images/rabbit.webp',
    ),
    CharacterItem(
      name: 'Deer',
      description: 'Graceful long jump',
      stars: 4,
      price: 20000,
      imagePath: 'assets/images/deer.png',
    ),
    CharacterItem(
      name: 'Zebra',
      description: 'Balanced speed',
      stars: 4,
      price: 26000,
      imagePath: 'assets/images/zebra.png',
    ),
    CharacterItem(
      name: 'Bear',
      description: 'Heavy but strong',
      stars: 4,
      price: 30000,
      imagePath: 'assets/images/bear.png',
    ),
    CharacterItem(
      name: 'Lion',
      description: 'Jungle king power',
      stars: 5,
      price: 45000,
      imagePath: 'assets/images/lion.webp',
    ),
    CharacterItem(
      name: 'Dog',
      description: 'Night runner',
      stars: 5,
      price: 48000,
      imagePath: 'assets/images/dog.webp',
    ),
    CharacterItem(
      name: 'Gorilla',
      description: 'Power smash jump',
      stars: 5,
      price: 52000,
      imagePath: 'assets/images/gorilla.jpg',
    ),
    CharacterItem(
      name: 'Elephant',
      description: 'Tank style runner',
      stars: 5,
      price: 60000,
      imagePath: 'assets/images/elephant.webp',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/shopBg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                _buildNewHeader(),
                const SizedBox(height: 10),
                _buildFeaturedCard(),
                const SizedBox(height: 16),
                _buildSectionTitle('JUNGLE CREW', suffix: '${_characters.length} AVAILABLE'),
                const SizedBox(height: 8),
                Expanded(child: _buildCrewList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'JUNGLE CREW SHOP',
            style: TextStyle(
              fontFamily: 'FredokaOne',
              height: 1.1,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12).withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                '${_coins}',
                style: const TextStyle(
                  fontFamily: 'FredokaOne',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard() {
    final using = _usingCharacter;
    final char = _characters.firstWhere(
      (c) => c.name == using,
      orElse: () => _characters.first,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xff3f4920).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              char.imagePath,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  char.name.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  char.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xff49561d).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xff86a801)),
                  ),
                  child: const Text(
                    'USING',
                    style: TextStyle(
                      fontFamily: 'FredokaOne',
                      fontSize: 12,
                      color: Colors.greenAccent,
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

  Widget _buildSectionTitle(String title, {String? suffix}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'FredokaOne',
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        if (suffix != null)
          Text(
            suffix,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildCrewList() {
    return ListView.separated(
      itemCount: _characters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final item = _characters[i];
        final isOwned = _ownedCharacters.contains(item.name);
        final isUsing = _usingCharacter == item.name;
        final canAfford = _coins >= item.price;
        return GestureDetector(
          onTap: () => _handleCharacterTap(item),
          child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(0xff3f4920).withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: Image.asset(item.imagePath, width: 56, height: 56, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isUsing)
                _pill(text: 'USING', bg: Color(0xff86a801).withOpacity(0.6), fg: Colors.greenAccent, price: item.price)
              else if (isOwned)
                _pill(text: 'USE', bg: Color(0xff49561d).withOpacity(0.6), fg: Colors.greenAccent, price: item.price)
              else
                _pill(
                    text: canAfford ? 'BUY' : 'BUY',
                    price: item.price,
                    bg: canAfford ? Colors.yellow : Colors.white.withOpacity(0.2),
                    fg: canAfford ? const Color(0xFF1A2A10) : Colors.white70),
            ],
          ),
        ));
      },
    );
  }

  Widget _pill({required String text, int? price, required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xff86a801)),
      ),
      child: Row(
        children: [
          if (price != null) ...[
            const Text('🪙', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              '$price',
              style: TextStyle(
                fontFamily: 'FredokaOne',
                fontSize: 12,
                color: fg,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'FredokaOne',
              fontSize: 12,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // Legacy helpers removed (new UI in use)

  Future<void> _handleCharacterTap(CharacterItem item) async {
    final isOwned = _ownedCharacters.contains(item.name);
    if (isOwned) {
      setState(() => _usingCharacter = item.name);
      _saveCharacterState();
      return;
    }

    if (_coins < item.price) {
      final need = item.price - _coins;
      _showInfoDialog(
        title: 'Not Enough Coins',
        message: 'You need $need more coins to unlock ${item.name}.',
      );
      return;
    }

    final confirmed = await _showPurchaseConfirmDialog(item);
    if (!confirmed || !mounted) return;

    final spent = await CoinHistoryService.spendCoins(item.price);
    if (!spent || !mounted) {
      _showInfoDialog(
        title: 'Purchase Failed',
        message: 'Coins are not sufficient for this purchase.',
      );
      return;
    }

    setState(() {
      _coins -= item.price;
      _ownedCharacters.add(item.name);
      _usingCharacter = item.name;
    });
    _saveCharacterState();
  }

  Future<bool> _showPurchaseConfirmDialog(CharacterItem item) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.58),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF173B14).withOpacity(0.98),
                const Color(0xFF0B2A1A).withOpacity(0.98),
              ],
            ),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: const Color(0xFF86A801).withOpacity(0.45), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB7E300).withOpacity(0.18),
                blurRadius: 26,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 172,
                height: 172,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 0.9,
                    colors: [Color(0xFF293640), Color(0xFF101920)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.asset(item.imagePath, fit: BoxFit.cover)),
              ),
              const SizedBox(height: 14),
              Text(
                'UNLOCK\n${item.name.toUpperCase()}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'FredokaOne',
                  fontSize: 22,
                  height: 1.05,
                  color: Color(0xFFB7E300),
                  shadows: [
                    Shadow(
                      color: Color(0x88000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF173C3A).withOpacity(0.55),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.09)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'COST:',
                      style: TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFFFFD400),
                      size: 22,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.price}',
                      style: const TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 34,
                        color: Color(0xFFFFD400),
                        height: 0.95,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2.8,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB7E300), Color(0xFF93CC00)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB7E300).withOpacity(0.52),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'CONFIRM',
                          style: TextStyle(
                            fontFamily: 'FredokaOne',
                            fontSize: 16,
                            color: Color(0xFF233300),
                          ),
                        ),
                      ),
                    ),
                  ),
                   GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  width: MediaQuery.of(context).size.width / 2.8,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF163932).withOpacity(0.55),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 16,
                        letterSpacing: 1.0,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ),
                ),
              ),
                ],
              ),
              const SizedBox(height: 15),
             
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _showInfoDialog({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF163A10).withOpacity(0.98),
                const Color(0xFF0C2715).withOpacity(0.98),
              ],
            ),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: const Color(0xFF86A801).withOpacity(0.35), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8BC34A).withOpacity(0.22),
                blurRadius: 28,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFFF176), Color(0xFFFFD700)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFEB3B).withOpacity(0.55),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 46,
                      color: Color(0xFF3A2D00),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: 6,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCDD2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black.withOpacity(0.8), width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.close_rounded, size: 16, color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'FredokaOne',
                  fontSize: 30,
                  height: 1.0,
                  letterSpacing: 0.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              _buildHighlightedMessage(message),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB7E300), Color(0xFF8BC400)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB7E300).withOpacity(0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 20,
                        color: Color(0xFF223300),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle, color: Color(0xFFB7E300), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'GET MORE COINS',
                      style: TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 14,
                        color: Color(0xFFB7E300),
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

  Widget _buildHighlightedMessage(String message) {
    final parts = message.split(RegExp(r'(\d+|coins?)'));
    final matches = RegExp(r'(\d+|coins?)', caseSensitive: false).allMatches(message).toList();
    final spans = <TextSpan>[];

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(
          TextSpan(
            text: parts[i],
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              height: 1.3,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.82),
            ),
          ),
        );
      }
      if (i < matches.length) {
        spans.add(
          TextSpan(
            text: matches[i].group(0),
            style: const TextStyle(
              fontFamily: 'FredokaOne',
              fontSize: 18,
              height: 1.15,
              color: Color(0xFFFFD400),
            ),
          ),
        );
      }
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }

  // Legacy placeholder unused in new UI (removed)
}

// Legacy card unused (removed)

// (Removed legacy action button)
