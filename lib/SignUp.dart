import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Login.dart';
import 'utils/beautiful_alerts.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  bool checked = false;
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
      title: "Signup Failed",
      message: message,
    );
  }

  Future<void> _signUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
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

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        BeautifulAlerts.showSuccessSnackBar(context, "Signup Successful!");

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const Login(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          ),
        );
      }
    } catch (e) {
      _showErrorDialog("An unexpected error occurred. Please try again.");
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
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

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
              padding: const EdgeInsets.only(top: 80, left: 22),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Join us today",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Create Account",
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

          // Enhanced form container
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
                    curve: Curves.easeOutBack,
                  ),
                ),
                child: Container(
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
                      left: 18,
                      right: 18,
                      bottom: 40,
                      top: 30,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Username field
                        _buildEnhancedTextField(
                          controller: _usernameController,
                          label: "Username",
                          hint: "Enter your username",
                          icon: Icons.person,
                          animationDelay: 0,
                        ),

                        const SizedBox(height: 20),

                        // Email field
                        _buildEnhancedTextField(
                          controller: _emailController,
                          label: "Email",
                          hint: "Enter your email",
                          icon: Icons.email,
                          animationDelay: 100,
                        ),

                        const SizedBox(height: 20),

                        // Phone field
                        _buildEnhancedTextField(
                          controller: _phoneController,
                          label: "Phone",
                          hint: "Enter your phone number",
                          icon: Icons.phone,
                          animationDelay: 200,
                        ),

                        const SizedBox(height: 20),

                        // Password field
                        _buildEnhancedPasswordField(),

                        const SizedBox(height: 15),

                        // Enhanced checkbox
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                (1 - _fadeAnimation.value) * 60,
                              ),
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: Row(
                                  children: [
                                    Transform.scale(
                                      scale: 1.2,
                                      child: Checkbox(
                                        value: checked,
                                        onChanged: (value) {
                                          setState(() {
                                            checked = value!;
                                          });
                                        },
                                        activeColor: const Color(0xFF4B6EAF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        "I agree to terms and conditions",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        // Enhanced Sign up button
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                (1 - _fadeAnimation.value) * 70,
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
                                      onPressed: _isLoading ? null : _signUp,
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
                                                "Sign up",
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

                        const SizedBox(height: 30),

                        // Enhanced sign in redirect
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                (1 - _fadeAnimation.value) * 80,
                              ),
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Already have an account?",
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
                                                  ) => const Login(),
                                              transitionsBuilder: (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                child,
                                              ) {
                                                return SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(
                                                      -1.0,
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
                                          "Sign in",
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

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required int animationDelay,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            (1 - _fadeAnimation.value) * (20 + animationDelay / 10),
          ),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelText: label,
                  labelStyle: GoogleFonts.poppins(
                    color: const Color(0xFF14213D),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  hintText: hint,
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14213D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: const Color(0xFF14213D)),
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedPasswordField() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _fadeAnimation.value) * 50),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
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
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelText: "Password",
                  hintText: "Enter your password",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  labelStyle: GoogleFonts.poppins(
                    color: const Color(0xFF14213D),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14213D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock, color: Color(0xFF14213D)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
