import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/contact_tile.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

/// Home Screen – displays the list of chats, a search FAB,
/// and bottom navigation between Chats, Contacts, and Profile tabs.
class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  List<ChatModel> _chats = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final raw = await ApiService.instance.getChats();
      setState(() {
        _chats = raw
            .map((j) => ChatModel.fromJson(j as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToChat(ChatModel chat) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final userId = auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        title: const Text('NexusChat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _showSearchSheet,
            tooltip: 'Search users',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'logout') {
                await auth.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              } else if (value == 'profile') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (i) => setState(() => _selectedIndex = i),
          tabs: const [
            Tab(text: 'CHATS'),
            Tab(text: 'CONTACTS'),
            Tab(text: 'PROFILE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Chats Tab ──────────────────────────────────────────────────────
          RefreshIndicator(
            onRefresh: _loadChats,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 8),
                            Text(_error!),
                            TextButton(
                                onPressed: _loadChats, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _chats.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 64,
                                    color: AppTheme.mediumGrey.withAlpha(102)),
                                const SizedBox(height: 12),
                                Text('No chats yet',
                                    style: TextStyle(
                                        color: AppTheme.mediumGrey,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('Tap the search icon to start one',
                                    style: TextStyle(
                                        color: AppTheme.mediumGrey,
                                        fontSize: 13)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _chats.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, indent: 72),
                            itemBuilder: (_, i) {
                              final chat = _chats[i];
                              return ContactTile(
                                name: chat.displayName(userId),
                                avatarUrl: chat.displayAvatar(userId),
                                subtitle: _chatSubtitle(chat),
                                trailingTime: _formatTime(chat.lastMessageAt),
                                isOnline: chat.otherIsOnline(userId),
                                onTap: () => _navigateToChat(chat),
                              );
                            },
                          ),
          ),
          // ── Contacts Tab ───────────────────────────────────────────────────
          const _ContactsTab(),
          // ── Profile Tab ────────────────────────────────────────────────────
          const ProfileScreen(embedded: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSearchSheet,
        backgroundColor: AppTheme.lightGreen,
        tooltip: 'New chat',
        child: const Icon(Icons.chat_rounded, color: Colors.white),
      ),
    );
  }

  String _chatSubtitle(ChatModel chat) {
    final msg = chat.lastMessage;
    if (msg == null) return 'No messages yet';
    if (msg.isDeleted) return 'This message was deleted';
    switch (msg.type) {
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎙 Audio';
      case MessageType.file:
        return '📎 File';
      default:
        return msg.content;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${dt.day}/${dt.month}';
  }

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SearchSheet(
        onChatCreated: (chat) {
          Navigator.of(ctx).pop();
          _navigateToChat(chat);
        },
      ),
    );
  }
}

// ── Search Sheet ──────────────────────────────────────────────────────────────

class _SearchSheet extends StatefulWidget {
  final void Function(ChatModel) onChatCreated;
  const _SearchSheet({required this.onChatCreated});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await ApiService.instance.searchUsers(query.trim());
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _openChat(String userId) async {
    try {
      final chatJson =
          await ApiService.instance.createOrGetDirectChat(userId);
      final chat = ChatModel.fromJson(chatJson);
      widget.onChatCreated(chat);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const Text('New Chat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search users by name or email…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final user = _results[i] as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (user['profilePicUrl'] as String?)
                                  ?.isNotEmpty ==
                              true
                          ? NetworkImage(user['profilePicUrl'] as String)
                          : null,
                      backgroundColor: AppTheme.tealGreen,
                      child: (user['profilePicUrl'] as String?)?.isEmpty != false
                          ? Text(
                              (user['username'] as String? ?? 'U')[0]
                                  .toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    title: Text(user['username'] as String? ?? ''),
                    subtitle: Text(user['email'] as String? ?? ''),
                    onTap: () => _openChat(user['_id'] as String),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contacts Tab ──────────────────────────────────────────────────────────────

class _ContactsTab extends StatefulWidget {
  const _ContactsTab();

  @override
  State<_ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<_ContactsTab> {
  List<dynamic> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final contacts = await ApiService.instance.getContacts();
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_contacts.isEmpty) {
      return const Center(child: Text('No contacts yet'));
    }
    return ListView.builder(
      itemCount: _contacts.length,
      itemBuilder: (_, i) {
        final c = _contacts[i] as Map<String, dynamic>;
        return ContactTile(
          name: c['username'] as String? ?? '',
          avatarUrl: c['profilePicUrl'] as String? ?? '',
          subtitle: c['status'] as String? ?? '',
          isOnline: c['isOnline'] as bool? ?? false,
          onTap: () {},
        );
      },
    );
  }
}
