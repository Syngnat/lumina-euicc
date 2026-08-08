# Lumina eUICC (Flutter)

Flutter-first removable eUICC manager with a modern Material 3 interface.

> **For AI agents / handoff:** read **[AGENTS.md](AGENTS.md)** first (purpose, architecture, current evidence, license, and build requirements).
>
> Status below describes code present in the repository. One exact 9eSIM-card/device combination has completed limited, read-only OMAPI channel and profile-list validation; this is not model-wide certification, and USB CCID plus all profile mutations remain unvalidated.

Lumina is intentionally an ordinary, non-root Android app. It does not require or support Root, Magisk, Shizuku, installation as a system app, or privileged telephony permissions. In-phone access is limited to removable eUICC cards whose ARA-M rule authorizes Lumina's signing certificate; USB CCID is the other unprivileged path. Built-in phone eSIM management remains out of scope.

## Status

| Area | Current status |
|---|---|
| Material 3 UI | Implemented in Flutter |
| Language | Simplified Chinese and English; follows the Android system locale, with English fallback |
| Profile list / enable / disable / delete / rename | Flutter and native paths implemented; listing succeeded on one exact 9eSIM-card/device combination, while enable/disable/delete/rename remain unvalidated on hardware |
| Download via activation code / QR + progress + confirm | UI, channel contract, and native path implemented; real-card validation pending |
| Compatibility check | Read-only package/signing identity, per-slot OMAPI/ARA-M, and LPA diagnostics implemented; one field result opened ISD-R on OMAPI slot 1 and discovered port 1/0 without exposing a card identifier |
| STK management | Settings opens the system SIM Toolkit/LPAe menu through known generic, OPPO/Oplus, MTK, and slot-specific activities; this card-side UI is independent of Lumina's OMAPI/ARA-M authorization |
| Online update | Settings can check the official immutable GitHub Release, preserve the installed APK ABI family, verify SHA-256/package/version/exact four-signer identity, and open the Android system installer; silent installation is intentionally unsupported |
| Notifications | List UI implemented; native process/delete handlers are not exposed through the Dart API or UI |
| Memory reset | UI and bridge implemented; destructive real-card path not validated |
| OpenEUICC `lpac-jni` + `app-common` | Vendored, wired, and included in successful Windows debug and dedicated-key release APK builds; broader read, write, and USB device validation remains |
| Mock fallback without hardware | Debug builds only; release builds show the real channel as unavailable instead of inventing profiles |
| Internal eSIM (privileged) | Out of scope |

## Removable-card compatibility

Lumina has one limited real-device result: the `0.1.1` four-signer Release APK
opened ISD-R through OMAPI slot 1, discovered eUICC port 1/0, reported a valid
LPA channel, and listed multiple real profiles on one seller-described 9eSIM
card. The card's exact 9eSIM model and the phone/Android version were not
recorded, so this does **not** certify a named 9eSIM model or production batch.
The matrix below combines that field result with published ARA-M certificate
metadata.

| Card / family | Current assessment |
|---|---|
| 9eSIM v3, V2S, v0 | Published signer match plus mixed field evidence: one exact, model-unknown 9eSIM card/device combination listed profiles, while another card from the same retailer was denied by ARA-M; no listed model is certified as a family |
| eSIM.gg Card | Signer-fingerprint-match candidate for the same signer; not yet tested by Lumina |
| 蚊子玩卡 S3 | Signer-fingerprint-match candidate for the same signer; not yet tested by Lumina |
| ESTKme Light, Plus, Max | Not compatible by default according to published metadata; candidate only after its changeable ARA-M list is configured with a current Lumina signer and any package binding permits `top.syngnat.lumina.euicc` |
| Generic / unbranded "white card" | Unknown; EID prefix, chip maker, STK menu, or "GSMA certified" wording does not prove ARA-M compatibility |

Phone-slot access ultimately depends on the exact card's effective ARA-M rule.
The pass/fail results from two cards bought from the same retailer demonstrate
that seller name alone is not a compatibility guarantee; batch or card
personalization can differ. The denied card was retested with Lumina `0.1.2` on
an OPPO PME110 / OP61C1L1 running Android 16 (API 36): OMAPI enumerated SIM 0
and SIM 1, the SIM 0 probe reached the ISD-R access check, and access control
then denied the current Lumina identity. This proves the phone-side OMAPI path
was present; it does not indicate a locked phone channel. A certificate-only rule may match any current
Lumina signer, while a package-bound rule must also name
`top.syngnat.lumina.euicc`. Download, enable/disable, rename, delete, and other
mutating operations were not exercised in the successful read-only test. See
the complete evidence, limitations, and pre-purchase checklist in
[card compatibility](docs/SUPPORTED_CARDS.md).

USB CCID avoids the phone-slot ARA-M rule, but it is not yet a verified fallback:
the current Flutter activity does not expose the complete USB permission and
attach/detach refresh flow, and no reader has completed Lumina device sign-off.

**Settings → STK management** opens the phone's system SIM Toolkit so a
compatible card can show its own LPAe menu. This is useful even when Lumina is
denied by ARA-M because the menu executes on the card/system STK path. It does
not expose the menu's profile data back to Lumina and does not grant the Lumina
bridge permission to list or mutate profiles through OMAPI.

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

Starting with `0.1.3`, **Settings → Software update** can check and download the
latest official immutable GitHub Release. It automatically keeps the installed
APK family (`arm64-v8a`, `armeabi-v7a`, `x86_64`, or `universal`), verifies the
GitHub SHA-256 digest and then asks Android to verify the package, newer version,
and exact installed four-signer set before opening the system installer. Android
still requires the user to approve installation and may first ask for the
per-app “install unknown apps” permission. Existing `0.1.2` installations do
not contain the updater, so `0.1.3` must be installed manually once.

Each GitHub Release custom-uploads only the four APK variants. GitHub also shows
its automatic `Source code (zip)` and `Source code (tar.gz)` entries for the
immutable version tag; those platform-generated entries cannot be hidden. The
release notes link the exact tag tree and its license/notices, while the same CI
run produces and verifies a complete source, dependency-source, inventory,
checksum, and license bundle. That bundle is retained as an Actions audit
artifact for 90 days, and all non-APK materials are also combined into one
persistent versioned ZIP on the `release-materials` branch. Release notes link
the ZIP by its exact materials commit and publish its SHA-256.

If a debug build or an APK with a different signer set is already installed under `top.syngnat.lumina.euicc`, Android will reject an in-place update. In particular, an installed `0.1.0` APK carrying only the original Lumina signer must be uninstalled once before installing the four-signer Release APK. Uninstalling the Android app does not delete profiles stored on the removable eUICC, although the app's local settings are cleared.

## Release signing

Release builds use the Lumina dedicated project key together with three publicly reproducible community keys; they never fall back to the Android debug key. Gradle first checks `android/key.properties`, then `%USERPROFILE%/.android/lumina-euicc/key.properties`; start from `android/key.properties.example` and never commit the populated file or any keystore.

Starting with `0.1.1`, every multi-signed Release APK has the same four current signers:

| Signer | ARA-M SHA-1 fingerprint | Role / provenance |
|---|---|---|
| Lumina dedicated release key | `10:0C:A7:FD:2C:E4:B7:12:BA:3C:88:4C:AE:20:FD:33:25:ED:85:E0` | Private project identity and update-security anchor |
| Sakura community key | `65:D0:57:18:54:AF:EC:51:9A:90:F9:2D:7C:5D:8C:F8:14:8D:A3:73` | Publicly reproducible community identity from pinned upstream source |
| ShiinaSekiu Community Key | `C4:73:50:C7:BA:68:2B:34:A3:E5:84:A0:D5:84:63:EA:42:B1:AD:73` | Publicly reproducible community identity from pinned upstream source |
| 9eSIM community key | `D1:C0:F4:8B:37:0E:74:D4:EA:47:70:ED:4C:3C:D7:0A:31:98:D3:1F` | Publicly reproducible community identity from pinned upstream source |

The Lumina certificate's SHA-256 fingerprint remains `1F:C1:52:76:70:A8:0B:2B:B5:A8:1F:FC:D2:D8:D7:82:C2:AD:00:3A:21:8F:2C:AD:42:9D:30:08:81:07:D8:9F`. Back up the Lumina keystore and its properties together. All later releases must keep exactly this four-signer set or Android update compatibility will break. APK Signature Scheme v2 is enabled; v1 and v3 are deliberately disabled for the Android 9+ multiple-current-signer APK.

Although the three community keys are public, an update-compatible APK must
still carry the complete four-signer set. The non-public Lumina signer therefore
remains the update-security anchor.

For a certificate-only ARA-M rule without package binding, a match against any
one of these four certificates can authorize Lumina. A package-bound rule must
also name `top.syngnat.lumina.euicc`; a different bound package can still cause
denial. Fingerprints alone are not enough to add another signer: only identities
whose signing material is controlled by Lumina or reproducible from pinned
public source are eligible. See the
[community multi-signing policy](docs/COMMUNITY_SIGNING.md) for provenance,
migration, and limitations.

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

On a trusted version-tag run, CI custom-uploads the ARM64, 32-bit ARM, x86_64,
and universal APKs to GitHub Releases. The immutable tag supplies GitHub's
automatic project source archives and contains the tracked vendor sources,
license scope, notices, and nested license files. The same run separately
builds and verifies the full exact-commit source/dependency-source bundle,
`SOURCE_INFO.txt`, `SHA256SUMS`, dependency inventories, source manifests, and
license tree. It retains the complete build bundle as one 90-day Actions audit
artifact and publishes the non-APK portion as one versioned ZIP on the
`release-materials` branch. The Release body uses an immutable raw URL pinned
to the exact materials commit and records the ZIP SHA-256. Pull-request jobs
never receive release signing secrets and cannot publish a signed APK, source
materials, or Release; the `contents: write` publishing job has no signing
environment or keystore secrets.

The app currently has a minimum SDK of API 28 (Android 9), compiles with API 36, and targets API 35. This covers installation on Android 9 through Android 16 without opting into target-36 behaviour changes. CI cannot validate OPPO/ColorOS OMAPI, ARA-M access rules, or a physical eUICC; those checks must be run on the phone.

## License

- Lumina-owned portions are Copyright (C) 2026 Syngnat and licensed
  `GPL-3.0-only`; see [LICENSE](LICENSE) and the precise
  [license scope](LICENSES_SCOPE.md).
- Vendored and registry components retain their own licenses. OpenEUICC is
  GPL-3.0-only; lpac-jni, lpac components, cJSON, and other dependencies keep
  the component-specific terms documented in
  [third-party notices](THIRD_PARTY_NOTICES.md) and nested license files.
- Each release is tied to an immutable version tag containing the exact tracked
  project/vendor source and legal materials. The trusted CI run also verifies a
  complete dependency-source, inventory, source-metadata, checksum, and license
  bundle, retains it as a 90-day Actions audit artifact, and keeps the non-APK
  materials persistently available as one exact-commit-pinned ZIP on the
  `release-materials` branch. Redistribution must preserve a clear link to the
  matching tag, persistent materials ZIP, and legal notices.

## Docs

- [Native/API capability mapping](docs/FEATURE_PARITY.md)
- [Native integration](docs/NATIVE_INTEGRATION.md)
- [Community multi-signing policy](docs/COMMUNITY_SIGNING.md)
- [Removable-card compatibility](docs/SUPPORTED_CARDS.md)
- [License scope](LICENSES_SCOPE.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)
