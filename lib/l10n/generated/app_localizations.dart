import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Lumina eUICC'**
  String get appTitle;

  /// No description provided for @compatibility.
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get compatibility;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @newEsim.
  ///
  /// In en, this message translates to:
  /// **'New eSIM'**
  String get newEsim;

  /// No description provided for @noEuiccFound.
  ///
  /// In en, this message translates to:
  /// **'No eUICC found'**
  String get noEuiccFound;

  /// No description provided for @noEuiccFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'Insert a compatible removable eUICC, or connect a USB CCID reader.'**
  String get noEuiccFoundDescription;

  /// No description provided for @compatibilityCheck.
  ///
  /// In en, this message translates to:
  /// **'Compatibility check'**
  String get compatibilityCheck;

  /// No description provided for @compatibilityOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Compatibility overview'**
  String get compatibilityOverviewTitle;

  /// No description provided for @compatibilityDeviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get compatibilityDeviceLabel;

  /// No description provided for @compatibilityAndroidLabel.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get compatibilityAndroidLabel;

  /// No description provided for @compatibilityOmapiSlotsLabel.
  ///
  /// In en, this message translates to:
  /// **'OMAPI-enumerated SIM slots'**
  String get compatibilityOmapiSlotsLabel;

  /// No description provided for @compatibilityIsdrReachedSlotsLabel.
  ///
  /// In en, this message translates to:
  /// **'ISD-R access check reached'**
  String get compatibilityIsdrReachedSlotsLabel;

  /// No description provided for @compatibilityIsdrAuthorizedSlotsLabel.
  ///
  /// In en, this message translates to:
  /// **'Authorized ISD-R access'**
  String get compatibilityIsdrAuthorizedSlotsLabel;

  /// No description provided for @compatibilityAraMDeniedSlotsLabel.
  ///
  /// In en, this message translates to:
  /// **'ARA-M / access control denied'**
  String get compatibilityAraMDeniedSlotsLabel;

  /// No description provided for @compatibilityDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed diagnostics'**
  String get compatibilityDetailsTitle;

  /// No description provided for @compatibilityNoSlots.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get compatibilityNoSlots;

  /// No description provided for @compatibilitySlotName.
  ///
  /// In en, this message translates to:
  /// **'SIM {slotId}'**
  String compatibilitySlotName(int slotId);

  /// No description provided for @channels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channels;

  /// No description provided for @channelError.
  ///
  /// In en, this message translates to:
  /// **'Channel error: {error}'**
  String channelError(String error);

  /// No description provided for @noProfilesYet.
  ///
  /// In en, this message translates to:
  /// **'No profiles yet'**
  String get noProfilesYet;

  /// No description provided for @noProfilesDescription.
  ///
  /// In en, this message translates to:
  /// **'Download a profile with a QR / activation code.'**
  String get noProfilesDescription;

  /// No description provided for @profilesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profiles: {error}'**
  String profilesLoadError(String error);

  /// No description provided for @deleteProfileQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete profile?'**
  String get deleteProfileQuestion;

  /// No description provided for @deleteProfileConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”? This cannot be undone.'**
  String deleteProfileConfirmation(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @renameProfile.
  ///
  /// In en, this message translates to:
  /// **'Rename profile'**
  String get renameProfile;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @profileRegionUnitedKingdom.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get profileRegionUnitedKingdom;

  /// No description provided for @profileRegionGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get profileRegionGlobal;

  /// No description provided for @profileRegionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Region unknown'**
  String get profileRegionUnknown;

  /// No description provided for @iccidCopied.
  ///
  /// In en, this message translates to:
  /// **'ICCID copied'**
  String get iccidCopied;

  /// No description provided for @iccidCopyHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press to copy ICCID'**
  String get iccidCopyHint;

  /// No description provided for @profileSummary.
  ///
  /// In en, this message translates to:
  /// **'#{sequence} · {profileClass}'**
  String profileSummary(int sequence, String profileClass);

  /// No description provided for @profileClass.
  ///
  /// In en, this message translates to:
  /// **'{profileClass, select, operational{Operational} testing{Test} test{Test} provisioning{Provisioning} other{{profileClass}}}'**
  String profileClass(String profileClass);

  /// No description provided for @activationCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Activation code is required'**
  String get activationCodeRequired;

  /// No description provided for @confirmDownload.
  ///
  /// In en, this message translates to:
  /// **'Confirm download'**
  String get confirmDownload;

  /// No description provided for @confirmDownloadDescription.
  ///
  /// In en, this message translates to:
  /// **'Provider: {provider}\nName: {name}\n\nContinue?'**
  String confirmDownloadDescription(String provider, String name);

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @profileDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Profile downloaded'**
  String get profileDownloaded;

  /// No description provided for @downloadProfile.
  ///
  /// In en, this message translates to:
  /// **'Download profile'**
  String get downloadProfile;

  /// No description provided for @channelLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel: {channel}'**
  String channelLabel(String channel);

  /// No description provided for @activationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Activation code / LPA string'**
  String get activationCodeLabel;

  /// No description provided for @activationCodeHint.
  ///
  /// In en, this message translates to:
  /// **'LPA:1\$smdp.example.com\$...'**
  String get activationCodeHint;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQr;

  /// No description provided for @confirmationCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Confirmation code (optional)'**
  String get confirmationCodeOptional;

  /// No description provided for @imeiOptional.
  ///
  /// In en, this message translates to:
  /// **'IMEI (optional)'**
  String get imeiOptional;

  /// No description provided for @phaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Phase: {phase}'**
  String phaseLabel(String phase);

  /// No description provided for @downloadPhase.
  ///
  /// In en, this message translates to:
  /// **'{phase, select, resolving{Resolving} metadata{Reading metadata} preparing{Preparing} connecting{Connecting} authenticating{Authenticating} confirming{Awaiting confirmation} downloading{Downloading} finalizing{Finalizing} cancelling{Cancelling} cancelled{Cancelled} done{Done} error{Failed} other{{phase}}}'**
  String downloadPhase(String phase);

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get downloading;

  /// No description provided for @startDownload.
  ///
  /// In en, this message translates to:
  /// **'Start download'**
  String get startDownload;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Lumina eUICC — a modern Flutter interface for removable eUICC management.\nCore LPA runs in the Android native bridge.'**
  String get aboutDescription;

  /// No description provided for @legalAndOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Legal & open source'**
  String get legalAndOpenSource;

  /// No description provided for @legalAndOpenSourceDescription.
  ///
  /// In en, this message translates to:
  /// **'License, source code, warranty, and third-party notices'**
  String get legalAndOpenSourceDescription;

  /// No description provided for @projectLicense.
  ///
  /// In en, this message translates to:
  /// **'Lumina license'**
  String get projectLicense;

  /// No description provided for @projectLicenseDescription.
  ///
  /// In en, this message translates to:
  /// **'Lumina-owned code is free software licensed under the GNU General Public License version 3 only.'**
  String get projectLicenseDescription;

  /// No description provided for @noWarrantyTitle.
  ///
  /// In en, this message translates to:
  /// **'No warranty'**
  String get noWarrantyTitle;

  /// No description provided for @noWarrantyDescription.
  ///
  /// In en, this message translates to:
  /// **'Lumina is provided without any warranty, to the extent permitted by law. See sections 15 and 16 of GPL v3.'**
  String get noWarrantyDescription;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @sourceCodeDescription.
  ///
  /// In en, this message translates to:
  /// **'The project source is available at:'**
  String get sourceCodeDescription;

  /// No description provided for @copySourceCodeUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy source code URL'**
  String get copySourceCodeUrl;

  /// No description provided for @sourceCodeUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'Source code URL copied'**
  String get sourceCodeUrlCopied;

  /// No description provided for @thirdPartySoftware.
  ///
  /// In en, this message translates to:
  /// **'Third-party software'**
  String get thirdPartySoftware;

  /// No description provided for @openEuiccAttribution.
  ///
  /// In en, this message translates to:
  /// **'Peter Cai and contributors · GPL-3.0-only.'**
  String get openEuiccAttribution;

  /// No description provided for @lpacAttribution.
  ///
  /// In en, this message translates to:
  /// **'ESTKME TECHNOLOGY LIMITED and OpenEUICC contributors · lpac-jni and the compiled lpac euicc component are LGPL-2.1-only; other vendored lpac files retain their component-specific licenses.'**
  String get lpacAttribution;

  /// No description provided for @cjsonAttribution.
  ///
  /// In en, this message translates to:
  /// **'Dave Gamble and cJSON contributors · MIT License.'**
  String get cjsonAttribution;

  /// No description provided for @zxingAttribution.
  ///
  /// In en, this message translates to:
  /// **'JourneyApps, ZXing authors, and contributors · Apache License 2.0 (Apache-2.0). Used for on-device QR decoding; Google ML Kit is not included.'**
  String get zxingAttribution;

  /// No description provided for @legalDocuments.
  ///
  /// In en, this message translates to:
  /// **'Complete legal documents'**
  String get legalDocuments;

  /// No description provided for @legalDocumentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete license texts and attribution are provided in the corresponding-source bundle and repository: LICENSE, NOTICE.md, THIRD_PARTY_NOTICES.md, LICENSES_SCOPE.md, and the component LICENSE files under third_party/OpenEUICC/.'**
  String get legalDocumentsDescription;

  /// No description provided for @runtimeLicenses.
  ///
  /// In en, this message translates to:
  /// **'Flutter and Dart packages'**
  String get runtimeLicenses;

  /// No description provided for @runtimeLicensesDescription.
  ///
  /// In en, this message translates to:
  /// **'Review the open-source license notices generated for the Flutter and Dart packages included in this build.'**
  String get runtimeLicensesDescription;

  /// No description provided for @openRuntimeLicenses.
  ///
  /// In en, this message translates to:
  /// **'View package licenses'**
  String get openRuntimeLicenses;

  /// No description provided for @licensePageLegalese.
  ///
  /// In en, this message translates to:
  /// **'Lumina-owned code is GPL-3.0-only and is provided without warranty.'**
  String get licensePageLegalese;

  /// No description provided for @memoryReset.
  ///
  /// In en, this message translates to:
  /// **'Memory reset'**
  String get memoryReset;

  /// No description provided for @selectChannelFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a channel first'**
  String get selectChannelFirst;

  /// No description provided for @memoryResetWarning.
  ///
  /// In en, this message translates to:
  /// **'Dangerous: wipe profiles on {channel}'**
  String memoryResetWarning(String channel);

  /// No description provided for @memoryResetQuestion.
  ///
  /// In en, this message translates to:
  /// **'Memory reset?'**
  String get memoryResetQuestion;

  /// No description provided for @memoryResetConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This may delete profiles on the eUICC. Continue only if you know what you are doing.'**
  String get memoryResetConfirmation;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @memoryResetRequested.
  ///
  /// In en, this message translates to:
  /// **'Memory reset requested'**
  String get memoryResetRequested;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'List pending eUICC notifications'**
  String get notificationsDescription;

  /// No description provided for @noPendingNotifications.
  ///
  /// In en, this message translates to:
  /// **'No pending notifications'**
  String get noPendingNotifications;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @compatibilityError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String compatibilityError(String error);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @omapiChannelLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone slot {slotId} · port {portId} · SE {seId}'**
  String omapiChannelLabel(int slotId, int portId, String seId);

  /// No description provided for @usbChannelLabel.
  ///
  /// In en, this message translates to:
  /// **'USB reader · slot {slotId} · port {portId} · SE {seId}'**
  String usbChannelLabel(int slotId, int portId, String seId);

  /// No description provided for @mockChannelLabel.
  ///
  /// In en, this message translates to:
  /// **'Removable eUICC (mock)'**
  String get mockChannelLabel;

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @compatibilityAppIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'App identity for ARA-M'**
  String get compatibilityAppIdentityTitle;

  /// No description provided for @compatibilityAppIdentityAvailable.
  ///
  /// In en, this message translates to:
  /// **'Package {packageName}; signing certificate SHA-1: {certificates}.'**
  String compatibilityAppIdentityAvailable(
      String packageName, String certificates);

  /// No description provided for @compatibilityAppIdentityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Package {packageName}; signing certificate SHA-1 is unavailable.'**
  String compatibilityAppIdentityUnavailable(String packageName);

  /// No description provided for @compatibilityLpaPortTitle.
  ///
  /// In en, this message translates to:
  /// **'LPA slot {slotId} / port {portId}'**
  String compatibilityLpaPortTitle(int slotId, int portId);

  /// No description provided for @compatibilityLpaPortFailed.
  ///
  /// In en, this message translates to:
  /// **'Read-only LPA validation failed ({failureType}).'**
  String compatibilityLpaPortFailed(String failureType);

  /// No description provided for @compatibilityLpaProbeTitle.
  ///
  /// In en, this message translates to:
  /// **'LPA probe'**
  String get compatibilityLpaProbeTitle;

  /// No description provided for @compatibilityLpaProbeFailed.
  ///
  /// In en, this message translates to:
  /// **'Read-only channel discovery failed ({failureType}).'**
  String compatibilityLpaProbeFailed(String failureType);

  /// No description provided for @compatibilityOmapiTitle.
  ///
  /// In en, this message translates to:
  /// **'OMAPI support'**
  String get compatibilityOmapiTitle;

  /// No description provided for @compatibilityOmapiPresent.
  ///
  /// In en, this message translates to:
  /// **'android.se.omapi.SEService is available.'**
  String get compatibilityOmapiPresent;

  /// No description provided for @compatibilityOmapiMissing.
  ///
  /// In en, this message translates to:
  /// **'OMAPI is missing on this device or Android version.'**
  String get compatibilityOmapiMissing;

  /// No description provided for @compatibilityOmapiServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'OMAPI service'**
  String get compatibilityOmapiServiceTitle;

  /// No description provided for @compatibilityOmapiServiceFailed.
  ///
  /// In en, this message translates to:
  /// **'Read-only OMAPI service probe failed ({failureType}).'**
  String compatibilityOmapiServiceFailed(String failureType);

  /// No description provided for @compatibilityOmapiSlotTitle.
  ///
  /// In en, this message translates to:
  /// **'OMAPI phone slot {slotId}'**
  String compatibilityOmapiSlotTitle(int slotId);

  /// No description provided for @compatibilityOmapiSlotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'ISD-R opened for the current app identity.'**
  String get compatibilityOmapiSlotAuthorized;

  /// No description provided for @compatibilityOmapiSlotAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Phone slot {slotId} is reachable, but OMAPI access control (normally ARA-M / ARF for UICC) did not authorize the current app identity.'**
  String compatibilityOmapiSlotAccessDenied(int slotId);

  /// No description provided for @compatibilityOmapiSlotIsdrUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Phone slot {slotId} is reachable, but none of the configured ISD-R AIDs opened a channel.'**
  String compatibilityOmapiSlotIsdrUnavailable(int slotId);

  /// No description provided for @compatibilityOmapiSlotFailed.
  ///
  /// In en, this message translates to:
  /// **'Read-only OMAPI probe failed ({failureType}).'**
  String compatibilityOmapiSlotFailed(String failureType);

  /// No description provided for @compatibilityOmapiReadersTitle.
  ///
  /// In en, this message translates to:
  /// **'OMAPI UICC readers'**
  String get compatibilityOmapiReadersTitle;

  /// No description provided for @compatibilityOmapiNoReaders.
  ///
  /// In en, this message translates to:
  /// **'OMAPI exposed no phone-slot UICC reader.'**
  String get compatibilityOmapiNoReaders;

  /// No description provided for @compatibilityEuiccPortsTitle.
  ///
  /// In en, this message translates to:
  /// **'Discovered eUICC ports'**
  String get compatibilityEuiccPortsTitle;

  /// No description provided for @compatibilityEuiccPortsMissing.
  ///
  /// In en, this message translates to:
  /// **'No usable OMAPI or USB eUICC channel was opened.'**
  String get compatibilityEuiccPortsMissing;

  /// No description provided for @compatibilityEuiccPort.
  ///
  /// In en, this message translates to:
  /// **'slot {slotId} / port {portId}'**
  String compatibilityEuiccPort(int slotId, int portId);

  /// No description provided for @compatibilityLpaChannelTitle.
  ///
  /// In en, this message translates to:
  /// **'LPA channel validity'**
  String get compatibilityLpaChannelTitle;

  /// No description provided for @compatibilityLpaChannelValid.
  ///
  /// In en, this message translates to:
  /// **'A valid ISD-R / LPA channel opened successfully.'**
  String get compatibilityLpaChannelValid;

  /// No description provided for @compatibilityLpaChannelInvalid.
  ///
  /// In en, this message translates to:
  /// **'No valid LPA channel opened. Check the per-slot result and ARA-M rule.'**
  String get compatibilityLpaChannelInvalid;

  /// No description provided for @compatibilityRootlessTitle.
  ///
  /// In en, this message translates to:
  /// **'Rootless access / ARA-M'**
  String get compatibilityRootlessTitle;

  /// No description provided for @compatibilityRootlessReady.
  ///
  /// In en, this message translates to:
  /// **'No root is used or required; a real LPA channel is available.'**
  String get compatibilityRootlessReady;

  /// No description provided for @compatibilityRootlessAraMRequired.
  ///
  /// In en, this message translates to:
  /// **'No root is used or required. For a card in the phone, its access-control rule must match at least one current Lumina signing certificate; if the rule also binds an Android package, it must match Lumina\'s package. USB CCID uses a separate permission path.'**
  String get compatibilityRootlessAraMRequired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
