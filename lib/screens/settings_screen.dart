import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/best_score_service.dart';
import '../services/coin_history_service.dart';
import '../services/level_progress_service.dart';
import '../utils/colors.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _music = prefs.getBool(kMusic) ?? _music;
      _sfx = prefs.getBool(kSfx) ?? _sfx;
      _vibration = prefs.getBool(kVibration) ?? _vibration;
      _notifications = prefs.getBool(kNotifications) ?? _notifications;
      _volume = prefs.getDouble(kVolume) ?? _volume;
    });
  }

  Future<void> _saveBool(String key, bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, v);
  }

  Future<void> _saveDouble(String key, double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/settingBg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                          border:
                              Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Settings list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _SectionTitle(label: 'Audio'),
                    _ToggleTile(
                      icon: Icons.music_note_rounded,
                      label: 'Background Music',
                      value: _music,
                      onChanged: (v) {
                        setState(() => _music = v);
                        _saveBool(kMusic, v);
                      },
                    ),
                    _SliderTile(
                      icon: Icons.volume_up_rounded,
                      label: 'Volume',
                      value: _volume,
                      onChanged: (v) {
                        setState(() => _volume = v);
                        _saveDouble(kVolume, v);
                      },
                    ),
                    _ToggleTile(
                      icon: Icons.notifications_active_rounded,
                      label: 'Sound Effects',
                      value: _sfx,
                      onChanged: (v) {
                        setState(() => _sfx = v);
                        _saveBool(kSfx, v);
                      },
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(label: 'Game'),
                    _ToggleTile(
                      icon: Icons.vibration_rounded,
                      label: 'Vibration',
                      value: _vibration,
                      onChanged: (v) {
                        setState(() => _vibration = v);
                        _saveBool(kVibration, v);
                      },
                    ),
                    _ToggleTile(
                      icon: Icons.notifications_active_rounded,
                      label: 'Notifications',
                      value: _notifications,
                      onChanged: (v) {
                        setState(() => _notifications = v);
                        _saveBool(kNotifications, v);
                      },
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(label: 'About'),
                    _InfoTile(icon: Icons.phone_android_rounded, label: 'Version', value: '1.0.0'),
                    const SizedBox(height: 24),
                    _DangerButton(
                      label: '🗑️  Reset Progress',
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withOpacity(0.6),
                          builder: (_) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF173D17).withOpacity(0.98),
                                    const Color(0xFF0A2A1C).withOpacity(0.98),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(34),
                                border: Border.all(
                                  color: const Color(0xFF74A80A).withOpacity(0.45),
                                  width: 1.4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8BC34A).withOpacity(0.2),
                                    blurRadius: 26,
                                    spreadRadius: 1,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 74,
                                    height: 74,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF0F2B24),
                                      border: Border.all(
                                        color: const Color(0xFF56DE62).withOpacity(0.35),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.warning_rounded,
                                      size: 36,
                                      color: Color(0xFF56DE62),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'RESET PROGRESS?',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'FredokaOne',
                                      fontSize: 36,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'This will erase all your scores and\nunlocked characters. This action\ncannot be undone.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.68),
                                      fontSize: 20,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    height: 16,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.75),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: 0.72,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.45),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: () async {
                                      await CoinHistoryService.resetAll();
                                      await LevelProgressService.resetProgress();
                                      await BestScoreService.resetAll();
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.remove('shop_owned_characters');
                                      await prefs.remove('shop_using_character');
                                      if (mounted) {
                                        Navigator.pop(context);
                                       
                                      }
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFF6D6D), Color(0xFFB50025)],
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'RESET',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontFamily: 'FredokaOne',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0C2D27).withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'CANCEL',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.85),
                                            fontSize: 15,
                                            letterSpacing: 1.0,
                                            fontFamily: 'FredokaOne',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'SECURITY PROTOCOL ALPHA-9',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.42),
                                      fontSize: 10,
                                      letterSpacing: 2.0,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                   
                    const SizedBox(height: 24),
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

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 2,
          color: JColors.lightGreen,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 25, color: Colors.lightGreenAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: JColors.treeLightGreen,
            activeTrackColor: JColors.lightGreen.withOpacity(0.8),
            inactiveThumbColor: Colors.white.withOpacity(0.4),
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 25, color: Colors.lightGreenAccent),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  fontFamily: 'FredokaOne',
                  fontSize: 14,
                  color: JColors.yellow,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: JColors.lightGreen,
              inactiveTrackColor: Colors.white.withOpacity(0.15),
              thumbColor: JColors.yellow,
              overlayColor: JColors.yellow.withOpacity(0.1),
              trackHeight: 3,
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 25, color: Colors.lightGreenAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DangerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.25)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'FredokaOne',
              fontSize: 16,
              color: Color(0xFFFF8080),
            ),
          ),
        ),
      ),
    );
  }
}

