import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/business_entity.dart';

part 'business_model.freezed.dart';
part 'business_model.g.dart';

@freezed
class BusinessModel with _$BusinessModel {
  const BusinessModel._();

  const factory BusinessModel({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    required String name,
    String? description,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'default_currency') @Default('GHS') String defaultCurrency,
    @JsonKey(name: 'supported_currencies') @Default(['GHS']) List<String> supportedCurrencies,
    @JsonKey(name: 'tax_rate') @Default(0.0) double taxRate,
    String? address,
    String? phone,
    String? email,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'subscription_tier') @Default('free') String subscriptionTier,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _BusinessModel;

  factory BusinessModel.fromJson(Map<String, dynamic> json) => _$BusinessModelFromJson(json);

  BusinessEntity toEntity() {
    return BusinessEntity(
      id: id,
      ownerId: ownerId,
      name: name,
      description: description,
      logoUrl: logoUrl,
      defaultCurrency: defaultCurrency,
      supportedCurrencies: supportedCurrencies,
      taxRate: taxRate,
      address: address,
      phone: phone,
      email: email,
      isActive: isActive,
      subscriptionTier: subscriptionTier,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory BusinessModel.fromEntity(BusinessEntity entity) {
    return BusinessModel(
      id: entity.id,
      ownerId: entity.ownerId,
      name: entity.name,
      description: entity.description,
      logoUrl: entity.logoUrl,
      defaultCurrency: entity.defaultCurrency,
      supportedCurrencies: entity.supportedCurrencies,
      taxRate: entity.taxRate,
      address: entity.address,
      phone: entity.phone,
      email: entity.email,
      isActive: entity.isActive,
      subscriptionTier: entity.subscriptionTier,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
