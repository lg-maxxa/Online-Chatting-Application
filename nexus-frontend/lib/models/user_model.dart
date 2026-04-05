/// Data model for a user (matches backend User schema)
class UserModel {
  final String id;
  final String username;
  final String email;
  final String phoneNumber;
  final String profilePicUrl;
  final String status;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.phoneNumber = '',
    this.profilePicUrl = '',
    this.status = 'Hey there! I am using NexusChat.',
    this.isOnline = false,
    this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      profilePicUrl: json['profilePicUrl'] as String? ?? '',
      status: json['status'] as String? ?? 'Hey there! I am using NexusChat.',
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'username': username,
        'email': email,
        'phoneNumber': phoneNumber,
        'profilePicUrl': profilePicUrl,
        'status': status,
        'isOnline': isOnline,
        'lastSeen': lastSeen?.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? phoneNumber,
    String? profilePicUrl,
    String? status,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
