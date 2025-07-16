import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Providers/user_provider.dart';
import 'package:murir_tin/utils/beautiful_alerts.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final String username;
  final String email;
  final String phone;
  final String? imagePath;

  const EditProfileScreen({
    super.key,
    required this.username,
    required this.email,
    required this.phone,
    this.imagePath,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with TickerProviderStateMixin {
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  File? _pickedImageFile;
  bool _isUploading = false;
  bool _showSuccess = false;
  String? _usernameError;
  String? _emailError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);

    // Initialize animations
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Start animation
    _animationController.forward();

    // Add listeners for real-time validation
    _usernameController.addListener(_validateUsername);
    _emailController.addListener(_validateEmail);
    _phoneController.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Validation methods
  void _validateUsername() {
    setState(() {
      if (_usernameController.text.isEmpty) {
        _usernameError = 'Username is required';
      } else if (_usernameController.text.length < 3) {
        _usernameError = 'Username must be at least 3 characters';
      } else if (!RegExp(
        r'^[a-zA-Z0-9_\s]+$',
      ).hasMatch(_usernameController.text)) {
        _usernameError =
            'Username can only contain letters, numbers, and spaces';
      } else {
        _usernameError = null;
      }
    });
  }

  void _validateEmail() {
    setState(() {
      if (_emailController.text.isEmpty) {
        _emailError = 'Email is required';
      } else if (!RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(_emailController.text)) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePhone() {
    setState(() {
      if (_phoneController.text.isEmpty) {
        _phoneError = 'Phone number is required';
      } else if (!RegExp(r'^[\+]?[0-9]{10,15}$').hasMatch(
        _phoneController.text.replaceAll(' ', '').replaceAll('-', ''),
      )) {
        _phoneError = 'Please enter a valid phone number';
      } else {
        _phoneError = null;
      }
    });
  }

  bool get _isFormValid {
    return _usernameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _usernameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty;
  }

  Future<void> _pickImage() async {
    try {
      // Show image source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Select Image Source',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF4A90E2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.camera_alt, color: Color(0xFF4A90E2)),
                  ),
                  title: Text('Camera', style: GoogleFonts.poppins()),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF2F4F78).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.photo_library, color: Color(0xFF2F4F78)),
                  ),
                  title: Text('Gallery', style: GoogleFonts.poppins()),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source != null) {
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          setState(() {
            _pickedImageFile = File(pickedFile.path);
          });

          // Show success feedback
          HapticFeedback.lightImpact();
          BeautifulAlerts.showSuccessSnackBar(
            context,
            'Image selected successfully!',
          );
        }
      }
    } catch (e) {
      BeautifulAlerts.showErrorSnackBar(
        context,
        'Error selecting image: ${e.toString()}',
      );
    }
  }

  Future<void> _saveProfile(BuildContext context) async {
    // Validate all fields (except phone since server might not support it)
    _validateUsername();
    _validateEmail();
    // _validatePhone(); // Commented out since deployed server might not support phone

    if (_usernameError != null ||
        _emailError != null ||
        _usernameController.text.isEmpty ||
        _emailController.text.isEmpty) {
      HapticFeedback.mediumImpact();
      BeautifulAlerts.showErrorSnackBar(
        context,
        'Please fix all errors before saving',
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Choose the appropriate update method based on whether an image is selected
      if (_pickedImageFile != null) {
        // Use the image upload method
        await ref
            .read(userProvider.notifier)
            .updateUserWithImage(
              username: _usernameController.text.trim(),
              email: _emailController.text.trim(),
              imagePath: _pickedImageFile!.path,
            );
      } else {
        // Use the regular update method (no image)
        await ref
            .read(userProvider.notifier)
            .updateUser(
              username: _usernameController.text.trim(),
              email: _emailController.text.trim(),
              // Note: Phone might not be supported by the deployed server
            );
      }

      // Show success state
      setState(() {
        _showSuccess = true;
      });

      HapticFeedback.heavyImpact();

      // Show success message
      BeautifulAlerts.showSuccessSnackBar(
        context,
        'Profile updated successfully!',
      );

      // Wait a moment for user to see success, then navigate back
      await Future.delayed(Duration(milliseconds: 1500));

      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      HapticFeedback.mediumImpact();
      BeautifulAlerts.showErrorSnackBar(
        context,
        'Error updating profile: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _showSuccess = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final middleBlueColor = Color(0xFF2F4F78);
    final lightBlueColor = Color(0xFF4A90E2);

    // Watch user data from Riverpod for current profile picture
    final userProfilePic = ref.watch(userProfilePicProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: middleBlueColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [middleBlueColor, lightBlueColor],
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header text
                      Text(
                        'Update Your Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: middleBlueColor,
                        ),
                      ),
                      Text(
                        'Keep your information up to date',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 30),

                      // Profile Picture Section
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: middleBlueColor.withOpacity(0.1),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: lightBlueColor,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 65,
                                      backgroundColor: Colors.white,
                                      child:
                                          _pickedImageFile != null
                                              ? ClipOval(
                                                child: Image.file(
                                                  _pickedImageFile!,
                                                  width: 130,
                                                  height: 130,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                              : (userProfilePic != null &&
                                                      userProfilePic.isNotEmpty
                                                  ? ClipOval(
                                                    child: Image.network(
                                                      userProfilePic,
                                                      width: 130,
                                                      height: 130,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) =>
                                                              _buildAvatarFallback(),
                                                    ),
                                                  )
                                                  : _buildAvatarFallback()),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 5,
                                  right: 5,
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: lightBlueColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 5,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Tap to change picture',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      // Form Fields Section
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: middleBlueColor.withOpacity(0.1),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personal Information',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: middleBlueColor,
                              ),
                            ),
                            SizedBox(height: 20),

                            _buildEnhancedTextField(
                              label: "Username",
                              controller: _usernameController,
                              icon: Icons.person_outline,
                              error: _usernameError,
                              color: middleBlueColor,
                            ),
                            SizedBox(height: 20),

                            _buildEnhancedTextField(
                              label: "Email",
                              controller: _emailController,
                              icon: Icons.email_outlined,
                              error: _emailError,
                              color: middleBlueColor,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            SizedBox(height: 20),

                            _buildEnhancedTextField(
                              label: "Phone Number",
                              controller: _phoneController,
                              icon: Icons.phone_outlined,
                              error: _phoneError,
                              color: middleBlueColor,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      // Update Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              (_isUploading || !_isFormValid)
                                  ? null
                                  : () => _saveProfile(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isFormValid
                                    ? middleBlueColor
                                    : Colors.grey[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: _isFormValid ? 8 : 2,
                            shadowColor: middleBlueColor.withOpacity(0.3),
                          ),
                          child:
                              _isUploading
                                  ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Updating...',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                  : _showSuccess
                                  ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle, size: 24),
                                      SizedBox(width: 8),
                                      Text(
                                        'Success!',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                  : Text(
                                    'Update Profile',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    String? error,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: error != null ? Colors.red : color),
              hintText: 'Enter $label',
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      error != null
                          ? Colors.red.withOpacity(0.5)
                          : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: error != null ? Colors.red : color,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              filled: true,
              fillColor:
                  error != null
                      ? Colors.red.withOpacity(0.05)
                      : Colors.grey[50],
            ),
          ),
        ),
        if (error != null) ...[
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: Colors.red),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  error,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAvatarFallback() {
    final initials =
        widget.username.isNotEmpty
            ? widget.username
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join('')
                .toUpperCase()
            : 'U';

    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A90E2), Color(0xFF2F4F78)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
