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

## Downloading an APK

For normal installation, download APKs from [GitHub Releases](https://github.com/Syngnat/lumina-euicc/releases), not from an arbitrary mirror. Android version and CPU ABI are different things: Android 9 through Android 16 can all run on ARM or x86 hardware, so choose the APK for the device's CPU architecture.

| Release asset | Choose it when |
|---|---|
| `lumina-euicc-<version>-arm64-v8a.apk` | **Recommended for nearly all modern phones**, including recent OPPO/ColorOS and other Android 16 devices |
| `lumina-euicc-<version>-armeabi-v7a.apk` | Only for older 32-bit ARM phones that cannot install the ARM64 build |
| `lumina-euicc-<version>-x86_64.apk` | Primarily for x86_64 Android emulators or uncommon Intel-based Android hardware |
| `lumina-euicc-<version>-universal.apk` | Fallback when the ABI is unknown; supports every packaged ABI but is larger |

For a recent OPPO phone running Android 16, choose **`arm64-v8a`**. Lumina supports Android 9+ (API 28+); an older Android version does not by itself mean that the phone needs `armeabi-v7a`.

For later updates, keep using the same APK family when possible. Flutter assigns ABI-split APKs architecture-specific version codes, so moving from an ABI-specific installation back to `universal` may require uninstalling the app first; profiles stored on the removable eUICC are unaffected.

Each GitHub Release also includes `SHA256SUMS`, exact-commit project source, dependency-source materials, source metadata, dependency inventories, and license notices from the same trusted build. Verify the APK against `SHA256SUMS`, and keep the matching source and notices with it when redistributing the APK.

If a debug build or an APK with a different signer set is already installed under `top.syngnat.lumina.euicc`, Android will reject an in-place update. In particular, an installed `0.1.0` APK carrying only the original Lumina signer must be uninstalled once before installing the four-signer Release APK. Uninstalling the Android app does not delete profiles stored on the removable eUICC, although the app's local settings are cleared.

## Release signing

Release builds use the Lumina dedicated project key together with three publicly reproducible community keys; they never fall back to the Android debug key. Gradle first checks `android/key.properties`, then `%USERPROFILE%/.android/lumina-euicc/key.properties`; start from `android/key.properties.example` and never commit the populated file or any keystore.

Starting with `0.1.1`, every multi-signed Release APK has the same four current signers:

| Signer | ARA-M SHA-1 fingerprint |
|---|---|
| Lumina dedicated release key | `10:0C:A7:FD:2C:E4:B7:12:BA:3C:88:4C:AE:20:FD:33:25:ED:85:E0` |
| Sakura community key | `65:D0:57:18:54:AF:EC:51:9A:90:F9:2D:7C:5D:8C:F8:14:8D:A3:73` |
| ShiinaSekiu Community Key | `C4:73:50:C7:BA:68:2B:34:A3:E5:84:A0:D5:84:63:EA:42:B1:AD:73` |
| 9eSIM community key | `D1:C0:F4:8B:37:0E:74:D4:EA:47:70:ED:4C:3C:D7:0A:31:98:D3:1F` |

The Lumina certificate's SHA-256 fingerprint remains `1F:C1:52:76:70:A8:0B:2B:B5:A8:1F:FC:D2:D8:D7:82:C2:AD:00:3A:21:8F:2C:AD:42:9D:30:08:81:07:D8:9F`. Back up the Lumina keystore and its properties together. All later releases must keep exactly this four-signer set or Android update compatibility will break. APK Signature Scheme v2 is enabled; v1 and v3 are deliberately disabled for the Android 9+ multiple-current-signer APK.

Although the three community keys are public, an update-compatible APK must
still carry the complete four-signer set. The non-public Lumina signer therefore
remains the update-security anchor.

For a certificate-only ARA-M rule without package binding, a match against any one of these four certificates can authorize Lumina. A package-bound rule must also name `top.syngnat.lumina.euicc`; a different bound package can still cause denial. EasyEUICC's `2A…` signing identity is not included because its private key is not public. Two additional signers found in NekokoLPA (`nekokobeef` and `wenzi`) are also excluded because their key containers cannot be publicly unlocked. See the [community multi-signing policy](docs/COMMUNITY_SIGNING.md) for provenance, migration, and limitations.

The command below is useful only for producing a local **Lumina-single-signer
base APK**. It does not apply the three community signers and is neither the
official distributable Release nor update-compatible with the four-signer
release chain. Official four-signer APKs are produced and verified only by the
protected GitHub Actions tag workflow.

```powershell
flutter build apk --release --no-pub
```

## CI, releases, and Android compatibility

GitHub Actions runs Dart analysis, Flutter tests, Kotlin unit tests, a debug APK build, APK metadata checks, and both ZIP and ELF 16 KB alignment checks. A separate protected `release-signing` environment builds release APKs with v1/v3 disabled, then verifies the package ID, SDK levels, expected ABI, v2 signature, disabled v3 signing, exactly four current signers, all four certificate fingerprints, and 16 KB compatibility.

On a trusted version-tag run, CI creates a GitHub Release with the ARM64, 32-bit ARM, x86_64, and universal APKs plus their matching compliance materials: `lumina-euicc-source-<full-commit-sha>.zip`, `lumina-euicc-dependency-sources-<full-commit-sha>.zip`, `SOURCE_INFO.txt`, `SHA256SUMS`, resolved Flutter/Gradle inventories and source manifests, and root/nested license notices. The metadata records exact Flutter framework/engine revisions and source URLs; unavailable Maven source artifacts are explicitly marked with candidate source/POM URLs. Trusted `main` builds may also retain the complete bundle as a GitHub Actions artifact for CI traceability. Pull-request jobs never receive the release signing secrets and cannot publish a signed APK or Release.

The app currently has a minimum SDK of API 28 (Android 9), compiles with API 36, and targets API 35. This covers installation on Android 9 through Android 16 without opting into target-36 behaviour changes. CI cannot validate OPPO/ColorOS OMAPI, ARA-M access rules, or a physical eUICC; those checks must be run on the phone.

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
- [Community multi-signing policy](docs/COMMUNITY_SIGNING.md)
- [License scope](LICENSES_SCOPE.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)
