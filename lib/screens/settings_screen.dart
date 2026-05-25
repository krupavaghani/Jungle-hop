import 'dart:math' show max, min;

import 'package:flutter/material.dart';
import 'package:jungle_jumpping/widgets/top_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_update_service.dart';
import '../services/best_score_service.dart';
import '../services/coin_history_service.dart';
import '../services/leaderboard_service.dart';
import '../services/level_progress_service.dart';
import '../services/premium_service.dart';
import '../services/remove_ads_purchase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String kMusic = 'settings_music';
  static const String kSfx = 'settings_sfx';
  static const String kVibration = 'settings_vibration';
  static const String kNotifications = 'settings_notifications';
  static const String kVolume = 'settings_volume';

  bool _music = true;
  bool _sfx = true;
  bool _vibration = true;
  bool _notifications = false;
  double _volume = 0.75;
  int _coins = 0;
  String _appVersion = '—';
  bool _isRestoringPurchases = false;

  @override
  void initState() {
    super.initState();
    PremiumService.instance.addListener(_onPremiumChanged);
    _loadSettings();
    _loadCoins();
    _loadAppVersion();
  }

  @override
  void dispose() {
    PremiumService.instance.removeListener(_onPremiumChanged);
    super.dispose();
  }

  void _onPremiumChanged() {
    if (!mounted) return;
    setState(() {
      _isRestoringPurchases = false;
    });
  }

  Future<void> _restorePurchases() async {
    if (_isRestoringPurchases) return;
    setState(() => _isRestoringPurchases = true);

    final result =
        await RemoveAdsPurchaseService.instance.restorePurchases();

    if (!mounted) return;
    setState(() => _isRestoringPurchases = false);

    final message = switch (result) {
      RestorePurchaseResult.restored =>
        'Remove Ads restored. Welcome back!',
      RestorePurchaseResult.alreadyPremium => 'You already have Remove Ads.',
      RestorePurchaseResult.nothingFound =>
        'No Remove Ads purchase found for this account.',
      RestorePurchaseResult.storeUnavailable =>
        'Store is not available. Try again later.',
      RestorePurchaseResult.failed =>
        'Could not restore purchases. Try again.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadAppVersion() async {
    final version = await AppUpdateService.getCurrentVersion();
    if (!mounted) return;
    setState(() => _appVersion = version);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _music = prefs.getBool(kMusic) ?? _music;
      _sfx = prefs.getBool(kSfx) ?? _sfx;
      _vibration = prefs.getBool(kVibration) ?? _vibration;
      _notifications = prefs.getBool(kNotifications) ?? _notifications;
      _volume = prefs.getDouble(kVolume) ?? _volume;
    });
  }

  Future<void> _loadCoins() async {
    final coins = await CoinHistoryService.getAvailableCoins();
    if (!mounted) return;
    setState(() => _coins = coins);
  }

  Future<void> _saveBool(String key, bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, v);
  }

  Future<void> _saveDouble(String key, double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, v);
  }

  void _showResetDialog() {
    final mq = MediaQuery.sizeOf(context);
    final scale = (mq.width / 375).clamp(0.78, 1.15);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: (20 * scale).clamp(14.0, 28.0),
          vertical: 24,
        ),
        child: _ResetProgressDialog(
          scale: scale,
          onCancel: () => Navigator.pop(dialogContext),
          onReset: () async {
            await CoinHistoryService.resetAll();
            await LevelProgressService.resetProgress();
            await BestScoreService.resetAll();
            await LeaderboardService.deleteCurrentPlayer();
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('shop_owned_characters');
            await prefs.remove('shop_using_character');
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
            if (mounted) _loadCoins();
          },
        ),
      ),
    );
  }

  static double _scale(double width) => (width / 375).clamp(0.78, 1.2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/settingBg.png', fit: BoxFit.cover),
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = _scale(constraints.maxWidth);
              final padH = (10 * scale).clamp(10.0, 20.0);

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: padH),
                child: Column(
                  children: [
                    TopHeader(label: 'SETTINGS'),  
                   
                    SizedBox(height: (10 * scale).clamp(4.0, 12.0)),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.only(
                          bottom: (12 * scale).clamp(8.0, 16.0),
                        ),
                        children: [
                          _SettingsSection(
                            scale: scale,
                            title: 'AUDIO',
                            children: [
                              _SettingsToggleRow(
                                scale: scale,
                                icon: Icons.music_note_rounded,
                                label: 'Background Music',
                                value: _music,
                                onChanged: (v) {
                                  setState(() => _music = v);
                                  _saveBool(kMusic, v);
                                },
                              ),
                              _SettingsDivider(scale: scale),
                              _SettingsVolumeRow(
                                scale: scale,
                                value: _volume,
                                onChanged: (v) {
                                  setState(() => _volume = v);
                                  _saveDouble(kVolume, v);
                                },
                              ),
                              _SettingsDivider(scale: scale),
                              _SettingsToggleRow(
                                scale: scale,
                                icon: Icons.notifications_active_rounded,
                                label: 'Sound Effects',
                                value: _sfx,
                                onChanged: (v) {
                                  setState(() => _sfx = v);
                                  _saveBool(kSfx, v);
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: (10 * scale).clamp(6.0, 14.0)),
                          _SettingsSection(
                            scale: scale,
                            title: 'GAME',
                            children: [
                              _SettingsToggleRow(
                                scale: scale,
                                icon: Icons.vibration_rounded,
                                label: 'Vibration',
                                value: _vibration,
                                onChanged: (v) {
                                  setState(() => _vibration = v);
                                  _saveBool(kVibration, v);
                                },
                              ),
                              _SettingsDivider(scale: scale),
                              _SettingsToggleRow(
                                scale: scale,
                                icon: Icons.notifications_rounded,
                                label: 'Notifications',
                                value: _notifications,
                                onChanged: (v) {
                                  setState(() => _notifications = v);
                                  _saveBool(kNotifications, v);
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: (10 * scale).clamp(6.0, 14.0)),
                          _SettingsSection(
                            scale: scale,
                            title: 'PURCHASES',
                            children: [
                              _SettingsInfoRow(
                                scale: scale,
                                icon: Icons.block_rounded,
                                label: 'Remove Ads',
                                value: PremiumService.instance.isPremiumUser
                                    ? 'ACTIVE'
                                    : 'OFF',
                              ),
                              _SettingsDivider(scale: scale),
                              _RestorePurchasesRow(
                                scale: scale,
                                isLoading: _isRestoringPurchases,
                                onTap: _restorePurchases,
                              ),
                            ],
                          ),
                          SizedBox(height: (10 * scale).clamp(6.0, 14.0)),
                          _SettingsSection(
                            scale: scale,
                            title: 'ABOUT',
                            children: [
                              _SettingsInfoRow(
                                scale: scale,
                                icon: Icons.phone_android_rounded,
                                label: 'Version',
                                value: _appVersion,
                              ),
                            ],
                          ),
                          SizedBox(height: (14 * scale).clamp(10.0, 18.0)),
                          _ResetProgressButton(
                            scale: scale,
                            onTap: _showResetDialog,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final double scale;
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.scale,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final tabH = (36 * scale).clamp(26.0, 38.0);
    final labelSize = (15 * scale).clamp(13.0, 17.0);
    final panelPadH = (28 * scale).clamp(18.0, 30.0);
    final panelPadV = (20 * scale).clamp(12.0, 22.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            height: tabH,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset('assets/images/subTitle.png', fit: BoxFit.fill),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: labelSize,
                    color: const Color(0xFFFDF1CA),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, -(6 * scale).clamp(4.0, 8.0)),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/setting-board.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                panelPadH,
                panelPadV,
                panelPadH,
                panelPadV,
              ),
              child: Column(children: children),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  final double scale;

  const _SettingsDivider({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: (2 * scale).clamp(1.0, 3.0),
      thickness: 1,
      color: const Color(0xFF5C4A2E).withValues(alpha: 0.35),
    );
  }
}

class _SettingsIconBox extends StatelessWidget {
  final double scale;
  final IconData icon;

  const _SettingsIconBox({required this.scale, required this.icon});

  @override
  Widget build(BuildContext context) {
    final size = (36 * scale).clamp(30.0, 42.0);
    final iconSize = (18 * scale).clamp(15.0, 22.0);
    final radius = (8 * scale).clamp(6.0, 10.0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF3D8B28),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFF5CB63A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final double scale;
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.scale,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rowPadV = (15 * scale).clamp(12.0, 18.0);
    final labelSize = (14 * scale).clamp(12.0, 16.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: rowPadV),
      child: Row(
        children: [
          _SettingsIconBox(scale: scale, icon: icon),
          SizedBox(width: (10 * scale).clamp(8.0, 14.0)),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: labelSize,
                color: const Color(0xFF2F4A16),
              ),
            ),
          ),
          _JungleToggle(scale: scale, value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _JungleToggle extends StatelessWidget {
  final double scale;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _JungleToggle({
    required this.scale,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final w = (64 * scale).clamp(54.0, 72.0);
    final h = (30 * scale).clamp(26.0, 34.0);
    final knob = (24 * scale).clamp(20.0, 28.0);
    final fontSize = (9 * scale).clamp(7.0, 10.0);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: w,
        height: h,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF4CAF50) : const Color(0xFF5C3D1E),
          borderRadius: BorderRadius.circular(h / 2),
          border: Border.all(
            color: value ? const Color(0xFF2E7D32) : const Color(0xFF3D2810),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Align(
              alignment: value ? Alignment.centerLeft : Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(
                  left: value ? (8 * scale).clamp(6.0, 10.0) : 0,
                  right: value ? 0 : (8 * scale).clamp(6.0, 10.0),
                ),
                child: Text(
                  value ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: fontSize,
                    color: Colors.white.withValues(alpha: value ? 0.95 : 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: knob,
                height: knob,
                decoration: BoxDecoration(
                  color: value
                      ? const Color(0xFF81C784)
                      : const Color(0xFF8D6E4A),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsVolumeRow extends StatelessWidget {
  final double scale;
  final double value;
  final ValueChanged<double> onChanged;

  const _SettingsVolumeRow({
    required this.scale,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rowPadV = (10 * scale).clamp(6.0, 14.0);
    final labelSize = (14 * scale).clamp(12.0, 16.0);
    final pctSize = (13 * scale).clamp(11.0, 15.0);
    final trackH = (10 * scale).clamp(8.0, 12.0);
    final thumb = (26 * scale).clamp(22.0, 32.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: rowPadV),
      child: Column(
        children: [
          Row(
            children: [
              _SettingsIconBox(scale: scale, icon: Icons.volume_up_rounded),
              SizedBox(width: (10 * scale).clamp(8.0, 14.0)),
              Expanded(
                child: Text(
                  'Volume',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: labelSize,
                    color: const Color(0xFF2F4A16),
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  fontFamily: 'FredokaOne',
                  fontSize: pctSize,
                  color: const Color(0xFF5C3408),
                ),
              ),
            ],
          ),
          SizedBox(height: (8 * scale).clamp(4.0, 10.0)),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final fillW = max(0.0, min(maxW - thumb, maxW * value));

              return SizedBox(
                height: thumb,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: trackH,
                      margin: EdgeInsets.only(left: thumb / 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D2810).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(trackH),
                      ),
                    ),
                    Positioned(
                      left: thumb / 2,
                      child: Container(
                        width: fillW,
                        height: trackH,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                          ),
                          borderRadius: BorderRadius.circular(trackH),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF4CAF50,
                              ).withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: fillW,
                      child: Image.asset(
                        'assets/images/coin.png',
                        width: thumb,
                        height: thumb,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned.fill(
                      child: SliderTheme(
                        data: const SliderThemeData(
                          trackHeight: 0,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 0,
                          ),
                          overlayShape: RoundSliderOverlayShape(
                            overlayRadius: 0,
                          ),
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          thumbColor: Colors.transparent,
                        ),
                        child: Slider(value: value, onChanged: onChanged),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RestorePurchasesRow extends StatelessWidget {
  final double scale;
  final bool isLoading;
  final VoidCallback onTap;

  const _RestorePurchasesRow({
    required this.scale,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rowPadV = (15 * scale).clamp(12.0, 18.0);
    final labelSize = (14 * scale).clamp(12.0, 16.0);
    final btnFont = (12 * scale).clamp(10.0, 14.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: rowPadV),
      child: Row(
        children: [
          _SettingsIconBox(
            scale: scale,
            icon: Icons.restore_rounded,
          ),
          SizedBox(width: (10 * scale).clamp(8.0, 14.0)),
          Expanded(
            child: Text(
              'Restore Purchases',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: labelSize,
                color: const Color(0xFF2F4A16),
              ),
            ),
          ),
          if (isLoading)
            SizedBox(
              width: (22 * scale).clamp(18.0, 26.0),
              height: (22 * scale).clamp(18.0, 26.0),
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: (12 * scale).clamp(10.0, 16.0),
                  vertical: (6 * scale).clamp(4.0, 8.0),
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1B5E20), width: 1.2),
                ),
                child: Text(
                  'RESTORE',
                  style: TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: btnFont,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  final double scale;
  final IconData icon;
  final String label;
  final String value;

  const _SettingsInfoRow({
    required this.scale,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final rowPadV = (10 * scale).clamp(6.0, 14.0);
    final labelSize = (14 * scale).clamp(12.0, 16.0);
    final badgeFont = (12 * scale).clamp(10.0, 14.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: rowPadV),
      child: Row(
        children: [
          _SettingsIconBox(scale: scale, icon: icon),
          SizedBox(width: (10 * scale).clamp(8.0, 14.0)),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: labelSize,
                color: const Color(0xFF2F4A16),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (12 * scale).clamp(10.0, 16.0),
              vertical: (5 * scale).clamp(4.0, 8.0),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF5C3D1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF8D6E4A), width: 1),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'FredokaOne',
                fontSize: badgeFont,
                color: const Color(0xFFFDF1CA),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetProgressDialog extends StatelessWidget {
  final double scale;
  final VoidCallback onCancel;
  final Future<void> Function() onReset;

  const _ResetProgressDialog({
    required this.scale,
    required this.onCancel,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = (88 * scale).clamp(72.0, 100.0);
    final titleSize = (30 * scale).clamp(24.0, 34.0);
    final bodySize = (14 * scale).clamp(12.0, 16.0);
    final btnH = (48 * scale).clamp(42.0, 54.0);
    final btnFont = (18 * scale).clamp(15.0, 20.0);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,

          // margin: EdgeInsets.only(top: iconSize * 0.42),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/setting-popUp-bg.png'),
              fit: BoxFit.fill,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 30,bottom: 60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
            'assets/images/alert-button.png',
            width: iconSize,
            height: iconSize,
            fit: BoxFit.fill,
          ),
                _GradientTitleLine(
                  text: 'RESET',
                  fontSize: titleSize,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFB8F06A), Color(0xFF4CAF50)],
                  ),
                  strokeColor: const Color(0xFF2E4A12),
                ),
                _GradientTitleLine(
                  text: 'PROGRESS?',
                  fontSize: titleSize,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFF176), Color(0xFFFF9800)],
                  ),
                  strokeColor: const Color(0xFF5C3D10),
                ),
                SizedBox(height: (12 * scale).clamp(8.0, 16.0)),
                Text(
                  'This will erase all your scores and\nunlocked characters. This action\ncannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: bodySize,
                    height: 1.35,
                    color: const Color(0xFFF5ECD8),
                  ),
                ),
                SizedBox(height: (18 * scale).clamp(14.0, 22.0)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ResetDialogButton(
                      label: 'RESET',
                      height: btnH,
                      fontSize: btnFont,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFF5252), Color(0xFFC62828)],
                      ),
                      borderColor: const Color(0xFF8B0000),
                      onTap: () => onReset(),
                    ),
                      _ResetDialogButton(
                  label: 'CANCEL',
                  height: btnH,
                  fontSize: btnFont,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                  ),
                  borderColor: const Color(0xFF1B5E20),
                  onTap: onCancel,
                ),
                  ],
                ),
              
              ],
            ),
          ),
        ),
       
      ],
    );
  }
}

class _GradientTitleLine extends StatelessWidget {
  final String text;
  final double fontSize;
  final Gradient gradient;
  final Color strokeColor;

  const _GradientTitleLine({
    required this.text,
    required this.fontSize,
    required this.gradient,
    required this.strokeColor,
  });

  @override
  Widget build(BuildContext context) {
    final strokeW = (fontSize * 0.08).clamp(2.0, 3.5);

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'FredokaOne',
            fontSize: fontSize,
            height: 1.05,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeW
              ..color = strokeColor,
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'FredokaOne',
              fontSize: fontSize,
              height: 1.05,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResetDialogButton extends StatelessWidget {
  final String label;
  final double height;
  final double fontSize;
  final Gradient gradient;
  final Color borderColor;
  final VoidCallback onTap;

  const _ResetDialogButton({
    required this.label,
    required this.height,
    required this.fontSize,
    required this.gradient,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // width: double.infinity - 40,
        // height: height,
        padding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        // alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'FredokaOne',
            fontSize: fontSize,
            color: Colors.white,
            letterSpacing: 0.8,
            shadows: const [
              Shadow(
                color: Color(0x88000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetProgressButton extends StatelessWidget {
  final double scale;
  final VoidCallback onTap;

  const _ResetProgressButton({required this.scale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final h = (52 * scale).clamp(44.0, 58.0);
    final fontSize = (15 * scale).clamp(13.0, 18.0);
    final iconSize = (22 * scale).clamp(18.0, 26.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
          ),
          borderRadius: BorderRadius.circular((14 * scale).clamp(10.0, 18.0)),
          border: Border.all(color: const Color(0xFF8B0000), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFFFF5252).withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: const Color(0xFFFFEB3B),
              size: iconSize,
            ),
            SizedBox(width: (8 * scale).clamp(6.0, 12.0)),
            Text(
              'RESET PROGRESS',
              style: TextStyle(
                fontFamily: 'FredokaOne',
                fontSize: fontSize,
                color: Colors.white,
                letterSpacing: 0.8,
                shadows: const [
                  Shadow(
                    color: Color(0x88000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
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
