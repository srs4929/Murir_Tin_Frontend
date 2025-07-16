class UserModel {
  final String id;
  final String email;
  final String username;
  final String phone;
  final String? profilePicUrl;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.phone,
    this.profilePicUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      profilePicUrl: json['profile_pic_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'phone': phone,
      'profile_pic_url': profilePicUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? phone,
    String? profilePicUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.username == username &&
        other.phone == phone &&
        other.profilePicUrl == profilePicUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        username.hashCode ^
        phone.hashCode ^
        profilePicUrl.hashCode;
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, username: $username, phone: $phone, profilePicUrl: $profilePicUrl)';
  }
}
