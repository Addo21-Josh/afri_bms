# DEPENDENCIES.md — Afri_BMS Package Dependencies

> Complete list of Flutter/Dart packages required with versions and purposes.

---

## pubspec.yaml Dependencies

```yaml
name: afri_bms
description: "African Business Management System"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.11.5

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # ─── State Management ───
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # ─── Routing ───
  go_router: ^14.8.1

  # ─── Local Database ───
  isar: ^4.0.0-dev.14
  isar_flutter_libs: ^4.0.0-dev.14

  # ─── Backend ───
  supabase_flutter: ^2.8.3

  # ─── Network ───
  dio: ^5.7.0
  connectivity_plus: ^6.1.1

  # ─── Code Generation (runtime) ───
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

  # ─── Functional Programming ───
  fpdart: ^1.1.0

  # ─── UI / Design ───
  cupertino_icons: ^1.0.8
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.16
  cached_network_image: ^3.4.1
  shimmer: ^3.0.0
  lottie: ^3.2.0
  fl_chart: ^0.70.2
  flutter_staggered_animations: ^1.1.1

  # ─── Barcode ───
  mobile_scanner: ^6.0.2
  barcode_widget: ^2.0.4

  # ─── PDF & Printing ───
  pdf: ^3.11.2
  printing: ^5.13.5

  # ─── Thermal Printing ───
  esc_pos_utils: ^1.1.0
  esc_pos_bluetooth: ^0.4.1

  # ─── Sharing ───
  share_plus: ^10.1.3

  # ─── Storage ───
  flutter_secure_storage: ^9.2.3
  path_provider: ^2.1.5
  path: ^1.9.0

  # ─── Image ───
  image_picker: ^1.1.2
  flutter_image_compress: ^2.3.0

  # ─── Background Work ───
  workmanager: ^0.5.2

  # ─── Utils ───
  uuid: ^4.5.1
  intl: ^0.19.0
  equatable: ^2.0.7
  collection: ^1.19.0
  logger: ^2.5.0
  url_launcher: ^6.3.1
  package_info_plus: ^8.1.3
  device_info_plus: ^11.2.1
  permission_handler: ^11.3.1

  # ─── In-App Purchase ───
  in_app_purchase: ^3.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # ─── Code Generation ───
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  riverpod_generator: ^2.6.3
  isar_generator: ^4.0.0-dev.14

  # ─── Linting ───
  flutter_lints: ^6.0.0
  custom_lint: ^0.7.1
  riverpod_lint: ^2.6.3

  # ─── Testing ───
  mocktail: ^1.0.4
  golden_toolkit: ^0.15.0

flutter:
  uses-material-design: true
  generate: true  # For l10n

  assets:
    - assets/images/
    - assets/icons/
    - assets/lottie/
    - assets/fonts/

  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Regular.ttf
        - asset: assets/fonts/PlusJakartaSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/PlusJakartaSans-Bold.ttf
          weight: 700
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
        - asset: assets/fonts/JetBrainsMono-Medium.ttf
          weight: 500
```

---

## l10n.yaml

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/generated/l10n
synthetic-package: false
nullable-getter: false
```

---

## Package Purposes

| Package | Purpose | Layer |
|---|---|---|
| `flutter_riverpod` | State management & DI | Presentation |
| `riverpod_annotation` | Code-gen annotations | All |
| `go_router` | Declarative routing with guards | Presentation |
| `isar` / `isar_flutter_libs` | Local NoSQL database | Data |
| `supabase_flutter` | Backend (auth, database, storage, realtime) | Data |
| `dio` | HTTP client with interceptors | Data |
| `connectivity_plus` | Network connectivity monitoring | Core |
| `freezed_annotation` / `freezed` | Immutable classes & unions | Domain/Data |
| `json_annotation` / `json_serializable` | JSON serialization | Data |
| `fpdart` | `Either<L,R>`, `Option<T>` for error handling | Domain |
| `google_fonts` | Plus Jakarta Sans & Inter fonts | Presentation |
| `flutter_svg` | SVG icon/illustration rendering | Presentation |
| `cached_network_image` | Image caching | Presentation |
| `shimmer` | Skeleton loading effects | Presentation |
| `lottie` | Rich animations (success, empty states) | Presentation |
| `fl_chart` | Charts (line, bar, pie) for reports | Presentation |
| `mobile_scanner` | Camera barcode/QR scanning | Feature |
| `barcode_widget` | Barcode/QR code generation | Feature |
| `pdf` | PDF document generation | Feature |
| `printing` | PDF printing & sharing | Feature |
| `esc_pos_utils` | ESC/POS command generation | Feature |
| `esc_pos_bluetooth` | Bluetooth thermal printer | Feature |
| `share_plus` | Native share sheet | Feature |
| `flutter_secure_storage` | Encrypted token storage | Core |
| `path_provider` | File system paths | Core |
| `image_picker` | Camera/gallery image selection | Feature |
| `flutter_image_compress` | Image compression before upload | Feature |
| `workmanager` | Background task scheduling | Core |
| `uuid` | UUID generation for offline records | Core |
| `intl` | Date/number formatting, i18n | Core |
| `in_app_purchase` | Subscription management | Feature |
| `mocktail` | Test mocking | Test |
| `golden_toolkit` | Visual regression testing | Test |

---

## Android Permissions (AndroidManifest.xml)

```xml
<!-- Network -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Camera (barcode scanning, product photos) -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Bluetooth (thermal printing) -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />

<!-- Storage (receipts, exports) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- Location (for Bluetooth scanning on Android 12+) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

## iOS Permissions (Info.plist)

```xml
<!-- Camera -->
<key>NSCameraUsageDescription</key>
<string>Afri_BMS needs camera access to scan barcodes and take product photos.</string>

<!-- Photo Library -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Afri_BMS needs photo access to upload product images.</string>

<!-- Bluetooth -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Afri_BMS uses Bluetooth to connect to thermal receipt printers.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Afri_BMS uses Bluetooth to connect to thermal receipt printers.</string>

<!-- Location (for Bluetooth) -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access is required to discover nearby Bluetooth printers.</string>
```
