# EasyEUICC ↔ Lumina Flutter 功能对齐

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
| `downloadProfile` | `activationCode`, 可选 `confirmationCode`, `imei` |
| Event: `taskEvents` | `progress`(0-1), `phase`, `provider`, `name`, `needConfirmation`, `done`, `error` |
| `confirmDownload` | 用户确认继续下载 |
| `cancelDownload` | 取消 |

## 设备 / 兼容

| API | 说明 |
|---|---|
| `runCompatibilityCheck` | 返回 OMAPI / 通道 / ARA-M 相关检查项 |
| `getEuiccInfo` | EID、剩余空间等（通道支持时） |
| `memoryReset` | 危险操作，需二次确认 |

## 通知

| API | 说明 |
|---|---|
| `listNotifications` | 待处理通知列表 |
| `processNotification` | 处理单条 |
| `deleteNotification` | 删除单条 |

## 与上游映射（集成时）

OpenEUICC `EuiccChannelManagerService`：

- `launchProfileDownloadTask` → `downloadProfile`
- `launchProfileRenameTask` → `renameProfile`
- `launchProfileDeleteTask` → `deleteProfile`
- `launchProfileSwitchTask` → `switchProfile`

Flutter 不重新实现 SGP.22；协议与安全边界仍在原生 LPA。
