import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../sync/data/local/local_cache_service.dart';

class AuthGuard {
  static Future<String?> redirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    // Use currentUser as fallback — it persists from cached JWT data
    // even when the session token has expired (critical for offline).
    final user = supabase.auth.currentUser;
    bool isLoggedIn = session != null || user != null;

    if (!isLoggedIn) {
      // Offline fallback: check if we have a cached user ID from a previous session
      final cachedUserId = await LocalCacheService().getLastUserId();
      if (cachedUserId != null && cachedUserId.isNotEmpty) {
        isLoggedIn = true;
      }
    }

    if (state.matchedLocation == '/splash') {
      return null;
    }

    final isGoingToAuth =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/onboarding' ||
        state.matchedLocation == '/forgot-password';

    if (!isLoggedIn && !isGoingToAuth) {
      return '/onboarding';
    }

    if (isLoggedIn && isGoingToAuth) {
      return '/dashboard';
    }

    return null;
  }
}
