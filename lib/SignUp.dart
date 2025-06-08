import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Login.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool _obscureText = true;
  bool checked = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF14213D), Color(0xFF4B6EAF)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 80, left: 22),
              child: Text(
                "Create your\nAccount",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 18, right: 18, bottom: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    TextField(
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: "Username",
                        labelStyle: GoogleFonts.poppins(
                          color: const Color(0xFF14213D),
                          fontWeight: FontWeight.bold,
                        ),
                        hintText: "Enter your username",
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Color(0xFF14213D),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: "Email",
                        labelStyle: GoogleFonts.poppins(
                          color: const Color(0xFF14213D),
                          fontWeight: FontWeight.bold,
                        ),
                        hintText: "Enter your email",
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Color(0xFF14213D),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: "Phone",
                        labelStyle: GoogleFonts.poppins(
                          color: const Color(0xFF14213D),
                          fontWeight: FontWeight.bold,
                        ),
                        hintText: "Enter your phone number",
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.phone,
                          color: Color(0xFF14213D),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: "Password",
                        hintText: "Enter your password",
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        labelStyle: GoogleFonts.poppins(
                          color: const Color(0xFF14213D),
                          fontWeight: FontWeight.bold,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Color(0xFF14213D),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                              MaterialPageRoute(
                                builder: (context) => const Login(),
                              ),
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
                                MaterialPageRoute(
                                  builder: (context) => const Login(),
                                ),
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
            ),
          ),
        ],
      ),
    );
  }
}
