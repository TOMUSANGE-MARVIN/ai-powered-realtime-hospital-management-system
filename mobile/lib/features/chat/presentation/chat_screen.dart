import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/providers.dart';
import '../../../core/realtime/socket_providers.dart';
import '../../auth/state/auth_controller.dart';
import '../../calls/state/call_providers.dart';
import '../data/chat_message.dart';
import '../state/chat_providers.dart';
import 'chat_list_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
  });

  final String otherUserId;
  final String otherUserName;
  final String? otherUserImage;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<Map<String, dynamic>>? _newMessageSubscription;
  StreamSubscription<Map<String, dynamic>>? _deletedMessageSubscription;
  StreamSubscription<Map<String, dynamic>>? _statusSubscription;

  List<ChatMessage>? _messages;
  Object? _loadError;
  bool _sending = false;
  bool _uploadingAttachment = false;
  ChatMessage? _replyingTo;

  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    // Rebuild on every keystroke so the mic/send icon swap tracks whether
    // there's text, like WhatsApp's input.
    _textController.addListener(_onTextChanged);
    _loadHistory();
    _newMessageSubscription = ref.read(socketServiceProvider).messages.listen((data) {
      final message = ChatMessage.fromJson(data);
      if (message.senderId == widget.otherUserId || message.receiverId == widget.otherUserId) {
        _appendIfNew(message);
      }
    });
    _deletedMessageSubscription =
        ref.read(socketServiceProvider).deletedMessages.listen((data) {
      final deleted = ChatMessage.fromJson(data);
      _replace(deleted);
    });
    _statusSubscription =
        ref.read(socketServiceProvider).messageStatusUpdates.listen((data) {
      final updated = ChatMessage.fromJson(data);
      if (updated.senderId == widget.otherUserId || updated.receiverId == widget.otherUserId) {
        _replace(updated);
      }
    });
  }

  Future<void> _loadHistory() async {
    try {
      final history = await ref.read(chatRepositoryProvider).getConversation(widget.otherUserId);
      if (!mounted) return;
      setState(() => _messages = history);
      _scrollToBottom();
      // Fetching the thread marks incoming messages read server-side —
      // refresh the inbox badge next time it's shown.
      ref.invalidate(conversationsProvider);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  void _appendIfNew(ChatMessage message) {
    final current = _messages;
    if (current == null) return;
    if (current.any((m) => m.id == message.id)) return;
    setState(() => _messages = [...current, message]);
    _scrollToBottom();
  }

  void _replace(ChatMessage message) {
    final current = _messages;
    if (current == null) return;
    final index = current.indexWhere((m) => m.id == message.id);
    if (index == -1) return;
    final updated = [...current];
    updated[index] = message;
    setState(() => _messages = updated);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _newMessageSubscription?.cancel();
    _deletedMessageSubscription?.cancel();
    _statusSubscription?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  Future<void> _startRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required to record a voice note')),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _recordingPath = path;
      _recordingDuration = Duration.zero;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _audioRecorder.stop();
    final path = _recordingPath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingPath = null;
      });
    }
  }

  Future<void> _finishRecording() async {
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();
    if (mounted) setState(() => _isRecording = false);
    if (path == null) return;
    await _uploadAndSend(filePath: path, attachmentType: 'audio', attachmentName: 'Voice message');
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _textController.clear();
    final replyToId = _replyingTo?.id;
    setState(() => _replyingTo = null);
    try {
      final sent = await ref
          .read(chatRepositoryProvider)
          .send(receiverId: widget.otherUserId, text: text, replyToId: replyToId);
      _appendIfNew(sent);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message failed to send. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAttachment() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo from gallery'),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Document'),
              onTap: () => Navigator.of(context).pop('file'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    if (choice == 'camera' || choice == 'gallery') {
      final picked = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      await _uploadAndSend(
        filePath: picked.path,
        attachmentType: 'image',
        attachmentName: picked.name,
      );
    } else {
      final result = await FilePicker.platform.pickFiles();
      final file = result?.files.single;
      if (file?.path == null) return;
      await _uploadAndSend(
        filePath: file!.path!,
        attachmentType: 'file',
        attachmentName: file.name,
      );
    }
  }

  Future<void> _uploadAndSend({
    required String filePath,
    required String attachmentType,
    required String attachmentName,
  }) async {
    setState(() => _uploadingAttachment = true);
    final replyToId = _replyingTo?.id;
    setState(() => _replyingTo = null);
    try {
      final url = await ref.read(uploadRepositoryProvider).uploadFile(filePath);
      final sent = await ref.read(chatRepositoryProvider).send(
            receiverId: widget.otherUserId,
            attachmentUrl: url,
            attachmentType: attachmentType,
            attachmentName: attachmentName,
            replyToId: replyToId,
          );
      _appendIfNew(sent);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attachment failed to send. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAttachment = false);
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This will remove the message for both of you.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final deleted = await ref.read(chatRepositoryProvider).delete(message.id);
      _replace(deleted);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete message.')),
        );
      }
    }
  }

  void _startReply(ChatMessage message) {
    setState(() => _replyingTo = message);
  }

  Future<void> _showMessageActions(ChatMessage message, bool isMine) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () => Navigator.of(context).pop('reply'),
            ),
            if (isMine)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'reply') _startReply(message);
    if (action == 'delete') _deleteMessage(message);
  }

  Future<void> _placeCall(String type, String label) async {
    // Voice/video calling itself is a UI-only stub for now — no real
    // WebRTC connects — but the attempt is still logged so the Calls tab
    // has genuine history, matching how a real call log behaves.
    try {
      await ref.read(callRepositoryProvider).recordCall(calleeId: widget.otherUserId, type: type);
    } catch (_) {
      // Logging is best-effort — don't block the "coming soon" message on it.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label calls are coming soon!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(authControllerProvider).value?.id;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  widget.otherUserImage != null ? NetworkImage(widget.otherUserImage!) : null,
              child: widget.otherUserImage == null ? const Icon(Icons.person, size: 18) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherUserName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            tooltip: 'Voice call',
            onPressed: () => _placeCall('voice', 'Voice'),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            tooltip: 'Video call',
            onPressed: () => _placeCall('video', 'Video'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(myId)),
          if (_uploadingAttachment)
            const LinearProgressIndicator(minHeight: 2),
          if (_replyingTo != null) _ReplyPreviewBar(
            message: _replyingTo!,
            isMine: _replyingTo!.senderId == myId,
            otherUserName: widget.otherUserName,
            onCancel: () => setState(() => _replyingTo = null),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
              child: _isRecording ? _buildRecordingBar() : _buildInputRow(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    final hasText = _textController.text.trim().isNotEmpty;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.attach_file),
          onPressed: _uploadingAttachment ? null : _pickAttachment,
        ),
        Expanded(
          child: TextField(
            controller: _textController,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: const InputDecoration(
              hintText: 'Type a message',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          icon: _sending
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(hasText ? Icons.send : Icons.mic),
          onPressed: _sending || _uploadingAttachment
              ? null
              : (hasText ? _send : _startRecording),
        ),
      ],
    );
  }

  Widget _buildRecordingBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Cancel',
          onPressed: _cancelRecording,
        ),
        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _formatDuration(_recordingDuration),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton.filled(
          icon: const Icon(Icons.send),
          tooltip: 'Send voice note',
          onPressed: _finishRecording,
        ),
      ],
    );
  }

  Widget _buildBody(String? myId) {
    if (_loadError != null) {
      return Center(child: Text(_loadError.toString()));
    }
    final messages = _messages;
    if (messages == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (messages.isEmpty) {
      return const Center(child: Text('Say hello 👋'));
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMine = message.senderId == myId;
        return _MessageBubble(
          message: message,
          isMine: isMine,
          myId: myId,
          otherUserName: widget.otherUserName,
          onLongPress: message.isDeleted ? null : () => _showMessageActions(message, isMine),
        );
      },
    );
  }
}

class _ReplyPreviewBar extends StatelessWidget {
  const _ReplyPreviewBar({
    required this.message,
    required this.isMine,
    required this.otherUserName,
    required this.onCancel,
  });

  final ChatMessage message;
  final bool isMine;
  final String otherUserName;
  final VoidCallback onCancel;

  String get _preview {
    if (message.text.isNotEmpty) return message.text;
    if (message.isImage) return '📷 Photo';
    if (message.isAudio) return '🎤 Voice message';
    if (message.hasAttachment) return '📎 Document';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMine ? 'You' : otherUserName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(_preview, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onCancel),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.myId,
    required this.otherUserName,
    this.onLongPress,
  });

  final ChatMessage message;
  final bool isMine;
  final String? myId;
  final String otherUserName;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bubbleColor = isMine ? scheme.primary : scheme.surfaceContainerHighest;
    final textColor = isMine ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.isDeleted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block, size: 14, color: textColor.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      'This message was deleted',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                )
              else ...[
                if (message.isReply)
                  _QuotedMessage(
                    message: message,
                    myId: myId,
                    otherUserName: otherUserName,
                    textColor: textColor,
                  ),
                if (message.hasAttachment) _Attachment(message: message, textColor: textColor),
                if (message.text.isNotEmpty) ...[
                  if (message.hasAttachment || message.isReply) const SizedBox(height: 6),
                  Text(message.text, style: TextStyle(color: textColor)),
                ],
              ],
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(fontSize: 10.5, color: textColor.withValues(alpha: 0.7)),
                  ),
                  if (isMine && !message.isDeleted) ...[
                    const SizedBox(width: 4),
                    _MessageTicks(message: message, textColor: textColor),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// WhatsApp-style delivery ticks for the sender's own messages: single gray
/// (sent), double gray (delivered), double blue (seen).
class _MessageTicks extends StatelessWidget {
  const _MessageTicks({required this.message, required this.textColor});

  final ChatMessage message;
  final Color textColor;

  static const _seenColor = Color(0xFF34B7F1);

  @override
  Widget build(BuildContext context) {
    if (message.readAt != null) {
      return const Icon(Icons.done_all, size: 15, color: _seenColor);
    }
    if (message.deliveredAt != null) {
      return Icon(Icons.done_all, size: 15, color: textColor.withValues(alpha: 0.7));
    }
    return Icon(Icons.done, size: 15, color: textColor.withValues(alpha: 0.7));
  }
}

class _QuotedMessage extends StatelessWidget {
  const _QuotedMessage({
    required this.message,
    required this.myId,
    required this.otherUserName,
    required this.textColor,
  });

  final ChatMessage message;
  final String? myId;
  final String otherUserName;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final quotedLabel = message.replyToSenderId == myId ? 'You' : otherUserName;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: textColor.withValues(alpha: 0.6), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quotedLabel,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textColor),
          ),
          Text(
            message.replyToText ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: textColor.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _Attachment extends StatelessWidget {
  const _Attachment({required this.message, required this.textColor});

  final ChatMessage message;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    if (message.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          message.attachmentUrl!,
          width: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              height: 140,
              width: 200,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
          errorBuilder: (context, error, stackTrace) => const SizedBox(
            height: 100,
            width: 200,
            child: Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      );
    }
    if (message.isAudio) {
      return _AudioAttachment(url: message.attachmentUrl!, textColor: textColor);
    }
    return InkWell(
      onTap: () => launchUrl(Uri.parse(message.attachmentUrl!), mode: LaunchMode.externalApplication),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, color: textColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message.attachmentName ?? 'Attachment',
              style: TextStyle(color: textColor, decoration: TextDecoration.underline),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioAttachment extends StatefulWidget {
  const _AudioAttachment({required this.url, required this.textColor});

  final String url;
  final Color textColor;

  @override
  State<_AudioAttachment> createState() => _AudioAttachmentState();
}

class _AudioAttachmentState extends State<_AudioAttachment> {
  final _player = AudioPlayer();
  bool _playing = false;
  bool _loading = false;
  bool _hasError = false;
  bool _completed = false;
  String? _errorMessage;
  String? _localPath;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playing = state == PlayerState.playing);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      // Some platforms don't reliably emit a distinct onPlayerStateChanged
      // event for natural completion, so _playing can otherwise get stuck
      // true — every later tap would then think it should *pause* an
      // already-stopped player instead of restarting it.
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _playing = false;
          _completed = true;
        });
      }
    });
    // Download up front, like WhatsApp showing the full length before you
    // ever hit play, rather than only fetching it on first tap.
    _ensureDownloaded();
  }

  /// Voice notes are downloaded once into permanent app storage (matching
  /// how WhatsApp keeps voice notes on-device rather than re-streaming them)
  /// and played from local disk from then on — this also sidesteps any
  /// quirks in ExoPlayer's progressive-HTTP data source (range requests,
  /// chunked transfer, redirects) that a plain network `UrlSource` can hit.
  Future<void> _ensureDownloaded() async {
    if (_localPath != null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/voice_notes');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);
      final segments = Uri.parse(widget.url).pathSegments;
      final filename = segments.isNotEmpty ? segments.last : 'voice_note.m4a';
      final file = File('${cacheDir.path}/$filename');

      if (!await file.exists() || await file.length() == 0) {
        final client = HttpClient();
        try {
          final request = await client.getUrl(Uri.parse(widget.url));
          final response = await request.close();
          if (response.statusCode != 200) {
            throw Exception('Download failed: HTTP ${response.statusCode}');
          }
          final bytes = <int>[];
          await for (final chunk in response) {
            bytes.addAll(chunk);
          }
          if (bytes.isEmpty) throw Exception('Downloaded file was empty');
          await file.writeAsBytes(bytes, flush: true);
        } finally {
          client.close();
        }
      }

      // Prefetch duration only — actual playback start still goes through
      // _toggle, which issues a fresh play() after natural completion
      // rather than resume() (see there for why).
      await _player.setSourceDeviceFile(file.path);
      _localPath = file.path;
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _toggle() async {
    if (_hasError) {
      // Retry from scratch.
      setState(() {
        _hasError = false;
        _errorMessage = null;
        _localPath = null;
      });
    }
    setState(() => _loading = true);
    try {
      if (_playing) {
        await _player.pause();
      } else {
        await _ensureDownloaded();
        if (_hasError) return;
        if (_completed) {
          // Resuming a player that already ran to completion is unreliable
          // on some platforms — that was the cause of voice notes not
          // replaying. A fresh play() call always restarts cleanly.
          _completed = false;
          await _player.stop();
          await _player.play(DeviceFileSource(_localPath!));
        } else {
          // Plain pause -> resume (e.g. the user paused partway through) —
          // continues from where it was, not from the beginning.
          await _player.resume();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final shown = _playing || _position > Duration.zero ? _position : _duration;
    final maxMs = _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0;
    final valueMs = _position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return SizedBox(
      width: 200,
      child: Row(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: _loading
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: CircularProgressIndicator(strokeWidth: 2, color: widget.textColor),
                  )
                : IconButton(
                    icon: Icon(
                      _hasError
                          ? Icons.error_outline
                          : (_playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
                      color: widget.textColor,
                      size: 34,
                    ),
                    onPressed: _toggle,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: widget.textColor,
                    inactiveTrackColor: widget.textColor.withValues(alpha: 0.3),
                    thumbColor: widget.textColor,
                    overlayColor: widget.textColor.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    min: 0,
                    max: maxMs,
                    value: valueMs,
                    onChanged: _hasError || maxMs <= 1
                        ? null
                        : (v) => setState(() => _position = Duration(milliseconds: v.toInt())),
                    onChangeEnd: (v) => _player.seek(Duration(milliseconds: v.toInt())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _hasError
                        ? 'Tap to retry${_errorMessage != null ? ' ($_errorMessage)' : ''}'
                        : _format(shown),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: widget.textColor, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
