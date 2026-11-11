import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/subscription_tier.dart';
import '../../domain/services/feature_gate_service.dart';
import '../../../config/paystack_config.dart';
import '../../../../features/business/presentation/providers/business_provider.dart';
import '../../../../core/utils/logger.dart';

/// Provider for the currently active subscription tier of the selected business
final currentSubscriptionTierProvider = Provider<SubscriptionTier>((ref) {
  final activeBiz = ref.watch(currentBusinessProvider);
  if (activeBiz == null) return SubscriptionTier.free;
  return SubscriptionTier.fromString(activeBiz.subscriptionTier);
});

/// Provider for the TierLimits matching the active business tier
final currentTierLimitsProvider = Provider<TierLimits>((ref) {
  final tier = ref.watch(currentSubscriptionTierProvider);
  return TierLimits.forTier(tier);
});

/// Provider for the FeatureGateService
final featureGateProvider = Provider<FeatureGateService>((ref) {
  final tier = ref.watch(currentSubscriptionTierProvider);
  return FeatureGateService(tier: tier);
});

/// Controller to handle subscription upgrades, downgrades, and billing state
class SubscriptionController
    extends StateNotifier<AsyncValue<SubscriptionTier>> {
  SubscriptionController(this._ref)
    : super(AsyncValue.data(_ref.read(currentSubscriptionTierProvider)));

  final Ref _ref;

  /// Upgrades or changes subscription tier for the active business
  Future<bool> changeTier(SubscriptionTier newTier) async {
    final activeBiz = _ref.read(currentBusinessProvider);
    if (activeBiz == null) {
      state = AsyncValue.error(
        'No active business selected',
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncValue.loading();
    try {
      // 1. Invalidate and re-fetch user businesses to pull any tier changes applied
      // by the backend Edge Function / webhook
      _ref.invalidate(userBusinessesProvider);
      final refreshedList = await _ref.read(userBusinessesProvider.future);
      final refreshedBiz = refreshedList
          .where((b) => b.id == activeBiz.id)
          .firstOrNull;

      if (refreshedBiz != null && refreshedBiz.subscriptionTier == newTier.id) {
        _ref.read(currentBusinessProvider.notifier).select(refreshedBiz);
        state = AsyncValue.data(newTier);
        return true;
      }

      // 2. If it was a free tier activation or test bypass, update business
      final updatedBiz = (refreshedBiz ?? activeBiz).copyWith(
        subscriptionTier: newTier.id,
      );
      final repo = _ref.read(businessRepositoryProvider);
      final result = await repo.updateBusiness(updatedBiz);

      return result.fold(
        (failure) {
          AppLogger.w('Subscription update note: ${failure.message}');
          final isTestMode = PaystackConfig.publicKey.startsWith('pk_test_');
          if (isTestMode) {
            // In Test Mode, update in-memory active business so developer can test all features
            AppLogger.i(
              'Test mode active: setting in-memory tier to ${newTier.displayName}',
            );
            _ref.read(currentBusinessProvider.notifier).select(updatedBiz);
            state = AsyncValue.data(newTier);
            return true;
          }
          if (refreshedBiz != null) {
            _ref.read(currentBusinessProvider.notifier).select(refreshedBiz);
            state = AsyncValue.data(
              SubscriptionTier.fromString(refreshedBiz.subscriptionTier),
            );
          } else {
            state = AsyncValue.error(failure.message, StackTrace.current);
          }
          return false;
        },
        (savedBiz) {
          AppLogger.i(
            'Subscription tier updated to ${newTier.displayName} for ${savedBiz.name}',
          );
          _ref.read(currentBusinessProvider.notifier).select(savedBiz);
          _ref.invalidate(userBusinessesProvider);
          state = AsyncValue.data(newTier);
          return true;
        },
      );
    } catch (e, st) {
      AppLogger.e('Exception changing subscription tier: $e');
      final isTestMode = PaystackConfig.publicKey.startsWith('pk_test_');
      if (isTestMode) {
        final updatedBiz = activeBiz.copyWith(subscriptionTier: newTier.id);
        _ref.read(currentBusinessProvider.notifier).select(updatedBiz);
        state = AsyncValue.data(newTier);
        return true;
      }
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, AsyncValue<SubscriptionTier>>(
      (ref) {
        return SubscriptionController(ref);
      },
    );
