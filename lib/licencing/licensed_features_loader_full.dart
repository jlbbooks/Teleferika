// import 'package:teleferika_licensed_features/licensed_features.dart';

import 'package:teleferika_licensed_features/licensed_features.dart';

import 'feature_registry.dart';

class LicensedFeaturesLoader {
  static Future<void> registerLicensedFeatures() async {
    try {
      final FeaturePlugin plugin = LicensedPlugin();
      FeatureRegistry.registerPlugin(plugin);
      print('Licensed features registered successfully');
    } catch (e) {
      print('Failed to register licensed features: $e');
      rethrow;
    }
  }
}
