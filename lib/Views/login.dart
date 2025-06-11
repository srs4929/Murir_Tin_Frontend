import 'package:flutter/material.dart';
import 'package:murir_tin/Widgets/widgets.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          UpperBackground(
            primaryText: "Welcome Back",
            secondaryText: "Sign in and Explore!",
          ),

          Positioned(
            top: 250,
            left: 0,
            right: 0,
            bottom: 0,
            child: LoginForm(),
          ),
        ],
      ),
    );
  }
}
