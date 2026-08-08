# Lumina eUICC — OpenEUICC native integration status

This document distinguishes repository/build evidence from real-card validation. Windows debug and dedicated-key release APK builds are recorded below. One exact, model-unknown 9eSIM-card/device combination has limited read-only ARA-M/channel/profile-list evidence; all mutation paths and USB CCID remain unvalidated.

Lumina is an unprivileged application by design. Root, Magisk, Shizuku, system-app installation, and privileged telephony permissions are outside the product boundary. OMAPI access from the phone's SIM slot therefore depends on a card-side ARA-M rule matching Lumina's signing identity; USB CCID does not depend on the phone-slot ARA-M path.

## What is wired

| Layer | Status |
|---|---|
| Flutter UI | Home, profile, download, compatibility, settings, STK launcher, and software-update screens are present |
| Notification UI | Lists pending notifications only; process/delete actions are not exposed in Dart or Flutter |
| MethodChannel API | Profile/download/device/STK/update operations and notification listing are exposed to Dart; native-only notification process/delete handlers remain |
| EventChannel download progress | Implemented in code, including confirmation/cancellation flow |
| OpenEUICC `app-common` + `lpac-jni` as Gradle modules | **Included under `third_party/OpenEUICC`** |
| `EuiccBridgePlugin` real LPA path | Implemented in code for profile operations, download, notification handlers, memory reset, eUICC info, and compatibility; channel/profile listing has one limited field result, while all mutation paths remain device-unvalidated |
| USB CCID permission / hotplug UX | Transport scan is present, but the Lumina Flutter activity does not yet expose the complete runtime permission request or attach/detach refresh flow; no reader is device-validated |
| Mock fallback | Debug builds only; release builds return `mode=unavailable` and no invented channel/profile |
| Online update | Official immutable GitHub Release lookup, installed-ABI selection, bounded private-cache download, SHA-256/package/version/exact-signer verification, and Android system-installer launch are implemented; no silent install or card privilege is added |
| STK launcher | Settings can open generic, OPPO/Oplus, MTK, and slot-specific system SIM Toolkit activities; the card-side LPAe menu does not provide a data channel or ARA-M grant to Lumina |

## Intended runtime behaviour

1. App starts with `LuminaApplication` → provides OpenEUICC `DefaultAppContainer`.
2. `listChannels` tries OMAPI + USB via `DefaultEuiccChannelManager`.
3. If at least one channel opens → `mode=real` and all ops use `channel.lpa.*`.
4. If none open in a debug build → `mode=mock` supplies development-only UI data.
5. If none open in a release build → `mode=unavailable` with no fabricated channel or profile.

The read-only compatibility probe reports the running package and signing SHA-1, then attempts each OMAPI phone slot with the configured ISD-R AIDs. It distinguishes ARA-M denial, an unavailable ISD-R, and other sanitized failure types without returning EID, ICCID, or raw exception messages. Opening and closing these logical channels does not mutate the card.

These branches are derived from the current implementation. The field evidence below covers only the real channel and profile-list branch; it is not evidence that a physical card or reader has completed the full lifecycle.

For USB, `DefaultEuiccChannelManager` can discover a candidate reader before
permission, but it can open the CCID channel only after Android grants access.
The upstream permission fragment and attach/detach
receiver are not part of Lumina's Flutter activity flow, and the current
manifest attachment filter is not proof that every standard CCID reader will
receive an automatic grant. A reader may therefore be discovered but remain
unopenable, or require reconnect/relaunch. This is a known current limitation,
not verified USB support.

No card model or production batch has completed model-wide real-device sign-off.
One exact combination has limited read-only evidence, described below.
Published ARA-M candidates, models requiring card-side configuration, and the
reasons an EID, retailer, or GSMA certificate cannot establish compatibility
are recorded in [the card matrix](SUPPORTED_CARDS.md).

## Recorded real-device evidence (2026-08-08)

With the `0.1.1` four-signer Release APK, one seller-described 9eSIM card opened
ISD-R with the current application identity on OMAPI slot 1. Diagnostics
reported eUICC port 1/0 and a valid LPA channel, and the home screen listed
multiple real profiles. The exact 9eSIM model, phone model, and Android version
were not recorded.

Another card bought from the same retailer was retested with Lumina `0.1.2` on
an OPPO PME110 / OP61C1L1 running Android 16 (API 36). OMAPI enumerated SIM 0
and SIM 1; the SIM 0 probe reached the ISD-R access check before Android/UICC
access control denied the current Lumina identity. SIM 1 separately returned a
sanitized `IOException`, and no LPA port opened. This establishes that the
phone-side OMAPI/ISD-R path was reached and that seller identity does not
guarantee equal card personalization or effective ARA-M policy; it is not
evidence of a phone channel lock. A same-device card swap and card rule
inspection would be required to isolate the exact card difference. Neither
result validates download, enable/disable, rename, delete, memory reset, or USB
CCID behavior.

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
- Universal and `--split-per-abi` release builds succeeded with the dedicated release key; `apksigner verify --verbose --print-certs` passed using APK Signature Scheme v2 for all four APKs. This is the historical single-signer baseline and predates the four-current-signer release policy.
- Release certificate SHA-256: `1F:C1:52:76:70:A8:0B:2B:B5:A8:1F:FC:D2:D8:D7:82:C2:AD:00:3A:21:8F:2C:AD:42:9D:30:08:81:07:D8:9F`.
- APK metadata: `top.syngnat.lumina.euicc`, version `0.1.0`, compile SDK 36, target SDK 35; the universal APK contains `arm64-v8a`, `armeabi-v7a`, and `x86_64`, while each split APK contains exactly its named ABI.
- `zipalign -c -P 16 4` passed for all four release APKs. Every arm64-v8a and x86_64 ELF `LOAD` segment has alignment of at least `2**14`; this includes vendored `liblpac-jni.so`.

This is build/test evidence only. It does not validate OMAPI, ARA-M access, USB CCID, APDU traffic, profile mutation, or download behaviour on physical hardware. Consult GitHub Actions for the exact pushed-commit result and current native verification.

## GitHub Actions, Releases, and Android compatibility

`.github/workflows/ci.yml` uses pinned actions on Ubuntu 24.04:

- `verify` runs for pull requests, `main` pushes, version tags, and manual dispatch. It enforces the lockfile, runs Dart analysis, Flutter and Kotlin tests, builds the debug APK, checks package/min/compile/target SDK metadata and ABIs, then checks both APK ZIP alignment and every 64-bit ELF `LOAD` segment for 16 KB compatibility.
- `release` runs only after `verify` on a trusted `main` ref or matching `v*` tag allowed by the `release-signing` Environment. The job builds universal plus three ABI-specific APKs with v1/v3 disabled and one stable set of four current signers: Lumina, Sakura, ShiinaSekiu Community, and 9eSIM. It verifies APK Signature Scheme v2, disabled v3 signing, exactly those four certificate fingerprints, exact ABI metadata, unprivileged manifest policy, ZIP alignment, and 64-bit ELF alignment.
- `publish_release` runs only for a `v<pubspec version name>` tag already contained in `main`. It downloads and fully verifies the bundle with `actions: read`, excludes the four APKs from one combined source-materials ZIP, appends that ZIP under `v<version-name>/` on the pre-existing `release-materials` branch, and then creates and verifies an immutable GitHub Release with exactly four custom APK assets. Its fixed concurrency group serializes different tag publications. The job has `contents: write`, but no signing environment or keystore secrets.

After verification, a trusted build publishes one Actions artifact containing
the four signed APKs, `lumina-euicc-source-<full-commit-sha>.zip`,
`lumina-euicc-dependency-sources-<full-commit-sha>.zip`, `SOURCE_INFO.txt`,
`SHA256SUMS`, Flutter/Gradle dependency inventories and source manifests, and
root/nested license materials. A matching version-tag run custom-uploads only
the four APKs as GitHub Release assets. GitHub separately displays its automatic
`Source code (zip)` and `Source code (tar.gz)` archives for the immutable tag;
those platform entries cannot be hidden. Release notes link the exact tag tree
and tag-pinned legal files. The complete build bundle remains available as a
90-day Actions audit artifact. All non-APK files from that verified bundle are
also packed into one persistent source-materials ZIP on the
`release-materials` branch; the Release body identifies it with an exact-commit
raw URL and its SHA-256. The dependency archive contains complete hosted Pub
package trees plus available Maven source JARs and cached POMs; the manifest
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

`16384` means the device uses 16 KB pages. Regardless of that value, each new card/device combination still requires an ARA-M rule matching this app's package/certificate identity. The single profile-list observation above does not validate mutations or other devices.

The four current ARA-M SHA-1 identities are:

- Lumina: `10:0C:A7:FD:2C:E4:B7:12:BA:3C:88:4C:AE:20:FD:33:25:ED:85:E0`;
- Sakura: `65:D0:57:18:54:AF:EC:51:9A:90:F9:2D:7C:5D:8C:F8:14:8D:A3:73`;
- ShiinaSekiu Community: `C4:73:50:C7:BA:68:2B:34:A3:E5:84:A0:D5:84:63:EA:42:B1:AD:73`;
- 9eSIM: `D1:C0:F4:8B:37:0E:74:D4:EA:47:70:ED:4C:3C:D7:0A:31:98:D3:1F`.

A certificate-only ARA-M rule without a package binding may authorize the APK by matching any one of these current signers. A package-bound rule must also match `top.syngnat.lumina.euicc`; a rule bound to another package can still reject Lumina. Fingerprints alone cannot add a signer, so Lumina includes only the private project identity and community identities reproducible from pinned public source. This is a card access-control requirement, not an Android runtime permission that the user can approve. See [community multi-signing policy](COMMUNITY_SIGNING.md) for exact provenance and update constraints.

An installed `0.1.0` single-signer Lumina build is not update-compatible with the four-signer APK and must be uninstalled once. Subsequent releases must preserve the exact four-current-signer set. Neither this policy nor CI verification extends the limited field result to another card, device, or operation.

## License

- Lumina-owned code is Copyright (C) 2026 Syngnat and licensed
  GPL-3.0-only under the root `LICENSE`; `LICENSES_SCOPE.md` defines the scope.
- `third_party/OpenEUICC/LICENSE` is GPL-3.0-only.
- lpac-jni, lpac components, cJSON, and registry dependencies retain their own
  bundled or upstream licenses; they must not all be described as
  GPL-3.0-only. See `THIRD_PARTY_NOTICES.md` and nested license files.
- CI retains all APK variants, exact-commit project source, dependency source
  archive/manifests, dependency inventories, notices, source metadata, and
  checksums in one 90-day audit artifact. The same verified non-APK set is kept
  persistently as one exact-commit-pinned source-materials ZIP. The Release ties
  its four custom-uploaded APKs to an immutable tag containing the tracked
  source and legal materials. Redistribution must preserve the tag, persistent
  materials ZIP, and notice linkage.
- The three community signing identities retain the pinned NekokoLPA MIT
  attribution recorded in `THIRD_PARTY_NOTICES.md`; signing keys and passwords
  are excluded from project source and release artifacts.

## Remaining gaps (honest)

- Reproduce the local baseline in GitHub Actions after the changes are committed and pushed.
- Align bridge channel-manager ownership with OpenEUICC's `EuiccChannelManagerService`; upstream marks independent long-lived manager references unsupported.
- Add Dart API and Flutter actions for notification process/delete if parity requires them.
- Not every OpenEUICC UI-only setting screen is reimplemented in Flutter (developer options, ISD-R AID editor, logs viewer). Core profile/download paths are present and build successfully but still need device evidence.
- Flutter 3.44.9 warns that Gradle 8.9, AGP 8.7.0, and Kotlin 2.0.21 are nearing the end of its support window; migrate them together only after checking vendored OpenEUICC compatibility.
- Privileged internal-eSIM management is intentionally outside Lumina's product boundary.
- Complete real-device validation still needs exact card/device identification plus download, enable/disable, rename, delete, and USB-reader tests; the current field evidence covers only channel opening and profile listing on one combination.
- Release signing is wired to the dedicated project key; secure backup and
  recovery of that key remain an owner responsibility. CI now packages the APK
  with matching source and license materials, and future dependency changes
  must keep those materials current.
