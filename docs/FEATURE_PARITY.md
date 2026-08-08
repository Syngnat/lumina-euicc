# EasyEUICC ↔ Lumina Flutter 功能对齐

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

## 通知

| API | 当前暴露范围 |
|---|---|
| `listNotifications` | Kotlin、Dart API 与 Flutter 列表 UI 均已接线 |
| `processNotification` | 仅 Kotlin handler；尚无 Dart API / Flutter 操作 |
| `deleteNotification` | 仅 Kotlin handler；尚无 Dart API / Flutter 操作 |

## 与上游映射（集成时）

OpenEUICC `EuiccChannelManagerService`：

- `launchProfileDownloadTask` → `downloadProfile`
- `launchProfileRenameTask` → `renameProfile`
- `launchProfileDeleteTask` → `deleteProfile`
- `launchProfileSwitchTask` → `switchProfile`

Flutter 不重新实现 SGP.22；协议与安全边界仍在原生 LPA。
