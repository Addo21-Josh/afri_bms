import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGuard {
  static String? redirect(BuildContext context, GoRouterState state) {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    final isLoggedIn = session != null;
    final isGoingToAuth = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/onboarding' || 
        state.matchedLocation == '/forgot-password';

    if (!isLoggedIn && !isGoingToAuth) {
      // If the user is not logged in, they need to login
      // But if they are just opening the app for the first time, they should see onboarding.
      // This logic will be refined when we add the "isFirstTime" flag via shared_prefs.
      // For now, redirect to /onboarding if not logged in.
      return '/onboarding';
    }

    if (isLoggedIn && isGoingToAuth) {
      // If logged in but trying to go to login/register, send to dashboard
      return '/dashboard';
    }

    return null;
  }
}
