import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/sync/data/local/local_cache_service.dart';
import '../../../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final Duration minDisplayDuration;
  final bool autoNavigate;

  const SplashScreen({
    super.key,
    this.minDisplayDuration = const Duration(milliseconds: 1200),
    this.autoNavigate = true,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
    if (widget.autoNavigate) {
      _scheduleNavigation();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _scheduleNavigation() async {
    await Future.delayed(widget.minDisplayDuration);
    if (!mounted) return;

    try {
      // Use currentUser instead of currentSession — currentUser can persist
      // from cached JWT data even when the session/token has expired offline.
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        context.go('/dashboard');
      } else {
        // Fallback: check if we have a cached user ID from a previous session.
        // This handles the case where Supabase clears the session entirely
        // during offline token refresh failure.
        final cachedUserId = await LocalCacheService().getLastUserId();
        if (!mounted) return;
        if (cachedUserId != null && cachedUserId.isNotEmpty) {
          context.go('/dashboard');
        } else {
          context.go('/onboarding');
        }
      }
    } catch (_) {
      if (mounted) {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primarySeed.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/logo/main_logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primarySeed,
                        child: const Icon(
                          Icons.storefront_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Afri_BMS',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Smarter Business, Bigger Profits',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 48),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primarySeed),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
