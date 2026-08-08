# AGENTS.md — Context for AI agents working on this repo

> **Read this file first.** It is the source of truth for project intent, architecture, status, and constraints.

## What this repository is

**Lumina eUICC** is a **Flutter UI rewrite** of [EasyEUICC](https://easyeuicc.org) / [OpenEUICC](https://gitea.angry.im/PeterCxy/OpenEUICC), with a modern Material 3 interface, while aiming for **feature parity on removable / programmable eUICC cards**.

| Field | Value |
|---|---|
| GitHub | https://github.com/Syngnat/lumina-euicc (public) |
| Owner | Syngnat |
| App ID | `top.syngnat.lumina.euicc` |
| Display name | Lumina eUICC |
| Primary platforms | Android 9+ (API 28); Flutter UI |
| Not a goal | Managing **internal** phone eSIM without system privilege (same limit as EasyEUICC unprivileged) |

Non-root operation is a hard product constraint: never add Root/Magisk/Shizuku flows, system-app installation requirements, or privileged telephony permissions. The supported in-phone path is OMAPI to a removable eUICC whose ARA-M authorizes Lumina's certificate; USB CCID is the alternative. A card that only authorizes EasyEUICC's unrelated signing certificate will not authorize Lumina.

### Product goal (user request)

- EasyEUICC is useful but **UI is ugly**
- User wants **same capability**, **better UI**
- Prefer **not writing app logic in Java**; accepted architecture is **Flutter UI + thin Kotlin bridge + OpenEUICC/lpac LPA stack**
- User develops on **Windows**; this repo was scaffolded on a low-RAM VPS that **cannot** reliably build full Flutter/Android APKs

## What it is NOT

- Not a pure-Flutter eUICC stack (impossible: OMAPI/APDU need native Android)
- Not a full privileged OpenEUICC system app for internal eSIM
- Not a web app
- Not finished end-to-end until real-device validation on ARA-M cards / USB CCID

## Architecture

```text
Flutter (Dart) — Material 3 UI
    MethodChannel: top.syngnat.lumina.euicc/bridge
    EventChannel:  top.syngnat.lumina.euicc/task_events
        ↓
EuiccBridgePlugin.kt  (thin bridge)
        ↓
OpenEUICC DefaultEuiccChannelManager + LocalProfileAssistant
        ↓
lpac-jni (native LPA / SGP.22)
        ↓
OMAPI (removable eUICC)  or  USB CCID reader
```

### Key paths

| Path | Role |
|---|---|
| `lib/` | Flutter UI, models, providers, MethodChannel client |
| `lib/services/euicc_bridge.dart` | Dart API surface (what Flutter pages call) |
| `lib/pages/` | Home, download/QR, compatibility, settings |
| `android/app/.../EuiccBridgePlugin.kt` | Real LPA + read-only diagnostics; mock fallback is debug-only |
| `android/app/.../LuminaApplication.kt` | Hosts OpenEUICC `DefaultAppContainer` |
| `third_party/OpenEUICC/` | Vendored upstream sources; preserve each component's license files |
| `docs/FEATURE_PARITY.md` | Native/API capability mapping; not proof of Flutter UI exposure |
| `docs/NATIVE_INTEGRATION.md` | Integration status & build notes |
| `LICENSE` / `LICENSES_SCOPE.md` | GPL-3.0-only text and precise project/third-party license boundary |
| `NOTICE.md` / `THIRD_PARTY_NOTICES.md` | Copyright attribution and component-specific third-party terms |

## Feature parity (EasyEUICC unprivileged)

| Capability | Status in code |
|---|---|
| List channels (OMAPI / USB) | Real path implemented; debug-only mock and release unavailable states are explicit; hardware validation pending |
| List profiles | UI/bridge path implemented; hardware validation pending |
| Enable / disable profile | UI/bridge path implemented; hardware validation pending |
| Delete / rename profile | UI/bridge path implemented; hardware validation pending |
| Download via LPA activation code / QR | UI/bridge path, progress events, and confirmation implemented; hardware validation pending |
| Compatibility check | UI/bridge path implemented |
| Notifications | Listing is exposed in Flutter; process/delete have native handlers but no Dart API or UI actions |
| Memory reset | UI/bridge path implemented; destructive hardware path not validated |
| eUICC info (EID, etc.) | Dart/native API implemented; no dedicated Flutter presentation or hardware validation |
| Internal eSIM | **Out of scope** (needs privileged OpenEUICC) |

### Runtime modes

The current implementation intends to select:

1. **`mode=real`**: at least one eUICC channel opened → ops use `channel.lpa.*`
2. **`mode=mock`**: debug build and no channel → in-memory development data
3. **`mode=unavailable`**: release build and no channel → empty real result; never show invented profiles

Agents must **not** claim “real-card tested” unless logcat/device evidence exists.

## MethodChannel contract (summary)

Channel name: `top.syngnat.lumina.euicc/bridge`  
Events: `top.syngnat.lumina.euicc/task_events`

Methods (see `lib/services/euicc_bridge.dart` + `EuiccBridgePlugin.kt`):

- `listChannels` → `{channels:[{slotId,portId,seId,label,type,...}], mode}`
- `listProfiles` / `switchProfile` / `deleteProfile` / `renameProfile`
- `downloadProfile` returns a `taskId`; every EventChannel event and each confirm/cancel call carries that ID to prevent cross-task delivery
- `runCompatibilityCheck` / `getEuiccInfo` / `memoryReset`
- Dart-visible notification method: `listNotifications`
- Native handlers without Dart/UI exposure: `processNotification` / `deleteNotification`

Activation codes: `LPA:1$smdp.example.com$matchingId...` (parsed like OpenEUICC `LPAString`).

## License constraints (critical)

- Lumina-owned portions are Copyright (C) 2026 Syngnat and licensed
  GPL-3.0-only under the root `LICENSE`; `LICENSES_SCOPE.md` defines the exact
  boundary.
- `third_party/OpenEUICC/LICENSE` applies GPL-3.0-only terms to OpenEUICC.
- lpac-jni and cJSON retain different licenses in their bundled license files; do not label every vendored component GPL-3.0-only.
- A signed APK may be distributed only with its matching exact-commit source
  archive, dependency-source archive/manifests, `SOURCE_INFO.txt`, dependency
  inventories, checksums, and root/nested license materials produced by the
  same trusted CI run. Do not publish or redistribute a bare APK detached from
  those materials.
- The exact upstream OpenEUICC revision was not retained separately. The
  authoritative source is the tracked `third_party/OpenEUICC` snapshot in the
  full Lumina commit recorded by `SOURCE_INFO.txt`; never invent an upstream
  commit identifier.
- Do **not** ship under EasyEUICC package name `im.angry.easyeuicc` (upstream asks derivatives to rename)
- Do **not** strip `NOTICE.md`, `THIRD_PARTY_NOTICES.md`,
  `LICENSES_SCOPE.md`, or upstream license files.

## Build (Windows / agent on a real Android host)

```powershell
git clone https://github.com/Syngnat/lumina-euicc.git
cd lumina-euicc
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

Requirements:

- Flutter **3.44.9**
- JDK 17
- Android SDK platforms 35 and 36, plus Build Tools 34.0.0 and 35.0.0
- NDK **28.2.13676358** for the app and transitive pub package `jni` 1.0.3 through Flutter's `flutter.ndkVersion`
- NDK **26.1.10909125** for vendored OpenEUICC `lpac-jni`
- CMake 3.22.1 for `jni` 1.0.3's `externalNativeBuild.cmake` path
- Checked-in Gradle 8.9 wrapper

OpenEUICC `lpac-jni` uses `externalNativeBuild.ndkBuild`; pub package `jni` 1.0.3 separately uses `externalNativeBuild.cmake`. The Lumina app compiles against SDK 36 and targets SDK 35; vendored `app-common` and `lpac-jni` compile against SDK 35. Keep both SDK platforms, both Build Tools versions, both NDKs, and CMake in CI unless those locked dependencies change.

Verified on Windows on 2026-08-08 after the legal-screen/native-ZXing changes: `flutter analyze --no-pub` reported no issues, all 21 Flutter tests passed, all 32 Kotlin/JUnit tests passed, and a dedicated-key `:app:assembleRelease` completed successfully. `apksigner` verified that release APK with v2 signing and certificate SHA-256 `1F:C1:52:76:70:A8:0B:2B:B5:A8:1F:FC:D2:D8:D7:82:C2:AD:00:3A:21:8F:2C:AD:42:9D:30:08:81:07:D8:9F`. Release ZIP alignment passed, and every 64-bit native ELF—including `liblpac-jni.so`—had `LOAD` alignment of at least `2**14`. The APK contained the three configured ABIs and both native build paths. This is not real-card validation; consult GitHub Actions for the exact pushed-commit result. Flutter currently warns that Gradle 8.9, AGP 8.7.0, and Kotlin 2.0.21 are nearing its support floor.

GitHub Actions uses a `verify` job for pull requests/main/manual runs and a separate dedicated-key `release` job only on trusted `main`. Release secrets live in the `release-signing` Environment, which is restricted to `main`; never move them into source, logs, PR jobs, or artifacts. CI verifies package/SDK/ABI metadata, v2 signing, one signer, the fixed certificate, ZIP alignment, and every arm64-v8a/x86_64 ELF. A trusted release publishes the signed APK only as part of a bundle containing the matching exact-commit project source, hosted Pub sources, available Maven source JARs/POMs, exact Flutter framework/engine source references, source manifests, `SOURCE_INFO.txt`, checksums, dependency inventories, and license materials.

Use CI or a sufficiently provisioned Android host for native builds. A failed or unattempted low-resource build is not validation evidence.

## What is present vs remaining

### Present in code

- Flutter scaffold + Material 3 UI
- MethodChannel/EventChannel paths for profiles, download, device operations, and notification listing
- OpenEUICC vendored under `third_party/`
- Gradle includes `:app-common`, `:libs:lpac-jni`, `:app-deps`
- Real LPA bridge code path with debug-only mock fallback and release unavailable state; no real-card sign-off
- Public GitHub repo + docs for handoff

### Remaining (next agent should focus here)

1. Reproduce the verified Windows build in GitHub Actions after commit/push
2. **Real-device validation** on an ARA-M removable eUICC (9eSIM / ESTKme / etc.) or USB CCID
3. Replace the bridge's independently held `DefaultEuiccChannelManager` with the upstream `EuiccChannelManagerService` lifecycle before claiming hotplug/long-running stability
4. Expose notification process/delete through the Dart API and Flutter UI if full parity requires them
5. Optional: Flutter screens for OpenEUICC developer settings (ISD-R AID list, verbose logs UI)
6. Back up the dedicated release keystore/properties and keep the CI release
   bundle/source packaging gates in sync with dependency or license changes
7. Polish UI (animations, empty states, dark theme edge cases)

## Conventions for agents

- Prefer **editing bridge + Flutter**, not forking OpenEUICC UI XML unless necessary
- Keep package id `top.syngnat.lumina.euicc`
- When changing LPA behavior, mirror OpenEUICC/`LocalProfileAssistant` semantics
- Never put secrets, redemption codes, or tokens in this repo
- Commit style used by owner elsewhere: emoji conventional commits, Chinese OK, e.g. `✨ feat(...): ...`
- Push with `gh` auth if available (`gh auth status`); owner is Syngnat

## Related prior work (not in this repo)

- Kotlin-only UI restyle attempt: `LuminaEUICC` under workspace (separate from this Flutter repo)
- User also runs Hermes bots / GoNavi on the same VPS — **do not** mix those concerns into this app unless asked

## Quick verification checklist for a new agent

1. Read this file + `docs/FEATURE_PARITY.md` + `docs/NATIVE_INTEGRATION.md`
2. `git pull` latest `main`
3. Confirm `third_party/OpenEUICC` exists and has `app-common` + `libs/lpac-jni`
4. Use Flutter 3.44.9; run `flutter pub get`, `flutter analyze --no-pub`, `flutter test --no-pub`, and `flutter build apk --debug --no-pub`
5. Run on device; use the compatibility page to distinguish per-slot ARA-M denial from missing OMAPI/ISD-R, then check logcat tag `LuminaEuiccBridge`
6. With a real card: list → download → enable/disable → delete; record device/log evidence before claiming success

## Contact / ownership

- Repo owner: **Syngnat**
- Product direction: Flutter-first, EasyEUICC feature parity on **removable** eUICC, better UI
