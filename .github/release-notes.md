## APK 下载选择

Android 系统版本和 CPU ABI 是两件事。Android 9 到 Android 16 都可能运行在不同架构上，请按设备架构下载：

- **现代手机 / OPPO 等 Android 设备（推荐）**：`lumina-euicc-@VERSION@-arm64-v8a.apk`
- **老旧 32 位 ARM 手机**：`lumina-euicc-@VERSION@-armeabi-v7a.apk`
- **x86_64 模拟器或少见的 Intel Android 设备**：`lumina-euicc-@VERSION@-x86_64.apk`
- **不确定设备架构时的兜底版本**：`lumina-euicc-@VERSION@-universal.apk`（兼容本次打包的全部 ABI，但文件更大）

近年的 OPPO/ColorOS 手机，包括 Android 16 机型，应下载 **`arm64-v8a`**。Lumina 支持 Android 9+（API 28+）；Android 版本较低不代表必须下载 `armeabi-v7a`。

后续升级时请尽量继续使用同一种 APK。Flutter 会给分架构 APK 分配架构专用版本号，从 ABI 专用版改回 `universal` 时，Android 可能要求先卸载旧版；这不会删除可插拔 eUICC 卡内的配置。

## 安装前必读

- 从 `0.1.1` 起，Release APK 使用同一个稳定的四签名集合：Lumina、Sakura、ShiinaSekiu Community 和 9eSIM。它使用 APK Signature Scheme v2，并明确关闭 v1、v3。
- 如果手机已安装仅含 Lumina 原始单签名的 `0.1.0` APK，Android 无法直接覆盖升级；这一次需要先卸载旧版，再安装这里的四签名 Release APK。卸载应用不会删除可插拔 eUICC 卡内的 eSIM 配置，但会清除应用本地设置。后续版本会固定保留同一四签名集合。
- Lumina 是普通的非 Root 应用，不需要也不支持 Root、Magisk、Shizuku 或系统应用安装。通过手机 SIM 卡槽访问可插拔 eUICC 时，没有包名绑定的 ARA-M 规则可匹配四个 current signer 中的任意一个；如果规则绑定了包名，还必须匹配 `top.syngnat.lumina.euicc`。USB CCID 是另一条非特权访问路径。
- 四个 ARA-M SHA-1 指纹分别为：Lumina `10:0C:A7:FD:2C:E4:B7:12:BA:3C:88:4C:AE:20:FD:33:25:ED:85:E0`、Sakura `65:D0:57:18:54:AF:EC:51:9A:90:F9:2D:7C:5D:8C:F8:14:8D:A3:73`、ShiinaSekiu Community `C4:73:50:C7:BA:68:2B:34:A3:E5:84:A0:D5:84:63:EA:42:B1:AD:73`、9eSIM `D1:C0:F4:8B:37:0E:74:D4:EA:47:70:ED:4C:3C:D7:0A:31:98:D3:1F`。
- EasyEUICC 的 `2A…` 私钥没有公开，因此无法纳入；NekokoLPA 的 `nekokobeef`、`wenzi` 密钥也无法通过公开信息解锁，因此未纳入。
- Release 构建在无法打开真实 OMAPI/USB 通道时会明确显示不可用，不会展示 debug mock 配置。

## 校验与对应源码

本 Release 的每个 APK 都必须与同一 Release 中的 `SHA256SUMS`、精确提交源码包、依赖源码包/清单、`SOURCE_INFO.txt`、依赖清单和许可证材料一起提供。安装前请核对 SHA-256；转载 APK 时也请保留同一发布中的对应源码和 notices。

APK 构建时已关闭 v1/v3；CI 已检查包名、SDK、ABI、v2 签名、关闭的 v3、四个 current signers、全部证书指纹、ZIP 对齐和 64 位 ELF 对齐。这不等于已在所有手机、白卡或 USB CCID 读卡器上完成真实硬件验证。
