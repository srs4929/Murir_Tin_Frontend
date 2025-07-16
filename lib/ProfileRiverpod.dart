import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Component.dart';
import 'package:murir_tin/Providers/user_provider.dart';
import 'package:murir_tin/Components/user_profile_widget.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load user data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).loadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final userName = ref.watch(userNameProvider);
    final userEmail = ref.watch(userEmailProvider);
    final userPhone = ref.watch(userPhoneProvider);
    final profilePic = ref.watch(userProfilePicProvider);

    return Scaffold(
      appBar: const GAppBar(title: "My Profile"),
      body: userState.when(
        data:
            (user) => _buildProfileContent(
              context,
              user,
              userName,
              userEmail,
              userPhone,
              profilePic,
            ),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    dynamic user,
    String userName,
    String userEmail,
    String userPhone,
    String? profilePic,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // User Profile Widget
          UserProfileWidget(
            showFullProfile: true,
            onTap: () {
              // TODO: Navigate to edit profile when EditProfile widget is updated
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Edit profile coming soon!"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          // Profile Details Cards
          _buildDetailCard(
            icon: Icons.person,
            title: "Username",
            value: userName,
            color: const Color(0xFF4B6EAF),
          ),

          const SizedBox(height: 15),

          _buildDetailCard(
            icon: Icons.email,
            title: "Email",
            value: userEmail,
            color: const Color(0xFF14213D),
          ),

          const SizedBox(height: 15),

          _buildDetailCard(
            icon: Icons.phone,
            title: "Phone Number",
            value: userPhone.isNotEmpty ? userPhone : "Not provided",
            color: const Color(0xFF0A0E27),
          ),

          const SizedBox(height: 30),

          // Action Buttons
          _buildActionButton(context, "Edit Profile", Icons.edit, () {
            // TODO: Navigate to edit profile when EditProfile widget is updated
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Edit profile coming soon!"),
                duration: Duration(seconds: 2),
              ),
            );
            /*
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfile(),
                ),
              ).then((_) {
                // Refresh user data when returning from edit
                ref.read(userProvider.notifier).loadUser();
              });
              */
          }),

          const SizedBox(height: 15),

          _buildActionButton(context, "Refresh Profile", Icons.refresh, () {
            ref.read(userProvider.notifier).loadUser();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Profile refreshed"),
                duration: Duration(seconds: 2),
              ),
            );
          }),

          const SizedBox(height: 15),

          _buildActionButton(context, "Logout", Icons.logout, () {
            _showLogoutDialog(context);
          }, isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : const Color(0xFF4B6EAF);

    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF4B6EAF)),
          SizedBox(height: 16),
          Text("Loading profile..."),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            "Error loading profile",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.red.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(userProvider.notifier).loadUser();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4B6EAF),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Text(
                "Logout",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to logout?",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                "Logout",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
