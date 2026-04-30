import 'package:flutter/widgets.dart';
import 'package:war_armies_app/l10n/arb/app_localizations.dart';

export 'package:war_armies_app/l10n/arb/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
