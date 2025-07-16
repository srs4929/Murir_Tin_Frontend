import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/SignUp.dart';
import 'Landingpage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:murir_tin/api.dart';
import 'package:murir_tin/Providers/user_provider.dart';
import 'utils/beautiful_alerts.dart';

class Login extends ConsumerStatefulWidget {
  const Login({super.key});

  @override
  ConsumerState<Login> createState() => _LoginState();
}

class _LoginState extends ConsumerState<Login> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );

    _animationController.forward();
  }

  void _showErrorDialog(String message) {
    BeautifulAlerts.showErrorDialog(
      context,
      title: "Login Failed",
      message: message,
    );
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog("Please fill in all fields.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(login_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['access_token'];

        if (token == null) {
          _showErrorDialog(
            "Invalid response from server: no access token received",
          );
          return;
        }

        // Use Riverpod auth provider to handle login
        await ref.read(authProvider.notifier).login(token);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Landingpage()),
          );
        }
      } else {
        String errorMessage = 'Login failed';

        if (response.statusCode == 401) {
          errorMessage = 'Invalid email or password';
        } else if (response.statusCode >= 500) {
          // Server error - check if it's a specific server message
          if (response.body.contains('server error has occurred') ||
              response.body.contains('A server error has occurred')) {
            errorMessage =
                'Server is experiencing issues. This may be due to:\n'
                '• Database connection problems\n'
                '• Server configuration issues\n'
                'Please try again later or contact support.';
          } else {
            errorMessage = 'Server error occurred. Please try again later.';
          }
        } else {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage =
                errorData['detail'] ?? errorData['message'] ?? 'Login failed';
          } catch (e) {
            // If JSON parsing fails, check if response body has any useful info
            if (response.body.isNotEmpty && response.body.length < 200) {
              errorMessage = response.body;
            } else {
              errorMessage = 'Login failed. Please check your credentials.';
            }
            print('DEBUG: Error parsing response: $e');
          }
        }
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Network error: $e');
      _showErrorDialog(
        "Network error: Please check your connection and try again.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Enhanced Background
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A0E27),
                  Color(0xFF14213D),
                  Color(0xFF4B6EAF),
                ],
                stops: [0.0, 0.4, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 120.0, left: 22),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Sign in!",
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 280,
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.fastOutSlowIn,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 40,
                        offset: const Offset(0, -10),
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      top: 20,
                      left: 18,
                      right: 18,
                      bottom: 40,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 50),

                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                (1 - _fadeAnimation.value) * 20,
                              ),
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                      labelText: "Email",
                                      hintText: "Enter your email",
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.grey,
                                      ),
                                      labelStyle: GoogleFonts.poppins(
                                        color: const Color(0xFF14213D),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF14213D,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.email,
                                          color: Color(0xFF14213D),
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF4B6EAF),
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 20,
                                            horizontal: 16,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 25),

                        // Password field with enhanced styling
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                (1 - _fadeAnimation.value) * 30,
                              ),
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _passwordController,
                                    obscureText: _obscureText,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                      labelText: "Password",
                                      hintText: "Enter your password",
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.grey,
                                      ),
                                      labelStyle: GoogleFonts.poppins(
                                        color: const Color(0xFF14213D),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF14213D,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.lock,
                                          color: Color(0xFF14213D),
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF4B6EAF),
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 20,
                                            horizontal: 16,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 70),

                        // Enhanced Sign in button with loading state
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                (1 - _fadeAnimation.value) * 40,
                              ),
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: Container(
                                  width: double.infinity,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF4B6EAF,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                        spreadRadius: 0,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF14213D),
                                          Color(0xFF4B6EAF),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      onPressed: _isLoading ? null : _signIn,
                                      child:
                                          _isLoading
                                              ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 3,
                                                    ),
                                              )
                                              : Text(
                                                "Sign in",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 50),

                        // Enhanced signup redirect
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                (1 - _fadeAnimation.value) * 50,
                              ),
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Don't have an account?",
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder:
                                                  (
                                                    context,
                                                    animation,
                                                    secondaryAnimation,
                                                  ) => const Signup(),
                                              transitionsBuilder: (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                child,
                                              ) {
                                                return SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(
                                                      1.0,
                                                      0.0,
                                                    ),
                                                    end: Offset.zero,
                                                  ).animate(animation),
                                                  child: child,
                                                );
                                              },
                                            ),
                                          );
                                        },
                                        child: Text(
                                          "Sign Up",
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF4B6EAF),
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: const Color(
                                              0xFF4B6EAF,
                                            ),
                                            decorationThickness: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
