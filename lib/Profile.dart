import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Component.dart';
import 'package:murir_tin/Providers/user_provider.dart';
import 'EditProfile.dart';
import 'utils/beautiful_alerts.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load user profile when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).loadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final middleBlueColor = Color(0xFF2F4F78);
    final darkBlueColor = Color(0xFF14213D);
    final lightBlueColor = Color(0xFF4A90E2);

    final userAsyncValue = ref.watch(userProvider);
    final userName = ref.watch(userNameProvider);
    final userEmail = ref.watch(userEmailProvider);
    final userPhone = ref.watch(userPhoneProvider);
    final userProfilePic = ref.watch(userProfilePicProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: GAppBar(title: "My Profile"),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(userProvider.notifier).loadUser();
        },
        child: userAsyncValue.when(
          data:
              (user) => _buildProfileContent(
                context,
                userName,
                userEmail,
                userPhone,
                userProfilePic ?? '',
                middleBlueColor,
                darkBlueColor,
                lightBlueColor,
              ),
          loading:
              () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: middleBlueColor),
                    SizedBox(height: 16),
                    Text(
                      'Loading profile...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
          error:
              (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load profile',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(userProvider.notifier).loadUser();
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: middleBlueColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    String userName,
    String userEmail,
    String userPhone,
    String userProfilePic,
    Color middleBlueColor,
    Color darkBlueColor,
    Color lightBlueColor,
  ) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile Header Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [middleBlueColor, lightBlueColor],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: middleBlueColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile Picture
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child:
                        userProfilePic.isNotEmpty
                            ? ClipOval(
                              child: Image.network(
                                userProfilePic,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        _buildAvatarFallback(userName),
                              ),
                            )
                            : _buildAvatarFallback(userName),
                  ),
                ),
                SizedBox(height: 16),
                // Username
                Text(
                  userName.isEmpty ? 'User' : userName,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                // Status
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Active User',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Profile Information Cards
          _buildInfoCard(
            icon: Icons.email_outlined,
            label: "Email",
            value: userEmail.isEmpty ? 'Not provided' : userEmail,
            color: darkBlueColor,
          ),

          _buildInfoCard(
            icon: Icons.phone_outlined,
            label: "Phone Number",
            value: userPhone.isEmpty ? 'Not provided' : userPhone,
            color: darkBlueColor,
          ),

          SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final user = ref.read(userProvider).value;
                    if (user != null) {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => EditProfileScreen(
                                username: user.username,
                                email: user.email,
                                phone: user.phone,
                              ),
                        ),
                      );

                      if (updated == true) {
                        ref.read(userProvider.notifier).loadUser();
                      }
                    }
                  },
                  icon: Icon(Icons.edit_outlined),
                  label: Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: middleBlueColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm =
                        await BeautifulAlerts.showConfirmationDialog(
                          context,
                          title: 'Logout',
                          message: 'Are you sure you want to logout?',
                          confirmText: 'Logout',
                          cancelText: 'Cancel',
                          icon: Icons.logout_rounded,
                          iconColor: Colors.red,
                        );

                    if (confirm) {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    }
                  },
                  icon: Icon(Icons.logout_outlined),
                  label: Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[600],
                    side: BorderSide(color: Colors.red[300]!),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String userName) {
    final initials =
        userName.isNotEmpty
            ? userName
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join('')
                .toUpperCase()
            : 'U';

    return Container(
      width: 120,
      height: 120,
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
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
