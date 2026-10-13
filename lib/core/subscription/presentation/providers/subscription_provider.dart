import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/subscription_tier.dart';
import '../../domain/services/feature_gate_service.dart';
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
class SubscriptionController extends StateNotifier<AsyncValue<SubscriptionTier>> {
  final Ref _ref;

  SubscriptionController(this._ref)
      : super(AsyncValue.data(_ref.read(currentSubscriptionTierProvider)));

  /// Upgrades or changes subscription tier for the active business
  Future<bool> changeTier(SubscriptionTier newTier) async {
    final activeBiz = _ref.read(currentBusinessProvider);
    if (activeBiz == null) {
      state = AsyncValue.error('No active business selected', StackTrace.current);
      return false;
    }

    state = const AsyncValue.loading();
    try {
      final updatedBiz = activeBiz.copyWith(subscriptionTier: newTier.id);
      final repo = _ref.read(businessRepositoryProvider);
      final result = await repo.updateBusiness(updatedBiz);

      return result.fold(
        (failure) {
          AppLogger.e('Failed to change subscription tier: ${failure.message}');
          state = AsyncValue.error(failure.message, StackTrace.current);
          return false;
        },
        (savedBiz) {
          AppLogger.i('Subscription tier updated to ${newTier.displayName} for ${savedBiz.name}');
          // Update the in-memory active business
          _ref.read(currentBusinessProvider.notifier).select(savedBiz);
          // Invalidate user businesses so list updates
          _ref.invalidate(userBusinessesProvider);
          state = AsyncValue.data(newTier);
          return true;
        },
      );
    } catch (e, st) {
      AppLogger.e('Exception changing subscription tier: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, AsyncValue<SubscriptionTier>>((ref) {
  return SubscriptionController(ref);
});
