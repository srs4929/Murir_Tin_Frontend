import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murir_tin/Models/user_model.dart';
import 'package:murir_tin/Services/user_service.dart';

// Auth state provider
final authStateProvider = StateProvider<bool>((ref) => false);

// User data provider
final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
      return UserNotifier();
    });


class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  UserNotifier() : super(const AsyncValue.data(null));

  // Load user data
  Future<void> loadUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await UserService.getUserInfo();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Update user data
  Future<void> updateUser({
    String? username,
    String? email,
    String? phone,
    String? profilePicUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updatedUser = await UserService.updateUserProfile(
        username: username,
        email: email,
        phone: phone,
        profilePicUrl: profilePicUrl,
      );
      state = AsyncValue.data(updatedUser);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Update user data with image
  Future<void> updateUserWithImage({
    String? username,
    String? email,
    String? imagePath,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updatedUser = await UserService.updateUserProfileWithImage(
        username: username,
        email: email,
        imagePath: imagePath,
      );
      state = AsyncValue.data(updatedUser);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Clear user data
  void clearUser() {
    state = const AsyncValue.data(null);
  }

  // Get current user synchronously
  UserModel? get currentUser {
    return state.asData?.value;
  }
}

// Authentication provider
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>((
  ref,
) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AsyncValue.data(false)) {
    _checkAuthStatus();
  }

  // Check initial auth status
  Future<void> _checkAuthStatus() async {
    try {
      final isAuth = await UserService.isAuthenticated();
      state = AsyncValue.data(isAuth);

      if (isAuth) {
        // Load user data if authenticated
        ref.read(userProvider.notifier).loadUser();
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Login
  Future<void> login(String token) async {
    try {
      await UserService.saveToken(token);
      state = const AsyncValue.data(true);

      // Load user data after login
      await ref.read(userProvider.notifier).loadUser();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await UserService.logout();
      state = const AsyncValue.data(false);

      // Clear user data
      ref.read(userProvider.notifier).clearUser();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Check if authenticated
  bool get isAuthenticated {
    return state.asData?.value ?? false;
  }
}

// Convenience providers for specific user data
final userNameProvider = Provider<String>((ref) {
  final user = ref.watch(userProvider).asData?.value;
  return user?.username ?? 'Guest';
});

final userEmailProvider = Provider<String>((ref) {
  final user = ref.watch(userProvider).asData?.value;
  return user?.email ?? '';
});

final userProfilePicProvider = Provider<String?>((ref) {
  final user = ref.watch(userProvider).asData?.value;
  return user?.profilePicUrl;
});

final userPhoneProvider = Provider<String>((ref) {
  final user = ref.watch(userProvider).asData?.value;
  return user?.phone ?? '';
});

// User loading state provider
final userLoadingProvider = Provider<bool>((ref) {
  final userState = ref.watch(userProvider);
  return userState.isLoading;
});

// User error provider
final userErrorProvider = Provider<String?>((ref) {
  final userState = ref.watch(userProvider);
  return userState.hasError ? userState.error.toString() : null;
});
