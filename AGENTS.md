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
| `android/app/.../EuiccBridgePlugin.kt` | Real LPA + mock fallback |
| `android/app/.../LuminaApplication.kt` | Hosts OpenEUICC `DefaultAppContainer` |
| `third_party/OpenEUICC/` | Vendored OpenEUICC sources (**GPL-3 only**) |
| `docs/FEATURE_PARITY.md` | API / capability mapping |
| `docs/NATIVE_INTEGRATION.md` | Integration status & build notes |
| `NOTICE.md` | Upstream license attribution |

## Feature parity (EasyEUICC unprivileged)

| Capability | Status in code |
|---|---|
| List channels (OMAPI / USB) | Implemented (real or mock) |
| List profiles | Implemented |
| Enable / disable profile | Implemented |
| Delete / rename profile | Implemented |
| Download via LPA activation code / QR | Implemented + progress events + confirm |
| Compatibility check | Implemented |
| Notifications list / process / delete | Implemented |
| Memory reset | Implemented |
| eUICC info (EID, etc.) | Implemented when channel real |
| Internal eSIM | **Out of scope** (needs privileged OpenEUICC) |

### Runtime modes

1. **`mode=real`**: at least one eUICC channel opened → ops use `channel.lpa.*`
2. **`mode=mock`**: no channel (emulator / no ARA-M / no USB permission) → in-memory mock so UI still works

Agents must **not** claim “real-card tested” unless logcat/device evidence exists.

## MethodChannel contract (summary)

Channel name: `top.syngnat.lumina.euicc/bridge`  
Events: `top.syngnat.lumina.euicc/task_events`

Methods (see `lib/services/euicc_bridge.dart` + `EuiccBridgePlugin.kt`):

- `listChannels` → `{channels:[{slotId,portId,seId,label,type,...}], mode}`
- `listProfiles` / `switchProfile` / `deleteProfile` / `renameProfile`
- `downloadProfile` + `confirmDownload` + `cancelDownload` (progress on EventChannel)
- `runCompatibilityCheck` / `getEuiccInfo` / `memoryReset`
- `listNotifications` / `processNotification` / `deleteNotification`

Activation codes: `LPA:1$smdp.example.com$matchingId...` (parsed like OpenEUICC `LPAString`).

## License constraints (critical)

- Vendored **OpenEUICC / lpac / cJSON** → **GNU GPL v3 only**
- Any binary that links them must comply with GPL-3 (source offer for the combined work)
- Do **not** ship under EasyEUICC package name `im.angry.easyeuicc` (upstream asks derivatives to rename)
- Do **not** strip `NOTICE.md` / upstream `LICENSE` files

## Build (Windows / agent on a real Android host)

```powershell
git clone https://github.com/Syngnat/lumina-euicc.git
cd lumina-euicc
flutter pub get
flutter run
```

Requirements:

- Flutter stable
- Android SDK 35
- NDK **26.1.10909125** (lpac-jni)
- CMake / NDK build tools

Low-memory VPS builds are expected to **fail**; do not burn hours retrying full APK builds on small hosts unless resources are expanded.

## What’s done vs remaining

### Done (as of last push)

- Flutter scaffold + Material 3 UI
- Full MethodChannel/EventChannel surface aligned with EasyEUICC ops
- OpenEUICC vendored under `third_party/`
- Gradle includes `:app-common`, `:libs:lpac-jni`, `:app-deps`
- Real LPA bridge with mock fallback
- Public GitHub repo + docs for handoff

### Remaining (next agent should focus here)

1. **Real-device validation** on ARA-M removable eUICC (9eSIM / ESTKme / etc.) or USB CCID
2. Fix compile/link issues if any when building with Flutter+NDK on Windows
3. Optional: Flutter screens for OpenEUICC developer settings (ISD-R AID list, verbose logs UI) — not required for core parity
4. Release signing / Play distribution (only if user asks; watch GPL obligations)
5. Polish UI (animations, empty states, dark theme edge cases)

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
4. Build on a machine with Flutter+NDK
5. Run on device; check logcat tag `LuminaEuiccBridge` for `mode=real` vs `mock`
6. With a real card: list → download → enable/disable → delete

## Contact / ownership

- Repo owner: **Syngnat**
- Product direction: Flutter-first, EasyEUICC feature parity on **removable** eUICC, better UI
