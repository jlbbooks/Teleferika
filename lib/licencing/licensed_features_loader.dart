import 'package:teleferika/logger.dart';

// This file will be overridden when licensed features are available
class LicensedFeaturesLoader {
  static Future<void> registerLicensedFeatures() async {
    // No-op in open source version
    logger.warning('Licensed features not available in this build');
  }
}
