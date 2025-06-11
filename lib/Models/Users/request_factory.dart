import 'login_request.dart';
import 'register_request.dart';

class RequestType {
  static const String login = 'login';
  static const String register = 'register';
}

class RequestFactory {
  static dynamic createRequest(String type, Map<String, dynamic> data) {
    switch (type) {
      case RequestType.login:
        return UserLoginRequest(
          email: data['email'],
          password: data['password'],
        );
      case RequestType.register:
        return UserRegisterRequest(
          email: data['email'],
          password: data['password'],
          userName: data['user_name'],
          phoneNumber: data['phone_number'],
        );

      default:
        throw Exception('Unknown request type: $type');
    }
  }
}
