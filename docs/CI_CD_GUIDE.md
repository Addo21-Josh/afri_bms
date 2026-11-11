# Afri_BMS — CI/CD Pipeline & Deployment Guide

This document explains the Continuous Integration and Continuous Deployment (CI/CD) pipelines set up for Afri_BMS across **GitHub Actions**, **Fastlane**, and **Codemagic**.

---

## 1. Overview of Workflows

| Pipeline | Trigger | Target Artifacts | Purpose |
| :--- | :--- | :--- | :--- |
| **Multi-Platform CI** (`multi_platform_ci.yml`) | Push / PR on `main`, `master`, `develop`, dispatch | All platform binaries & coverage | Matrix build & verification across Android (APK/AAB), iOS (no-codesign), Web, and Desktop (Win/Linux/Mac). |
| **CI: Test & Lint** (`ci.yml`) | Push / PR on `main`, `master`, `develop` | `coverage/lcov.info` | Enforces code formatting, `flutter analyze`, and unit/widget tests (71+ tests). |
| **PR Build** (`pr_build.yml`) | Pull Request opened/synced | Debug APK verification | Validates compilation and builds without crashing. |
| **Release Pipeline** (`release.yml`) | Git tag `v*.*.*` or manual trigger | Release `.aab` & `.apk` | Builds signed production Google Play bundle and universal APKs; creates a GitHub Release. |
| **Fastlane** (`android/fastlane/`) | Local command or CI trigger | Google Play Console | Deploys directly to Internal Testing or Production track using Google Service Account. |
| **Codemagic** (`codemagic.yaml`) | Cloud commit/tag trigger | Google Play & TestFlight | Cloud macOS runner for building and publishing Android (`.aab`) and iOS (`.ipa`). |

---

## 2. Multi-Platform CI Architecture (`multi_platform_ci.yml`)

The Multi-Platform CI workflow (`.github/workflows/multi_platform_ci.yml`) provides end-to-end continuous integration and cross-platform compilation verification across all supported Flutter platforms:

```
┌────────────────────────────────────────────────────────┐
│             Stage 1: Code Quality & Tests Gate         │
│  (dart format, flutter analyze, flutter test coverage) │
└──────────────────────────┬─────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┬──────────────────┐
        ▼                  ▼                  ▼                  ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   Android    │   │     iOS      │   │     Web      │   │   Desktop    │
│  (APK & AAB) │   │(No-Codesign) │   │  (Release)   │   │ (Win/Lin/Mac)│
└───────┬──────┘   └───────┬──────┘   └───────┬──────┘   └───────┬──────┘
        │                  │                  │                  │
        └──────────────────┼──────────────────┴──────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│            Stage 3: CI Summary & Health Report         │
│    (Markdown Table in $GITHUB_STEP_SUMMARY + Enforce)  │
└────────────────────────────────────────────────────────┘
```

### Stages & Capabilities
1. **Quality Gate (`ubuntu-latest`)**:
   - Dart code format verification (`dart format --set-exit-if-changed .`)
   - Static analysis (`flutter analyze --no-fatal-warnings --no-fatal-infos`)
   - Unit & widget test execution with coverage (`flutter test --coverage`)
   - Code coverage artifact archiving (`code-coverage-report`)

2. **Android Pipeline (`ubuntu-latest`)**:
   - JDK 17 & Flutter stable
   - Gradle wrapper and dependency caching (`~/.gradle/caches`)
   - Builds Debug APK (`flutter build apk --debug`)
   - Builds Release APK & AppBundle (`flutter build apk --release`, `flutter build appbundle --release`)
   - Archives APK and AAB artifacts

3. **iOS Pipeline (`macos-latest`)**:
   - macOS runner with CocoaPods & Xcode toolchain
   - Dependency & Pods caching (`~/.cocoapods`, `ios/Pods`)
   - Builds iOS application without code signing (`flutter build ios --no-codesign --debug`)
   - Validates native CocoaPods integration and iOS engine compilation

4. **Web Platform (`ubuntu-latest`)**:
   - Enables Flutter Web (`flutter config --enable-web`)
   - Compiles production release Web bundle (`flutter build web --release`)
   - Archives Web static distribution bundle

5. **Desktop Matrix (`ubuntu-latest`, `windows-latest`, `macos-latest`)**:
   - **Linux**: Installs GTK development headers (`libgtk-3-dev`, `ninja-build`, `pkg-config`), enables Linux desktop, and builds debug executable
   - **Windows**: Enables Windows desktop and compiles Windows executable bundle
   - **macOS**: Enables macOS desktop and compiles macOS application bundle

6. **Summary & Health Enforcement**:
   - Collects results across all matrix jobs
   - Publishes an execution summary table to `$GITHUB_STEP_SUMMARY`
   - Strictly enforces success on Quality Gate, Android, and iOS pipelines

---

## 3. GitHub Secrets Setup

To enable automated release signing and GitHub Actions uploads, add the following secrets under **Repository Settings → Secrets and variables → Actions**:

| Secret Name | Description | Example / Format |
| :--- | :--- | :--- |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded release `.keystore` / `.jks` file | Output of `base64 -w 0 upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | `your_keystore_password` |
| `ANDROID_KEY_ALIAS` | Key alias name inside keystore | `upload` or `afribms_key` |
| `ANDROID_KEY_PASSWORD` | Key private password | `your_key_password` |
| `SUPABASE_URL` | Production Supabase URL | `https://xxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | Production Supabase Anon Public Key | `eyJhbGciOiJIUzI1...` |

### How to Generate and Base64-Encode an Android Keystore

1. **Generate Keystore**:
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. **Convert to Base64 (Windows PowerShell)**:
   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/upload-keystore.jks")) | Set-Clipboard
   ```
3. Paste the copied string into GitHub Secret `ANDROID_KEYSTORE_BASE64`.

---

## 4. Fastlane Deployment (Google Play Store)

Fastlane is configured in [`android/fastlane/Fastfile`](file:///c:/Users/DELL/StudioProjects/afri_bms/android/fastlane/Fastfile).

### Prerequisites
1. Install Fastlane:
   ```bash
   gem install fastlane
   ```
2. Download your Google Play Console API service account JSON key file and place it at:
   `android/play_store_key.json` (or set `export SUPPLY_JSON_KEY_FILE=/path/to/key.json`).

### Running Fastlane Lanes
* **Run tests**:
  ```bash
  cd android && bundle exec fastlane test
  ```
* **Build production App Bundle**:
  ```bash
  cd android && bundle exec fastlane build
  ```
* **Deploy to Google Play Internal Testing**:
  ```bash
  cd android && bundle exec fastlane internal
  ```
* **Promote Internal track to Production**:
  ```bash
  cd android && bundle exec fastlane promote_to_production
  ```

---

## 5. Codemagic Cloud CI/CD

[`codemagic.yaml`](file:///c:/Users/DELL/StudioProjects/afri_bms/codemagic.yaml) provides automated builds without needing local Mac hardware for iOS.

* **Android Workflow**: Runs linter and unit tests, builds `.aab` and `.apk`, and submits to the Google Play Store internal track.
* **iOS Workflow**: Runs tests, builds `.ipa`, and submits directly to Apple TestFlight.
* **Environment Configuration**: Set `GPLAY_SERVICE_ACCOUNT_KEY` and `APP_STORE_CONNECT_KEY` in the Codemagic dashboard under **Environment Variables**.

---

## 6. Local Release Build Verification

To verify release builds locally prior to CI/CD:
```bash
# Verify release APK
flutter build apk --release

# Verify release Google Play App Bundle
flutter build appbundle --release
```
Both are configured with fallback signing in [`android/app/build.gradle.kts`](file:///c:/Users/DELL/StudioProjects/afri_bms/android/app/build.gradle.kts) so local testing works out of the box.
