// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'branch_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BranchEntity {
  String get id => throw _privateConstructorUsedError;
  String get businessId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  bool get isMain => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BranchEntityCopyWith<BranchEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BranchEntityCopyWith<$Res> {
  factory $BranchEntityCopyWith(
    BranchEntity value,
    $Res Function(BranchEntity) then,
  ) = _$BranchEntityCopyWithImpl<$Res, BranchEntity>;
  @useResult
  $Res call({
    String id,
    String businessId,
    String name,
    String? address,
    String? phone,
    String currency,
    bool isMain,
    bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$BranchEntityCopyWithImpl<$Res, $Val extends BranchEntity>
    implements $BranchEntityCopyWith<$Res> {
  _$BranchEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = null,
    Object? name = null,
    Object? address = freezed,
    Object? phone = freezed,
    Object? currency = null,
    Object? isMain = null,
    Object? isActive = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            businessId: null == businessId
                ? _value.businessId
                : businessId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String?,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            isMain: null == isMain
                ? _value.isMain
                : isMain // ignore: cast_nullable_to_non_nullable
                      as bool,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BranchEntityImplCopyWith<$Res>
    implements $BranchEntityCopyWith<$Res> {
  factory _$$BranchEntityImplCopyWith(
    _$BranchEntityImpl value,
    $Res Function(_$BranchEntityImpl) then,
  ) = __$$BranchEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String businessId,
    String name,
    String? address,
    String? phone,
    String currency,
    bool isMain,
    bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$BranchEntityImplCopyWithImpl<$Res>
    extends _$BranchEntityCopyWithImpl<$Res, _$BranchEntityImpl>
    implements _$$BranchEntityImplCopyWith<$Res> {
  __$$BranchEntityImplCopyWithImpl(
    _$BranchEntityImpl _value,
    $Res Function(_$BranchEntityImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = null,
    Object? name = null,
    Object? address = freezed,
    Object? phone = freezed,
    Object? currency = null,
    Object? isMain = null,
    Object? isActive = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$BranchEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        businessId: null == businessId
            ? _value.businessId
            : businessId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String?,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        isMain: null == isMain
            ? _value.isMain
            : isMain // ignore: cast_nullable_to_non_nullable
                  as bool,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$BranchEntityImpl implements _BranchEntity {
  const _$BranchEntityImpl({
    required this.id,
    required this.businessId,
    required this.name,
    this.address,
    this.phone,
    this.currency = 'GHS',
    this.isMain = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  @override
  final String id;
  @override
  final String businessId;
  @override
  final String name;
  @override
  final String? address;
  @override
  final String? phone;
  @override
  @JsonKey()
  final String currency;
  @override
  @JsonKey()
  final bool isMain;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'BranchEntity(id: $id, businessId: $businessId, name: $name, address: $address, phone: $phone, currency: $currency, isMain: $isMain, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BranchEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.isMain, isMain) || other.isMain == isMain) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    businessId,
    name,
    address,
    phone,
    currency,
    isMain,
    isActive,
    createdAt,
    updatedAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BranchEntityImplCopyWith<_$BranchEntityImpl> get copyWith =>
      __$$BranchEntityImplCopyWithImpl<_$BranchEntityImpl>(this, _$identity);
}

abstract class _BranchEntity implements BranchEntity {
  const factory _BranchEntity({
    required final String id,
    required final String businessId,
    required final String name,
    final String? address,
    final String? phone,
    final String currency,
    final bool isMain,
    final bool isActive,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$BranchEntityImpl;

  @override
  String get id;
  @override
  String get businessId;
  @override
  String get name;
  @override
  String? get address;
  @override
  String? get phone;
  @override
  String get currency;
  @override
  bool get isMain;
  @override
  bool get isActive;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$BranchEntityImplCopyWith<_$BranchEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
