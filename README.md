# Lumina eUICC (Flutter)

EasyEUICC 功能对齐的 **Flutter UI** 版本。

- UI：Flutter Material 3（青绿主题、圆角卡片、状态 chip）
- 能力：通过 Android **Kotlin 薄桥** 调用与 EasyEUICC 同级的 eUICC LPA 操作
- 许可：业务桥接层可自有；若复用 OpenEUICC/lpac 源码，必须遵守 **GPL-3 only**

## 功能对齐表（EasyEUICC unprivileged）

| 能力 | EasyEUICC | Flutter 版 | 实现路径 |
|---|---|---|---|
| 列出 profile | ✅ | ✅ | `listProfiles` |
| 启用 / 禁用 | ✅ | ✅ | `switchProfile` |
| 删除 | ✅ | ✅ | `deleteProfile` |
| 重命名 | ✅ | ✅ | `renameProfile` |
| 扫码 / 粘贴下载 | ✅ | ✅ | `downloadProfile` + mobile_scanner |
| 下载进度 / 确认码 | ✅ | ✅ | EventChannel `taskEvents` |
| 兼容性检查 | ✅ | ✅ | `runCompatibilityCheck` |
| USB CCID 读卡器 | ✅ | ✅ | 原生桥枚举通道 |
| 通知处理 | ✅ | ✅ | `listNotifications` / `processNotification` |
| 内存重置 | ✅ | ✅ | `memoryReset` |
| 内置 eSIM | ❌ | ❌ | 与 EasyEUICC 一致，无系统特权不支持 |

## 架构

```text
Flutter UI (Dart)
   MethodChannel / EventChannel
Android Kotlin thin bridge
   → 接入 OpenEUICC app-common / lpac-jni（本机完整集成时）
   → 或 MockEuiccBridge（无真卡/无原生栈时的开发预览）
```

当前仓库默认使用 **Mock 桥**，保证 UI 与接口可运行、可联调。  
把 `android/` 里的 `EuiccBridgePlugin` 接到真实 LPA 实现后，即可真机管卡。

## 本机开发

```bash
# 需要本机 Flutter + Android SDK
cd lumina_euicc_flutter
flutter pub get
flutter run
```

真机调试可写 eUICC：

1. 完成 `android/` 与 OpenEUICC `app-common` + `lpac-jni` 的依赖集成  
2. 将 `EuiccBridgePlugin` 中的 TODO 接到 `EuiccChannelManagerService` 同类 API  
3. 使用带 ARA-M 的可写卡（9eSIM / ESTKme 等）

## 服务器说明

本仓库生成于内存/磁盘紧张的 VPS，**不在服务器上执行完整 Flutter/Android 编译**。  
请在本机 Android Studio / Flutter 环境构建。

## 包名

- ApplicationId: `top.syngnat.lumina.euicc`
- 显示名: Lumina eUICC
