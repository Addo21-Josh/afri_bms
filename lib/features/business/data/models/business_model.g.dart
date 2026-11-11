// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BusinessModelImpl _$$BusinessModelImplFromJson(Map<String, dynamic> json) =>
    _$BusinessModelImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      defaultCurrency: json['default_currency'] as String? ?? 'GHS',
      supportedCurrencies:
          (json['supported_currencies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['GHS'],
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$BusinessModelImplToJson(_$BusinessModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'name': instance.name,
      'description': instance.description,
      'logo_url': instance.logoUrl,
      'default_currency': instance.defaultCurrency,
      'supported_currencies': instance.supportedCurrencies,
      'tax_rate': instance.taxRate,
      'address': instance.address,
      'phone': instance.phone,
      'email': instance.email,
      'is_active': instance.isActive,
      'subscription_tier': instance.subscriptionTier,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
