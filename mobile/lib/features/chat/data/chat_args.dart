/// Navigation payload for opening a chat — carries the other participant's
/// display name and (when known) profile photo, so the chat screen's
/// AppBar can show their avatar without an extra network round-trip.
class ChatArgs {
  const ChatArgs({required this.name, this.image, this.gender});

  final String name;
  final String? image;

  /// Profile gender, for the default portrait when there's no photo.
  final String? gender;
}
