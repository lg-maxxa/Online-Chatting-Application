import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../utils/constants.dart';

typedef MessageCallback = void Function(Map<String, dynamic> message);
typedef PresenceCallback = void Function(String userId);
typedef TypingCallback = void Function(String userId);
typedef ReadCallback = void Function(String messageId, String readerId);

/// Manages the Socket.io connection and event dispatching.
class SocketService extends ChangeNotifier {
  io.Socket? _socket;
  bool _connected = false;
  bool get isConnected => _connected;

  // ── Connect ────────────────────────────────────────────────────────────────
  void connect(String userId, String token) {
    if (_socket != null && _connected) return;

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'userId': userId, 'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      notifyListeners();
      debugPrint('🔌 Socket connected');
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      notifyListeners();
      debugPrint('🔌 Socket disconnected');
    });

    _socket!.onConnectError((err) {
      debugPrint('🔌 Socket connect error: $err');
    });
  }

  // ── Disconnect ─────────────────────────────────────────────────────────────
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
    notifyListeners();
  }

  // ── Chat Room Management ───────────────────────────────────────────────────
  void joinChat(String chatId) {
    _socket?.emit('join_chat', chatId);
  }

  void leaveChat(String chatId) {
    _socket?.emit('leave_chat', chatId);
  }

  // ── Send a message notification via socket ─────────────────────────────────
  void sendMessageEvent(String chatId, Map<String, dynamic> message) {
    _socket?.emit('send_message', {'chatId': chatId, 'message': message});
  }

  // ── Typing indicators ──────────────────────────────────────────────────────
  void startTyping(String chatId, String userId) {
    _socket?.emit('typing_start', {'chatId': chatId, 'userId': userId});
  }

  void stopTyping(String chatId, String userId) {
    _socket?.emit('typing_stop', {'chatId': chatId, 'userId': userId});
  }

  // ── Message read receipt ───────────────────────────────────────────────────
  void emitMessageRead(String chatId, String messageId, String readerId) {
    _socket?.emit('message_read', {
      'chatId': chatId,
      'messageId': messageId,
      'readerId': readerId,
    });
  }

  // ── Event Listeners ────────────────────────────────────────────────────────
  void onNewMessage(MessageCallback callback) {
    _socket?.on('receive_message', (data) {
      callback(Map<String, dynamic>.from(data as Map));
    });
  }

  void onTypingStart(TypingCallback callback) {
    _socket?.on('typing_start', (data) {
      callback((data as Map)['userId'] as String);
    });
  }

  void onTypingStop(TypingCallback callback) {
    _socket?.on('typing_stop', (data) {
      callback((data as Map)['userId'] as String);
    });
  }

  void onUserOnline(PresenceCallback callback) {
    _socket?.on('user_online', (data) {
      callback((data as Map)['userId'] as String);
    });
  }

  void onUserOffline(PresenceCallback callback) {
    _socket?.on('user_offline', (data) {
      callback((data as Map)['userId'] as String);
    });
  }

  void onMessageRead(ReadCallback callback) {
    _socket?.on('message_read', (data) {
      final m = data as Map;
      callback(m['messageId'] as String, m['readerId'] as String);
    });
  }

  // ── Remove listeners (cleanup) ─────────────────────────────────────────────
  void offNewMessage() => _socket?.off('receive_message');
  void offTyping() {
    _socket?.off('typing_start');
    _socket?.off('typing_stop');
  }
  void offPresence() {
    _socket?.off('user_online');
    _socket?.off('user_offline');
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
