import 'dart:io';

import 'package:flutter/material.dart';
import 'package:murir_tin/Models/model.dart';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:murir_tin/Widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Views/views.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final loginUrl = "http://localhost:8000/auth/login/";

  late List<FormTextFieldModel> _fields;

  Future<void> _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    UserLoginRequest loginRequest = UserLoginRequest(
      email: email,
      password: password,
    );

    String payLoad = jsonEncode(loginRequest.toJson());

    try {
      Response response = await post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: payLoad,
      );
      if (response.statusCode == 200 && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Landingpage()),
        );
      }
    } on SocketException catch (_) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                titlePadding: EdgeInsets.all(0),
                title: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 114, 114),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    "Error",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                content: Text(
                  'Server not found. Please check your internet connection or try again later.',
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _fields = [
      FormTextFieldModel(
        controller: _emailController,
        hintText: "Enter your E-mail",
        label: "Email",
        icon: Icons.email_outlined,
      ),
      FormTextFieldModel(
        controller: _passwordController,
        hintText: "Enter your password",
        label: "Password",
        icon: Icons.lock_outline,
      ),
    ];
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 18, right: 18, bottom: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _fields.length,
              itemBuilder: (context, index) {
                final field = _fields[index];
                return FormTextField(textData: field);
              },
            ),

            const SizedBox(height: 70),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14213D), Color(0xFF4B6EAF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _login,
                  child: Text(
                    "Sign in",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Align(
              alignment: Alignment.bottomRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Don't have account?",
                    style: TextStyle(fontSize: 15),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Signup()),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
