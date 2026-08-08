// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lumina eUICC';

  @override
  String get compatibility => 'Compatibility';

  @override
  String get settings => 'Settings';

  @override
  String get simToolkitManagement => 'STK management';

  @override
  String get simToolkitManagementDescription =>
      'Open the card\'s LPAe menu in the system SIM Toolkit';

  @override
  String get simToolkitUnavailable =>
      'The system SIM Toolkit is unavailable. Check that the device provides and enables an STK app.';

  @override
  String get newEsim => 'New eSIM';

  @override
  String get noEuiccFound => 'No eUICC found';

  @override
  String get noEuiccFoundDescription =>
      'Insert a compatible removable eUICC, or connect a USB CCID reader.';

  @override
  String get compatibilityCheck => 'Compatibility check';

  @override
  String get compatibilityOverviewTitle => 'Compatibility overview';

  @override
  String get compatibilityDeviceLabel => 'Device';

  @override
  String get compatibilityAndroidLabel => 'Android';

  @override
  String get compatibilityOmapiSlotsLabel => 'OMAPI-enumerated SIM slots';

  @override
  String get compatibilityIsdrReachedSlotsLabel => 'ISD-R access check reached';

  @override
  String get compatibilityIsdrAuthorizedSlotsLabel => 'Authorized ISD-R access';

  @override
  String get compatibilityAraMDeniedSlotsLabel =>
      'ARA-M / access control denied';

  @override
  String get compatibilityDetailsTitle => 'Detailed diagnostics';

  @override
  String get compatibilityNoSlots => 'None';

  @override
  String compatibilitySlotName(int slotId) {
    return 'SIM $slotId';
  }

  @override
  String get channels => 'Channels';

  @override
  String channelError(String error) {
    return 'Channel error: $error';
  }

  @override
  String get noProfilesYet => 'No profiles yet';

  @override
  String get noProfilesDescription =>
      'Download a profile with a QR / activation code.';

  @override
  String profilesLoadError(String error) {
    return 'Failed to load profiles: $error';
  }

  @override
  String get channelReconnectingTitle => 'eUICC channel is reconnecting';

  @override
  String get channelReconnectingDescription =>
      'A profile switch or card change can take a few seconds. Keep the card inserted and retry.';

  @override
  String get profilesUnavailableTitle => 'Profiles unavailable';

  @override
  String get profilesUnavailableDescription =>
      'Lumina could not read profiles from the selected channel. Refresh the channel and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get deleteProfileQuestion => 'Delete profile?';

  @override
  String deleteProfileConfirmation(String name) {
    return 'Delete “$name”? This cannot be undone.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get renameProfile => 'Rename profile';

  @override
  String get displayName => 'Display name';

  @override
  String get save => 'Save';

  @override
  String get enable => 'Enable';

  @override
  String get disable => 'Disable';

  @override
  String get rename => 'Rename';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get provider => 'Provider';

  @override
  String get profileRegionUnitedKingdom => 'United Kingdom';

  @override
  String profileRegionIssuerCountry(String countryCode) {
    return 'Issuer region $countryCode';
  }

  @override
  String get profileRegionGlobal => 'Global';

  @override
  String get profileRegionUnknown => 'Region unknown';

  @override
  String get iccidCopied => 'ICCID copied';

  @override
  String get iccidCopyHint => 'Long-press to copy ICCID';

  @override
  String profileSummary(int sequence, String profileClass) {
    return '#$sequence · $profileClass';
  }

  @override
  String profileClass(String profileClass) {
    String _temp0 = intl.Intl.selectLogic(
      profileClass,
      {
        'operational': 'Operational',
        'testing': 'Test',
        'test': 'Test',
        'provisioning': 'Provisioning',
        'other': '$profileClass',
      },
    );
    return '$_temp0';
  }

  @override
  String get activationCodeRequired => 'Activation code is required';

  @override
  String get confirmDownload => 'Confirm download';

  @override
  String confirmDownloadDescription(String provider, String name) {
    return 'Provider: $provider\nName: $name\n\nContinue?';
  }

  @override
  String get continueAction => 'Continue';

  @override
  String get profileDownloaded => 'Profile downloaded';

  @override
  String get downloadProfile => 'Download profile';

  @override
  String channelLabel(String channel) {
    return 'Channel: $channel';
  }

  @override
  String get activationCodeLabel => 'Activation code / LPA string';

  @override
  String get activationCodeHint => 'LPA:1\$smdp.example.com\$...';

  @override
  String get scanQr => 'Scan QR';

  @override
  String get confirmationCodeOptional => 'Confirmation code (optional)';

  @override
  String get imeiOptional => 'IMEI (optional)';

  @override
  String phaseLabel(String phase) {
    return 'Phase: $phase';
  }

  @override
  String downloadPhase(String phase) {
    String _temp0 = intl.Intl.selectLogic(
      phase,
      {
        'resolving': 'Resolving',
        'metadata': 'Reading metadata',
        'preparing': 'Preparing',
        'connecting': 'Connecting',
        'authenticating': 'Authenticating',
        'confirming': 'Awaiting confirmation',
        'downloading': 'Downloading',
        'finalizing': 'Finalizing',
        'cancelling': 'Cancelling',
        'cancelled': 'Cancelled',
        'done': 'Done',
        'error': 'Failed',
        'other': '$phase',
      },
    );
    return '$_temp0';
  }

  @override
  String get downloading => 'Downloading…';

  @override
  String get startDownload => 'Start download';

  @override
  String get about => 'About';

  @override
  String get aboutDescription =>
      'Lumina eUICC — a modern Flutter interface for removable eUICC management.\nCore LPA runs in the Android native bridge.';

  @override
  String get legalAndOpenSource => 'Legal & open source';

  @override
  String get legalAndOpenSourceDescription =>
      'License, source code, warranty, and third-party notices';

  @override
  String get projectLicense => 'Lumina license';

  @override
  String get projectLicenseDescription =>
      'Lumina-owned code is free software licensed under the GNU General Public License version 3 only.';

  @override
  String get noWarrantyTitle => 'No warranty';

  @override
  String get noWarrantyDescription =>
      'Lumina is provided without any warranty, to the extent permitted by law. See sections 15 and 16 of GPL v3.';

  @override
  String get sourceCode => 'Source code';

  @override
  String get sourceCodeDescription => 'The project source is available at:';

  @override
  String get copySourceCodeUrl => 'Copy source code URL';

  @override
  String get sourceCodeUrlCopied => 'Source code URL copied';

  @override
  String get thirdPartySoftware => 'Third-party software';

  @override
  String get openEuiccAttribution =>
      'Peter Cai and contributors · GPL-3.0-only.';

  @override
  String get lpacAttribution =>
      'ESTKME TECHNOLOGY LIMITED and OpenEUICC contributors · lpac-jni and the compiled lpac euicc component are LGPL-2.1-only; other vendored lpac files retain their component-specific licenses.';

  @override
  String get cjsonAttribution =>
      'Dave Gamble and cJSON contributors · MIT License.';

  @override
  String get zxingAttribution =>
      'JourneyApps, ZXing authors, and contributors · Apache License 2.0 (Apache-2.0). Used for on-device QR decoding; Google ML Kit is not included.';

  @override
  String get legalDocuments => 'Complete legal documents';

  @override
  String get legalDocumentsDescription =>
      'Complete license texts and attribution are provided in the corresponding-source bundle and repository: LICENSE, NOTICE.md, THIRD_PARTY_NOTICES.md, LICENSES_SCOPE.md, and the component LICENSE files under third_party/OpenEUICC/.';

  @override
  String get runtimeLicenses => 'Flutter and Dart packages';

  @override
  String get runtimeLicensesDescription =>
      'Review the open-source license notices generated for the Flutter and Dart packages included in this build.';

  @override
  String get openRuntimeLicenses => 'View package licenses';

  @override
  String get licensePageLegalese =>
      'Lumina-owned code is GPL-3.0-only and is provided without warranty.';

  @override
  String get memoryReset => 'Memory reset';

  @override
  String get selectChannelFirst => 'Select a channel first';

  @override
  String memoryResetWarning(String channel) {
    return 'Dangerous: wipe profiles on $channel';
  }

  @override
  String get memoryResetQuestion => 'Memory reset?';

  @override
  String get memoryResetConfirmation =>
      'This may delete profiles on the eUICC. Continue only if you know what you are doing.';

  @override
  String get reset => 'Reset';

  @override
  String get memoryResetRequested => 'Memory reset requested';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsDescription => 'List pending eUICC notifications';

  @override
  String get noPendingNotifications => 'No pending notifications';

  @override
  String get notification => 'Notification';

  @override
  String compatibilityError(String error) {
    return 'Error: $error';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String omapiChannelLabel(int slotId, int portId, String seId) {
    return 'Phone slot $slotId · port $portId · SE $seId';
  }

  @override
  String usbChannelLabel(int slotId, int portId, String seId) {
    return 'USB reader · slot $slotId · port $portId · SE $seId';
  }

  @override
  String get mockChannelLabel => 'Removable eUICC (mock)';

  @override
  String get listSeparator => ', ';

  @override
  String get compatibilityAppIdentityTitle => 'App identity for ARA-M';

  @override
  String compatibilityAppIdentityAvailable(
      String packageName, String certificates) {
    return 'Package $packageName; signing certificate SHA-1: $certificates.';
  }

  @override
  String compatibilityAppIdentityUnavailable(String packageName) {
    return 'Package $packageName; signing certificate SHA-1 is unavailable.';
  }

  @override
  String compatibilityLpaPortTitle(int slotId, int portId) {
    return 'LPA slot $slotId / port $portId';
  }

  @override
  String compatibilityLpaPortFailed(String failureType) {
    return 'Read-only LPA validation failed ($failureType).';
  }

  @override
  String get compatibilityLpaProbeTitle => 'LPA probe';

  @override
  String compatibilityLpaProbeFailed(String failureType) {
    return 'Read-only channel discovery failed ($failureType).';
  }

  @override
  String get compatibilityOmapiTitle => 'OMAPI support';

  @override
  String get compatibilityOmapiPresent =>
      'android.se.omapi.SEService is available.';

  @override
  String get compatibilityOmapiMissing =>
      'OMAPI is missing on this device or Android version.';

  @override
  String get compatibilityOmapiServiceTitle => 'OMAPI service';

  @override
  String compatibilityOmapiServiceFailed(String failureType) {
    return 'Read-only OMAPI service probe failed ($failureType).';
  }

  @override
  String compatibilityOmapiSlotTitle(int slotId) {
    return 'OMAPI phone slot $slotId';
  }

  @override
  String get compatibilityOmapiSlotAuthorized =>
      'ISD-R opened for the current app identity.';

  @override
  String compatibilityOmapiSlotAccessDenied(int slotId) {
    return 'Phone slot $slotId is reachable, but OMAPI access control (normally ARA-M / ARF for UICC) did not authorize the current app identity.';
  }

  @override
  String compatibilityOmapiSlotIsdrUnavailable(int slotId) {
    return 'Phone slot $slotId is reachable, but none of the configured ISD-R AIDs opened a channel.';
  }

  @override
  String compatibilityOmapiSlotFailed(String failureType) {
    return 'Read-only OMAPI probe failed ($failureType).';
  }

  @override
  String get compatibilityOmapiReadersTitle => 'OMAPI UICC readers';

  @override
  String get compatibilityOmapiNoReaders =>
      'OMAPI exposed no phone-slot UICC reader.';

  @override
  String get compatibilityEuiccPortsTitle => 'Discovered eUICC ports';

  @override
  String get compatibilityEuiccPortsMissing =>
      'No usable OMAPI or USB eUICC channel was opened.';

  @override
  String compatibilityEuiccPort(int slotId, int portId) {
    return 'slot $slotId / port $portId';
  }

  @override
  String get compatibilityLpaChannelTitle => 'LPA channel validity';

  @override
  String get compatibilityLpaChannelValid =>
      'A valid ISD-R / LPA channel opened successfully.';

  @override
  String get compatibilityLpaChannelInvalid =>
      'No valid LPA channel opened. Check the per-slot result and ARA-M rule.';

  @override
  String get compatibilityRootlessTitle => 'Rootless access / ARA-M';

  @override
  String get compatibilityRootlessReady =>
      'No root is used or required; a real LPA channel is available.';

  @override
  String get compatibilityRootlessAraMRequired =>
      'No root is used or required. For a card in the phone, its access-control rule must match at least one current Lumina signing certificate; if the rule also binds an Android package, it must match Lumina\'s package. USB CCID uses a separate permission path.';

  @override
  String get softwareUpdate => 'Software update';

  @override
  String get softwareUpdateDescription =>
      'Check for signed updates from GitHub Releases';

  @override
  String get updateSourceDescription =>
      'Updates come only from the official immutable Lumina GitHub Release.';

  @override
  String get updateSecurityDescription =>
      'The APK download is checked against GitHub\'s SHA-256 digest. Android also requires the package and complete signing-certificate set to match the installed app.';

  @override
  String currentVersionLabel(String version) {
    return 'Current version: $version';
  }

  @override
  String latestVersionLabel(String version) {
    return 'Latest version: $version';
  }

  @override
  String get checkingForUpdates => 'Checking for updates…';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String get upToDateTitle => 'You\'re up to date';

  @override
  String get upToDateDescription =>
      'This is the latest published stable version.';

  @override
  String updateAssetDetail(String variant, String size) {
    return '$variant · $size';
  }

  @override
  String get downloadAndInstall => 'Download and install';

  @override
  String updateDownloading(int percent) {
    return 'Downloading update… $percent%';
  }

  @override
  String get verifyingUpdate => 'Verifying the APK…';

  @override
  String get installPermissionRequiredTitle => 'Allow app installs';

  @override
  String get installPermissionRequiredDescription =>
      'Android must allow Lumina to open its downloaded APK in the system installer. Enable this permission, return here, then retry installation.';

  @override
  String get openInstallSettings => 'Open install settings';

  @override
  String get retryInstall => 'Retry installation';

  @override
  String get checkAgain => 'Check again';

  @override
  String get updateCheckFailed =>
      'Could not check for updates. Check the network connection and try again.';

  @override
  String get updateDownloadFailed =>
      'The update could not be downloaded or did not match the published file.';

  @override
  String get updateInstallFailed =>
      'Android could not verify or open this update. The installed app was not changed.';

  @override
  String get updateInstallerLaunched =>
      'The verified APK was handed to Android\'s system installer. Confirm the update there.';

  @override
  String get keepAliveReminder => 'Keep-alive reminder';

  @override
  String get editKeepAliveReminder => 'Edit reminder';

  @override
  String get cancelReminder => 'Cancel reminder';

  @override
  String reminderScheduledAt(String date, String time) {
    return 'Keep-alive reminder set for $date at $time';
  }

  @override
  String get selectReminderDate => 'Select keep-alive date';

  @override
  String get selectReminderTime => 'Select reminder time';

  @override
  String get reminderMustBeFuture => 'Choose a future date and time.';

  @override
  String get reminderSaved => 'Keep-alive reminder saved';

  @override
  String get reminderCancelled => 'Keep-alive reminder cancelled';

  @override
  String get reminderScheduleFailed =>
      'The keep-alive reminder could not be updated.';

  @override
  String get reminderNotificationsDeniedTitle => 'Notifications are disabled';

  @override
  String get reminderNotificationsDeniedDescription =>
      'The date was saved, but Android will not show the reminder until notifications are allowed for Lumina.';

  @override
  String get exactAlarmUnavailableTitle => 'Exact alarm access is off';

  @override
  String get exactAlarmUnavailableDescription =>
      'The reminder is scheduled, but Android may delay it. Allow Alarms & reminders for a more precise alert.';

  @override
  String get openAlarmSettings => 'Open alarm settings';

  @override
  String get close => 'Close';
}
