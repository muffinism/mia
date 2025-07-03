import 'package:flame/components.dart';
// import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame_audio/flame_audio.dart';

import '../components/hitzone.dart';
import '../components/note_component.dart';
import '../components/slam_ball.dart';
import '../components/slam_prompt.dart';
import '../data/beatmap.dart';
import '../data/slam_side.dart';

// Represents the current state of the game.
enum GameState { menu, playing, paused, finished }

// A generic button class for the UI.
class GameButton extends PositionComponent {
  final VoidCallback onPressed;
  final String text;
  final Color color;

  GameButton({
    required this.onPressed,
    required this.text,
    this.color = Colors.red,
    required super.position,
  });

  @override
  Future<void> onLoad() async {
    final background = RectangleComponent(
      size: Vector2(200, 50),
      paint: Paint()..color = color,
    );
    final label = TextComponent(
      text: text,
      anchor: Anchor.center,
      position: Vector2(100, 25),
    );
    background.add(label);
    add(background);
    size = background.size;
    anchor = Anchor.center;
  }
}

class RythmGame extends FlameGame
    with KeyboardEvents, HasCollisionDetection, TapDetector {
  static const int numberOfLanes = 4;
  static const double scrollSpeed = 600;
  static const double noteHeight = 100;
  static const double perfectWindow = 0.05;
  static const double goodWindow = 0.1;
  static const double okWindow = 0.15;

  late final Beatmap beatmap;
  
  // Audio-based timing
  double songPosition = 0;
  
  int _noteIndex = 0;
  int _slamIndex = 0;
  int score = 0;
  int combo = 0;

  TextComponent? _scoreText;
  TextComponent? _comboText;
  TextComponent? _judgmentText;
  TextComponent? _titleText;

  final List<Hitzone> hitzones = [];
  final List<SlamNote> _hitSlams = [];

  GameState currentState = GameState.menu;

  late final GameButton playButton;
  late final GameButton pauseButton;
  late final GameButton resumeButton;
  late final GameButton restartButton;
  late final GameButton mainMenuButton;

  TimerComponent? _judgmentTimer;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    beatmap = Beatmap.sample();
    
    // Listen for song position changes to sync the game
    FlameAudio.bgm.audioPlayer.onPositionChanged.listen((p) {
        songPosition = p.inMilliseconds / 1000.0;
    });

    _titleText = TextComponent(
      text: 'Mia',
      position: Vector2(size.x / 2, size.y / 3),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 64, color: Colors.white),
      ),
    );

    playButton = GameButton(
      onPressed: startGame,
      text: 'Play',
      position: Vector2(size.x / 2, size.y / 2),
    );

    pauseButton = GameButton(
      onPressed: pauseGame,
      text: 'Pause',
      color: Colors.grey,
      position: Vector2(size.x - 110, 115),
    );

    resumeButton = GameButton(
      onPressed: resumeGame,
      text: 'Resume',
      color: Colors.green,
      position: Vector2(size.x / 2, size.y / 2 - 60),
    );
    
    restartButton = GameButton(
      onPressed: resetGame,
      text: 'Restart',
      position: Vector2(size.x / 2, size.y / 2),
    );
    
    mainMenuButton = GameButton(
        onPressed: goToMainMenu,
        text: 'Main Menu',
        color: Colors.amber,
        position: Vector2(size.x / 2, size.y / 2 + 60));

    showMenu();
  }
  
  @override
  void onTapUp(TapUpInfo info) {
    super.onTapUp(info);
    
    final tapPosition = info.eventPosition.global;

    switch (currentState) {
      case GameState.menu:
        if (playButton.isMounted && playButton.containsPoint(tapPosition)) {
          playButton.onPressed();
        }
        break;
      case GameState.playing:
        if (pauseButton.isMounted && pauseButton.containsPoint(tapPosition)) {
          pauseButton.onPressed();
        } else {
          final laneWidth = size.x / numberOfLanes;
          for (int i = 0; i < numberOfLanes; i++) {
            final laneRect = Rect.fromLTWH(i * laneWidth, 0, laneWidth, size.y);
            if (laneRect.contains(tapPosition.toOffset())) {
              onTapLane(i);
              break; 
            }
          }
        }
        break;
      case GameState.paused:
        if (resumeButton.isMounted && resumeButton.containsPoint(tapPosition)) {
          resumeButton.onPressed();
        }
        if (restartButton.isMounted && restartButton.containsPoint(tapPosition)) {
          restartButton.onPressed();
        }
        if (mainMenuButton.isMounted && mainMenuButton.containsPoint(tapPosition)) {
          mainMenuButton.onPressed();
        }
        break;
      case GameState.finished:
        if (restartButton.isMounted && restartButton.containsPoint(tapPosition)) {
          restartButton.onPressed();
        }
        break;
    }
  }


  void showMenu() {
    currentState = GameState.menu;
    add(_titleText!);
    add(playButton);
  }
  
  void removeAllGameComponents() {
    final componentsToRemove = children.where((c) => 
        c is NoteComponent || 
        c is SlamPrompt || 
        c is Hitzone || 
        c is SlamBall ||
        c == _scoreText ||
        c == _comboText ||
        c == _judgmentText ||
        c == pauseButton ||
        c == resumeButton ||
        c == restartButton ||
        c == mainMenuButton
    ).toList();
    removeAll(componentsToRemove);
  }
  
  void goToMainMenu() {
    FlameAudio.bgm.stop();
    removeAllGameComponents();
    
    score = 0;
    combo = 0;
    _noteIndex = 0;
    _slamIndex = 0;
    songPosition = 0;
    _hitSlams.clear();
    hitzones.clear();
    
    showMenu();
  }


  void startGame() async {
    if (_titleText?.isMounted ?? false) remove(_titleText!);
    if (playButton.isMounted) remove(playButton);

    final laneWidth = size.x / numberOfLanes;
    for (int i = 0; i < numberOfLanes; i++) {
      final hitzone = Hitzone(lane: i)
        ..size = Vector2(laneWidth, noteHeight)
        ..position = Vector2(i * laneWidth, size.y - noteHeight);
      hitzones.add(hitzone);
      add(hitzone);
    }

    final slamBall = SlamBall()
      ..anchor = Anchor.center
      ..position = Vector2(size.x / 2, size.y - noteHeight - 80);
    add(slamBall);

    _scoreText = TextComponent(text: 'Score: 0', position: Vector2(20, 100));
    _comboText = TextComponent(text: 'Combo: 0', position: Vector2(20, 130));
    _judgmentText = TextComponent(
      text: '',
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
    add(_scoreText!);
    add(_comboText!);
    add(_judgmentText!);
    add(pauseButton);
    
    await FlameAudio.bgm.play('tetris.mp3'); // Assumes your song is named tetris.mp3
    currentState = GameState.playing;
  }

  void resetGame() {
    FlameAudio.bgm.stop();
    removeAllGameComponents();

    score = 0;
    combo = 0;
    _noteIndex = 0;
    _slamIndex = 0;
    songPosition = 0;
    _hitSlams.clear();
    hitzones.clear();
    
    startGame();
  }

  void pauseGame() {
    if (currentState != GameState.playing) return;
    FlameAudio.bgm.pause();
    currentState = GameState.paused;
    remove(pauseButton);
    add(resumeButton);
    add(restartButton);
    add(mainMenuButton);
  }

  void resumeGame() {
    if (currentState != GameState.paused) return;
    FlameAudio.bgm.resume();
    currentState = GameState.playing;
    remove(resumeButton);
    remove(restartButton);
    remove(mainMenuButton);
    add(pauseButton);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (currentState == GameState.playing) {
      if (songPosition >= beatmap.songDuration) {
        currentState = GameState.finished;
        FlameAudio.bgm.stop();
        remove(pauseButton);
        add(restartButton);
        return;
      }

      // Spawn notes based on the song's current position
      while (_noteIndex < beatmap.notes.length &&
          beatmap.notes[_noteIndex].time <= songPosition + (size.y / scrollSpeed)) {
        final noteData = beatmap.notes[_noteIndex];
        final laneWidth = size.x / numberOfLanes;
        add(
          NoteComponent(note: noteData)
            ..size = Vector2(laneWidth, noteHeight)
            ..position = Vector2(noteData.lane * laneWidth, -noteHeight),
        );
        _noteIndex++;
      }

      while (_slamIndex < beatmap.slams.length &&
          beatmap.slams[_slamIndex].time <= songPosition + 0.5) {
        final slamData = beatmap.slams[_slamIndex];
        add(SlamPrompt(side: slamData.side));
        _slamIndex++;
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (currentState != GameState.playing) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyD) {
        onTapLane(0);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
        onTapLane(1);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyJ) {
        onTapLane(2);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyK) {
        onTapLane(3);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void onTapLane(int lane) {
    if (currentState != GameState.playing) return;
    hitzones[lane].flash();

    final hitTime = songPosition; // Judge based on song position
    NoteComponent? closestNote;
    double minTimeDiff = double.infinity;

    for (final note in children.whereType<NoteComponent>()) {
      if (note.note.lane == lane) {
        final timeDiff = (note.note.time - hitTime).abs();
        final yPos = note.position.y;
        if (timeDiff < minTimeDiff && yPos > size.y - noteHeight * 2 && yPos < size.y) {
          minTimeDiff = timeDiff;
          closestNote = note;
        }
      }
    }

    if (closestNote != null) {
      if (minTimeDiff <= perfectWindow) {
        judgeHit("Perfect", 100);
      } else if (minTimeDiff <= goodWindow) {
        judgeHit("Good", 50);
      } else if (minTimeDiff <= okWindow) {
        judgeHit("OK", 20);
      } else {
        return;
      }
      closestNote.removeFromParent();
    }
  }

  void onSlam(SlamSide side) {
    if (currentState != GameState.playing) return;
    final hitTime = songPosition; // Judge based on song position
    SlamNote? closestSlam;
    double minTimeDiff = double.infinity;

    for (final slam in beatmap.slams) {
      if (slam.side == side && !_hitSlams.contains(slam)) {
        final timeDiff = (slam.time - hitTime).abs();
        if (timeDiff < minTimeDiff) {
          minTimeDiff = timeDiff;
          closestSlam = slam;
        }
      }
    }

    if (closestSlam != null && minTimeDiff <= okWindow * 1.5) {
      judgeHit("SLAM!", 150);
      _hitSlams.add(closestSlam);
    }
  }

  void showJudgmentText(String text) {
    _judgmentText?.text = text;
    _judgmentTimer?.removeFromParent();
    _judgmentTimer = TimerComponent(
      period: 0.5,
      onTick: () {
        if (_judgmentText != null) {
          _judgmentText!.text = '';
        }
      },
      removeOnFinish: true,
    );
    add(_judgmentTimer!);
  }

  void judgeHit(String text, int points) {
    score += points;
    combo++;
    _scoreText?.text = 'Score: $score';
    _comboText?.text = 'Combo: $combo';
    showJudgmentText(text);
  }

  void onNoteMissed() {
    if (currentState != GameState.playing) return;
    combo = 0;
    _comboText?.text = 'Combo: $combo';
    showJudgmentText("Miss");
  }
}
