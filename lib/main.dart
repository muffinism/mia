import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/rythm_game.dart';

void main() {
  final game = RythmGame();
  runApp(GameWidget(game: game));
}
