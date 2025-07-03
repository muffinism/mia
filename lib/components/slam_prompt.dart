import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../data/slam_side.dart';
import '../game/rythm_game.dart';

/// A visual indicator on the side of the screen prompting the player to slam.
class SlamPrompt extends RectangleComponent with HasGameRef<RythmGame> {
  final SlamSide side;

  SlamPrompt({required this.side});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    paint = Paint()..color = Colors.red.withOpacity(0.0);

    // Define the position and size based on the side
    size = Vector2(100, gameRef.size.y);
    if (side == SlamSide.left) {
      position = Vector2.zero();
    } else {
      position = Vector2(gameRef.size.x - size.x, 0);
    }

    // Add a fade-in and fade-out effect.
    // The prompt appears, stays visible, then fades.
    add(
      SequenceEffect([
        OpacityEffect.to(0.6, EffectController(duration: 0.2)),
        OpacityEffect.to(0.6, EffectController(duration: 0.5)), // Hold
        OpacityEffect.to(0.0, EffectController(duration: 0.3)),
        RemoveEffect(), // Remove the component after the effect is done.
      ]),
    );
  }
}
