class BaseUser {
  String email;

  BaseUser({required this.email});

  factory BaseUser.fromJson(Map<String, dynamic> jsonMap) {
    return BaseUser(email: jsonMap['email']);
  }

  Map<String, dynamic> toJson() {
    return {'email': email};
  }

  @override
  String toString() {
    return 'BaseUser{email: $email}';
  }
}
