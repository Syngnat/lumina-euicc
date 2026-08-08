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
  String get newEsim => 'New eSIM';

  @override
  String get noEuiccFound => 'No eUICC found';

  @override
  String get noEuiccFoundDescription =>
      'Insert a compatible removable eUICC, or connect a USB CCID reader.';

  @override
  String get compatibilityCheck => 'Compatibility check';

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
  String get iccidCopied => 'ICCID copied';

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
      'Lumina eUICC — Flutter UI aligned with EasyEUICC capabilities.\nCore LPA runs in the Android native bridge.';

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
      'ISD-R opened for this app certificate.';

  @override
  String compatibilityOmapiSlotAccessDenied(int slotId) {
    return 'Phone slot $slotId is reachable, but OMAPI / ARA-M denied this app certificate.';
  }

  @override
  String compatibilityOmapiSlotIsdrUnavailable(int slotId) {
    return 'Phone slot $slotId is reachable, but the default ISD-R AID returned no channel.';
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
      'No root is used or required. For a card in the phone, its ARA-M must authorize Lumina\'s package and signing certificate; an EasyEUICC-only rule does not authorize Lumina. USB CCID uses a separate permission path.';
}
