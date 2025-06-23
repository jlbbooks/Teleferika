// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class SIt extends S {
  SIt([String locale = 'it']) : super(locale);

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
