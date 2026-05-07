import 'package:flutter/material.dart';

class SpeechUpLogo extends StatelessWidget {
  final double width;
  final double height;

  const SpeechUpLogo({
    super.key,
    this.width = 112,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
