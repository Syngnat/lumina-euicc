## 本次更新

- Profile 列表接口不提供单个配置的精确占用大小；本版本在公开观测样本与当前 EID 芯片族可靠匹配时显示“约 xx KiB”，无法可靠匹配时隐藏该字段，不再显示“大小未知”，也不会把估算值冒充卡片测量值。
- 保号日期改用 Android AlarmClock 调度，并使用新的高优先级“eSIM 保号闹钟”通道，默认播放系统闹钟铃声并振动；未获得精确闹钟权限时仍保留可恢复的非精确调度并提示用户开启权限。
- 首页顶部铃铛现在只展示本机保号提醒，不再混入卡片侧技术事件。配置安装、启用、停用或删除后等待服务端上报的事件移到设置页，并明确标记为“eUICC 待上报事件”。
- 保留密集配置仪表盘、单国旗、ICCID 脱敏、启停互斥、微流量检查、重命名和删除等既有能力。
- 保留 **设置 → 软件更新**：仅检查本项目官方不可变 GitHub Release，自动选择与当前安装一致的 APK 架构，下载后校验 GitHub SHA-256、包名、新版本和完整四签名集合，再交给 Android 系统安装器确认。
- 配置大小属于估算，闹钟声音仍受 Android/ColorOS 通知通道设置影响；Profile 写操作也仍需更多真实白卡验证。

## APK 下载选择

Android 系统版本和 CPU ABI 是两件事。Lumina 支持 Android 9+（API 28+），请按设备架构下载：

- **现代手机 / OPPO 等 Android 设备（推荐）**：`lumina-euicc-@VERSION@-arm64-v8a.apk`
- **老旧 32 位 ARM 手机**：`lumina-euicc-@VERSION@-armeabi-v7a.apk`
- **x86_64 模拟器或少见的 Intel Android 设备**：`lumina-euicc-@VERSION@-x86_64.apk`
- **不确定架构时的兜底版本**：`lumina-euicc-@VERSION@-universal.apk`（兼容本次打包的全部 ABI，但文件更大）

近年的 OPPO/ColorOS 手机，包括 Android 16 机型，应下载 **`arm64-v8a`**。后续升级时尽量继续使用同一种 APK；从 ABI 专用版改回 `universal` 时，Android 可能要求先卸载旧版，但这不会删除可插拔 eUICC 卡内的配置。

## 白卡兼容性

已记录 **1 个具体 9eSIM 白卡/手机组合的只读实测结果**：`0.1.1` 四签名 APK 在 OMAPI 卡槽 1 使用当前应用身份打开 ISD-R，发现端口 1/0、LPA 通道有效，并成功读取多张真实 Profile。该白卡的确切 9eSIM 型号、手机型号和 Android 版本未记录，因此不能据此宣称某个 9eSIM 型号或全部批次已经认证。

同一家店购买的另一张白卡使用 Lumina `0.1.2` 在 OPPO PME110 / OP61C1L1（Android 16 / API 36）复测：系统枚举出 SIM 0 和 SIM 1，SIM 0 已到达 ISD-R 访问检查，随后访问控制拒绝当前 Lumina 身份；这证明手机侧 OMAPI/ISD-R 路径存在，并不是手机通道被锁。店铺相同仍不代表卡片个性化数据或有效 ARA-M 规则相同；下载、启停、重命名、删除等写操作也尚未完成实卡验证。以下是结合该有限现场证据、固定版本社区卡片数据库与当前 APK 签名得出的候选判断，不是兼容保证：

- **签名指纹匹配候选**：9eSIM v3、V2S、v0，eSIM.gg Card，蚊子玩卡 S3；公开数据列出了 Lumina 已包含的 9eSIM 社区证书，但型号未知的一次成功读取不能认证其中任何完整型号，仍需确认实际卡片没有不兼容的包名绑定，并在目标手机上实测。
- **需要卡侧配置**：ESTKme Light、Plus、Max；公开数据中的默认规则没有当前 Lumina 签名，只有先把卡的可变 ARA-M 列表配置为允许 Lumina 当前签名，并正确处理包名绑定，才属于候选。
- **未知**：通用白卡、无品牌白卡或只标注“GSMA 证书”的卡。EID 前缀、芯片厂商、STK 菜单和 GSMA 生产认证均不等于 ARA-M 应用授权。

完整证据、固定数据源和购买前检查项见[白卡兼容矩阵](https://github.com/Syngnat/lumina-euicc/blob/v@VERSION_NAME@/docs/SUPPORTED_CARDS.md)。

## 四签名与访问边界

从 `0.1.1` 起，Release APK 固定使用 **1 个 Lumina 私有项目签名 + 3 个可从固定上游源码公开复现的社区签名**：

- Lumina：`10:0C:A7:FD:2C:E4:B7:12:BA:3C:88:4C:AE:20:FD:33:25:ED:85:E0`
- Sakura：`65:D0:57:18:54:AF:EC:51:9A:90:F9:2D:7C:5D:8C:F8:14:8D:A3:73`
- ShiinaSekiu Community：`C4:73:50:C7:BA:68:2B:34:A3:E5:84:A0:D5:84:63:EA:42:B1:AD:73`
- 9eSIM：`D1:C0:F4:8B:37:0E:74:D4:EA:47:70:ED:4C:3C:D7:0A:31:98:D3:1F`

三个社区签名用于覆盖公开的 ARA-M 证书规则；Lumina 私有签名仍是更新安全锚点。Android 覆盖升级要求 APK 保留完整四签名集合，公开社区签名不能单独伪造本项目更新。签名来源、固定上游提交和安全边界见[社区多签名策略](https://github.com/Syngnat/lumina-euicc/blob/v@VERSION_NAME@/docs/COMMUNITY_SIGNING.md)。

手机 SIM 卡槽内的可插拔 eUICC 仍由卡侧 ARA-M 决定：无包名绑定的规则可匹配四个 current signer 中任意一个；有包名绑定时还必须允许 `top.syngnat.lumina.euicc`。这不是 Android 运行时权限，用户无法在系统权限页手动批准。

如果已安装仅含 Lumina 原始单签名的 `0.1.0` APK，需要先卸载一次再安装四签名版本；卸载应用不会删除卡内 eSIM 配置，但会清除应用本地设置。APK 使用 Signature Scheme v2，并关闭 v1、v3。

## USB CCID 说明

USB CCID 使用 Android USB Host 通道，不依赖手机卡槽的 ARA-M 规则。但当前实现尚无已认证读卡器，Flutter 主界面也尚未补齐完整的 USB 授权请求和插拔自动刷新流程；如果 Android 没有预先授予访问权，或设备未被当前连接路径识别，读卡器仍可能显示不可用。因此它是“传输代码已接入、真实硬件未验证”的候选路径。

Release 构建在无法打开真实 OMAPI/USB 通道时会明确显示不可用，不会展示 debug mock 配置。

## 发布资产、源码与许可

本 Release **自定义上传资产只有上面的 4 个 APK**。GitHub 会按不可变版本标签自动附加 `Source code (zip)` 和 `Source code (tar.gz)`；这是平台固定条目，无法由项目隐藏或删除。

- [此版本的精确标签源码](https://github.com/Syngnat/lumina-euicc/tree/v@VERSION_NAME@)
- [GPL-3.0-only 项目许可证](https://github.com/Syngnat/lumina-euicc/blob/v@VERSION_NAME@/LICENSE)
- [许可证范围](https://github.com/Syngnat/lumina-euicc/blob/v@VERSION_NAME@/LICENSES_SCOPE.md)
- [项目声明](https://github.com/Syngnat/lumina-euicc/blob/v@VERSION_NAME@/NOTICE.md)
- [第三方声明](https://github.com/Syngnat/lumina-euicc/blob/v@VERSION_NAME@/THIRD_PARTY_NOTICES.md)

同一次受信任 CI 会生成并校验精确提交源码、依赖源码/清单、`SOURCE_INFO.txt`、`SHA256SUMS`、依赖清单和嵌套许可证材料。完整的非 APK 对应源码与合规材料会合并为一个持续公开的 ZIP，追加到专用 `release-materials` 分支。下面的链接固定到该分支的精确提交，不会随分支后续更新漂移：

- [下载此版本的完整 source-materials ZIP](https://raw.githubusercontent.com/Syngnat/lumina-euicc/@RELEASE_COMMIT@/v@VERSION_NAME@/lumina-euicc-@VERSION@-source-materials.zip)
- materials commit：`@RELEASE_COMMIT@`
- ZIP SHA-256：`@SOURCE_MATERIALS_SHA256@`

同一次构建的完整 bundle 还会作为 Actions 审计 artifact 保留 90 天；持久 ZIP 不依赖 Actions 的保留期。GitHub Release 的每个 APK 条目会显示其 SHA-256 摘要。

CI 已检查包名、SDK、ABI、v2 签名、关闭的 v3、四个 current signers、证书指纹、ZIP 对齐和 64 位 ELF 对齐。这些构建证据不等于在所有手机、白卡或 USB CCID 读卡器上完成真实硬件验证。
