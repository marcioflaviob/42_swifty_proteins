class User {
  final int id;
  final String username;
  final String? password;

  const User({
    required this.id,
    required this.username,
    this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username
    };
  }

    Map<String, dynamic> toAuthJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
    };
  }
}
