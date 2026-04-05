import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../utils/theme.dart';

/// A single chat message bubble (sent = right/green, received = left/white).
class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final VoidCallback? onReply;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMine ? AppTheme.sentBubble : AppTheme.receivedBubble;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMine ? 16 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 16),
    );

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onHorizontalDragEnd: (_) => onReply?.call(),
        child: Container(
          margin: EdgeInsets.only(
            top: 2,
            bottom: 2,
            left: isMine ? 48 : 0,
            right: isMine ? 0 : 48,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Sender name (group chats) ─────────────────────────────
              if (!isMine && message.senderName.isNotEmpty)
                Text(
                  message.senderName,
                  style: const TextStyle(
                    color: AppTheme.tealGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),

              // ── Deleted ───────────────────────────────────────────────
              if (message.isDeleted)
                const Text(
                  'This message was deleted',
                  style: TextStyle(
                    color: AppTheme.mediumGrey,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                )
              else ...[
                // ── Media ─────────────────────────────────────────────
                if (message.type == MessageType.image &&
                    message.mediaUrl.isNotEmpty)
                  _MediaPreview(url: message.mediaUrl, type: message.type),

                if (message.type == MessageType.video &&
                    message.mediaUrl.isNotEmpty)
                  _MediaPreview(url: message.mediaUrl, type: message.type),

                if (message.type == MessageType.audio &&
                    message.mediaUrl.isNotEmpty)
                  _AudioPreview(url: message.mediaUrl),

                if (message.type == MessageType.file &&
                    message.mediaUrl.isNotEmpty)
                  _FilePreview(url: message.mediaUrl),

                // ── Text content ──────────────────────────────────────
                if (message.content.isNotEmpty)
                  Text(
                    message.content,
                    style: const TextStyle(
                        fontSize: 15, color: AppTheme.black, height: 1.3),
                  ),
              ],

              // ── Timestamp + Read receipt ──────────────────────────────
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.createdAt.toLocal()),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.mediumGrey),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.isRead
                          ? const Color(0xFF4FC3F7)
                          : AppTheme.mediumGrey,
                    ),
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

// ── Media preview placeholder ──────────────────────────────────────────────────

class _MediaPreview extends StatelessWidget {
  final String url;
  final MessageType type;
  const _MediaPreview({required this.url, required this.type});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {/* Open full-screen viewer */},
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          width: 220,
          height: 160,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 220,
            height: 100,
            color: AppTheme.lightGrey,
            child: Icon(
                type == MessageType.image ? Icons.broken_image : Icons.videocam,
                color: AppTheme.mediumGrey),
          ),
        ),
      ),
    );
  }
}

class _AudioPreview extends StatelessWidget {
  final String url;
  const _AudioPreview({required this.url});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.play_circle_outline, color: AppTheme.tealGreen),
        const SizedBox(width: 6),
        Container(
          width: 140,
          height: 3,
          color: AppTheme.lightGrey,
        ),
        const SizedBox(width: 6),
        const Text('0:00', style: TextStyle(fontSize: 12, color: AppTheme.mediumGrey)),
      ],
    );
  }
}

class _FilePreview extends StatelessWidget {
  final String url;
  const _FilePreview({required this.url});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.insert_drive_file_outlined, color: AppTheme.tealGreen),
        const SizedBox(width: 8),
        Text(
          url.split('/').last,
          style: const TextStyle(
              fontSize: 14, decoration: TextDecoration.underline),
        ),
      ],
    );
  }
}
