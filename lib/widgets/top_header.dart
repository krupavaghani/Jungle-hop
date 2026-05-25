import 'package:flutter/material.dart';

class TopHeader extends StatelessWidget {
  final String label;

  const TopHeader({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(top: 25,),
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF9A6535), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              color: const Color(0xFF6B3F1A),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        SizedBox(
          height: (MediaQuery.sizeOf(context).height * 0.11).clamp(75.0, 96.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/leaderBoard-title.png',
                fit: BoxFit.cover,
              ),
               Positioned(
                top: 45,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'FredokaOne',
                      fontSize: 22,
                      height: 1.05,
                      letterSpacing: 0.4,
                      color: Color(0xff5c3408),
                      shadows: [
                        Shadow(
                          color: Color(0xAA000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
