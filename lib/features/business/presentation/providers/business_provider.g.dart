// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$businessRemoteDatasourceHash() =>
    r'50fd9eba9f2314408ae4178180ebc71dfbec9e5b';

/// See also [businessRemoteDatasource].
@ProviderFor(businessRemoteDatasource)
final businessRemoteDatasourceProvider =
    AutoDisposeProvider<BusinessRemoteDatasource>.internal(
      businessRemoteDatasource,
      name: r'businessRemoteDatasourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$businessRemoteDatasourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef BusinessRemoteDatasourceRef =
    AutoDisposeProviderRef<BusinessRemoteDatasource>;
String _$businessRepositoryHash() =>
    r'12c766c8d71d09b331a4ec549eb084903c6f73bd';

/// See also [businessRepository].
@ProviderFor(businessRepository)
final businessRepositoryProvider =
    AutoDisposeProvider<BusinessRepository>.internal(
      businessRepository,
      name: r'businessRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$businessRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef BusinessRepositoryRef = AutoDisposeProviderRef<BusinessRepository>;
String _$branchRepositoryHash() => r'2c727ef6d0b62f2dfb575cc5982b0899faf852fe';

/// See also [branchRepository].
@ProviderFor(branchRepository)
final branchRepositoryProvider = AutoDisposeProvider<BranchRepository>.internal(
  branchRepository,
  name: r'branchRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$branchRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BranchRepositoryRef = AutoDisposeProviderRef<BranchRepository>;
String _$userBusinessesHash() => r'4883b9cc1d261744ad3a5d9b25d73dcf79175003';

/// See also [userBusinesses].
@ProviderFor(userBusinesses)
final userBusinessesProvider =
    AutoDisposeFutureProvider<List<BusinessEntity>>.internal(
      userBusinesses,
      name: r'userBusinessesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userBusinessesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef UserBusinessesRef = AutoDisposeFutureProviderRef<List<BusinessEntity>>;
String _$businessBranchesHash() => r'472feb0b0ab072e0ca387654f9b2a1147dec37eb';

/// See also [businessBranches].
@ProviderFor(businessBranches)
final businessBranchesProvider =
    AutoDisposeFutureProvider<List<BranchEntity>>.internal(
      businessBranches,
      name: r'businessBranchesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$businessBranchesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef BusinessBranchesRef = AutoDisposeFutureProviderRef<List<BranchEntity>>;
String _$currentBusinessHash() => r'8ba6ac33046ca988b0e1e977ee49d82ba0cd9ba0';

/// See also [CurrentBusiness].
@ProviderFor(CurrentBusiness)
final currentBusinessProvider =
    AutoDisposeNotifierProvider<CurrentBusiness, BusinessEntity?>.internal(
      CurrentBusiness.new,
      name: r'currentBusinessProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentBusinessHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentBusiness = AutoDisposeNotifier<BusinessEntity?>;
String _$currentBranchHash() => r'c8751f9617279a5ccd028c870713840e4bccb486';

/// See also [CurrentBranch].
@ProviderFor(CurrentBranch)
final currentBranchProvider =
    AutoDisposeNotifierProvider<CurrentBranch, BranchEntity?>.internal(
      CurrentBranch.new,
      name: r'currentBranchProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentBranchHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentBranch = AutoDisposeNotifier<BranchEntity?>;
String _$businessControllerHash() =>
    r'6eb6ad9ea5398411c9d45eec45f03150f43e4512';

/// See also [BusinessController].
@ProviderFor(BusinessController)
final businessControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      BusinessController,
      BusinessEntity?
    >.internal(
      BusinessController.new,
      name: r'businessControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$businessControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BusinessController = AutoDisposeAsyncNotifier<BusinessEntity?>;
String _$branchControllerHash() => r'80eb023d28c24a40c847e3bfe4462542a5e4c1a9';

/// See also [BranchController].
@ProviderFor(BranchController)
final branchControllerProvider =
    AutoDisposeAsyncNotifierProvider<BranchController, BranchEntity?>.internal(
      BranchController.new,
      name: r'branchControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$branchControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BranchController = AutoDisposeAsyncNotifier<BranchEntity?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
