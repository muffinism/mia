import '../components/note.dart';
import 'slam_side.dart';

/// Represents a note that is part of a slam event.
class SlamNote {
  /// The time in seconds from the start of the song when the slam should occur.
  final double time;
  /// The side to which the ball should be slammed.
  final SlamSide side;

  SlamNote({required this.time, required this.side});
}


/// Holds the entire sequence of notes and events for a song.
class Beatmap {
  /// The list of regular notes to be hit.
  final List<Note> notes;
  /// The list of slam events.
  final List<SlamNote> slams;
  /// The total duration of the song in seconds.
  final double songDuration;

  Beatmap({required this.notes, required this.slams, required this.songDuration});

  /// A factory constructor to create a sample beatmap for testing.
  factory Beatmap.sample() {
    // This beatmap is based on the first ~40 seconds of the Tetris A-TYPE theme.
    // Timings have been adjusted to sync with the provided video.
    return Beatmap(
      songDuration: 39.6,
      slams: [
        SlamNote(time: 3.6, side: SlamSide.left),
        SlamNote(time: 11.6, side: SlamSide.right),
        SlamNote(time: 19.6, side: SlamSide.left),
        SlamNote(time: 27.6, side: SlamSide.right),
        SlamNote(time: 35.6, side: SlamSide.left),
      ],
      notes: [
        // Intro (0-4s)
        Note(lane: 2, time: 1.6),
        Note(lane: 1, time: 2.1),
        Note(lane: 0, time: 2.6),
        
        // Main Melody Part 1 (4-12s) -> Now (3.6s - 11.6s)
        Note(lane: 2, time: 3.6), Note(lane: 1, time: 3.85), Note(lane: 0, time: 4.1),
        Note(lane: 1, time: 4.35), Note(lane: 2, time: 4.6), Note(lane: 3, time: 4.85),
        Note(lane: 3, time: 5.1), Note(lane: 2, time: 5.35), Note(lane: 1, time: 5.6),
        Note(lane: 2, time: 5.85), Note(lane: 1, time: 6.1), Note(lane: 0, time: 6.35),
        Note(lane: 0, time: 6.6),
        // Chords
        Note(lane: 0, time: 7.1), Note(lane: 2, time: 7.1),
        Note(lane: 1, time: 7.6), Note(lane: 3, time: 7.6),
        Note(lane: 0, time: 8.1), Note(lane: 2, time: 8.1),
        // Repeat phrase
        Note(lane: 2, time: 8.6), Note(lane: 3, time: 8.85), Note(lane: 1, time: 9.1),
        Note(lane: 0, time: 9.35), Note(lane: 1, time: 9.6), Note(lane: 2, time: 9.85),
        Note(lane: 2, time: 10.1), Note(lane: 3, time: 10.35), Note(lane: 1, time: 10.6),
        Note(lane: 0, time: 10.85), Note(lane: 0, time: 11.1),

        // Main Melody Part 2 (12-20s) -> Now (11.6s - 19.6s)
        Note(lane: 2, time: 11.6), Note(lane: 1, time: 11.85), Note(lane: 0, time: 12.1),
        Note(lane: 1, time: 12.35), Note(lane: 2, time: 12.6), Note(lane: 3, time: 12.85),
        Note(lane: 3, time: 13.1), Note(lane: 2, time: 13.35), Note(lane: 1, time: 13.6),
        Note(lane: 2, time: 13.85), Note(lane: 1, time: 14.1), Note(lane: 0, time: 14.35),
        Note(lane: 0, time: 14.6),
        Note(lane: 0, time: 15.1), Note(lane: 2, time: 15.1),
        Note(lane: 1, time: 15.6), Note(lane: 3, time: 15.6),
        Note(lane: 0, time: 16.1), Note(lane: 2, time: 16.1),
        Note(lane: 2, time: 16.6), Note(lane: 3, time: 16.85), Note(lane: 1, time: 17.1),
        Note(lane: 0, time: 17.35), Note(lane: 1, time: 17.6), Note(lane: 2, time: 17.85),
        Note(lane: 2, time: 18.1), Note(lane: 3, time: 18.35), Note(lane: 1, time: 18.6),
        Note(lane: 0, time: 18.85), Note(lane: 0, time: 19.1),

        // B-Part Melody 1 (20-28s) -> Now (19.6s - 27.6s)
        Note(lane: 3, time: 19.6), Note(lane: 3, time: 19.85),
        Note(lane: 0, time: 20.1), Note(lane: 0, time: 20.35),
        Note(lane: 1, time: 20.6), Note(lane: 1, time: 20.85),
        Note(lane: 2, time: 21.1), Note(lane: 2, time: 21.35),
        Note(lane: 3, time: 21.6), Note(lane: 2, time: 21.85),
        Note(lane: 1, time: 22.1), Note(lane: 1, time: 22.35),
        Note(lane: 0, time: 22.6), Note(lane: 2, time: 22.6), // Chord
        Note(lane: 0, time: 23.1),
        Note(lane: 1, time: 23.6),
        Note(lane: 2, time: 24.1),
        Note(lane: 3, time: 24.6),
        Note(lane: 2, time: 25.1),
        Note(lane: 1, time: 25.6),
        Note(lane: 0, time: 26.1), Note(lane: 2, time: 26.1), // Chord
        Note(lane: 0, time: 26.6),

        // B-Part Melody 2 (28-36s) -> Now (27.6s - 35.6s)
        Note(lane: 3, time: 27.6), Note(lane: 3, time: 27.85),
        Note(lane: 0, time: 28.1), Note(lane: 0, time: 28.35),
        Note(lane: 1, time: 28.6), Note(lane: 1, time: 28.85),
        Note(lane: 2, time: 29.1), Note(lane: 2, time: 29.35),
        Note(lane: 3, time: 29.6), Note(lane: 2, time: 29.85),
        Note(lane: 1, time: 30.1), Note(lane: 1, time: 30.35),
        Note(lane: 0, time: 30.6), Note(lane: 2, time: 30.6), // Chord
        Note(lane: 0, time: 31.1),
        Note(lane: 1, time: 31.6),
        Note(lane: 2, time: 32.1),
        Note(lane: 3, time: 32.6),
        Note(lane: 2, time: 33.1),
        Note(lane: 1, time: 33.6),
        Note(lane: 0, time: 34.1), Note(lane: 2, time: 34.1), // Chord
        Note(lane: 0, time: 34.6),
      ],
    );
  }
}