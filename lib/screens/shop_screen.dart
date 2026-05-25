import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jungle_jumpping/utils/ads_key_constant.dart';
import 'package:jungle_jumpping/widgets/top_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/premium_service.dart';
import '../services/coin_history_service.dart';
import 'coin_purchase_screen.dart';

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
  static const int _charactersPerNativeAd = 4;
  int _coins = 0;
  Set<String> _ownedCharacters = {'Monkey'};
  String _usingCharacter = 'Monkey';
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  List<NativeAd?> _nativeAds = [];
  List<bool> _nativeAdsLoaded = [];

  bool get _showAds => PremiumService.instance.canShowAds();

  @override
  void initState() {
    super.initState();
    PremiumService.instance.addListener(_onPremiumChanged);
    _loadCoins();
    _initShopAds();
  }

  @override
  void dispose() {
    PremiumService.instance.removeListener(_onPremiumChanged);
    _bannerAd?.dispose();
    _disposeNativeAds();
    super.dispose();
  }

  void _onPremiumChanged() {
    if (!mounted) return;
    if (!_showAds) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _isBannerLoaded = false;
      _disposeNativeAds();
    } else {
      _loadBannerAd();
      _loadNativeAds();
    }
    setState(() {});
  }

  void _initShopAds() {
    if (_showAds) {
      _loadBannerAd();
      _loadNativeAds();
    }
  }

  int get _nativeAdSlotCount => _characters.length ~/ _charactersPerNativeAd;

  int _crewListItemCount() =>
      _characters.length + (_showAds ? _nativeAdSlotCount : 0);

  bool _isNativeAdListIndex(int listIndex) {
    if (!_showAds || _nativeAdSlotCount == 0) return false;
    return (listIndex + 1) % (_charactersPerNativeAd + 1) == 0 &&
        listIndex >= _charactersPerNativeAd;
  }

  int _nativeAdSlotIndex(int listIndex) =>
      (listIndex + 1) ~/ (_charactersPerNativeAd + 1) - 1;

  int _characterListIndex(int listIndex) {
    if (!_showAds) return listIndex;
    return listIndex - (listIndex + 1) ~/ (_charactersPerNativeAd + 1);
  }

  void _loadNativeAds() {
    if (!_showAds) return;
    _disposeNativeAds();
    final slotCount = _nativeAdSlotCount;
    if (slotCount == 0) return;

    _nativeAds = List<NativeAd?>.filled(slotCount, null);
    _nativeAdsLoaded = List<bool>.filled(slotCount, false);

    for (var slot = 0; slot < slotCount; slot++) {
      final slotIndex = slot;
      final ad = NativeAd(
        adUnitId: AdsKeyConstant.getNativeAdvancedAdUnitId(),
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (!mounted) return;
            setState(() => _nativeAdsLoaded[slotIndex] = true);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (!mounted) return;
            setState(() {
              _nativeAds[slotIndex] = null;
              _nativeAdsLoaded[slotIndex] = false;
            });
          },
        ),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          mainBackgroundColor: const Color(0xFFF4E8C8),
          primaryTextStyle: NativeTemplateTextStyle(
            textColor: const Color(0xFF2F4A16),
            backgroundColor: Colors.transparent,
          ),
          secondaryTextStyle: NativeTemplateTextStyle(
            textColor: const Color(0xFF4A5F2D),
            backgroundColor: Colors.transparent,
          ),
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: const Color(0xFF689F38),
          ),
        ),
      );
      _nativeAds[slotIndex] = ad;
      ad.load();
    }
  }

  void _disposeNativeAds() {
    for (final ad in _nativeAds) {
      ad?.dispose();
    }
    _nativeAds = [];
    _nativeAdsLoaded = [];
  }

  void _loadBannerAd() {
    if (!_showAds) return;
    _bannerAd?.dispose();
    final ad = BannerAd(
      adUnitId: AdsKeyConstant.getBannerAdUnitId(),
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _isBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _isBannerLoaded = false);
        },
      ),
    );
    _bannerAd = ad;
    ad.load();
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

  // -------------- Character List --------------
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
      price: 1500,
      imagePath: 'assets/images/panda.webp',
    ),
    CharacterItem(
      name: 'Koala',
      description: 'Calm tree climber',
      stars: 3,
      price: 2500,
      imagePath: 'assets/images/koala.png',
    ),
    CharacterItem(
      name: 'Frog',
      description: 'Spring jump master',
      stars: 4,
      price: 3500,
      imagePath: 'assets/images/frog.png',
    ),
    CharacterItem(
      name: 'Fox',
      description: 'Agile leaper',
      stars: 4,
      price: 6000,
      imagePath: 'assets/images/fox.webp',
    ),
    CharacterItem(
      name: 'Tiger',
      description: 'Fastest runner',
      stars: 5,
      price: 8000,
      imagePath: 'assets/images/tiger.png',
    ),
    CharacterItem(
      name: 'Rabbit',
      description: 'Ultra quick hops',
      stars: 4,
      price: 12000,
      imagePath: 'assets/images/rabbit.webp',
    ),
    CharacterItem(
      name: 'Deer',
      description: 'Graceful long jump',
      stars: 4,
      price: 18000,
      imagePath: 'assets/images/deer.png',
    ),
    CharacterItem(
      name: 'Zebra',
      description: 'Balanced speed',
      stars: 4,
      price: 24500,
      imagePath: 'assets/images/zebra.png',
    ),
    CharacterItem(
      name: 'Bear',
      description: 'Heavy but strong',
      stars: 4,
      price: 28200,
      imagePath: 'assets/images/bear.png',
    ),
    CharacterItem(
      name: 'Lion',
      description: 'Jungle king power',
      stars: 5,
      price: 36800,
      imagePath: 'assets/images/lion.webp',
    ),
    CharacterItem(
      name: 'Dog',
      description: 'Night runner',
      stars: 5,
      price: 45000,
      imagePath: 'assets/images/dog.webp',
    ),
    CharacterItem(
      name: 'Gorilla',
      description: 'Power smash jump',
      stars: 5,
      price: 51000,
      imagePath: 'assets/images/gorilla.jpg',
    ),
    CharacterItem(
      name: 'Elephant',
      description: 'Tank style runner',
      stars: 5,
      price: 60500,
      imagePath: 'assets/images/elephant.webp',
    ),
  ];

  double _scale(BuildContext context) =>
      (MediaQuery.sizeOf(context).shortestSide / 375).clamp(0.72, 1.25);

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final horizontalPad = (12 * scale).clamp(10.0, 16.0);
    final featuredHeight = (MediaQuery.sizeOf(context).height * 0.17).clamp(
      118.0,
      156.0,
    );

    return Scaffold(
    
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/shopBg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPad),
          child: Column(
            children: [
               TopHeader(label: 'JUNGLE CREW SHOP'),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F12).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                       Image.asset('assets/images/coin.png', height: 25, fit: BoxFit.contain),
                        SizedBox(width: (6 * scale).clamp(4.0, 8.0)),
                        Text(
                          _coins.toString(),
                          style: TextStyle(
                            fontFamily: 'FredokaOne',
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: (8 * scale).clamp(6.0, 12.0)),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CoinStoreScreen(),
                            ),
                          ).then((_) => _loadCoins()),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: (8 * scale).clamp(4.0, 12.0)),
              SizedBox(
                height: featuredHeight,
                child: _buildFeaturedCard(scale),
              ),
              SizedBox(height: (10 * scale).clamp(6.0, 14.0)),
              _buildSectionTitle(scale),
              Expanded(child: _buildCrewList(scale)),
              _showAds && _isBannerLoaded && _bannerAd != null
          ? SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(double scale) {
    final char = _characters.firstWhere(
      (c) => c.name == _usingCharacter,
      orElse: () => _characters.first,
    );
    final nameSize = (18 * scale).clamp(15.0, 22.0);
    final bodySize = (12 * scale).clamp(10.0, 14.0);
    final actionHeight = (30 * scale).clamp(26.0, 34.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = (constraints.maxHeight * 0.62).clamp(72.0, 108.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/selected-characterBoard.png',
              fit: BoxFit.fill,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                (14 * scale).clamp(10.0, 18.0),
                (16 * scale).clamp(12.0, 20.0),
                (14 * scale).clamp(10.0, 18.0),
                (12 * scale).clamp(8.0, 16.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: imageSize,
                    height: imageSize,
                    margin: EdgeInsets.only(left: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4E8C8),
                      borderRadius: BorderRadius.circular(
                        (12 * scale).clamp(10.0, 14.0),
                      ),
                      border: Border.all(
                        color: const Color(0xFF6E8F2A).withOpacity(0.35),width: 1.8
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        (10 * scale).clamp(8.0, 12.0),
                      ),
                      child: Image.asset(char.imagePath, fit: BoxFit.cover),
                    ),
                  ),
                  SizedBox(width: (12 * scale).clamp(8.0, 14.0)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          char.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'FredokaOne',
                            fontSize: nameSize,
                            color: const Color(0xFF2F4A16),
                          ),
                        ),
                        SizedBox(height: (4 * scale).clamp(2.0, 6.0)),
                        Text(
                          char.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            fontSize: bodySize,
                            color: const Color(0xFF4A5F2D),
                          ),
                        ),
                        SizedBox(height: (8 * scale).clamp(4.0, 10.0)),
                        _statusButton(
                          scale: scale,
                          label: 'USING',
                          showCheck: true,
                          height: actionHeight,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(double scale) {
    final labelSize = (13 * scale).clamp(11.0, 15.0);
    return Row(
      children: [
        SizedBox(
          height: (40 * scale).clamp(28.0, 45.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset('assets/images/subTitle.png', fit: BoxFit.contain),
              Positioned(
                top: 14,
                child: Text(
                  'JUNGLE CREW',
                  style: TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: labelSize,
                    color: const Color(0xfffdf1ca),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNativeAdTile(double scale, int slotIndex) {
    final rowGap = (8 * scale).clamp(6.0, 10.0);
    if (slotIndex >= _nativeAds.length ||
        !_nativeAdsLoaded[slotIndex] ||
        _nativeAds[slotIndex] == null) {
      return SizedBox(height: rowGap);
    }

    final adHeight = (280 * scale).clamp(240.0, 320.0);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: rowGap / 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular((12 * scale).clamp(10.0, 14.0)),
        child: SizedBox(
          width: double.infinity,
          height: adHeight,
          child: AdWidget(ad: _nativeAds[slotIndex]!),
        ),
      ),
    );
  }

  Widget _buildCrewList(double scale) {
    final listPad = (10 * scale).clamp(8.0, 14.0);
    final rowGap = (8 * scale).clamp(6.0, 10.0);
    final rowHeight = (78 * scale).clamp(68.0, 88.0);
    return ListView.separated(
      padding: EdgeInsets.all(listPad),
      physics: const BouncingScrollPhysics(),
      itemCount: _crewListItemCount(),
      separatorBuilder: (_, __) => SizedBox(height: rowGap),
      itemBuilder: (_, index) {
        if (_isNativeAdListIndex(index)) {
          return _buildNativeAdTile(scale, _nativeAdSlotIndex(index));
        }

        final item = _characters[_characterListIndex(index)];
        final isOwned = _ownedCharacters.contains(item.name);
        final isUsing = _usingCharacter == item.name;
        final canAfford = _coins >= item.price;

        return GestureDetector(
          onTap: () => _handleCharacterTap(item),
          child: SizedBox(
            height: rowHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/shop-board.png', fit: BoxFit.fill),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    (10 * scale).clamp(8.0, 12.0),
                    (8 * scale).clamp(6.0, 10.0),
                    (8 * scale).clamp(6.0, 10.0),
                    (8 * scale).clamp(6.0, 10.0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: (52 * scale).clamp(44.0, 58.0),
                        height: (52 * scale).clamp(44.0, 58.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4E8C8),
                          borderRadius: BorderRadius.circular(
                            (10 * scale).clamp(8.0, 12.0),
                          ),
                          border: Border.all(
                            color: const Color(0xFF6E8F2A).withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            (8 * scale).clamp(6.0, 10.0),
                          ),
                          child: Image.asset(item.imagePath, fit: BoxFit.cover),
                        ),
                      ),
                      SizedBox(width: (10 * scale).clamp(8.0, 12.0)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'FredokaOne',
                                fontSize: (15 * scale).clamp(13.0, 17.0),
                                color: const Color(0xFF2F4A16),
                              ),
                            ),
                            SizedBox(height: (2 * scale).clamp(1.0, 4.0)),
                            Text(
                              item.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700,
                                fontSize: (11 * scale).clamp(10.0, 13.0),
                                color: const Color(0xFF4A5F2D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: (8 * scale).clamp(6.0, 10.0)),
                      if (isUsing)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _statusButton(
                            scale: scale,
                            label: 'USING',
                            showCheck: true,
                            height: (28 * scale).clamp(24.0, 32.0),
                          ),
                        )
                      else if (isOwned)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _statusButton(
                            scale: scale,
                            label: 'USE',
                            showCheck: false,
                            height: (28 * scale).clamp(24.0, 32.0),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buyButton(
                            scale: scale,
                            price: item.price,
                            enabled: canAfford,
                            height: (28 * scale).clamp(24.0, 32.0),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusButton({
    required double scale,
    required String label,
    required bool showCheck,
    required double height,
  }) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: (12 * scale).clamp(10.0, 16.0)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8BC34A), Color(0xFF689F38)],
        ),
        borderRadius: BorderRadius.circular((16 * scale).clamp(12.0, 18.0)),
        border: Border.all(color: const Color(0xFF4E6B1F), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCheck) ...[
            Icon(
              Icons.check_rounded,
              size: (15 * scale).clamp(12.0, 16.0),
              color: Colors.white,
            ),
            SizedBox(width: (4 * scale).clamp(2.0, 6.0)),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'FredokaOne',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buyButton({
    required double scale,
    required int price,
    required bool enabled,
    required double height,
  }) {
    final textColor = enabled ? Colors.white : Colors.white.withOpacity(0.72);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xff6a8a22),
        borderRadius: BorderRadius.circular((16 * scale).clamp(12.0, 18.0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🪙', style: TextStyle(fontSize: 14)),
            SizedBox(width: (4 * scale).clamp(2.0, 6.0)),
            Text(
              '$price',
              style: TextStyle(
                fontFamily: 'FredokaOne',
                fontSize: 14,
                color: textColor,
              ),
            ),
            SizedBox(width: (4 * scale).clamp(2.0, 6.0)),
            Container(
              color: Color(0xFFf8bb07),
              padding: EdgeInsets.symmetric(
                horizontal: (5 * scale).clamp(8.0, 12.0),
              ),
              alignment: Alignment.center,
              child: Text(
                'BUY',
                style: TextStyle(
                  fontFamily: 'FredokaOne',
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------- Handle Character Tap --------------
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
    // await LeaderboardService.syncCurrentScore();
  }

  // -------------- Purchase Confirm Dialog --------------
  Future<bool> _showPurchaseConfirmDialog(CharacterItem item) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.58),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
          decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage('assets/images/popUp-bg.png'), fit: BoxFit.fill),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(item.imagePath, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'UNLOCK\n${item.name.toUpperCase()}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'FredokaOne',
                  fontSize: 22,
                  height: 1.05,
                  color: Color(0xff6a8a22),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  image: DecorationImage(image: AssetImage('assets/images/cost-board.png'), fit: BoxFit.fill),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'COST:',
                      style: TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 18,
                        color: Color(0xff5c3408),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.currency_rupee,
                      color: Color(0xff5c3408),
                      size: 22,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.price}',
                      style: const TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 34,
                        color: Color(0xff5c3408),
                        height: 0.95,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2.8,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6a8a22), Color(0xFF527101)],
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
                            fontSize: 18,
                            color: Colors.white,
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
                        color: const Color(0xfffdf1ca),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Color(0xff5c3408),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            fontFamily: 'FredokaOne',
                            fontSize: 18,
                            letterSpacing: 1.0,
                            color: Color(0xffb96d2b),
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

  // -------------- Info Dialog --------------
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
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/popUp-bg.png'),
              fit: BoxFit.fill,
            ),
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/enoughCoin.png',
                width: 120,
                height: 120,
              ),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'FredokaOne',
                  fontSize: 28,
                  height: 1.0,
                  letterSpacing: 0.2,
                  color: Color(0xff2d3903),
                ),
              ),
              const SizedBox(height: 10),
              _buildHighlightedMessage(message),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Color(0xff6a8a22),
                  ),
                  child: const Center(
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CoinStoreScreen(),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle, color: Color(0xff6a8a22), size: 20),
                    SizedBox(width: 6),
                    Text(
                      'GET MORE COINS',
                      style: TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 14,
                        color: Color(0xff6a8a22),
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
    final matches = RegExp(
      r'(\d+|coins?)',
      caseSensitive: false,
    ).allMatches(message).toList();
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
              color: Color(0xffb96d2b),
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
              color: Color(0xFF6a8a22),
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
}

