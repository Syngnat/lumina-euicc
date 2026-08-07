# Lumina eUICC (Flutter)

EasyEUICC-aligned eUICC / eSIM manager with a modern Flutter UI.

## Status

| Area | Done |
|---|---|
| Material 3 UI | ✅ |
| Profile list / enable / disable / delete / rename | ✅ (real LPA when channel available) |
| Download via activation code / QR + progress + confirm | ✅ |
| Compatibility check | ✅ |
| Notifications list / process / delete | ✅ |
| Memory reset | ✅ |
| OpenEUICC `lpac-jni` + `app-common` integrated | ✅ |
| Mock fallback without hardware | ✅ |
| Internal eSIM (privileged) | ❌ (same as EasyEUICC) |

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

```powershell
git clone https://github.com/Syngnat/lumina-euicc.git
cd lumina-euicc
flutter pub get
flutter run
```

If `third_party/OpenEUICC` is missing:

```powershell
git clone --depth 1 --recurse-submodules https://gitea.angry.im/PeterCxy/OpenEUICC.git third_party/OpenEUICC
```

## Package

- App ID: `top.syngnat.lumina.euicc`
- Display name: Lumina eUICC

## License

- App scaffolding: see repository license / notices
- Vendored OpenEUICC / lpac: **GNU GPL v3 only** (upstream)

## Docs

- [Feature parity](docs/FEATURE_PARITY.md)
- [Native integration](docs/NATIVE_INTEGRATION.md)
