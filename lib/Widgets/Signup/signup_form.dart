import 'package:flutter/material.dart';
import 'package:murir_tin/Models/model.dart';
import 'package:murir_tin/Widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Views/views.dart';

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  final loginUrl = "http://localhost:8000/auth/register/";

  bool checked = false;
  late List<FormTextFieldModel> _fields;

  @override
  void initState() {
    super.initState();

    _fields = [
      FormTextFieldModel(
        controller: _userNameController,
        hintText: "Enter a user name",
        label: "Username",
        icon: Icons.person_outline,
      ),
      FormTextFieldModel(
        controller: _emailController,
        hintText: "Enter your E-mail",
        label: "Email",
        icon: Icons.email_outlined,
      ),
      FormTextFieldModel(
        controller: _phoneNumberController,
        hintText: "Enter your phone number",
        label: "Phone",
        icon: Icons.phone_outlined,
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
    _phoneNumberController.dispose();
    _userNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
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

            const SizedBox(height: 20),

            Row(
              children: [
                Checkbox(
                  value: checked,
                  onChanged: (value) {
                    setState(() {
                      checked = value!;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    "I agree to terms and conditions",
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "SignUp Successful!",
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.lightGreen,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                    );
                  },
                  child: Text(
                    "Sign up",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Align(
              alignment: Alignment.bottomRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Already have an account?",
                    style: TextStyle(fontSize: 15),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                      );
                    },
                    child: const Text(
                      "Sign in",
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
          ],
        ),
      ),
    );
  }
}
