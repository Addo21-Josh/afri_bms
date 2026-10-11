import 'package:freezed_annotation/freezed_annotation.dart';

part 'business_entity.freezed.dart';

@freezed
class BusinessEntity with _$BusinessEntity {
  const factory BusinessEntity({
    required String id,
    required String ownerId,
    required String name,
    String? description,
    String? logoUrl,
    @Default('NGN') String defaultCurrency,
    @Default(['NGN']) List<String> supportedCurrencies,
    @Default(0.00) double taxRate,
    String? address,
    String? phone,
    String? email,
    @Default(true) bool isActive,
    @Default('free') String subscriptionTier,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _BusinessEntity;
}
