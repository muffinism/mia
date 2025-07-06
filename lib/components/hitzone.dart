import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Hitzone extends PositionComponent {
  final int lane;

  Hitzone({required this.lane});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final area = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.transparent,
      position: Vector2.zero(),
    );

    add(area);
  }

  void flash() {
    // Efek visual ketika ditekan (misalnya blink atau animasi)
    // Optional: tambahkan efek di sini kalau mau
  }
}