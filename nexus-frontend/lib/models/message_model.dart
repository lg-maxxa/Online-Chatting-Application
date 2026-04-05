/// Supported message types
enum MessageType { text, image, video, audio, file, location }

/// Data model for a Message (matches backend Message schema)
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final MessageType type;
  final String mediaUrl;
  final bool isDeleted;
  final bool isRead;
  final String? replyToId;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName = '',
    this.senderAvatar = '',
    this.content = '',
    this.type = MessageType.text,
    this.mediaUrl = '',
    this.isDeleted = false,
    this.isRead = false,
    this.replyToId,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final senderRaw = json['senderId'];
    final senderId = senderRaw is Map ? senderRaw['_id'] as String : senderRaw as String;
    final senderName = senderRaw is Map ? senderRaw['username'] as String? ?? '' : '';
    final senderAvatar = senderRaw is Map ? senderRaw['profilePicUrl'] as String? ?? '' : '';

    MessageType type;
    switch (json['type'] as String? ?? 'text') {
      case 'image':
        type = MessageType.image;
        break;
      case 'video':
        type = MessageType.video;
        break;
      case 'audio':
        type = MessageType.audio;
        break;
      case 'file':
        type = MessageType.file;
        break;
      case 'location':
        type = MessageType.location;
        break;
      default:
        type = MessageType.text;
    }

    return MessageModel(
      id: json['_id'] as String,
      chatId: json['chatId'] as String? ?? '',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: json['content'] as String? ?? '',
      type: type,
      mediaUrl: json['mediaUrl'] as String? ?? '',
      isDeleted: json['isDeleted'] as bool? ?? false,
      isRead: (json['readBy'] as List<dynamic>?)?.isNotEmpty ?? false,
      replyToId: (json['replyTo'] as Map<String, dynamic>?)?['_id'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool isMine(String currentUserId) => senderId == currentUserId;
}
