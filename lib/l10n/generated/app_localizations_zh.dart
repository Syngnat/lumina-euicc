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
  String get notifications => '通知';

  @override
  String get notificationsDescription => '查看待处理的 eUICC 通知';

  @override
  String get noPendingNotifications => '暂无待处理通知';

  @override
  String get notification => '通知';

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
}
