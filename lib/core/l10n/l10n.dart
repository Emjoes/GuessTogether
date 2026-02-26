import 'package:flutter/widgets.dart';

import 'package:guesstogether/core/l10n/generated/app_localizations.dart';

extension AppL10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
