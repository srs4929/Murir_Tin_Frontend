import 'package:flutter/material.dart';
import 'package:murir_tin/Widgets/widgets.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          UpperBackground(primaryText: "Welcome", secondaryText: "Get Started"),
          Positioned(
            top: 250,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 18,
                    right: 18,
                    bottom: 40,
                  ),
                  child: SignupForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
