# Lumina eUICC — OpenEUICC native integration status

This document distinguishes repository/build evidence from real-card validation. Windows debug and dedicated-key release APK builds are recorded below; no ARA-M or USB CCID device evidence is currently recorded.

Lumina is an unprivileged application by design. Root, Magisk, Shizuku, system-app installation, and privileged telephony permissions are outside the product boundary. OMAPI access from the phone's SIM slot therefore depends on a card-side ARA-M rule matching Lumina's signing identity; USB CCID does not depend on the phone-slot ARA-M path.

## What is wired

| Layer | Status |
|---|---|
| Flutter UI | Home, profile, download, compatibility, and settings screens are present |
| Notification UI | Lists pending notifications only; process/delete actions are not exposed in Dart or Flutter |
| MethodChannel API | Profile/download/device operations and notification listing are exposed to Dart; native-only notification process/delete handlers remain |
| EventChannel download progress | Implemented in code, including confirmation/cancellation flow |
| OpenEUICC `app-common` + `lpac-jni` as Gradle modules | **Included under `third_party/OpenEUICC`** |
| `EuiccBridgePlugin` real LPA path | Implemented in code for profile operations, download, notification handlers, memory reset, eUICC info, and compatibility; not device-validated |
| Mock fallback | Debug builds only; release builds return `mode=unavailable` and no invented channel/profile |

## Intended runtime behaviour

1. App starts with `LuminaApplication` → provides OpenEUICC `DefaultAppContainer`.
2. `listChannels` tries OMAPI + USB via `DefaultEuiccChannelManager`.
3. If at least one channel opens → `mode=real` and all ops use `channel.lpa.*`.
4. If none open in a debug build → `mode=mock` supplies development-only UI data.
5. If none open in a release build → `mode=unavailable` with no fabricated channel or profile.

The read-only compatibility probe reports the running package and signing SHA-1, then attempts each OMAPI phone slot with the configured ISD-R AIDs. It distinguishes ARA-M denial, an unavailable ISD-R, and other sanitized failure types without returning EID, ICCID, or raw exception messages. Opening and closing these logical channels does not mutate the card.

These branches are derived from the current implementation. They are not evidence that a physical card or reader has completed the full lifecycle.

## Pinned build toolchain

On Windows, use the checked-in wrapper and pinned Flutter version:

```powershell
git clone https://github.com/Syngnat/lumina-euicc.git
cd lumina-euicc
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

A clean checkout must already contain the vendored `third_party/OpenEUICC` tree. Do not substitute an arbitrary upstream revision to repair an incomplete checkout.

Requirements:

- Flutter **3.44.9**
- JDK 17
- Android SDK platforms 35 and 36, plus Build Tools 34.0.0 and 35.0.0
- Android NDK **28.2.13676358** for the app and transitive pub package `jni` 1.0.3 through Flutter's `flutter.ndkVersion`
- Android NDK **26.1.10909125** for vendored OpenEUICC `lpac-jni`
- CMake 3.22.1 for `jni` 1.0.3's `externalNativeBuild.cmake` path
- The checked-in Gradle 8.9 wrapper

Both native paths are active: OpenEUICC `lpac-jni` uses Gradle `externalNativeBuild.ndkBuild`, while pub package `jni` 1.0.3 invokes `externalNativeBuild.cmake`. The Lumina app compiles against SDK 36 and targets SDK 35; vendored `app-common` and `lpac-jni` compile against SDK 35.

## Verified local baseline (2026-08-08)

On Windows with Flutter 3.44.9 and JDK 21 (CI remains pinned to JDK 17), after
the legal-screen and native-ZXing changes:

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: 21 tests passed.

The native baseline was rerun after those changes:

- `android/gradlew.bat :app:testDebugUnitTest`: 32 tests passed, 0 failures/errors, including the native-ZXing session tests.
- Universal and `--split-per-abi` release builds succeeded with the dedicated release key; `apksigner verify --verbose --print-certs` passed using APK Signature Scheme v2 for all four APKs.
- Release certificate SHA-256: `1F:C1:52:76:70:A8:0B:2B:B5:A8:1F:FC:D2:D8:D7:82:C2:AD:00:3A:21:8F:2C:AD:42:9D:30:08:81:07:D8:9F`.
- APK metadata: `top.syngnat.lumina.euicc`, version `0.1.0`, compile SDK 36, target SDK 35; the universal APK contains `arm64-v8a`, `armeabi-v7a`, and `x86_64`, while each split APK contains exactly its named ABI.
- `zipalign -c -P 16 4` passed for all four release APKs. Every arm64-v8a and x86_64 ELF `LOAD` segment has alignment of at least `2**14`; this includes vendored `liblpac-jni.so`.

This is build/test evidence only. It does not validate OMAPI, ARA-M access, USB CCID, APDU traffic, profile mutation, or download behaviour on physical hardware. Consult GitHub Actions for the exact pushed-commit result and current native verification.

## GitHub Actions, Releases, and Android compatibility

`.github/workflows/ci.yml` uses pinned actions on Ubuntu 24.04:

- `verify` runs for pull requests, `main` pushes, version tags, and manual dispatch. It enforces the lockfile, runs Dart analysis, Flutter and Kotlin tests, builds the debug APK, checks package/min/compile/target SDK metadata and ABIs, then checks both APK ZIP alignment and every 64-bit ELF `LOAD` segment for 16 KB compatibility.
- `release` runs only after `verify` on a trusted `main` ref or matching `v*` tag allowed by the `release-signing` Environment. The job builds universal plus three ABI-specific APKs with the dedicated key and verifies v2 signing, one signer, the expected certificate fingerprint, exact ABI metadata, unprivileged manifest policy, ZIP alignment, and 64-bit ELF alignment.
- `publish_release` runs only for a `v<pubspec version name>` tag already contained in `main`. It downloads the verified artifact with `actions: read` and creates the GitHub Release with `contents: write`; it has no signing environment or keystore secrets.

After verification, a trusted build publishes one Actions artifact containing
the four signed APKs, `lumina-euicc-source-<full-commit-sha>.zip`,
`lumina-euicc-dependency-sources-<full-commit-sha>.zip`, `SOURCE_INFO.txt`,
`SHA256SUMS`, Flutter/Gradle dependency inventories and source manifests, and
root/nested license materials. A matching version-tag run also exposes every
top-level file as a GitHub Release asset, including a ZIP of the nested license
tree. The dependency archive contains complete hosted
Pub package trees plus available Maven source JARs and cached POMs; the manifest
marks unavailable Maven sources and records candidate URLs. The source metadata
records the repository, full commit and commit URL, package/version, build
toolchain, and exact Flutter framework/engine source revisions. The tracked
`third_party/OpenEUICC` directory in that exact Lumina commit is the vendored
source used by the APK; this repository does not record a separate upstream
OpenEUICC revision.

GitHub-hosted runners cannot prove OPPO/ColorOS OMAPI or ARA-M behaviour. With
the phone connected, confirm its kernel page size separately:

```powershell
adb shell getconf PAGE_SIZE
```

`16384` means the device uses 16 KB pages. Regardless of that value, profile discovery and mutations still require a physical-card test and an ARA-M rule matching this app's package/certificate identity.

The dedicated Lumina certificate has ARA-M SHA-1 fingerprint `10:0C:A7:FD:2C:E4:B7:12:BA:3C:88:4C:AE:20:FD:33:25:ED:85:E0`. EasyEUICC-compatible cards commonly authorize EasyEUICC's different certificate; that rule cannot authorize Lumina. For rootless phone-slot use, provision an additional card rule for Lumina (and package `top.syngnat.lumina.euicc` when package-bound), or use a USB CCID reader. This is a card access-control requirement, not an Android runtime permission that the user can approve.

## License

- Lumina-owned code is Copyright (C) 2026 Syngnat and licensed
  GPL-3.0-only under the root `LICENSE`; `LICENSES_SCOPE.md` defines the scope.
- `third_party/OpenEUICC/LICENSE` is GPL-3.0-only.
- lpac-jni, lpac components, cJSON, and registry dependencies retain their own
  bundled or upstream licenses; they must not all be described as
  GPL-3.0-only. See `THIRD_PARTY_NOTICES.md` and nested license files.
- CI distribution keeps all APK variants, exact-commit project source, dependency source
  archive/manifests, dependency inventories, notices, source metadata, and
  checksums in one artifact. Redistribution must preserve that
  corresponding-source and notice set.

## Remaining gaps (honest)

- Reproduce the local baseline in GitHub Actions after the changes are committed and pushed.
- Align bridge channel-manager ownership with OpenEUICC's `EuiccChannelManagerService`; upstream marks independent long-lived manager references unsupported.
- Add Dart API and Flutter actions for notification process/delete if parity requires them.
- Not every OpenEUICC UI-only setting screen is reimplemented in Flutter (developer options, ISD-R AID editor, logs viewer). Core profile/download paths are present and build successfully but still need device evidence.
- Flutter 3.44.9 warns that Gradle 8.9, AGP 8.7.0, and Kotlin 2.0.21 are nearing the end of its support window; migrate them together only after checking vendored OpenEUICC compatibility.
- Privileged internal-eSIM path (OpenEUICC system app) is intentionally out of scope — same as EasyEUICC unprivileged.
- Real-device validation still needs your phone + ARA-M card / USB reader.
- Release signing is wired to the dedicated project key; secure backup and
  recovery of that key remain an owner responsibility. CI now packages the APK
  with matching source and license materials, and future dependency changes
  must keep those materials current.
