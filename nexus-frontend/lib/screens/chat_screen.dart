import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../utils/theme.dart';
import '../widgets/chat_bubble.dart';

/// Full-featured chat screen with real-time messaging, typing indicators,
/// read receipts, and media support.
class ChatScreen extends StatefulWidget {
  final ChatModel chat;
  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _otherIsTyping = false;
  String? _replyToId;
  String? _replyToContent;
  Timer? _typingTimer;
  bool _isTyping = false;

  late final SocketService _socket;
  late final AuthService _auth;
  String get _currentUserId => _auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthService>();
    _socket = context.read<SocketService>();

    _socket.joinChat(widget.chat.id);
    _loadMessages();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _socket.leaveChat(widget.chat.id);
    _socket.offNewMessage();
    _socket.offTyping();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupSocketListeners() {
    _socket.onNewMessage((msg) {
      final message = MessageModel.fromJson(msg);
      if (message.chatId == widget.chat.id || message.senderId != _currentUserId) {
        setState(() => _messages.add(message));
        _scrollToBottom();
        // Mark as read
        ApiService.instance.markMessageRead(message.id);
        _socket.emitMessageRead(widget.chat.id, message.id, _currentUserId);
      }
    });

    _socket.onTypingStart((userId) {
      if (userId != _currentUserId) setState(() => _otherIsTyping = true);
    });

    _socket.onTypingStop((userId) {
      if (userId != _currentUserId) setState(() => _otherIsTyping = false);
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final raw = await ApiService.instance.getMessages(widget.chat.id);
      setState(() {
        _messages.addAll(
          raw.map((j) => MessageModel.fromJson(j as Map<String, dynamic>)),
        );
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    _stopTypingIndicator();

    setState(() => _isSending = true);
    try {
      final json = await ApiService.instance.sendMessage(
        widget.chat.id,
        text,
        replyTo: _replyToId,
      );
      final message = MessageModel.fromJson(json);
      setState(() {
        _messages.add(message);
        _replyToId = null;
        _replyToContent = null;
        _isSending = false;
      });
      _socket.sendMessageEvent(widget.chat.id, json);
      _scrollToBottom();
    } catch (_) {
      setState(() => _isSending = false);
    }
  }

  void _onTextChanged(String value) {
    if (value.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _socket.startTyping(widget.chat.id, _currentUserId);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), _stopTypingIndicator);
  }

  void _stopTypingIndicator() {
    if (_isTyping) {
      _isTyping = false;
      _socket.stopTyping(widget.chat.id, _currentUserId);
    }
  }

  void _setReply(MessageModel msg) {
    setState(() {
      _replyToId = msg.id;
      _replyToContent = msg.isDeleted ? 'Deleted message' : msg.content;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatName = widget.chat.displayName(_currentUserId);
    final chatAvatar = widget.chat.displayAvatar(_currentUserId);
    final isOnline = widget.chat.otherIsOnline(_currentUserId);

    return Scaffold(
      backgroundColor: AppTheme.chatBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: chatAvatar.isNotEmpty
                  ? NetworkImage(chatAvatar)
                  : null,
              backgroundColor: AppTheme.tealGreen,
              child: chatAvatar.isEmpty
                  ? Text(chatName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white))
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chatName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                Text(
                  _otherIsTyping
                      ? 'typing…'
                      : isOnline
                          ? 'online'
                          : 'last seen ${timeago.format(widget.chat.lastMessageAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.white),
            onPressed: () {},
            tooltip: 'Video call',
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.white),
            onPressed: () {},
            tooltip: 'Voice call',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'media', child: Text('View media')),
              PopupMenuItem(value: 'mute', child: Text('Mute notifications')),
              PopupMenuItem(value: 'clear', child: Text('Clear chat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages List ────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          return GestureDetector(
                            onLongPress: () => _showMessageOptions(msg),
                            child: ChatBubble(
                              message: msg,
                              isMine: msg.isMine(_currentUserId),
                              onReply: () => _setReply(msg),
                            ),
                          );
                        },
                      ),
          ),

          // ── Typing Indicator ─────────────────────────────────────────────
          if (_otherIsTyping)
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _TypingIndicator(),
              ),
            ),

          // ── Reply Preview ────────────────────────────────────────────────
          if (_replyToContent != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                      width: 3,
                      height: 36,
                      color: AppTheme.tealGreen,
                      margin: const EdgeInsets.only(right: 8)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Replying to',
                            style: TextStyle(
                                color: AppTheme.tealGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                        Text(_replyToContent!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.darkGrey, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () =>
                        setState(() => _replyToId = _replyToContent = null),
                  ),
                ],
              ),
            ),

          // ── Input Bar ────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined,
                        color: AppTheme.mediumGrey),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: _onTextChanged,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        filled: true,
                        fillColor: AppTheme.offWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.attach_file,
                        color: AppTheme.mediumGrey),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.lightGreen,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(MessageModel msg) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('Reply'),
            onTap: () {
              Navigator.of(context).pop();
              _setReply(msg);
            },
          ),
          if (msg.isMine(_currentUserId))
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.of(context).pop();
                await ApiService.instance.deleteMessage(msg.id);
                setState(() {
                  final idx = _messages.indexWhere((m) => m.id == msg.id);
                  if (idx >= 0) {
                    _messages[idx] = MessageModel(
                      id: msg.id,
                      chatId: msg.chatId,
                      senderId: msg.senderId,
                      createdAt: msg.createdAt,
                      isDeleted: true,
                    );
                  }
                });
              },
            ),
        ],
      ),
    );
  }
}

// ── Typing Indicator (animated dots) ──────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true, min: i * 200 / 1000),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: 6).animate(c))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.mediumGrey
                    .withAlpha(((_animations[i].value / 6) * 200 + 55).round()),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}
