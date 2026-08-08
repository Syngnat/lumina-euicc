import 'package:flutter/material.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';
export 'euicc_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));
}
