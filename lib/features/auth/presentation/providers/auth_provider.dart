import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afri_bms/features/auth/domain/entities/user_entity.dart';
import 'package:afri_bms/features/auth/domain/usecases/auth_usecases.dart';
import 'package:afri_bms/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:afri_bms/features/auth/data/datasources/auth_remote_datasource.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/sync/presentation/providers/sync_provider.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRemoteDatasource authRemoteDatasource(AuthRemoteDatasourceRef ref) {
  return AuthRemoteDatasourceImpl(Supabase.instance.client);
}

@riverpod
AuthRepositoryImpl authRepository(AuthRepositoryRef ref) {
  final remote = ref.watch(authRemoteDatasourceProvider);
  return AuthRepositoryImpl(remoteDatasource: remote);
}

@riverpod
SignInUseCase signInUseCase(SignInUseCaseRef ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
SignUpUseCase signUpUseCase(SignUpUseCaseRef ref) {
  return SignUpUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
SignOutUseCase signOutUseCase(SignOutUseCaseRef ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
GetCurrentUserUseCase getCurrentUserUseCase(GetCurrentUserUseCaseRef ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<UserEntity?> build() async {
    final getCurrentUser = ref.watch(getCurrentUserUseCaseProvider);
    final result = await getCurrentUser();
    
    return result.fold(
      (failure) {
        // We could log this
        return null;
      },
      (user) => user,
    );
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    final signInUser = ref.read(signInUseCaseProvider);
    final result = await signInUser(email, password);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (user) {
        ref.read(localCacheServiceProvider).cacheLastUserId(user.id);
        SessionManager.invalidateAllSessionData(ref);
        return AsyncValue.data(user);
      },
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    final signUpUser = ref.read(signUpUseCaseProvider);
    final result = await signUpUser(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (user) {
        ref.read(localCacheServiceProvider).cacheLastUserId(user.id);
        return AsyncValue.data(user);
      },
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    final signOutUser = ref.read(signOutUseCaseProvider);
    final result = await signOutUser();

    await ref.read(localCacheServiceProvider).clearLastUserId();
    SessionManager.invalidateAllSessionData(ref);
    
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }
}
