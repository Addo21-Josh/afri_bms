import 'package:freezed_annotation/freezed_annotation.dart';

part 'branch_entity.freezed.dart';

@freezed
class BranchEntity with _$BranchEntity {
  const factory BranchEntity({
    required String id,
    required String businessId,
    required String name,
    String? address,
    String? phone,
    @Default('NGN') String currency,
    @Default(false) bool isMain,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _BranchEntity;
}
