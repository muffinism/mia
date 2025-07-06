/// A simple data class to hold information about a single note.
class Note {
  /// The lane this note belongs to (0 to 3).
  final int lane;
  /// The time in seconds from the start of the song when this note should be hit.
  final double time;

  Note({required this.lane, required this.time});
}