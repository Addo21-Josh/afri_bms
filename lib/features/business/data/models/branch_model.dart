import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/branch_entity.dart';

part 'branch_model.freezed.dart';
part 'branch_model.g.dart';

@freezed
class BranchModel with _$BranchModel {
  const BranchModel._();

  const factory BranchModel({
    required String id,
    @JsonKey(name: 'business_id') required String businessId,
    required String name,
    String? address,
    String? phone,
    @Default('GHS') String currency,
    @JsonKey(name: 'is_main') @Default(false) bool isMain,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _BranchModel;

  factory BranchModel.fromJson(Map<String, dynamic> json) => _$BranchModelFromJson(json);

  BranchEntity toEntity() {
    return BranchEntity(
      id: id,
      businessId: businessId,
      name: name,
      address: address,
      phone: phone,
      currency: currency,
      isMain: isMain,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory BranchModel.fromEntity(BranchEntity entity) {
    return BranchModel(
      id: entity.id,
      businessId: entity.businessId,
      name: entity.name,
      address: entity.address,
      phone: entity.phone,
      currency: entity.currency,
      isMain: entity.isMain,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
