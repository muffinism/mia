import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import 'note.dart';
import '../game/rythm_game.dart';

/// Visually represents a single falling note.
class NoteComponent extends PositionComponent with HasGameRef<RythmGame> {
  final Note note;

  /// Untuk mencegah note diproses dua kali (hit / miss).
  bool isHit = false;

  NoteComponent({required this.note});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    size = Vector2(80, 100); // Sesuaikan dengan laneWidth & noteHeight

    final outline = RectangleComponent(
      size: size,
      paint:
          Paint()
            ..color = Colors.cyan
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6),
    );

    final inner = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xAA0FF1F1),
    );

    addAll([inner, outline]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.currentState != GameState.playing) return;

    position.y += RythmGame.scrollSpeed * dt;

    // Cek jika note melewati batas bawah layar
    if (position.y > gameRef.size.y && !isRemoving && !isHit) {
      isHit = true; // tandai agar tidak diproses ulang
      debugPrint("Note missed at pos: ${position.y.toStringAsFixed(1)}");

      gameRef.onNoteMissed();

      removeFromParent();
    }
  }
}