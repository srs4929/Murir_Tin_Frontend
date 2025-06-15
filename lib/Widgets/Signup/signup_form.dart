import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Models/model.dart';
import 'package:murir_tin/Widgets/widgets.dart';
import 'package:murir_tin/Views/views.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    _emailController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
    _userNameController.dispose();
    super.dispose();
  }
  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _userNameController.text.trim();
    final phone = _phoneNumberController.text.trim();

    if (email.isEmpty || password.isEmpty || username.isEmpty || phone.isEmpty) {
      _showErrorDialog("Please fill in all fields.");
      return;
    }

    if (!checked) {
      _showErrorDialog("You must agree to the terms and conditions.");
      return;
    }

    if (phone.length != 11) {
      _showErrorDialog("Phone number must be exactly 11 digits.");
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        // Insert into 'users' table after successful sign up
        await supabase.from('user_profiles').insert({
          'id': user.id,
          'username': username,
          'email': email,
          'phone': phone,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Signup Successful!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
          );
        }
      }
    } on AuthException catch (e) {
      _showErrorDialog(e.message);
    } catch (e) {
      _showErrorDialog("An unexpected error occurred. Please try again.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Signup Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              physics: const NeverScrollableScrollPhysics(),
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
                  onPressed: _signUp,
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
