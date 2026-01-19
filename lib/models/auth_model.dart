import 'dart:convert';

class User {
  final int id;
  final String username;
  final String? fullName;
  final List<String> roles;
  final bool active;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    this.fullName,
    required this.roles,
    this.active = true,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['fullName'],
      roles: List<String>.from(json['roles'] ?? []),
      active: json['active'] ?? true,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'roles': roles,
      'active': active,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    User userObj;
    if (json['user'] != null) {
      userObj = User.fromJson(json['user']);
    } else {
      // Fallback: Extract from token
      final token = json['token'] as String;
      final username = _extractUsernameFromToken(token);
      userObj = User(id: 0, username: username, roles: []);
    }

    return AuthResponse(
      token: json['token'],
      user: userObj,
    );
  }

  static String _extractUsernameFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 'Usuario';

      final payload = parts[1];
      String normalized = base64Url.normalize(payload);
      final String decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> payloadMap = jsonDecode(decoded);

      return payloadMap['sub'] ?? 'Usuario';
    } catch (e) {
      return 'Usuario';
    }
  }
}
