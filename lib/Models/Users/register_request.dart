import 'base_model.dart';
class UserRegisterRequest extends BaseUser {
  String userName;
  String phoneNumber;
  String password;
  final String requestType = 'register';

  UserRegisterRequest({
    required super.email,
    required this.password,
    required this.userName,
    required this.phoneNumber,
  });

  factory UserRegisterRequest.fromJson(Map<String, dynamic> jsonMap) {
    return UserRegisterRequest(
      email: jsonMap['email'],
      password: jsonMap['password'],
      userName: jsonMap['user_name'],
      phoneNumber: jsonMap['phone_number'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'user_name': userName,
      'phone_number': phoneNumber,
    };
  }
}
