// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Lumina eUICC';

  @override
  String get compatibility => '兼容性';

  @override
  String get settings => '设置';

  @override
  String get simToolkitManagement => 'STK 管理';

  @override
  String get simToolkitManagementDescription => '打开系统 SIM 卡工具包中的卡内 LPAe 菜单';

  @override
  String get simToolkitUnavailable => '系统“SIM 卡工具包”不可用。请确认设备提供并已启用 STK 应用。';

  @override
  String get newEsim => '新增 eSIM';

  @override
  String get noEuiccFound => '未发现 eUICC';

  @override
  String get noEuiccFoundDescription => '请插入兼容的可插拔 eUICC，或连接 USB CCID 读卡器。';

  @override
  String get compatibilityCheck => '兼容性检查';

  @override
  String get compatibilityOverviewTitle => '兼容性概览';

  @override
  String get compatibilityDeviceLabel => '设备';

  @override
  String get compatibilityAndroidLabel => 'Android';

  @override
  String get compatibilityOmapiSlotsLabel => 'OMAPI 枚举的 SIM 卡槽';

  @override
  String get compatibilityIsdrReachedSlotsLabel => '已到达 ISD-R 访问检查';

  @override
  String get compatibilityIsdrAuthorizedSlotsLabel => '已授权打开 ISD-R';

  @override
  String get compatibilityAraMDeniedSlotsLabel => 'ARA-M / 访问控制拒绝';

  @override
  String get compatibilityDetailsTitle => '详细诊断';

  @override
  String get compatibilityNoSlots => '无';

  @override
  String compatibilitySlotName(int slotId) {
    return 'SIM $slotId';
  }

  @override
  String get channels => '通道';

  @override
  String get dashboardSubtitle => '数字 eSIM 护照';

  @override
  String get profilesSectionTitle => '配置';

  @override
  String profileCount(int count) {
    return '$count 个配置';
  }

  @override
  String get localReminders => '本地提醒';

  @override
  String get eidUnavailable => 'EID 暂不可用';

  @override
  String freeMemory(String size) {
    return '$size 可用';
  }

  @override
  String get freeMemoryUnknown => '可用空间未知';

  @override
  String profileSizeEstimate(String size) {
    return '约 $size';
  }

  @override
  String get reminderUnset => '未设置提醒';

  @override
  String get reminderExpired => '已过期';

  @override
  String reminderDaysRemaining(int days) {
    return '$days天';
  }

  @override
  String get profileSwitchFailed => '无法切换配置，请刷新后重试。';

  @override
  String get profileActions => '配置操作';

  @override
  String channelError(String error) {
    return '通道错误：$error';
  }

  @override
  String get noProfilesYet => '暂无配置文件';

  @override
  String get noProfilesDescription => '使用二维码或激活码下载配置文件。';

  @override
  String profilesLoadError(String error) {
    return '加载配置文件失败：$error';
  }

  @override
  String get channelReconnectingTitle => 'eUICC 通道正在重连';

  @override
  String get channelReconnectingDescription =>
      '启用配置或换卡后，通道可能需要几秒恢复。请保持卡片插入并重试。';

  @override
  String get profilesUnavailableTitle => '暂时无法读取配置';

  @override
  String get profilesUnavailableDescription => 'Lumina 无法从当前通道读取配置。请刷新通道后重试。';

  @override
  String get retry => '重试';

  @override
  String get deleteProfileQuestion => '删除配置文件？';

  @override
  String deleteProfileConfirmation(String name) {
    return '确定删除“$name”吗？此操作无法撤销。';
  }

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get renameProfile => '重命名配置文件';

  @override
  String get displayName => '显示名称';

  @override
  String get save => '保存';

  @override
  String get enable => '启用';

  @override
  String get disable => '停用';

  @override
  String get rename => '重命名';

  @override
  String get enabled => '已启用';

  @override
  String get disabled => '已停用';

  @override
  String get provider => '运营商';

  @override
  String get profileRegionUnitedKingdom => '英国';

  @override
  String profileRegionIssuerCountry(String countryCode) {
    return '发卡地区 $countryCode';
  }

  @override
  String get profileRegionGlobal => '全球';

  @override
  String get profileRegionUnknown => '地区未知';

  @override
  String get iccidCopied => '已复制 ICCID';

  @override
  String get iccidCopyHint => '长按复制 ICCID';

  @override
  String profileSummary(int sequence, String profileClass) {
    return '#$sequence · $profileClass';
  }

  @override
  String profileClass(String profileClass) {
    String _temp0 = intl.Intl.selectLogic(
      profileClass,
      {
        'operational': '正式',
        'testing': '测试',
        'test': '测试',
        'provisioning': '预置',
        'other': '$profileClass',
      },
    );
    return '$_temp0';
  }

  @override
  String get activationCodeRequired => '请输入激活码';

  @override
  String get confirmDownload => '确认下载';

  @override
  String confirmDownloadDescription(String provider, String name) {
    return '运营商：$provider\n名称：$name\n\n是否继续？';
  }

  @override
  String get continueAction => '继续';

  @override
  String get profileDownloaded => '配置文件下载完成';

  @override
  String get downloadProfile => '下载配置文件';

  @override
  String channelLabel(String channel) {
    return '通道：$channel';
  }

  @override
  String get activationCodeLabel => '激活码 / LPA 字符串';

  @override
  String get activationCodeHint => 'LPA:1\$smdp.example.com\$...';

  @override
  String get scanQr => '扫描二维码';

  @override
  String get confirmationCodeOptional => '确认码（选填）';

  @override
  String get imeiOptional => 'IMEI（选填）';

  @override
  String phaseLabel(String phase) {
    return '阶段：$phase';
  }

  @override
  String downloadPhase(String phase) {
    String _temp0 = intl.Intl.selectLogic(
      phase,
      {
        'resolving': '正在解析',
        'metadata': '正在读取信息',
        'preparing': '正在准备',
        'connecting': '正在连接',
        'authenticating': '正在认证',
        'confirming': '等待确认',
        'downloading': '正在下载',
        'finalizing': '正在完成',
        'cancelling': '正在取消',
        'cancelled': '已取消',
        'done': '已完成',
        'error': '失败',
        'other': '$phase',
      },
    );
    return '$_temp0';
  }

  @override
  String get downloading => '正在下载…';

  @override
  String get startDownload => '开始下载';

  @override
  String get about => '关于';

  @override
  String get aboutDescription =>
      'Lumina eUICC — 面向可插拔 eUICC 管理的现代 Flutter 界面。\n核心 LPA 运行在 Android 原生桥接层。';

  @override
  String get legalAndOpenSource => '法律与开源信息';

  @override
  String get legalAndOpenSourceDescription => '查看许可证、源代码、无担保声明及第三方声明';

  @override
  String get projectLicense => 'Lumina 许可证';

  @override
  String get projectLicenseDescription =>
      'Lumina 自有代码是自由软件，仅依据 GNU 通用公共许可证第 3 版（GPL-3.0-only）授权。';

  @override
  String get noWarrantyTitle => '无担保声明';

  @override
  String get noWarrantyDescription =>
      '在法律允许的范围内，Lumina 不提供任何担保。详情请参阅 GPL 第 3 版第 15、16 条。';

  @override
  String get sourceCode => '源代码';

  @override
  String get sourceCodeDescription => '项目源代码地址：';

  @override
  String get copySourceCodeUrl => '复制源代码地址';

  @override
  String get sourceCodeUrlCopied => '已复制源代码地址';

  @override
  String get thirdPartySoftware => '第三方软件';

  @override
  String get openEuiccAttribution => 'Peter Cai 及贡献者 · GPL-3.0-only。';

  @override
  String get lpacAttribution =>
      'ESTKME TECHNOLOGY LIMITED 及 OpenEUICC 贡献者 · lpac-jni 与实际编译的 lpac euicc 组件采用 LGPL-2.1-only；其他随附 lpac 文件保留各自组件许可证。';

  @override
  String get cjsonAttribution => 'Dave Gamble 及 cJSON 贡献者 · MIT 许可证。';

  @override
  String get zxingAttribution =>
      'JourneyApps、ZXing 作者及贡献者 · Apache License 2.0（Apache-2.0）。用于设备端二维码解码，不包含 Google ML Kit。';

  @override
  String get legalDocuments => '完整法律文件';

  @override
  String get legalDocumentsDescription =>
      '完整许可证正文及归属声明随对应源码包提供，也可在源码仓库中查看：LICENSE、NOTICE.md、THIRD_PARTY_NOTICES.md、LICENSES_SCOPE.md，以及 third_party/OpenEUICC/ 下各组件的 LICENSE 文件。';

  @override
  String get runtimeLicenses => 'Flutter 与 Dart 软件包';

  @override
  String get runtimeLicensesDescription =>
      '查看本构建所含 Flutter 与 Dart 软件包生成的开源许可证声明。';

  @override
  String get openRuntimeLicenses => '查看软件包许可证';

  @override
  String get licensePageLegalese => 'Lumina 自有代码采用 GPL-3.0-only 授权，且不提供任何担保。';

  @override
  String get memoryReset => '重置存储';

  @override
  String get selectChannelFirst => '请先选择通道';

  @override
  String memoryResetWarning(String channel) {
    return '危险操作：清除 $channel 上的配置文件';
  }

  @override
  String get memoryResetQuestion => '重置存储？';

  @override
  String get memoryResetConfirmation => '此操作可能删除 eUICC 上的配置文件。仅在了解风险后继续。';

  @override
  String get reset => '重置';

  @override
  String get memoryResetRequested => '已请求重置存储';

  @override
  String get euiccPendingReports => 'eUICC 待上报事件';

  @override
  String get euiccPendingReportsDescription =>
      '配置安装、启用、停用或删除后，卡片等待上报给服务端的技术事件；不是保号提醒或提醒历史。';

  @override
  String get noPendingEuiccReports => '暂无等待上报的卡片事件';

  @override
  String get euiccPendingReport => 'eUICC 待上报事件';

  @override
  String compatibilityError(String error) {
    return '错误：$error';
  }

  @override
  String get refresh => '刷新';

  @override
  String omapiChannelLabel(int slotId, int portId, String seId) {
    return '手机卡槽 $slotId · 端口 $portId · 安全元件 $seId';
  }

  @override
  String usbChannelLabel(int slotId, int portId, String seId) {
    return 'USB 读卡器 · 卡槽 $slotId · 端口 $portId · 安全元件 $seId';
  }

  @override
  String get mockChannelLabel => '可插拔 eUICC（模拟）';

  @override
  String get listSeparator => '、';

  @override
  String get compatibilityAppIdentityTitle => '用于 ARA-M 的应用身份';

  @override
  String compatibilityAppIdentityAvailable(
      String packageName, String certificates) {
    return '包名：$packageName；签名证书 SHA-1：$certificates。';
  }

  @override
  String compatibilityAppIdentityUnavailable(String packageName) {
    return '包名：$packageName；无法获取签名证书 SHA-1。';
  }

  @override
  String compatibilityLpaPortTitle(int slotId, int portId) {
    return 'LPA 卡槽 $slotId / 端口 $portId';
  }

  @override
  String compatibilityLpaPortFailed(String failureType) {
    return '只读 LPA 校验失败（$failureType）。';
  }

  @override
  String get compatibilityLpaProbeTitle => 'LPA 检测';

  @override
  String compatibilityLpaProbeFailed(String failureType) {
    return '只读通道发现失败（$failureType）。';
  }

  @override
  String get compatibilityOmapiTitle => 'OMAPI 支持';

  @override
  String get compatibilityOmapiPresent => '设备支持 android.se.omapi.SEService。';

  @override
  String get compatibilityOmapiMissing => '此设备或 Android 版本不支持 OMAPI。';

  @override
  String get compatibilityOmapiServiceTitle => 'OMAPI 服务';

  @override
  String compatibilityOmapiServiceFailed(String failureType) {
    return '只读 OMAPI 服务检测失败（$failureType）。';
  }

  @override
  String compatibilityOmapiSlotTitle(int slotId) {
    return 'OMAPI 手机卡槽 $slotId';
  }

  @override
  String get compatibilityOmapiSlotAuthorized => '已使用当前应用身份打开 ISD-R。';

  @override
  String compatibilityOmapiSlotAccessDenied(int slotId) {
    return '手机卡槽 $slotId 可访问，但 OMAPI 访问控制（UICC 通常为 ARA-M / ARF）未授权当前应用身份。';
  }

  @override
  String compatibilityOmapiSlotIsdrUnavailable(int slotId) {
    return '手机卡槽 $slotId 可访问，但所有已配置的 ISD-R AID 均未打开通道。';
  }

  @override
  String compatibilityOmapiSlotFailed(String failureType) {
    return '只读 OMAPI 检测失败（$failureType）。';
  }

  @override
  String get compatibilityOmapiReadersTitle => 'OMAPI UICC 读卡器';

  @override
  String get compatibilityOmapiNoReaders => 'OMAPI 未暴露任何手机卡槽 UICC 读卡器。';

  @override
  String get compatibilityEuiccPortsTitle => '发现的 eUICC 端口';

  @override
  String get compatibilityEuiccPortsMissing => '未打开可用的 OMAPI 或 USB eUICC 通道。';

  @override
  String compatibilityEuiccPort(int slotId, int portId) {
    return '卡槽 $slotId / 端口 $portId';
  }

  @override
  String get compatibilityLpaChannelTitle => 'LPA 通道有效性';

  @override
  String get compatibilityLpaChannelValid => '已成功打开有效的 ISD-R / LPA 通道。';

  @override
  String get compatibilityLpaChannelInvalid =>
      '未打开有效的 LPA 通道。请检查各卡槽结果和 ARA-M 规则。';

  @override
  String get compatibilityRootlessTitle => '免 Root 访问 / ARA-M';

  @override
  String get compatibilityRootlessReady => '无需也不会使用 Root；当前已有可用的真实 LPA 通道。';

  @override
  String get compatibilityRootlessAraMRequired =>
      '无需也不会使用 Root。对于插在手机里的卡，其访问控制规则必须匹配 Lumina 至少一个当前签名证书；如果规则还绑定 Android 包名，则必须同时匹配 Lumina 包名。USB CCID 使用独立的权限流程。';

  @override
  String get softwareUpdate => '软件更新';

  @override
  String get softwareUpdateDescription => '从 GitHub Releases 检查签名更新';

  @override
  String get updateSourceDescription => '更新仅来自 Lumina 官方且不可变的 GitHub Release。';

  @override
  String get updateSecurityDescription =>
      '下载完成后会核对 GitHub 公布的 SHA-256；Android 还会检查包名及完整签名证书集合是否与当前应用一致。';

  @override
  String currentVersionLabel(String version) {
    return '当前版本：$version';
  }

  @override
  String latestVersionLabel(String version) {
    return '最新版本：$version';
  }

  @override
  String get checkingForUpdates => '正在检查更新…';

  @override
  String get updateAvailableTitle => '发现新版本';

  @override
  String get upToDateTitle => '已是最新版本';

  @override
  String get upToDateDescription => '当前安装的是最新正式版本。';

  @override
  String updateAssetDetail(String variant, String size) {
    return '$variant · $size';
  }

  @override
  String get downloadAndInstall => '下载并安装';

  @override
  String updateDownloading(int percent) {
    return '正在下载更新… $percent%';
  }

  @override
  String get verifyingUpdate => '正在校验 APK…';

  @override
  String get installPermissionRequiredTitle => '允许安装应用';

  @override
  String get installPermissionRequiredDescription =>
      'Android 需要允许 Lumina 在系统安装器中打开已下载的 APK。请开启该权限，返回此页面后重试安装。';

  @override
  String get openInstallSettings => '打开安装权限设置';

  @override
  String get retryInstall => '重试安装';

  @override
  String get checkAgain => '重新检查';

  @override
  String get updateCheckFailed => '无法检查更新，请确认网络连接后重试。';

  @override
  String get updateDownloadFailed => '更新下载失败，或下载文件与发布内容不一致。';

  @override
  String get updateInstallFailed => 'Android 无法校验或打开此更新，当前应用未被修改。';

  @override
  String get updateInstallerLaunched =>
      '已将校验通过的 APK 交给 Android 系统安装器，请在系统界面确认更新。';

  @override
  String get keepAliveReminder => '保号提醒';

  @override
  String get keepAliveReminderCenterTitle => '保号提醒';

  @override
  String get noKeepAliveReminders => '当前通道暂无保号提醒';

  @override
  String get editKeepAliveReminder => '修改提醒';

  @override
  String get cancelReminder => '取消提醒';

  @override
  String reminderScheduledAt(String date, String time) {
    return '保号提醒已设置为 $date $time';
  }

  @override
  String get selectReminderDate => '选择保号日期';

  @override
  String get selectReminderTime => '选择提醒时间';

  @override
  String get reminderMustBeFuture => '请选择未来的日期和时间。';

  @override
  String get reminderSaved => '保号闹钟已设置';

  @override
  String get reminderCancelled => '已取消保号提醒';

  @override
  String get reminderScheduleFailed => '无法更新保号提醒。';

  @override
  String get reminderNotificationsDeniedTitle => '通知权限未开启';

  @override
  String get reminderNotificationsDeniedDescription =>
      '日期已经保存，但在允许 Lumina 发送通知之前，Android 不会显示保号提醒。';

  @override
  String get exactAlarmUnavailableTitle => '精确闹钟权限未开启';

  @override
  String get exactAlarmUnavailableDescription =>
      '提醒已经安排，但 Android 可能延迟触发。开启“闹钟和提醒”权限后可获得更准时的通知。';

  @override
  String get openAlarmSettings => '打开闹钟设置';

  @override
  String get microDataKeepAlive => '微流量保号';

  @override
  String get microDataKeepAliveTooltip => '使用目标号码进行一次微流量联网';

  @override
  String get microDataKeepAliveConfirmTitle => '使用一次蜂窝网络？';

  @override
  String microDataKeepAliveConfirmDescription(String profileName) {
    return 'Lumina 将临时启用“$profileName”，为该配置申请专用蜂窝网络，向 Lumina GitHub 页面发送一次不跟随跳转的 HTTPS HEAD 请求，然后恢复原配置。Android 电话权限只用于把卡槽映射到活动订阅；本操作不读取手机号码，也不持久化 ICCID。响应正文限制为 1 KB（通常为 0 字节），但 DNS、TCP、TLS、系统流量、漫游费用及运营商计费可能超过 1 KB。此操作只能证明联网成功，不能保证运营商已完成保号。';
  }

  @override
  String get microDataKeepAliveProceed => '联网一次';

  @override
  String get microDataKeepAliveRunningTitle => '正在使用所选 eSIM…';

  @override
  String get microDataKeepAliveRunningDescription =>
      '请保持 Lumina 在前台。网络请求结束后会恢复原配置。';

  @override
  String get microDataKeepAliveSuccessTitle => '微流量联网成功';

  @override
  String microDataKeepAliveSuccessDescription(
      int httpStatus, int bytes, int limit) {
    return '目标配置已返回 HTTP $httpStatus，响应正文 $bytes/$limit 字节。Lumina 已立即释放本应用的专用蜂窝网络请求，并恢复原配置状态。保号有效期仍请向运营商确认。';
  }

  @override
  String get microDataKeepAliveFailedTitle => '微流量联网失败';

  @override
  String microDataKeepAliveFailedDescription(String reason) {
    return '本次请求未完成：$reason。Lumina 不会将其视为保号成功。';
  }

  @override
  String get microDataRestoreFailedTitle => '请立即检查当前启用配置';

  @override
  String get microDataRestoreFailedDescription =>
      '尝试结束后 Lumina 未能恢复原配置状态。请返回配置列表，手动选择需要保持启用的号码。';

  @override
  String get microDataPermissionDenied => '需要电话权限，仅用于这次操作识别目标蜂窝订阅';

  @override
  String get microDataUnsupportedChannel =>
      '此功能只支持安装在手机 OMAPI 卡槽中的卡，不支持 USB 或模拟通道';

  @override
  String get microDataBusy => '已有一次微流量操作正在进行';

  @override
  String get microDataCancelled => 'Lumina 离开前台，本次操作已停止';

  @override
  String get microDataProfileNotFound => '所选配置已不存在';

  @override
  String get microDataChannelUnavailable => 'eUICC 通道正在重连或不可用';

  @override
  String get microDataActivationFailed => '无法启用目标配置';

  @override
  String get microDataSubscriptionUnavailable => 'Android 未将目标配置识别为活动蜂窝订阅';

  @override
  String get microDataCellularNetworkUnavailable => 'Android 无法为目标订阅提供蜂窝网络';

  @override
  String get microDataConnectionFailed => '无法通过目标订阅完成 HTTPS 请求';

  @override
  String get microDataGenericFailure => '发生未预期的联网操作错误';

  @override
  String get close => '关闭';
}
