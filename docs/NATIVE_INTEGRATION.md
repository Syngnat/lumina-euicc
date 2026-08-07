# Lumina eUICC — OpenEUICC native integration status

## What is wired

| Layer | Status |
|---|---|
| Flutter UI | Complete (home / cards / download / compatibility / settings) |
| MethodChannel API | Complete & EasyEUICC-aligned |
| EventChannel download progress | Complete |
| OpenEUICC `app-common` + `lpac-jni` as Gradle modules | **Included under `third_party/OpenEUICC`** |
| `EuiccBridgePlugin` real LPA path | **Implemented** (list / switch / delete / rename / download / notifications / memoryReset / euiccInfo / compatibility) |
| Mock fallback | Yes — when no eUICC channel can be opened |

## Runtime behaviour

1. App starts with `LuminaApplication` → provides OpenEUICC `DefaultAppContainer`.
2. `listChannels` tries OMAPI + USB via `DefaultEuiccChannelManager`.
3. If at least one channel opens → `mode=real` and all ops use `channel.lpa.*`.
4. If none open (emulator / no ARA-M card / no USB permission) → `mode=mock` so UI still works.

## Build on Windows (required)

This VPS cannot finish full Flutter/Android builds (RAM/disk). On your PC:

```powershell
git clone https://github.com/Syngnat/lumina-euicc.git
cd lumina-euicc

# Ensure third_party is present (if missing):
# git clone --depth 1 --recurse-submodules https://gitea.angry.im/PeterCxy/OpenEUICC.git third_party/OpenEUICC

flutter pub get
flutter run
```

Requirements:
- Flutter stable
- Android SDK 35 + NDK 26.1.10909125 (for lpac-jni)
- CMake / NDK build tools

## License

OpenEUICC / lpac-jni are **GPL-3 only**.  
Shipping a binary that links them requires releasing corresponding source under GPL-3.  
This repo already includes the vendored sources for compliance.

## Remaining gaps (honest)

- Not every OpenEUICC UI-only setting screen is reimplemented in Flutter (developer options, ISD-R AID editor, logs viewer). Core LPA ops are covered.
- Privileged internal-eSIM path (OpenEUICC system app) is intentionally out of scope — same as EasyEUICC unprivileged.
- Real-device validation still needs your phone + ARA-M card / USB reader.
