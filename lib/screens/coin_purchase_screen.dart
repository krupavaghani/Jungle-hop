import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jungle_jumpping/widgets/top_header.dart';

import '../services/coin_history_service.dart';
import '../services/coin_purchase_service.dart';
import '../services/premium_service.dart';
import '../services/remove_ads_purchase_service.dart';
import '../utils/colors.dart';

class CoinStoreScreen extends StatefulWidget {
  const CoinStoreScreen({super.key});

  @override
  State<CoinStoreScreen> createState() => _CoinStoreScreenState();
}

class _CoinStoreScreenState extends State<CoinStoreScreen> {
  final CoinPurchaseService _coinStore = CoinPurchaseService.instance;
  final RemoveAdsPurchaseService _removeAds = RemoveAdsPurchaseService.instance;
  StreamSubscription<void>? _purchaseSettledSub;
  StreamSubscription<CoinPurchaseResult>? _coinPurchaseSub;

  int _availableCoins = 0;
  bool _isPurchasingRemoveAds = false;

  bool get _isPremium => PremiumService.instance.isPremiumUser;

  @override
  void initState() {
    super.initState();
    PremiumService.instance.addListener(_onPremiumChanged);
    _purchaseSettledSub = _removeAds.purchaseSettled.listen((_) {
      if (!mounted) return;
      if (!PremiumService.instance.isPremiumUser) {
        setState(() => _isPurchasingRemoveAds = false);
      }
    });
    _coinPurchaseSub = _coinStore.purchaseResults.listen(_onCoinPurchaseResult);
    _loadCoins();
    _refreshStore();
  }

  @override
  void dispose() {
    _coinPurchaseSub?.cancel();
    _purchaseSettledSub?.cancel();
    PremiumService.instance.removeListener(_onPremiumChanged);
    super.dispose();
  }

  Future<void> _refreshStore() async {
    await _coinStore.refreshProducts();
    if (!mounted) return;
    setState(() {});
  }

  void _onPremiumChanged() {
    if (!mounted) return;
    setState(() {
      _isPurchasingRemoveAds = false;
    });
    if (PremiumService.instance.isPremiumUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ads removed. Enjoy uninterrupted play!'),
        ),
      );
    }
  }

  void _onCoinPurchaseResult(CoinPurchaseResult result) {
    if (!mounted) return;
    setState(() {});
    _loadCoins();

    if (result.success && result.coins != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+${result.coins} coins added!')),
      );
    } else if (result.canceled) {
      // User dismissed the flow — no message.
    } else if (result.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!)),
      );
    }
  }

  Future<void> _loadCoins() async {
    final coins = await CoinHistoryService.getAvailableCoins();
    if (!mounted) return;
    setState(() => _availableCoins = coins);
  }

  Future<void> _purchaseCoinPack(CoinPack pack) async {
    if (_coinStore.purchasingProductId != null) return;

    if (!_coinStore.storeAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store is not available. Try again later.'),
        ),
      );
      return;
    }

    setState(() {});
    final started = await _coinStore.buyPack(pack);
    if (!mounted) return;

    if (!started) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start purchase.')),
      );
    }
  }

  Future<void> _purchaseRemoveAds() async {
    if (_isPremium || _isPurchasingRemoveAds) return;

    setState(() => _isPurchasingRemoveAds = true);

    if (!_removeAds.storeAvailable) {
      if (!mounted) return;
      setState(() => _isPurchasingRemoveAds = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store is not available. Try again later.'),
        ),
      );
      return;
    }

    final started = await _removeAds.buyRemoveAds();
    if (!mounted) return;

    if (!started && !_isPremium) {
      setState(() => _isPurchasingRemoveAds = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start purchase.')),
      );
    } else if (_isPremium) {
      setState(() => _isPurchasingRemoveAds = false);
    }
  }

  String get _removeAdsPrice {
    return _removeAds.localizedPrice ?? '\$2.99';
  }

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = (constraints.maxWidth / 375).clamp(0.85, 1.15);
            final horizontalPad = (16 * scale).clamp(12.0, 20.0);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad),
              child: Column(
                children: [
                  TopHeader(label: 'COIN SHOP'),
                  SizedBox(height: (10 * scale).clamp(6.0, 14.0)),
                  _buildBanner(scale),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildCoinBadge(scale),
                  ),
                  SizedBox(height: (14 * scale).clamp(10.0, 18.0)),
                  _buildSectionTitle(scale),
                  SizedBox(height: (10 * scale).clamp(6.0, 12.0)),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCoinPackagesGrid(scale),
                          SizedBox(height: (10 * scale).clamp(4.0, 10.0)),
                          _buildRemoveAdsCard(scale),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCoinPackagesGrid(double scale) {
    if (_coinStore.isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: (32 * scale).clamp(24.0, 40.0)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_coinStore.storeAvailable) {
      return _buildStoreMessage(
        scale,
        'Store unavailable.\nCheck your connection and try again.',
        onRetry: _refreshStore,
      );
    }

    final packs = _coinStore.packs;
    if (packs.isEmpty) {
      final error = _coinStore.loadError;
      return _buildStoreMessage(
        scale,
        error != null
            ? 'Could not load coin packs.\n$error'
            : 'No coin packs found.\nAdd products in Play Console with IDs like coins_100.',
        onRetry: _refreshStore,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: packs.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: (10 * scale).clamp(8.0, 12.0),
        crossAxisSpacing: (10 * scale).clamp(8.0, 12.0),
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final pack = packs[index];
        final isPurchasing =
            _coinStore.purchasingProductId == pack.productId;
        return _CoinPackageCard(
          pack: pack,
          scale: scale,
          isPurchasing: isPurchasing,
          onPurchase: () => _purchaseCoinPack(pack),
        );
      },
    );
  }

  Widget _buildStoreMessage(
    double scale,
    String message, {
    required VoidCallback onRetry,
  }) {
    final fontSize = (13 * scale).clamp(11.0, 15.0);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: (24 * scale).clamp(16.0, 32.0)),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              color: JColors.trunk,
              height: 1.35,
            ),
          ),
          SizedBox(height: (12 * scale).clamp(8.0, 16.0)),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'FredokaOne',
                fontSize: (14 * scale).clamp(12.0, 16.0),
                color: JColors.brightGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(double scale) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Image.asset(
          'assets/images/get-coin-board.png',
          width: double.infinity,
          fit: BoxFit.contain,
        ),
        Padding(
          padding: EdgeInsets.only(
            right: (18 * scale).clamp(12.0, 24.0),
            left: (120 * scale).clamp(96.0, 140.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get Coins',
                style: TextStyle(
                  fontFamily: 'FredokaOne',
                  fontSize: (24 * scale).clamp(18.0, 28.0),
                  color: Colors.white,
                  height: 1.05,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              SizedBox(height: (4 * scale).clamp(2.0, 6.0)),
              Text(
                'Unlock fun and exciting rewards!',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: (12 * scale).clamp(10.0, 14.0),
                  color: JColors.yellow,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoinBadge(double scale) {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/coin.png', height: 25, fit: BoxFit.contain),
          SizedBox(width: (6 * scale).clamp(4.0, 8.0)),
          Text(
            '$_availableCoins',
            style: TextStyle(
              fontFamily: 'FredokaOne',
              fontSize: font,
              color: Colors.white,
            ),
          ),
          SizedBox(width: (8 * scale).clamp(6.0, 12.0)),
          GestureDetector(
            onTap: _loadCoins,
            child: Container(
              width: plus,
              height: plus,
              decoration: const BoxDecoration(
                color: JColors.brightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: iconPlus,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveAdsCard(double scale) {
    final radius = (16 * scale).clamp(12.0, 20.0);
    final imageHeight = (72 * scale).clamp(56.0, 84.0);
    final titleSize = (16 * scale).clamp(14.0, 18.0);
    final subtitleSize = (11 * scale).clamp(10.0, 12.0);
    final priceSize = (12 * scale).clamp(10.0, 14.0);
    final statusSize = (11 * scale).clamp(10.0, 12.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (12 * scale).clamp(10.0, 16.0),
        vertical: (6 * scale).clamp(8.0, 12.0),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A14).withOpacity(0.82),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: JColors.lightGreen.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: (8 * scale).clamp(6.0, 10.0),
            offset: Offset(0, (4 * scale).clamp(2.0, 6.0)),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/remove-ads.png',
            height: imageHeight,
            fit: BoxFit.contain,
          ),
          SizedBox(width: (10 * scale).clamp(8.0, 12.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remove Ads',
                  style: TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: titleSize,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: (4 * scale).clamp(2.0, 6.0)),
                Text(
                  _isPremium
                      ? 'Ads are off across the jungle.'
                      : 'Enjoy uninterrupted jungle hops.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: subtitleSize,
                    color: Colors.white.withOpacity(0.78),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: (8 * scale).clamp(6.0, 10.0)),
          if (_isPremium)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: (10 * scale).clamp(8.0, 12.0),
                vertical: (6 * scale).clamp(4.0, 8.0),
              ),
              decoration: BoxDecoration(
                color: JColors.lightGreen.withOpacity(0.22),
                borderRadius: BorderRadius.circular((12 * scale).clamp(10.0, 14.0)),
                border: Border.all(color: JColors.lightGreen.withOpacity(0.55)),
              ),
              child: Text(
                'ACTIVE',
                style: TextStyle(
                  fontFamily: 'FredokaOne',
                  fontSize: statusSize,
                  color: JColors.lightGreen,
                ),
              ),
            )
          else if (_isPurchasingRemoveAds)
            Padding(
              padding: EdgeInsets.all((8 * scale).clamp(6.0, 10.0)),
              child: SizedBox(
                width: (24 * scale).clamp(20.0, 28.0),
                height: (24 * scale).clamp(20.0, 28.0),
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _purchaseRemoveAds,
                borderRadius: BorderRadius.circular((12 * scale).clamp(10.0, 14.0)),
                child: Ink(
                  padding: EdgeInsets.symmetric(
                    horizontal: (12 * scale).clamp(10.0, 14.0),
                    vertical: (8 * scale).clamp(6.0, 10.0),
                  ),
                  decoration: BoxDecoration(
                    gradient: JColors.playButtonGradient,
                    borderRadius: BorderRadius.circular((12 * scale).clamp(10.0, 14.0)),
                  ),
                  child: Text(
                    _removeAdsPrice,
                    style: TextStyle(
                      fontFamily: 'FredokaOne',
                      fontSize: priceSize,
                      color: const Color(0xFF1A2A10),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(double scale) {
    final font = (18 * scale).clamp(15.0, 20.0);
    final leaf = (16 * scale).clamp(13.0, 18.0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('🌿', style: TextStyle(fontSize: leaf)),
        SizedBox(width: (8 * scale).clamp(6.0, 10.0)),
        Text(
          'Coin Packages',
          style: TextStyle(
            fontFamily: 'FredokaOne',
            fontSize: font,
            color: JColors.trunk,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: (8 * scale).clamp(6.0, 10.0)),
        Text('🌿', style: TextStyle(fontSize: leaf)),
      ],
    );
  }
}

class _CoinPackageCard extends StatelessWidget {
  final CoinPack pack;
  final double scale;
  final bool isPurchasing;
  final VoidCallback onPurchase;

  const _CoinPackageCard({
    required this.pack,
    required this.scale,
    required this.isPurchasing,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final amountSize = (16 * scale).clamp(13.0, 18.0);
    final priceSize = (12 * scale).clamp(10.0, 14.0);
    final tagSize = (8 * scale).clamp(7.0, 10.0);
    final radius = (14 * scale).clamp(12.0, 16.0);

    return Container(
      padding: EdgeInsets.all((8 * scale).clamp(6.0, 10.0)),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A14).withOpacity(0.82),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: JColors.lightGreen.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: (8 * scale).clamp(6.0, 10.0),
            offset: Offset(0, (4 * scale).clamp(2.0, 6.0)),
          ),
        ],
      ),
      child: Column(
        children: [
          if (pack.isBestValue)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: (8 * scale).clamp(6.0, 10.0),
                vertical: (3 * scale).clamp(2.0, 4.0),
              ),
              decoration: BoxDecoration(
                gradient: JColors.playButtonGradient,
                borderRadius: BorderRadius.circular((10 * scale).clamp(8.0, 12.0)),
              ),
              child: Text(
                'BEST VALUE',
                style: TextStyle(
                  fontFamily: 'FredokaOne',
                  fontSize: tagSize,
                  color: const Color(0xFF1A2A10),
                  letterSpacing: 0.4,
                ),
              ),
            ),
          if (pack.isBestValue)
            SizedBox(height: (4 * scale).clamp(2.0, 6.0)),
          Text(
            '${pack.coins}',
            style: TextStyle(
              fontFamily: 'FredokaOne',
              fontSize: amountSize,
              color: Colors.white,
            ),
          ),
          SizedBox(height: (4 * scale).clamp(2.0, 6.0)),
          Expanded(
            child: Image.asset(
              pack.imageAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/coin.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: (4 * scale).clamp(4.0, 6.0)),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isPurchasing ? null : onPurchase,
                borderRadius: BorderRadius.circular((12 * scale).clamp(10.0, 14.0)),
                child: Ink(
                  padding: EdgeInsets.symmetric(
                    vertical: (6 * scale).clamp(4.0, 8.0),
                  ),
                  decoration: BoxDecoration(
                    gradient: isPurchasing
                        ? null
                        : JColors.playButtonGradient,
                    color: isPurchasing
                        ? JColors.lightGreen.withOpacity(0.35)
                        : null,
                    borderRadius:
                        BorderRadius.circular((12 * scale).clamp(10.0, 14.0)),
                  ),
                  child: Center(
                    child: isPurchasing
                        ? SizedBox(
                            width: (18 * scale).clamp(16.0, 22.0),
                            height: (18 * scale).clamp(16.0, 22.0),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1A2A10),
                            ),
                          )
                        : Text(
                            pack.localizedPrice,
                            style: TextStyle(
                              fontFamily: 'FredokaOne',
                              fontSize: priceSize,
                              color: const Color(0xFF1A2A10),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
