import 'user_model.dart';
import 'message_model.dart';

/// Data model for a Chat (matches backend Chat schema)
class ChatModel {
  final String id;
  final bool isGroup;
  final String groupName;
  final String groupIcon;
  final List<UserModel> participants;
  final MessageModel? lastMessage;
  final DateTime lastMessageAt;

  const ChatModel({
    required this.id,
    this.isGroup = false,
    this.groupName = '',
    this.groupIcon = '',
    required this.participants,
    this.lastMessage,
    required this.lastMessageAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['_id'] as String,
      isGroup: json['isGroup'] as bool? ?? false,
      groupName: json['groupName'] as String? ?? '',
      groupIcon: json['groupIcon'] as String? ?? '',
      participants: (json['participants'] as List<dynamic>)
          .map((p) => UserModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : DateTime.now(),
    );
  }

  /// Returns the display name for a chat.
  /// For 1-on-1 chats, returns the other participant's username.
  String displayName(String currentUserId) {
    if (isGroup) return groupName;
    final other = participants.where((p) => p.id != currentUserId).firstOrNull;
    return other?.username ?? 'Unknown';
  }

  /// Returns the avatar URL for a chat.
  String displayAvatar(String currentUserId) {
    if (isGroup) return groupIcon;
    final other = participants.where((p) => p.id != currentUserId).firstOrNull;
    return other?.profilePicUrl ?? '';
  }

  /// Returns the online status for direct chats.
  bool otherIsOnline(String currentUserId) {
    if (isGroup) return false;
    final other = participants.where((p) => p.id != currentUserId).firstOrNull;
    return other?.isOnline ?? false;
  }
}
