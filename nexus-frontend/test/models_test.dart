import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_chat/models/user_model.dart';
import 'package:nexus_chat/models/message_model.dart';
import 'package:nexus_chat/models/chat_model.dart';

void main() {
  group('UserModel', () {
    final sampleJson = {
      '_id': 'user123',
      'username': 'alice',
      'email': 'alice@example.com',
      'phoneNumber': '+1234567890',
      'profilePicUrl': 'https://example.com/avatar.jpg',
      'status': 'Hello world!',
      'isOnline': true,
      'lastSeen': '2024-06-01T12:00:00.000Z',
    };

    test('fromJson parses correctly', () {
      final user = UserModel.fromJson(sampleJson);
      expect(user.id, 'user123');
      expect(user.username, 'alice');
      expect(user.email, 'alice@example.com');
      expect(user.isOnline, true);
    });

    test('toJson round-trips', () {
      final user = UserModel.fromJson(sampleJson);
      final json = user.toJson();
      expect(json['_id'], 'user123');
      expect(json['username'], 'alice');
    });

    test('copyWith produces updated model', () {
      final user = UserModel.fromJson(sampleJson);
      final updated = user.copyWith(username: 'bob', isOnline: false);
      expect(updated.username, 'bob');
      expect(updated.isOnline, false);
      expect(updated.email, user.email); // unchanged
    });

    test('default status applied when missing', () {
      final json = Map<String, dynamic>.from(sampleJson)..remove('status');
      final user = UserModel.fromJson(json);
      expect(user.status, 'Hey there! I am using NexusChat.');
    });
  });

  group('MessageModel', () {
    final sampleJson = {
      '_id': 'msg001',
      'chatId': 'chat123',
      'senderId': {
        '_id': 'user123',
        'username': 'alice',
        'profilePicUrl': '',
      },
      'content': 'Hello!',
      'type': 'text',
      'mediaUrl': '',
      'isDeleted': false,
      'readBy': [],
      'createdAt': '2024-06-01T12:00:00.000Z',
    };

    test('fromJson parses text message', () {
      final msg = MessageModel.fromJson(sampleJson);
      expect(msg.id, 'msg001');
      expect(msg.content, 'Hello!');
      expect(msg.type, MessageType.text);
      expect(msg.senderId, 'user123');
      expect(msg.senderName, 'alice');
    });

    test('isMine returns true for own message', () {
      final msg = MessageModel.fromJson(sampleJson);
      expect(msg.isMine('user123'), isTrue);
      expect(msg.isMine('other'), isFalse);
    });

    test('isRead false when readBy empty', () {
      final msg = MessageModel.fromJson(sampleJson);
      expect(msg.isRead, isFalse);
    });

    test('parses image type correctly', () {
      final json = Map<String, dynamic>.from(sampleJson)
        ..['type'] = 'image'
        ..['mediaUrl'] = 'https://example.com/img.jpg';
      final msg = MessageModel.fromJson(json);
      expect(msg.type, MessageType.image);
    });
  });

  group('ChatModel', () {
    final user1Json = {
      '_id': 'u1',
      'username': 'alice',
      'email': 'alice@example.com',
      'isOnline': true,
    };
    final user2Json = {
      '_id': 'u2',
      'username': 'bob',
      'email': 'bob@example.com',
      'isOnline': false,
    };

    final chatJson = {
      '_id': 'chat123',
      'isGroup': false,
      'groupName': '',
      'participants': [user1Json, user2Json],
      'lastMessageAt': '2024-06-01T12:00:00.000Z',
    };

    test('displayName returns other participant name', () {
      final chat = ChatModel.fromJson(chatJson);
      expect(chat.displayName('u1'), 'bob');
      expect(chat.displayName('u2'), 'alice');
    });

    test('otherIsOnline reflects correct status', () {
      final chat = ChatModel.fromJson(chatJson);
      // alice is online, bob is not
      expect(chat.otherIsOnline('u2'), isTrue);  // other = alice (online)
      expect(chat.otherIsOnline('u1'), isFalse); // other = bob (offline)
    });

    test('displayName returns groupName for groups', () {
      final groupJson = Map<String, dynamic>.from(chatJson)
        ..['isGroup'] = true
        ..['groupName'] = 'Team Chat';
      final chat = ChatModel.fromJson(groupJson);
      expect(chat.displayName('u1'), 'Team Chat');
    });
  });
}
