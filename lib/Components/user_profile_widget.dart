import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Providers/user_provider.dart';

class UserProfileWidget extends ConsumerWidget {
  final bool showFullProfile;
  final VoidCallback? onTap;

  const UserProfileWidget({
    super.key,
    this.showFullProfile = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final isLoading = ref.watch(userLoadingProvider);
    final userName = ref.watch(userNameProvider);
    final userEmail = ref.watch(userEmailProvider);
    final profilePic = ref.watch(userProfilePicProvider);

    return userState.when(
      data: (user) {
        if (user == null) {
          return _buildGuestProfile(context);
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0A0E27),
                  Color(0xFF14213D),
                  Color(0xFF4B6EAF),
                ],
                stops: [0.0, 0.4, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Profile Picture
                Container(
                  width: showFullProfile ? 80 : 60,
                  height: showFullProfile ? 80 : 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child:
                        profilePic != null && profilePic.isNotEmpty
                            ? Image.network(
                              profilePic,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      _buildDefaultAvatar(
                                        userName,
                                        showFullProfile,
                                      ),
                            )
                            : _buildDefaultAvatar(userName, showFullProfile),
                  ),
                ),

                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: showFullProfile ? 22 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        userEmail,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: showFullProfile ? 16 : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (showFullProfile && user.phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.phone,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow or status indicator
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => _buildLoadingProfile(context, isLoading),
      error: (error, stack) => _buildErrorProfile(context, error.toString()),
    );
  }

  Widget _buildDefaultAvatar(String userName, bool large) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: large ? 32 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade400,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guest User',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  'Please log in to access your profile',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingProfile(BuildContext context, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A0E27), Color(0xFF14213D), Color(0xFF4B6EAF)],
          stops: [0.0, 0.4, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorProfile(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error Loading Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                Text(
                  error,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
