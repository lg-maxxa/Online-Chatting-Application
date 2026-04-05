import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

/// Handles all REST API calls to the NexusChat backend.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // Auth token set after login
  String? _token;

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Helpers ────────────────────────────────────────────────────────────────

  Uri _uri(String path) => Uri.parse('${AppConstants.baseUrl}$path');

  Future<dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Future.value(body);
    }
    throw ApiException(
      message: body['message'] as String? ?? 'Unknown error',
      statusCode: response.statusCode,
    );
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String phoneNumber = '',
  }) async {
    final res = await http.post(
      _uri('/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
      }),
    );
    return await _handleResponse(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      _uri('/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return await _handleResponse(res) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await http.post(_uri('/auth/logout'), headers: _headers);
    clearToken();
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(_uri('/auth/me'), headers: _headers);
    return await _handleResponse(res) as Map<String, dynamic>;
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<List<dynamic>> searchUsers(String query) async {
    final res = await http.get(
      _uri('/users/search?q=${Uri.encodeComponent(query)}'),
      headers: _headers,
    );
    final data = await _handleResponse(res) as Map<String, dynamic>;
    return data['users'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getUser(String userId) async {
    final res = await http.get(_uri('/users/$userId'), headers: _headers);
    return (await _handleResponse(res) as Map<String, dynamic>)['user']
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updates) async {
    final res = await http.patch(
      _uri('/users/me/profile'),
      headers: _headers,
      body: jsonEncode(updates),
    );
    return (await _handleResponse(res) as Map<String, dynamic>)['user']
        as Map<String, dynamic>;
  }

  Future<List<dynamic>> getContacts() async {
    final res = await http.get(_uri('/users/me/contacts'), headers: _headers);
    final data = await _handleResponse(res) as Map<String, dynamic>;
    return data['contacts'] as List<dynamic>;
  }

  Future<void> addContact(String contactId) async {
    await http.post(
      _uri('/users/me/contacts'),
      headers: _headers,
      body: jsonEncode({'contactId': contactId}),
    );
  }

  // ── Chats ──────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getChats() async {
    final res = await http.get(_uri('/chats'), headers: _headers);
    final data = await _handleResponse(res) as Map<String, dynamic>;
    return data['chats'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> createOrGetDirectChat(String participantId) async {
    final res = await http.post(
      _uri('/chats'),
      headers: _headers,
      body: jsonEncode({'participantId': participantId}),
    );
    return (await _handleResponse(res) as Map<String, dynamic>)['chat']
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createGroupChat(
      List<String> participantIds, String groupName) async {
    final res = await http.post(
      _uri('/chats/group'),
      headers: _headers,
      body: jsonEncode({'participantIds': participantIds, 'groupName': groupName}),
    );
    return (await _handleResponse(res) as Map<String, dynamic>)['chat']
        as Map<String, dynamic>;
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  Future<List<dynamic>> getMessages(String chatId, {String? before}) async {
    final query = before != null ? '?before=${Uri.encodeComponent(before)}' : '';
    final res = await http.get(_uri('/messages/$chatId$query'), headers: _headers);
    final data = await _handleResponse(res) as Map<String, dynamic>;
    return data['messages'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> sendMessage(
      String chatId, String content, {String type = 'text', String? replyTo}) async {
    final res = await http.post(
      _uri('/messages/$chatId'),
      headers: _headers,
      body: jsonEncode({
        'content': content,
        'type': type,
        if (replyTo != null) 'replyTo': replyTo,
      }),
    );
    return (await _handleResponse(res) as Map<String, dynamic>)['message']
        as Map<String, dynamic>;
  }

  Future<void> markMessageRead(String messageId) async {
    await http.patch(_uri('/messages/$messageId/read'), headers: _headers);
  }

  Future<void> deleteMessage(String messageId) async {
    await http.delete(_uri('/messages/$messageId'), headers: _headers);
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
