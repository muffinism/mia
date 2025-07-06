import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../data/slam_side.dart';
import '../game/rythm_game.dart';

/// The central ball that the player swipes to perform a "slam".
class SlamBall extends CircleComponent with DragCallbacks, HasGameReference<RythmGame> {
  late final Vector2 initialPosition;
  
  SlamBall() {
    paint = Paint()..color = Colors.orange;
    radius = 30;
  }

  @override
  void onMount() {
    super.onMount();
    initialPosition = position.clone();
    // Anchor is set in the main game file when the component is added
  }
  
  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    // Check swipe velocity to determine direction
    if (event.velocity.x.abs() > 300) { // Threshold for a valid swipe
      if (event.velocity.x < 0) {
        // Swiped Left
        game.onSlam(SlamSide.left);
        slam(SlamSide.left);
      } else {
        // Swiped Right
        game.onSlam(SlamSide.right);
        slam(SlamSide.right);
      }
    }
  }

  /// Animates the ball slamming to one side and returning to the center.
  void slam(SlamSide side) {
    final destinationX = side == SlamSide.left ? 50.0 : game.size.x - 50.0;
    
    // Ensure no other move effects are running
    removeWhere((component) => component is MoveEffect);

    add(
      SequenceEffect([
        MoveToEffect(
          Vector2(destinationX, position.y),
          EffectController(duration: 0.1, curve: Curves.easeOut),
        ),
        MoveToEffect(
          initialPosition,
          EffectController(duration: 0.5, curve: Curves.elasticOut),
        ),
      ]),
    );
  }
}