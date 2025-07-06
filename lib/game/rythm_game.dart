import 'package:flame/components.dart';
// import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:mia/components/snow_component.dart';

import '../components/hitzone.dart';
import '../components/note_component.dart';
import '../components/slam_ball.dart';
import '../components/slam_prompt.dart';
import '../data/beatmap.dart';
import '../data/slam_side.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

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

class PauseButton extends SpriteComponent with TapCallbacks {
  final VoidCallback onPressed;

  PauseButton({required this.onPressed});

  @override
  void onTapDown(TapDownEvent event) {
    debugPrint('Pause button tapped');
    onPressed();
  }
}

class RythmGame extends FlameGame
    with KeyboardEvents, HasCollisionDetection, MultiTouchTapDetector {
  static const int numberOfLanes = 4;
  static const double scrollSpeed = 600;
  static const double noteHeight = 100;
  static const double perfectWindow = 10;
  static const double goodWindow = 30.0;
  static const double okWindow = 120.0;
  final ValueNotifier<bool> isHomeScreen = ValueNotifier(true);
  TextComponent? emailText;

  final VoidCallback? onProfileTap;
  RythmGame({this.onProfileTap});
  // final VoidCallback onLoginTap;
  // RythmGame({required this.onLoginTap});

  late final Beatmap beatmap;

  // Audio-based timing
  double songPosition = 0;

  int _noteIndex = 0;
  int _slamIndex = 0;
  int score = 0;
  int combo = 0;

  TextComponent? _scoreText;
  TextComponent? _comboLabel;
  TextComponent? _comboText;
  TextComponent? _judgmentText;
  TextComponent? _titleText;
  TextComponent? tapToStart;

  final List<Hitzone> hitzones = [];
  final List<SlamNote> _hitSlams = [];

  GameState currentState = GameState.menu;

  late PauseButton pauseIcon;
  IconButtonComponent? resumeButton;
  IconButtonComponent? restartButton;
  IconButtonComponent? mainMenuButton;
  late SpriteComponent loginButton;
  late SpriteComponent _backgroundMenu;
  SnowComponent? _snow;
  RectangleComponent? _blurOverlay;
  late PauseOverlay pauseOverlay;
  RectangleComponent? _perfectHitLine;

  SpriteComponent? _gameBackground;

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

    pauseIcon =
        PauseButton(onPressed: pauseGame)
          ..sprite = await loadSprite('pause_icon.png')
          ..size = Vector2(40, 40)
          ..position = Vector2(size.x - 20, 50)
          ..anchor = Anchor.topRight
          ..priority = 1000;

    await showMenu();
  }

  @override
  void onTapDown(int pointerId, TapDownInfo info) {
    super.onTapDown(pointerId, info);

    final tapPosition = info.eventPosition.global;

    switch (currentState) {
      case GameState.menu:
        final loginRect = Rect.fromLTWH(
          loginButton.position.x - loginButton.size.x / 2,
          loginButton.position.y - loginButton.size.y / 2,
          loginButton.size.x,
          loginButton.size.y,
        );

        if (loginRect.contains(tapPosition.toOffset())) {
          loginButton.scale = Vector2.all(1.2); // efek tap
          Future.delayed(const Duration(milliseconds: 100), () {
            if (loginButton.isMounted) {
              loginButton.scale = Vector2.all(1.0); // reset
            }
          });

          if (FirebaseAuth.instance.currentUser != null) {
            debugPrint('Navigating to ProfileScreen...');
            onProfileTap?.call();
          } else {
            debugPrint('User not logged in');
          }
        } else {
          // ✅ Start the game on any other tap
          startGame();
        }
        break;

      case GameState.playing:
        final pauseRect = pauseIcon.toRect();
        if (pauseRect.contains(tapPosition.toOffset())) {
          pauseGame();
          return;
        }

        final laneWidth = size.x / numberOfLanes;
        for (int i = 0; i < numberOfLanes; i++) {
          final laneRect = Rect.fromLTWH(i * laneWidth, 0, laneWidth, size.y);
          if (laneRect.contains(tapPosition.toOffset())) {
            onTapLane(i);
            break;
          }
        }
        break;
      case GameState.paused:
        if (pauseOverlay.isReady) {
          if (pauseOverlay.handleTap(tapPosition)) return;
        } else {
          print('PauseOverlay tap ignored, not ready');
        }
        break;
      case GameState.finished:
        if (restartButton!.isMounted &&
            restartButton!.containsPoint(tapPosition)) {
          restartButton!.onPressed();
        }
        break;
    }
  }

  Future<void> showMenu() async {
    isHomeScreen.value = true;
    currentState = GameState.menu;

    _snow =
        SnowComponent()
          ..size = size
          ..priority = -1;

    _backgroundMenu =
        SpriteComponent()
          ..sprite = await loadSprite('bg_menu.jpg')
          ..size = size
          ..priority = -2;

    add(_backgroundMenu);

    // Tambahan: Layer hitam transparan & blur
    _blurOverlay = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xCC000000), // semi-transparan hitam
    )..priority = -1;

    _titleText = TextComponent(
      text: '[ M I A ]',
      position: Vector2(size.x / 2, size.y / 3),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(blurRadius: 10, color: Colors.blueAccent),
            Shadow(blurRadius: 30, color: Colors.purple),
          ],
        ),
      ),
    );

    tapToStart = TextComponent(
      text: 'Touch to Start',
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(blurRadius: 10, color: Colors.white),
            Shadow(blurRadius: 30, color: Colors.purple),
          ],
        ),
      ),
    )..priority = -1;

    loginButton =
        SpriteComponent()
          ..sprite = await loadSprite('icon_person.png')
          ..size = Vector2(40, 40)
          ..anchor = Anchor.center
          ..position = Vector2(size.x / 2, size.y / 2 + 60)
          ..priority = 0;

    add(_backgroundMenu);
    add(_blurOverlay!);
    add(_snow!);
    add(loginButton);
    add(_titleText!);
    add(tapToStart!);

    // final user = FirebaseAuth.instance.currentUser;
    // if (user != null) {
    //   emailText = TextComponent(
    //     text: user.email ?? '',
    //     position: Vector2(size.x / 2, loginButton.position.y + 40),
    //     anchor: Anchor.topCenter,
    //     textRenderer: TextPaint(
    //       style: const TextStyle(
    //         fontSize: 18,
    //         color: Colors.white,
    //         fontWeight: FontWeight.w500,
    //         shadows: [Shadow(blurRadius: 10, color: Colors.black)],
    //       ),
    //     ),
    //   );
    //   add(emailText!);
    // }

  //   final highScore = await FirestoreService.getHighScore();
  //   final highScoreText = TextComponent(
  //     text: 'High Score: $highScore',
  //     position: Vector2(size.x / 2, loginButton.position.y + 70),
  //     anchor: Anchor.topCenter,
  //     textRenderer: TextPaint(
  //       style: const TextStyle(
  //         fontSize: 18,
  //         color: Colors.white,
  //         fontWeight: FontWeight.bold,
  //         shadows: [Shadow(blurRadius: 10, color: Colors.black)],
  //       ),
  //     ),
  //   );
  //   add(highScoreText);
  }

  void removeAllGameComponents() {
    final componentsToRemove =
        children
            .where(
              (c) =>
                  c is NoteComponent ||
                  c is SlamPrompt ||
                  c is Hitzone ||
                  c is SlamBall ||
                  c == _scoreText ||
                  c == _comboLabel ||
                  c == _comboText ||
                  c == _judgmentText ||
                  c == resumeButton ||
                  c == restartButton ||
                  c == mainMenuButton,
            )
            .toList();
    removeAll(componentsToRemove);
  }

  void goToMainMenu() {
    isHomeScreen.value = true;
    // if (emailText != null && emailText!.isMounted) remove(emailText!);
    FlameAudio.bgm.stop();
    removeAllGameComponents();
    if (_perfectHitLine != null && _perfectHitLine!.isMounted)
      remove(_perfectHitLine!);
    if (pauseOverlay.isMounted) remove(pauseOverlay);
    if (_gameBackground != null && _gameBackground!.isMounted)
      remove(_gameBackground!);

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
    isHomeScreen.value = false;
    if (emailText != null && emailText!.isMounted) remove(emailText!);

    if (_titleText?.isMounted ?? false) remove(_titleText!);

    if (tapToStart != null && tapToStart!.isMounted) remove(tapToStart!);

    if (loginButton.isMounted) remove(loginButton);

    if (_backgroundMenu != null && _backgroundMenu!.isMounted)
      remove(_backgroundMenu!);

    if (_snow != null && _snow!.isMounted) remove(_snow!);

    if (_blurOverlay != null && _blurOverlay!.isMounted) remove(_blurOverlay!);

    _gameBackground =
        SpriteComponent()
          ..sprite = await loadSprite('bg_game_blur.jpg')
          ..size = size
          ..priority = -3;

    add(_gameBackground!);

    _perfectHitLine = RectangleComponent(
      size: Vector2(size.x, 2),
      paint: Paint()..color = Colors.white.withOpacity(0.8),
      position: Vector2(0, size.y - 120),
    );
    add(_perfectHitLine!);

    final laneWidth = size.x / numberOfLanes;
    for (int i = 0; i < numberOfLanes; i++) {
      final hitzone =
          Hitzone(lane: i)
            ..size = Vector2(laneWidth, 240)
            ..position = Vector2(i * laneWidth, size.y - 240);
      hitzones.add(hitzone);
      add(hitzone);
    }

    final slamBall =
        SlamBall()
          ..anchor = Anchor.center
          ..position = Vector2(size.x / 2, size.y - noteHeight - 120);
    add(slamBall);

    _scoreText = TextComponent(
      text: '0',
      position: Vector2(20, 50),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    _comboLabel = TextComponent(
      text: 'COMBO',
      position: Vector2(size.x / 2, 50),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    _comboText = TextComponent(
      text: '0',
      position: Vector2(size.x / 2, 75),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    _judgmentText = TextComponent(
      text: '',
      position: Vector2(size.x / 2, 120),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 36,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(_scoreText!);
    add(_comboLabel!);
    add(_comboText!);
    add(_judgmentText!);
    add(pauseIcon);

    await FlameAudio.bgm.play(
      'tetris.mp3',
    ); // Assumes your song is named tetris.mp3
    currentState = GameState.playing;
  }

  void resetGame() {
    isHomeScreen.value = false;
    FlameAudio.bgm.stop();
    removeAllGameComponents();
    if (_perfectHitLine != null && _perfectHitLine!.isMounted)
      remove(_perfectHitLine!);
    if (pauseOverlay.isMounted) remove(pauseOverlay);

    score = 0;
    combo = 0;
    _noteIndex = 0;
    _slamIndex = 0;
    songPosition = 0;
    _hitSlams.clear();
    hitzones.clear();

    startGame();
  }

  void pauseGame() async {
    isHomeScreen.value = false;
    if (currentState != GameState.playing) return;

    FlameAudio.bgm.pause();
    currentState = GameState.paused;

    remove(pauseIcon);

    pauseOverlay =
        PauseOverlay(
            onResume: resumeGame,
            onRestart: resetGame,
            onMainMenu: goToMainMenu,
          )
          ..size = size
          ..priority = 50;

    add(pauseOverlay);
    await pauseOverlay.onLoad();
    print('PauseOverlay fully loaded and ready');
  }

  void resumeGame() {
    isHomeScreen.value = false;
    if (currentState != GameState.paused) return;
    FlameAudio.bgm.resume();
    currentState = GameState.playing;
    if (pauseOverlay.isMounted) remove(pauseOverlay);
    add(pauseIcon);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (currentState == GameState.playing) {
      if (songPosition >= beatmap.songDuration) {
        currentState = GameState.finished;
        FlameAudio.bgm.stop();
        remove(pauseIcon);
        add(restartButton!);
        return;
      }

      // Spawn notes based on the song's current position
      while (_noteIndex < beatmap.notes.length &&
          beatmap.notes[_noteIndex].time <=
              songPosition + (size.y / scrollSpeed)) {
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

    if (songPosition >= beatmap.songDuration) {
      currentState = GameState.finished;
      FlameAudio.bgm.stop();
      remove(pauseIcon);
      add(restartButton!);

      // Save score
      FirestoreService.saveHighScore(score);

      return;
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
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

    NoteComponent? closestNote;
    double minDistance = double.infinity;

    final hitzoneY = size.y - 120;
    final maxDistance = 120;

    for (final note in children.whereType<NoteComponent>()) {
      if (note.note.lane == lane) {
        final distance = (note.position.y - hitzoneY).abs();

        if (distance < minDistance && distance <= maxDistance) {
          minDistance = distance;
          closestNote = note;
        }
      }
    }

    if (closestNote != null) {
      if (minDistance <= perfectWindow) {
        judgeHit("PERFECT", 100);
      } else if (minDistance <= goodWindow) {
        judgeHit("GOOD", 50);
      } else if (minDistance <= okWindow) {
        judgeHit("OK", 20);
      } else {
        judgeHit("MISS", 0);
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

  void showJudgmentText(String text, Color color) {
    _judgmentText
      ?..text = text
      ..textRenderer = TextPaint(
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: color,
          shadows: [
            Shadow(
              color: color.withOpacity(0.7),
              blurRadius: 12,
              offset: Offset(0, 0),
            ),
            Shadow(color: color, blurRadius: 24, offset: Offset(0, 0)),
          ],
        ),
      );

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
    Color color;

    switch (text) {
      case "PERFECT":
        color = Colors.yellowAccent;
        break;
      case "GOOD":
        color = Colors.lightGreenAccent;
        break;
      case "OK":
        color = Colors.lightBlueAccent;
        break;
      case "MISS":
        color = Colors.redAccent;
        break;
      case "SLAM!":
        color = Colors.deepPurpleAccent;
      default:
        color = Colors.white;
    }

    score += points;

    if (text != "MISS")
      combo++;
    else
      combo = 0;

    _scoreText?.text = '$score';
    _comboText?.text = '$combo';
    showJudgmentText(text, color);
  }

  void onNoteMissed() {
    if (currentState != GameState.playing) return;
    combo = 0;
    _comboText?.text = '$combo';
    judgeHit("MISS", 0);
  }
}

class IconButtonComponent extends PositionComponent {
  final VoidCallback onPressed;
  final Sprite sprite;

  IconButtonComponent({
    required this.onPressed,
    required this.sprite,
    required Vector2 position,
  }) {
    this.position = position;
    size = Vector2(25, 25);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    final spriteComponent = SpriteComponent(
      sprite: sprite,
      size: size,
      anchor: Anchor.center,
      position: size / 2,
    );

    add(spriteComponent);
  }

  bool handleTap(Vector2 tapPosition) {
    final topLeft = absoluteTopLeftPosition;
    final rect = Rect.fromLTWH(topLeft.x, topLeft.y, size.x, size.y);
    if (rect.contains(tapPosition.toOffset())) {
      debugPrint('Tapped on button at $position');
      onPressed();
      return true;
    }
    return false;
  }
}

// class IconButtonComponent extends SpriteComponent with TapCallbacks {
//   final VoidCallback onPressed;

//   IconButtonComponent({
//     required this.onPressed,
//     required Sprite sprite,
//     required Vector2 position,
//   }) {
//     this.sprite = sprite;
//     this.size = Vector2(25, 25);
//     this.position = position;
//     anchor = Anchor.center;
//   }

//   @override
//   void onTapDown(TapDownEvent event) {
//     onPressed();
//   }
// }

class PauseOverlay extends PositionComponent {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;

  late IconButtonComponent resumeButton;
  late IconButtonComponent restartButton;
  late IconButtonComponent mainMenuButton;

  PauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onMainMenu,
  });

  bool isReady = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    print('PauseOverlay onLoad started');

    final background = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.black.withOpacity(0.8),
    );

    add(background);

    final spacing = 80.0;
    final centerX = size.x / 2;
    final yPos = size.y / 2;

    mainMenuButton = IconButtonComponent(
      sprite: await Sprite.load('main_menu.png'),
      position: Vector2(centerX - spacing, yPos),
      onPressed: onMainMenu,
    );

    restartButton = IconButtonComponent(
      sprite: await Sprite.load('restart.png'),
      position: Vector2(centerX, yPos),
      onPressed: onRestart,
    );

    resumeButton = IconButtonComponent(
      sprite: await Sprite.load('resume.png'),
      position: Vector2(centerX + spacing, yPos),
      onPressed: onResume,
    );

    addAll([mainMenuButton, restartButton, resumeButton]);

    isReady = true;
    print('PauseOverlay onLoad finished - buttons initialized');
  }

  bool handleTap(Vector2 tapPosition) {
    if (!isReady) return false;

    if (resumeButton?.handleTap(tapPosition) == true) return true;
    if (restartButton?.handleTap(tapPosition) == true) return true;
    if (mainMenuButton?.handleTap(tapPosition) == true) return true;

    return false;
  }

  Future<void> saveHighScore(int newScore) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();

    final currentHigh = doc.data()?['highScore'] ?? 0;
    if (newScore > currentHigh) {
      await docRef.set({'highScore': newScore}, SetOptions(merge: true));
    }
  }
}
