import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/sync/data/local/local_cache_service.dart';

abstract class AuthRemoteDatasource {
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final SupabaseClient _supabaseClient;

  AuthRemoteDatasourceImpl(this._supabaseClient);

  @override
  Future<UserModel> signIn(String email, String password) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AppException('Sign in failed: No user returned');
      }

      final profileData = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (profileData != null) {
        return UserModel.fromJson(profileData);
      }

      return UserModel(
        id: response.user!.id,
        email: response.user!.email ?? email,
        fullName:
            response.user!.userMetadata?['full_name'] as String? ??
            email.split('@').first,
        phone: response.user!.userMetadata?['phone'] as String?,
      );
    } catch (e) {
      AppLogger.e('SignIn Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );

      if (response.user == null) {
        throw AppException('Sign up failed: No user returned');
      }

      // Try fetching profile created by trigger
      await Future.delayed(const Duration(milliseconds: 300));

      Map<String, dynamic>? profileData;
      try {
        profileData = await _supabaseClient
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();
      } catch (e) {
        AppLogger.w('Could not fetch profile via select: $e');
      }

      // If trigger didn't create it, attempt direct insert
      if (profileData == null) {
        try {
          profileData = await _supabaseClient
              .from('profiles')
              .upsert({
                'id': response.user!.id,
                'email': email,
                'full_name': fullName,
                'phone': phone,
              })
              .select()
              .maybeSingle();
        } catch (e) {
          AppLogger.w('Could not upsert profile directly: $e');
        }
      }

      if (profileData != null) {
        return UserModel.fromJson(profileData);
      }

      // Fallback: construct from response.user
      return UserModel(
        id: response.user!.id,
        email: email,
        fullName: fullName,
        phone: phone,
      );
    } catch (e) {
      AppLogger.e('SignUp Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut(scope: SignOutScope.global);
    } catch (e) {
      AppLogger.w('Global SignOut warning, falling back to local: $e');
      try {
        await _supabaseClient.auth.signOut(scope: SignOutScope.local);
      } catch (localErr) {
        AppLogger.e('Local SignOut Error: $localErr');
        throw AppException(localErr.toString());
      }
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
    } catch (e) {
      AppLogger.e('ResetPassword Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        // Fallback: check if we have a cached user ID for offline resilience
        final cachedUserId = await LocalCacheService().getLastUserId();
        if (cachedUserId != null && cachedUserId.isNotEmpty) {
          return UserModel(
            id: cachedUserId,
            email: '',
            fullName: 'Offline User',
          );
        }
        return null;
      }

      // Try fetching profile from remote — may fail when offline
      try {
        final profileData = await _supabaseClient
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profileData != null) {
          return UserModel.fromJson(profileData);
        }
      } catch (e) {
        // Network failure — fall through to local data
        AppLogger.w('Profile fetch failed (likely offline): $e');
      }

      // Fallback: construct from cached Supabase auth user metadata
      return UserModel(
        id: user.id,
        email: user.email ?? '',
        fullName:
            user.userMetadata?['full_name'] as String? ??
            (user.email?.split('@').first ?? 'User'),
        phone: user.userMetadata?['phone'] as String?,
      );
    } catch (e) {
      AppLogger.e('GetCurrentUser Error: $e');
      return null;
    }
  }
}
