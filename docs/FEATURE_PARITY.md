# Lumina Flutter 功能覆盖

本表描述当前代码表面，不代表 ARA-M 卡或 USB CCID 读卡器真机验证结果。

## Profile 生命周期

| API | 参数 | 返回 |
|---|---|---|
| `listChannels` | - | `{channels:[{slotId,portId,seId,label,type}]}` |
| `listProfiles` | `slotId,portId,seId` | `{profiles:[{iccid,name,provider,enabled,profileClass,seq}]}` |
| `switchProfile` | `slotId,portId,seId,iccid,enable` | `{ok:true}` |
| `deleteProfile` | `slotId,portId,seId,iccid` | `{ok:true}` |
| `renameProfile` | `slotId,portId,seId,iccid,name` | `{ok:true}` |

## 下载

| API | 说明 |
|---|---|
| `downloadProfile` | `activationCode`，可选 `confirmationCode`、`imei`；返回本次下载的 `taskId` |
| Event: `taskEvents` | 每条事件携带 `taskId`，另含 `progress`(0-1)、`phase`、`provider`、`name`、`needConfirmation`、`done`、`error` |
| `confirmDownload` | 携带 `taskId`，仅确认对应下载 |
| `cancelDownload` | 携带 `taskId` 的协作式取消；若原生尾段已不可中断，最终结果仍可能是成功 |

## 设备 / 兼容

| API | 说明 |
|---|---|
| `runCompatibilityCheck` | 只读返回当前包名/签名 SHA-1、逐槽 OMAPI/ARA-M、ISD-R/LPA 检查项；使用稳定 `code` 和参数供中英文 UI 展示，不返回 EID/ICCID |
| `getEuiccInfo` | EID、通道有效性及原生 `euiccInfo2` 文本（通道支持时） |
| `memoryReset` | 危险操作，需二次确认 |
| `openSimToolkit` | 打开系统 SIM 卡工具包 / 卡内 LPAe 菜单；不授予 Lumina OMAPI/ARA-M 权限，也不返回卡内菜单数据 |

## 通知

| API | 当前暴露范围 |
|---|---|
| `listNotifications` | Kotlin、Dart API 与 Flutter 列表 UI 均已接线 |
| `processNotification` | 仅 Kotlin handler；尚无 Dart API / Flutter 操作 |
| `deleteNotification` | 仅 Kotlin handler；尚无 Dart API / Flutter 操作 |

## 应用更新

| API | 说明 |
|---|---|
| `getAppRuntimeInfo` | 返回当前版本、版本号和设备 ABI，不返回设备标识符 |
| `prepareUpdateFile` | 在应用私有缓存中准备经过名称约束的 APK 路径 |
| `verifyAndInstallUpdate` | 校验 SHA-256、大小、包名、目标版本、版本递增及完整签名集合后打开 Android 系统安装器 |
| `openInstallPermissionSettings` | 打开本应用的“安装未知应用”系统授权页；不支持静默安装 |

Flutter 仅接受官方仓库的不可变稳定 Release，并选择与当前安装一致的 APK
架构系列。首次带更新器的 `0.1.3` 仍需从 GitHub Release 手动安装。

## 与上游映射（集成时）

OpenEUICC `EuiccChannelManagerService`：

- `launchProfileDownloadTask` → `downloadProfile`
- `launchProfileRenameTask` → `renameProfile`
- `launchProfileDeleteTask` → `deleteProfile`
- `launchProfileSwitchTask` → `switchProfile`

Flutter 不重新实现 SGP.22；协议与安全边界仍在原生 LPA。
