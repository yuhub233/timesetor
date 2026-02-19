class User {
  final int id;
  final String username;
  final Map<String, dynamic>? settings;

  User({
    required this.id,
    required this.username,
    this.settings,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] as int,
      username: json['username'] as String? ?? '',
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }
}
