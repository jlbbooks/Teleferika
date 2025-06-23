import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:teleferika/l10n/app_localizations.dart';

import 'app_config.dart';

class LoadingPage extends StatefulWidget {
  final String? appVersion;
  const LoadingPage({super.key, this.appVersion});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: kDebugMode,
      localizationsDelegates: AppConfig.localizationsDelegates,
      supportedLocales: AppConfig.supportedLocales,
      // --- Dynamic Theme Settings ---
      theme: AppConfig.lightTheme, // Your defined light theme
      darkTheme: AppConfig.darkTheme, // Your defined dark theme
      themeMode: ThemeMode.system, // Auto-switch light/dark theme!
      // --- End Dynamic Theme Settings ---
      home: Builder(
        // Use a Builder to get a context from WITHIN this MaterialApp
        builder: (BuildContext innerContext) {
          // THIS 'innerContext' is from WITHIN LoadingPage's MaterialApp.
          // AppLocalizations.of(innerContext) here should now work.
          final localizations = S.of(innerContext);
          String loadingText =
              localizations?.loadingAppName(AppConfig.appName) ??
              'XXX ${AppConfig.appName}...';

          return Scaffold(
            backgroundColor:
                Colors.blueAccent, // TODO: Or your app's splash background
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loadingText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10), // Add some space
                  if (widget.appVersion != null &&
                      widget
                          .appVersion!
                          .isNotEmpty) // Only show if version is loaded
                    Text(
                      widget.appVersion!,
                      style: TextStyle(
                        color: Colors.white.withAlpha(
                          (0.7 * 255).round(),
                        ), // Slightly dimmer
                        fontSize: 12.0,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
