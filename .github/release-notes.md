## APK 下载选择

Android 系统版本和 CPU ABI 是两件事。Android 9 到 Android 16 都可能运行在不同架构上，请按设备架构下载：

- **现代手机 / OPPO 等 Android 设备（推荐）**：`lumina-euicc-@VERSION@-arm64-v8a.apk`
- **老旧 32 位 ARM 手机**：`lumina-euicc-@VERSION@-armeabi-v7a.apk`
- **x86_64 模拟器或少见的 Intel Android 设备**：`lumina-euicc-@VERSION@-x86_64.apk`
- **不确定设备架构时的兜底版本**：`lumina-euicc-@VERSION@-universal.apk`（兼容本次打包的全部 ABI，但文件更大）

近年的 OPPO/ColorOS 手机，包括 Android 16 机型，应下载 **`arm64-v8a`**。Lumina 支持 Android 9+（API 28+）；Android 版本较低不代表必须下载 `armeabi-v7a`。

后续升级时请尽量继续使用同一种 APK。Flutter 会给分架构 APK 分配架构专用版本号，从 ABI 专用版改回 `universal` 时，Android 可能要求先卸载旧版；这不会删除可插拔 eUICC 卡内的配置。

## 安装前必读

- Release APK 使用 Lumina 专用证书签名。若手机已安装同包名的 debug 版或其他证书签名版本，Android 会拒绝直接覆盖安装；请先卸载旧版，再安装这里的 Release APK。卸载应用不会删除可插拔 eUICC 卡内的 eSIM 配置，但会清除应用本地设置。
- Lumina 是普通的非 Root 应用，不需要也不支持 Root、Magisk、Shizuku 或系统应用安装。通过手机 SIM 卡槽访问可插拔 eUICC 时，卡内 ARA-M 必须授权 Lumina 的签名证书；只授权 EasyEUICC 证书的卡不会自动授权 Lumina。USB CCID 是另一条非特权访问路径。
- Lumina Release 证书的 ARA-M SHA-1 指纹为 `10:0C:A7:FD:2C:E4:B7:12:BA:3C:88:4C:AE:20:FD:33:25:ED:85:E0`，包名为 `top.syngnat.lumina.euicc`。
- Release 构建在无法打开真实 OMAPI/USB 通道时会明确显示不可用，不会展示 debug mock 配置。

## 校验与对应源码

本 Release 的每个 APK 都必须与同一 Release 中的 `SHA256SUMS`、精确提交源码包、依赖源码包/清单、`SOURCE_INFO.txt`、依赖清单和许可证材料一起提供。安装前请核对 SHA-256；转载 APK 时也请保留同一发布中的对应源码和 notices。

CI 已检查 APK 的包名、SDK、ABI、v2 签名、单一签名者、证书指纹、ZIP 对齐和 64 位 ELF 对齐。这不等于已在所有手机、白卡或 USB CCID 读卡器上完成真实硬件验证。
