# AGENT.md — Afri_BMS Development Agent Guide

> **This file is the single source of truth for any AI agent working on this project.**
> Read this file first before writing any code.

---

## 1. Project Identity

| Field | Value |
|---|---|
| **App Name** | Afri_BMS |
| **Full Name** | African Business Management System |
| **Package ID** | `com.afribms.app` |
| **Platforms** | Android, iOS |
| **Language** | Dart / Flutter |
| **Min SDK** | Flutter 3.11+ / Dart 3.11+ |
| **Target Audience** | Small & medium businesses in West Africa (Nigeria, Ghana) |
| **Monetization** | Freemium (free tier + paid plans) |

---

## 2. Tech Stack

| Layer | Technology | Version |
|---|---|---|
| **Framework** | Flutter | 3.11+ |
| **State Management** | Riverpod (with code generation) | ^2.5+ |
| **Local Database** | Isar | ^4.0+ |
| **Backend / Auth** | Supabase | Latest |
| **Cloud Database** | Supabase PostgreSQL | - |
| **Real-time Sync** | Supabase Realtime + custom sync engine | - |
| **Routing** | GoRouter | ^14+ |
| **DI / Service Locator** | Riverpod (no GetIt needed) | - |
| **HTTP Client** | Dio | ^5+ |
| **Barcode** | mobile_scanner + barcode_widget | Latest |
| **PDF Generation** | pdf + printing | Latest |
| **Thermal Printing** | esc_pos_utils + esc_pos_bluetooth | Latest |
| **i18n** | flutter_localizations + intl + ARB files | - |
| **Code Gen** | freezed, json_serializable, riverpod_generator, build_runner | Latest |
| **Testing** | flutter_test, mocktail, integration_test | - |
| **CI/CD** | GitHub Actions / Codemagic | - |

---

## 3. Project Structure (Feature-First)

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # MaterialApp.router configuration
├── bootstrap.dart                     # Initialization (Isar, Supabase, etc.)
│
├── core/                              # Shared infrastructure
│   ├── constants/                     # App-wide constants
│   │   ├── app_constants.dart
│   │   ├── api_constants.dart
│   │   └── storage_keys.dart
│   ├── config/                        # Environment & flavor configs
│   │   ├── env_config.dart
│   │   └── supabase_config.dart
│   ├── database/                      # Isar database setup
│   │   ├── isar_database.dart
│   │   └── collections/              # Isar collection schemas
│   ├── errors/                        # Custom exceptions & failures
│   │   ├── app_exception.dart
│   │   └── failure.dart
│   ├── extensions/                    # Dart extensions
│   ├── mixins/                        # Reusable mixins
│   ├── network/                       # Network layer
│   │   ├── dio_client.dart
│   │   ├── network_info.dart
│   │   └── interceptors/
│   ├── router/                        # GoRouter configuration
│   │   ├── app_router.dart
│   │   ├── route_names.dart
│   │   └── guards/                   # Route guards (auth, role)
│   ├── sync/                          # Background sync engine
│   │   ├── sync_engine.dart
│   │   ├── sync_queue.dart
│   │   └── conflict_resolver.dart
│   ├── theme/                         # Material 3 theming
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_dimensions.dart
│   ├── utils/                         # Utility functions
│   │   ├── currency_formatter.dart
│   │   ├── date_formatter.dart
│   │   ├── validators.dart
│   │   └── logger.dart
│   └── widgets/                       # Shared/reusable widgets
│       ├── app_scaffold.dart
│       ├── loading_overlay.dart
│       ├── empty_state.dart
│       ├── error_widget.dart
│       └── adaptive_dialog.dart
│
├── features/                          # Feature modules
│   ├── auth/                          # Authentication
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── auth_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── sign_up.dart
│   │   │       ├── sign_in.dart
│   │   │       └── sign_out.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   ├── register_screen.dart
│   │       │   └── forgot_password_screen.dart
│   │       └── widgets/
│   │
│   ├── business/                      # Business management
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── branch/                        # Branch management
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── user_management/               # Staff/role management
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── inventory/                     # Products, stock, variants
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── sales/                         # POS, cart, checkout
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── expenses/                      # Expense tracking
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── customers/                     # Customer management
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── suppliers/                     # Supplier management
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── debt_credit/                   # Debt/credit ledger
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── payments/                      # Cash, mobile money, payment methods
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── receipts/                      # Receipt generation & printing
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── reports/                       # Analytics & reports
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── barcode/                       # Barcode scan, generate, print
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── settings/                      # App & business settings
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── dashboard/                     # Main dashboard
│       ├── data/
│       ├── domain/
│       └── presentation/
│
├── l10n/                              # Localization
│   ├── app_en.arb                     # English (default)
│   └── arb_template.arb
│
└── generated/                         # Auto-generated files
    └── l10n/
```

---

## 4. Architecture: Clean Architecture + Riverpod

### 4.1 Layer Rules

Each feature follows **Clean Architecture** with three layers:

| Layer | Purpose | Allowed Dependencies |
|---|---|---|
| **Domain** | Business logic, entities, use cases, repository contracts | None (pure Dart) |
| **Data** | Repository implementations, models, data sources | Domain layer |
| **Presentation** | UI, providers, screens, widgets | Domain layer (via Riverpod) |

### 4.2 Dependency Flow

```
Presentation → Domain ← Data
     ↓            ↑        ↓
  Riverpod    Entities   Supabase / Isar
  Providers   UseCases   DataSources
```

### 4.3 Provider Architecture

```dart
// 1. Repository provider (injected)
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    remoteDatasource: ref.watch(authRemoteDatasourceProvider),
    localDatasource: ref.watch(authLocalDatasourceProvider),
  );
}

// 2. UseCase provider
@riverpod
SignIn signInUseCase(Ref ref) {
  return SignIn(ref.watch(authRepositoryProvider));
}

// 3. State Notifier for UI
@riverpod
class AuthController extends _$AuthController {
  @override
  AsyncValue<User?> build() => const AsyncValue.data(null);

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(signInUseCaseProvider).call(email, password),
    );
  }
}
```

---

## 5. Coding Conventions

### 5.1 Naming

| Item | Convention | Example |
|---|---|---|
| Files | `snake_case` | `auth_repository.dart` |
| Classes | `PascalCase` | `AuthRepository` |
| Variables/Functions | `camelCase` | `getUserById` |
| Constants | `camelCase` with `k` prefix | `kDefaultTimeout` |
| Enums | `PascalCase` + `camelCase` values | `UserRole.branchManager` |
| Providers | `camelCase` + `Provider` suffix (auto-generated) | `authControllerProvider` |
| Private members | `_camelCase` | `_isLoading` |
| Database collections | `PascalCase` matching entity | `ProductCollection` |
| Routes | `camelCase` | `salesDashboard` |

### 5.2 File Organization Rules

1. **One public class per file** (excluding small helper classes)
2. **Barrel files** (`index.dart`) only at feature level, never in `core/`
3. **Import order**: dart → flutter → packages → core → features → relative
4. **No relative imports** crossing feature boundaries — use package imports
5. **Freezed** for all domain entities and data models
6. **Result type** — use `Either<Failure, T>` from `fpdart` for error handling

### 5.3 Code Quality Rules

```yaml
# Enforced via analysis_options.yaml
- always_declare_return_types
- annotate_overrides
- avoid_print (use Logger)
- prefer_const_constructors
- prefer_const_declarations
- prefer_final_locals
- require_trailing_commas
- sort_constructors_first
- use_key_in_widget_constructors
```

### 5.4 Error Handling Pattern

```dart
// Domain layer — Failure class
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class ServerFailure extends Failure { ... }
class CacheFailure extends Failure { ... }
class NetworkFailure extends Failure { ... }

// Repository returns Either<Failure, T>
Future<Either<Failure, User>> getUser(String id);

// Presentation layer — handle in provider
state = await AsyncValue.guard(() async {
  final result = await ref.read(getUserProvider).call(id);
  return result.fold(
    (failure) => throw AppException(failure.message),
    (user) => user,
  );
});
```

---

## 6. Database Strategy

### 6.1 Offline-First Architecture

```
┌─────────────┐     ┌──────────┐     ┌──────────────┐
│   UI Layer   │────▶│   Isar   │────▶│   Supabase   │
│  (Riverpod)  │     │  (Local) │     │   (Cloud)    │
└─────────────┘     └──────────┘     └──────────────┘
                         ↑                    │
                         │    Sync Engine     │
                         └────────────────────┘
```

### 6.2 Sync Rules

1. **All writes go to Isar first** — never write directly to Supabase from UI
2. **Sync queue** tracks pending changes with timestamps
3. **Conflict resolution**: Last-write-wins with server timestamp authority
4. **Sync triggers**: On connectivity change, periodic (every 5 min), manual pull-to-refresh
5. **Idempotent operations** — all sync operations must be safely retryable
6. **Soft deletes** — never hard delete; use `deletedAt` timestamp

### 6.3 Isar Collections Naming

All Isar collections mirror Supabase table names with `Collection` suffix:
- `UserCollection` → `users` table
- `ProductCollection` → `products` table
- `SaleCollection` → `sales` table

---

## 7. Authentication & Authorization

### 7.1 Auth Flow

1. User signs up → Supabase Auth creates account → user gets `admin` role
2. Admin creates staff accounts → Supabase Auth + `user_roles` table
3. JWT token stored locally → Isar
4. Token refresh handled by Supabase SDK automatically
5. Role checked on every route via GoRouter guards

### 7.2 Role Permissions Matrix

| Permission | Admin | Branch Manager | Salesperson | Cashier |
|---|---|---|---|---|
| Create business | ✅ | ❌ | ❌ | ❌ |
| Manage branches | ✅ | ❌ | ❌ | ❌ |
| Create staff accounts | ✅ | ❌ | ❌ | ❌ |
| View all branches | ✅ | ❌ | ❌ | ❌ |
| Manage inventory | ✅ | ✅ | ❌ | ❌ |
| Create sales | ✅ | ✅ | ✅ | ✅ |
| Process payments | ✅ | ✅ | ✅ | ✅ |
| View reports | ✅ | ✅ (own branch) | ❌ | ❌ |
| Manage expenses | ✅ | ✅ | ❌ | ❌ |
| Manage customers | ✅ | ✅ | ✅ | ❌ |
| Manage suppliers | ✅ | ✅ | ❌ | ❌ |
| Manage debt/credit | ✅ | ✅ | ❌ | ❌ |
| View receipts | ✅ | ✅ | ✅ | ✅ |
| Custom permissions | ✅ (define) | — | — | — |

---

## 8. Multi-Currency Support

- Admin sets available currencies per business
- Default currency set per branch
- Exchange rates managed manually by admin
- All monetary values stored as `int` (minor units, e.g., kobo for NGN)
- Display formatting via `currency_formatter.dart`
- Supported: NGN, GHS, XOF, USD, EUR, GBP + extensible

---

## 9. Testing Strategy

| Type | Tool | Coverage Target |
|---|---|---|
| Unit tests | `flutter_test` + `mocktail` | Domain & Data layers: 90%+ |
| Widget tests | `flutter_test` | Critical UI components: 80%+ |
| Integration tests | `integration_test` | Core user flows: 100% |
| Golden tests | `golden_toolkit` | Design consistency |

### Test File Naming

```
test/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository_impl_test.dart
│   │   ├── domain/
│   │   │   └── sign_in_test.dart
│   │   └── presentation/
│   │       └── auth_controller_test.dart
```

---

## 10. Git & Branch Strategy

| Branch | Purpose |
|---|---|
| `main` | Production-ready code |
| `develop` | Integration branch |
| `feature/<name>` | New features |
| `bugfix/<name>` | Bug fixes |
| `release/<version>` | Release candidates |
| `hotfix/<name>` | Production hotfixes |

### Commit Convention

```
<type>(<scope>): <description>

Types: feat, fix, docs, style, refactor, test, chore, perf
Scope: auth, inventory, sales, sync, etc.

Example: feat(inventory): add batch expiry tracking
```

---

## 11. Build Phases

### Phase 1 — Foundation (Weeks 1-2)
- [ ] Project setup, dependencies, theme
- [ ] Core architecture (database, network, sync)
- [ ] Auth (signup, login, forgot password)
- [ ] Business creation & onboarding
- [ ] Branch management

### Phase 2 — Core Features (Weeks 3-5)
- [ ] User/role management
- [ ] Inventory (products, variants, stock)
- [ ] Sales (POS, cart, checkout)
- [ ] Payment methods (cash, mobile money)
- [ ] Customers & suppliers

### Phase 3 — Financial (Weeks 6-7)
- [ ] Expenses tracking
- [ ] Debt/credit ledger
- [ ] Receipt generation (PDF + thermal)
- [ ] Barcode scan/generate/print

### Phase 4 — Intelligence (Weeks 8-9)
- [ ] Reports & analytics
- [ ] Dashboard with charts
- [ ] Low stock alerts
- [ ] Auto-reorder suggestions

### Phase 5 — Polish (Weeks 10-11)
- [ ] Background sync optimization
- [ ] Offline mode hardening
- [ ] i18n framework
- [ ] Settings & preferences
- [ ] Performance optimization

### Phase 6 — Production (Week 12)
- [ ] Freemium gating
- [ ] App store assets
- [ ] CI/CD pipeline
- [ ] Security audit
- [ ] Beta testing

---

## 12. Critical Agent Rules

1. **NEVER skip Isar** — all data flows through local DB first
2. **NEVER hardcode strings** — use l10n ARB files
3. **NEVER use `print()`** — use the custom `Logger` class
4. **ALWAYS use freezed** for entities and models
5. **ALWAYS handle errors** with `Either<Failure, T>`
6. **ALWAYS write tests** alongside feature code
7. **ALWAYS run `dart format`** and `dart analyze` before committing
8. **ALWAYS use `const` constructors** where possible
9. **ALWAYS add doc comments** to public APIs
10. **NEVER import from `data/` in `presentation/`** — go through `domain/`
