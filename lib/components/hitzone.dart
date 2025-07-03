import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// The area at the bottom of a lane where notes are meant to be hit.
class Hitzone extends RectangleComponent {
  final int lane;

  Hitzone({required this.lane}) {
    paint = Paint()..color = Colors.white.withOpacity(0.2);
  }

  /// Triggers a visual feedback effect when the zone is activated.
  void flash() {
    add(
      ColorEffect(
        Colors.white,
        EffectController(duration: 0.1, reverseDuration: 0.2),
        opacityTo: 0.8,
      ),
    );
  }
}
