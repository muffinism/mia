
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class SnowBall {
  Vector2 position;
  double speed;
  double size;

  SnowBall({required this.position, required this.speed, required this.size});
}

class SnowComponent extends PositionComponent {
  final List<SnowBall> _snowBalls = [];
  final Random _random = Random();

  @override
  Future<void> onLoad() async {
    final count = 15 + _random.nextInt(10);
    for (int i = 0; i < count; i++) {
      _snowBalls.add(
        SnowBall(
          position: Vector2(
            _random.nextDouble() * size.x,
            _random.nextDouble() * size.y,
          ),
          speed: 30 + _random.nextDouble() * 40,
          size: 2 + _random.nextDouble() * 3,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    for (var ball in _snowBalls) {
      ball.position.y += ball.speed * dt;
      if (ball.position.y > size.y) {
        ball.position.y = 0;
        ball.position.x = _random.nextDouble() * size.x;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xCCFFFFFF);
    for (var ball in _snowBalls) {
      canvas.drawCircle(
        Offset(ball.position.x, ball.position.y),
        ball.size,
        paint,
      );
    }
  }
}
