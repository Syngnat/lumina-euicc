# Lumina eUICC (Flutter)

Flutter UI for an EasyEUICC-aligned removable eUICC manager.

> **For AI agents / handoff:** read **[AGENTS.md](AGENTS.md)** first (purpose, architecture, current evidence, license, and build requirements).
>
> Status below describes code present in the repository. Real-card behaviour has not been validated on an ARA-M card or USB CCID reader.

Lumina is intentionally an ordinary, non-root Android app. It does not require or support Root, Magisk, Shizuku, installation as a system app, or privileged telephony permissions. In-phone access is limited to removable eUICC cards whose ARA-M rule authorizes Lumina's signing certificate; USB CCID is the other unprivileged path. Built-in phone eSIM management remains out of scope.

## Status

| Area | Current status |
|---|---|
| Material 3 UI | Implemented in Flutter |
| Language | Simplified Chinese and English; follows the Android system locale, with English fallback |
| Profile list / enable / disable / delete / rename | Flutter and native paths implemented; real-card validation pending |
| Download via activation code / QR + progress + confirm | UI, channel contract, and native path implemented; real-card validation pending |
| Compatibility check | Read-only package/signing identity, per-slot OMAPI/ARA-M, and LPA diagnostics implemented; no card identifier is exposed |
| Notifications | List UI implemented; native process/delete handlers are not exposed through the Dart API or UI |
| Memory reset | UI and bridge implemented; destructive real-card path not validated |
| OpenEUICC `lpac-jni` + `app-common` | Vendored, wired, and included in successful Windows debug and dedicated-key release APK builds; device validation remains |
| Mock fallback without hardware | Debug builds only; release builds show the real channel as unavailable instead of inventing profiles |
| Internal eSIM (privileged) | Out of scope |

## Architecture

```text
Flutter UI
  MethodChannel: top.syngnat.lumina.euicc/bridge
  EventChannel:  top.syngnat.lumina.euicc/task_events
        ↓
EuiccBridgePlugin (Kotlin)
        ↓
OpenEUICC DefaultEuiccChannelManager + LocalProfileAssistant (lpac-jni)
        ↓
OMAPI / USB CCID eUICC
```

## Quick start (Windows)

Use Flutter **3.44.9**, JDK 17, Android SDK platforms 35 and 36, Build Tools 34.0.0 and 35.0.0, NDKs **26.1.10909125** and **28.2.13676358**, and CMake 3.22.1. The two native toolchains serve different modules; see [native integration](docs/NATIVE_INTEGRATION.md) for the exact mapping and current build evidence.

```powershell
git clone https://github.com/Syngnat/lumina-euicc.git
cd lumina-euicc
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

A clean checkout is expected to contain `third_party/OpenEUICC`; do not silently replace it with an arbitrary upstream revision.

## Package

- App ID: `top.syngnat.lumina.euicc`
- Display name: Lumina eUICC

## Release signing

Release builds use a dedicated project key and never fall back to the Android debug key. Gradle first checks `android/key.properties`, then `%USERPROFILE%/.android/lumina-euicc/key.properties`; start from `android/key.properties.example` and never commit the populated file or keystore.

The current dedicated release certificate SHA-256 fingerprint is `1F:C1:52:76:70:A8:0B:2B:B5:A8:1F:FC:D2:D8:D7:82:C2:AD:00:3A:21:8F:2C:AD:42:9D:30:08:81:07:D8:9F`; its ARA-M SHA-1 fingerprint is `10:0C:A7:FD:2C:E4:B7:12:BA:3C:88:4C:AE:20:FD:33:25:ED:85:E0`. This certificate is the identity relevant to future APK updates and card access rules; back up the keystore and its properties together.

An EasyEUICC-compatible card normally authorizes EasyEUICC's certificate, not this independently signed app. To use Lumina through the phone's SIM slot without Root, the card must also contain an ARA-M rule for Lumina's SHA-1 fingerprint (and `top.syngnat.lumina.euicc` if the rule binds a package name). Signing Lumina with a dedicated key does not automatically add that rule.

```powershell
flutter build apk --release --no-pub
```

## CI, releases, and Android 16

GitHub Actions runs Dart analysis, Flutter tests, Kotlin unit tests, a debug APK build, APK metadata checks, and both ZIP and ELF 16 KB alignment checks. A separate `release-signing` environment is restricted to `main` and builds a dedicated-key release APK, then verifies the package ID, SDK levels, ABIs, v2 signature, single signer, certificate fingerprint, and 16 KB compatibility.

On a trusted `main` run, CI publishes one release artifact containing the signed APK and its matching compliance materials: `lumina-euicc-source-<full-commit-sha>.zip`, `lumina-euicc-dependency-sources-<full-commit-sha>.zip`, `SOURCE_INFO.txt`, `SHA256SUMS`, resolved Flutter/Gradle inventories and source manifests, and root/nested license notices. The metadata records exact Flutter framework/engine revisions and source URLs; unavailable Maven source artifacts are explicitly marked with candidate source/POM URLs. Download the complete artifact from that commit's GitHub Actions run, verify the checksum before installing, and keep the source/notices together when redistributing the APK. Pull-request jobs never receive the release signing secrets and do not publish a signed APK.

The app currently compiles with API 36 and targets API 35, so Android 16 installation is covered without opting into target-36 behaviour changes. CI cannot validate OPPO/ColorOS OMAPI, ARA-M access rules, or a physical eUICC; those checks must be run on the phone.

## License

- Lumina-owned portions are Copyright (C) 2026 Syngnat and licensed
  `GPL-3.0-only`; see [LICENSE](LICENSE) and the precise
  [license scope](LICENSES_SCOPE.md).
- Vendored and registry components retain their own licenses. OpenEUICC is
  GPL-3.0-only; lpac-jni, lpac components, cJSON, and other dependencies keep
  the component-specific terms documented in
  [third-party notices](THIRD_PARTY_NOTICES.md) and nested license files.
- Each CI-distributed APK is accompanied by exact-commit project source,
  dependency-source archive/manifests, dependency inventories, notices, source
  metadata, and checksums. These files form one release set and should remain
  together on redistribution.

## Docs

- [Native/API capability mapping](docs/FEATURE_PARITY.md)
- [Native integration](docs/NATIVE_INTEGRATION.md)
- [License scope](LICENSES_SCOPE.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)
