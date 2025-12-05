
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config.dart';
import '../../../constants/app_colors.dart';
import '../../../models/message.dart';
import '../../../services/message_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  MessagesScreenState createState() => MessagesScreenState();
}

class MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Uint8List? _attachmentBytes;
  String? _attachmentName;
  String? _attachmentMime;
  int? _editingMessageId;
  MessageModel? _replyingTo;

  bool _loading = false;
  bool _sending = false;
  List<MessageModel> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
    });
    try {
      final msgs = await MessageService.getMyMessages();
      setState(() {
        _messages = msgs;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load messages: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final hasAttachment = _attachmentBytes != null && _attachmentName != null;
    if (text.isEmpty && !hasAttachment) return;
    if (_sending) return;

    setState(() {
      _sending = true;
    });

    try {
      // If editing, update existing message body only.
      if (_editingMessageId != null) {
        await MessageService.editMessage(_editingMessageId!, text);
      } else {
        // If replying to a specific message, prepend a simple quoted snippet
        // that can include text or attachment info.
        String bodyToSend = text;
        if (_replyingTo != null) {
          final snippet = _buildReplySnippet(_replyingTo!);
          bodyToSend = '> $snippet\n\n$text';
        }

        // Decide which attachment bytes/name/mime to send:
        // - If user selected a new attachment, use that.
        // - Else, if replying to an image-only message, clone that image as the attachment.
        Uint8List? bytesToSend = _attachmentBytes;
        String? nameToSend = _attachmentName;
        String? mimeToSend = _attachmentMime;

        if (bytesToSend == null &&
            _replyingTo != null &&
            _isImageMessage(_replyingTo!)) {
          final url = _replyImageUrl(_replyingTo!);
          if (url != null && url.isNotEmpty) {
            try {
              final resp = await http.get(Uri.parse(url));
              if (resp.statusCode == 200) {
                bytesToSend = resp.bodyBytes;
                nameToSend =
                    _replyingTo!.attachmentOriginalName ?? 'image_reply.jpg';
                mimeToSend = 'image/jpeg';
              }
            } catch (_) {
              // If cloning fails, just send without attachment.
            }
          }
        }

        await MessageService.sendMessage(
          bodyToSend,
          attachmentBytes: bytesToSend,
          attachmentName: nameToSend,
          attachmentMime: mimeToSend,
        );
      }
      _controller.clear();
      _attachmentBytes = null;
      _attachmentName = null;
      _attachmentMime = null;
      _editingMessageId = null;
      _replyingTo = null;
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    // For now, reuse image_picker for images; other files could be added later.
    // ignore: use_build_context_synchronously
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final mime = lookupMimeType(picked.name) ?? 'image/jpeg';

    setState(() {
      _attachmentBytes = bytes;
      _attachmentName = picked.name;
      _attachmentMime = mime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadMessages,
            child: _loading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      // In the app the logged-in user is the farmer, so treat farmer
                      // messages as "self" and align/color them as such.
                      final isMe = msg.isFromFarmer;
                      final align =
                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
                      final bubbleColor =
                          isMe ? AppColors.primary : Colors.grey.shade200;
                      final textColor =
                          isMe ? Colors.white : Colors.black87;
                      final attachmentUrl = msg.attachmentUrl(AppConfig.baseUrl);

                      return Column(
                        crossAxisAlignment: align,
                        children: [
                          GestureDetector(
                            onLongPress: () =>
                                _showMessageActions(context, msg, isMe),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // For replies with images/files, show the attachment
                                  // first, then the message text so the user clearly
                                  // sees what they replied to before their reply.
                                  if (attachmentUrl != null)
                                    Padding(
                                      padding: EdgeInsets.only(
                                          bottom: msg.body.isNotEmpty ? 8 : 0),
                                      child: _buildAttachmentWidget(
                                        attachmentUrl,
                                        msg.attachmentType,
                                        msg.attachmentOriginalName,
                                        isMe,
                                      ),
                                    ),
                                  if (msg.body.isNotEmpty)
                                    Text(
                                      msg.body,
                                      style: TextStyle(color: textColor),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _formatTime(msg.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_attachmentBytes != null && _attachmentName != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_attachmentMime != null &&
                                  _attachmentMime!.startsWith('image/'))
                                Container(
                                  width: 28,
                                  height: 28,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: Colors.grey.shade200,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.memory(
                                    _attachmentBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: Colors.grey.shade200,
                                  ),
                                  child: Text(
                                    (_attachmentName!.split('.').last)
                                        .toUpperCase(),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  _attachmentName!,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _attachmentBytes = null;
                                    _attachmentName = null;
                                    _attachmentMime = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      if (_replyingTo != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.reply, size: 16),
                              const SizedBox(width: 6),
                              if (_replyImageUrl(_replyingTo!) != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: Image.network(
                                        _replyImageUrl(_replyingTo!)!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, _, __) =>
                                            const Icon(Icons.image, size: 18),
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  _buildReplySnippet(_replyingTo!),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _replyingTo = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: _editingMessageId != null
                              ? 'Edit message…'
                              : 'Type a message to admin…',
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded),
                  color: Colors.grey.shade700,
                  onPressed: _sending ? null : _pickAttachment,
                ),
                IconButton(
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _editingMessageId != null
                              ? Icons.check_rounded
                              : Icons.send_rounded,
                        ),
                  color: AppColors.primary,
                  onPressed: _sending ? null : _send,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    // 12-hour format with AM/PM to match web: e.g. 12:00 AM / 11:59 PM
    return DateFormat('hh:mm a').format(dt);
  }

  /// Build a short snippet shown when replying to a specific message.
  /// If the original has text, use that; otherwise fall back to attachment info.
  String _buildReplySnippet(MessageModel msg) {
    if (msg.body.isNotEmpty) {
      return msg.body.length > 80
          ? '${msg.body.substring(0, 80)}…'
          : msg.body;
    }

    final name = msg.attachmentOriginalName ?? 'Attachment';
    if (_isImageMessage(msg)) {
      return '[Image] $name';
    }
    if (msg.attachmentType != null && msg.attachmentType!.isNotEmpty) {
      return '[File] $name';
    }

    return 'Message';
  }

  bool _isImageMessage(MessageModel msg) {
    final type = (msg.attachmentType ?? '').toLowerCase();
    if (type == 'image' || type.startsWith('image/')) return true;

    final name = (msg.attachmentOriginalName ?? '').toLowerCase();
    return name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.gif') ||
        name.endsWith('.webp');
  }

  String? _replyImageUrl(MessageModel msg) {
    if (!_isImageMessage(msg)) return null;
    final url = msg.attachmentUrl(AppConfig.baseUrl);
    if (url == null || url.isEmpty) return null;
    return url;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open attachment')),
      );
    }
  }

  Future<void> _showImageViewer(String url) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black.withValues(alpha: 0.9),
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  onPressed: () {
                    _openUrl(url);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessageActions(
    BuildContext context,
    MessageModel msg,
    bool isMe,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final messenger = ScaffoldMessenger.of(context);
        return SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: [
                _MessageActionButton(
                  icon: Icons.content_copy,
                  label: 'Copy',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await Clipboard.setData(ClipboardData(text: msg.body));
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Message copied')),
                    );
                  },
                ),
                _MessageActionButton(
                  icon: Icons.reply,
                  label: 'Reply',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _replyingTo = msg;
                    });
                  },
                ),
                if (isMe)
                  _MessageActionButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _editingMessageId = msg.id;
                        _controller.text = msg.body;
                        _replyingTo = null;
                      });
                    },
                  ),
                if (isMe)
                  _MessageActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final messenger2 = ScaffoldMessenger.of(context);
                      final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Delete message'),
                              content: const Text(
                                  'Are you sure you want to delete this message?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dCtx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dCtx).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (!confirmed) return;

                      try {
                        await MessageService.deleteMessage(msg.id);
                        await _loadMessages();
                      } catch (e) {
                        if (!mounted) return;
                        messenger2.showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentWidget(
    String url,
    String? type,
    String? name,
    bool isMe,
  ) {
    final isImage = (type ?? '').startsWith('image');
    if (isImage) {
      return GestureDetector(
        onTap: () => _showImageViewer(url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: 220,
            height: 220,
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _openUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isMe ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, size: 16),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                name ?? 'Attachment',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MessageActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}


