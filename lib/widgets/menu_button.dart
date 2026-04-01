import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum MenuButtonStyle { primary, glass }

class MenuButton extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;
  final MenuButtonStyle style;

  const MenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.style = MenuButtonStyle.glass,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = style == MenuButtonStyle.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: isPrimary ? 16 : 12,
          horizontal: 20,
        ),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [JungleColors.goldenYellow, JungleColors.amber],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimary ? null : JungleColors.glassWhite,
          borderRadius: BorderRadius.circular(14),
          border: isPrimary
              ? null
              : Border.all(color: JungleColors.glassBorder, width: 1),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: JungleColors.goldenYellow.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'FredokaOne',
                fontSize: isPrimary ? 17 : 15,
                color: isPrimary ? JungleColors.deepJungle : Colors.white,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
