import 'base_model.dart';

class UserLoginRequest extends BaseUser {
  String password;
  final String requestType = 'login';

  UserLoginRequest({required super.email, required this.password});

  factory UserLoginRequest.fromJson(Map<String, dynamic> jsonMap) {
    return UserLoginRequest(
      email: jsonMap['email'],
      password: jsonMap['password'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}