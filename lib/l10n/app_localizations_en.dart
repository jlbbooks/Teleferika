// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'TeleferiKa';

  @override
  String loadingAppName(String appName) {
    return 'Loading $appName...';
  }

  @override
  String get projectsListTitle => 'Projects';

  @override
  String versionInfo(String versionNumber) {
    return 'Version: $versionNumber';
  }
}
