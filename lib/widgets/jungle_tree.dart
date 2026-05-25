import 'package:flutter/material.dart';
import 'package:jungle_jumpping/utils/colors.dart';

class JungleTree extends StatelessWidget {
  final double height;
  final double crownWidth;
  final double crownHeight;
  final double opacity;
  final bool small;

  const JungleTree({
    super.key,
    this.height = 60,
    this.crownWidth = 40,
    this.crownHeight = 50,
    this.opacity = 1.0,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final double trunkW = small ? 7 : 9;
    final double trunkH = small ? 18 : 26;
    final double cW = small ? 28 : crownWidth;
    final double cH = small ? 34 : crownHeight;

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown (layered for depth)
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Back crown (darker, taller)
              Container(
                width: cW,
                height: cH,
                decoration: BoxDecoration(
                  color: JColors.treeGreen,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(cW / 2),
                    topRight: Radius.circular(cW / 2),
                    bottomLeft: const Radius.circular(6),
                    bottomRight: const Radius.circular(6),
                  ),
                ),
              ),
              // Front crown (lighter)
              Positioned(
                top: 0,
                child: Container(
                  width: cW * 0.75,
                  height: cH * 0.75,
                  decoration: BoxDecoration(
                    color: JColors.midGreen,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(cW * 0.375),
                      topRight: Radius.circular(cW * 0.375),
                      bottomLeft: const Radius.circular(4),
                      bottomRight: const Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Trunk
          Container(
            width: trunkW,
            height: trunkH,
            decoration: BoxDecoration(
              color: JColors.trunk,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class JungleTreeRow extends StatelessWidget {
  final double opacity;
  final int count;

  const JungleTreeRow({
    super.key,
    this.opacity = 1.0,
    this.count = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        count,
        (index) => Expanded(
          child: Center(
            child: JungleTree(
              opacity: opacity,
              small: index % 2 == 1,
            ),
          ),
        ),
      ),
    );
  }
}
