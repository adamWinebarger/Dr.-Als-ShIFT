import 'package:flutter/material.dart';

class GradientContainer extends Container {
  GradientContainer({super.key, required this.child});

  final Widget child;

  @override build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF92b662),
            Color(0xFF92b662),
            Color(0xFF5e8b3d),
            Color(0xffffffff),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight
        )
      ),
      child: child,
    );
  }

}