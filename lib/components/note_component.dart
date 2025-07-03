import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import 'note.dart';
import '../game/rythm_game.dart';

/// Visually represents a single falling note.
class NoteComponent extends RectangleComponent with HasGameRef<RythmGame> {
  /// The data for this note.
  final Note note;
  
  /// A flag to mark the note for removal.
  bool isHit = false;

  NoteComponent({required this.note}) {
    paint = Paint()..color = Colors.cyan;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Move the note down the screen based on the scroll speed.
    position.y += RythmGame.scrollSpeed * dt;

    // When the note goes off-screen, trigger a miss, fade it out, and then remove it.
    if (position.y > gameRef.size.y && !isRemoving) {
      gameRef.onNoteMissed();
      // Use ColorEffect to fade to transparent, which is compatible with RectangleComponent.
      add(
        ColorEffect(
          Colors.transparent,
          EffectController(duration: 0.2),
          onComplete: removeFromParent,
        ),
      );
    }
  }
}
