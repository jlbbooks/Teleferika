import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
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
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

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
    Locale('it'),
  ];

  /// The official title of the application. This is a brand name and should not be translated unless specified.
  ///
  /// In en, this message translates to:
  /// **'TeleferiKa'**
  String get appTitle;

  /// The text displayed on the loading screen, with a placeholder for the application's name.
  ///
  /// In en, this message translates to:
  /// **'Loading {appName}...'**
  String loadingScreenMessage(String appName);

  /// App bar title for the project details page
  ///
  /// In en, this message translates to:
  /// **'Project Details'**
  String get projectPageTitle;

  /// No description provided for @tabDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get tabDetails;

  /// No description provided for @tabPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get tabPoints;

  /// No description provided for @tabCompass.
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get tabCompass;

  /// No description provided for @tabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tabMap;

  /// No description provided for @formFieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get formFieldNameLabel;

  /// No description provided for @formFieldNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get formFieldNoteLabel;

  /// No description provided for @formFieldAzimuthLabel.
  ///
  /// In en, this message translates to:
  /// **'Azimuth (°)'**
  String get formFieldAzimuthLabel;

  /// No description provided for @formFieldProjectDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Project Date'**
  String get formFieldProjectDateLabel;

  /// No description provided for @formFieldLastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get formFieldLastUpdatedLabel;

  /// No description provided for @buttonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get buttonSave;

  /// No description provided for @buttonCalculateAzimuth.
  ///
  /// In en, this message translates to:
  /// **'Calculate Azimuth'**
  String get buttonCalculateAzimuth;

  /// No description provided for @buttonCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get buttonCalculate;

  /// No description provided for @buttonSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get buttonSelectDate;

  /// No description provided for @compassAddPointButton.
  ///
  /// In en, this message translates to:
  /// **'Add Point'**
  String get compassAddPointButton;

  /// No description provided for @compassAddAsEndPointButton.
  ///
  /// In en, this message translates to:
  /// **'Add as End Point'**
  String get compassAddAsEndPointButton;

  /// No description provided for @pointsSetAsStartButton.
  ///
  /// In en, this message translates to:
  /// **'Set as Start'**
  String get pointsSetAsStartButton;

  /// No description provided for @pointsSetAsEndButton.
  ///
  /// In en, this message translates to:
  /// **'Set as End'**
  String get pointsSetAsEndButton;

  /// No description provided for @pointsDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get pointsDeleteButton;

  /// No description provided for @errorSaveProjectBeforeAddingPoints.
  ///
  /// In en, this message translates to:
  /// **'Please save the project before adding points.'**
  String get errorSaveProjectBeforeAddingPoints;

  /// No description provided for @infoFetchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Fetching location...'**
  String get infoFetchingLocation;

  /// Snackbar message when a point is successfully added. The ordinalNumber is the point's number.
  ///
  /// In en, this message translates to:
  /// **'Point P{ordinalNumber} added.'**
  String pointAddedSnackbar(String ordinalNumber);

  /// No description provided for @pointAddedSetAsEndSnackbarSuffix.
  ///
  /// In en, this message translates to:
  /// **'Set as END point.'**
  String get pointAddedSetAsEndSnackbarSuffix;

  /// No description provided for @pointAddedInsertedBeforeEndSnackbarSuffix.
  ///
  /// In en, this message translates to:
  /// **'Inserted before current end point.'**
  String get pointAddedInsertedBeforeEndSnackbarSuffix;

  /// Default note for a point added using the compass tool, showing the heading.
  ///
  /// In en, this message translates to:
  /// **'Point from Compass (H: {heading}°)'**
  String pointFromCompassDefaultNote(String heading);

  /// No description provided for @errorAddingPoint.
  ///
  /// In en, this message translates to:
  /// **'Error adding point: {errorMessage}'**
  String errorAddingPoint(String errorMessage);

  /// No description provided for @errorLoadingProjectDetails.
  ///
  /// In en, this message translates to:
  /// **'Error loading project details: {errorMessage}'**
  String errorLoadingProjectDetails(String errorMessage);

  /// No description provided for @errorAzimuthPointsNotSet.
  ///
  /// In en, this message translates to:
  /// **'Starting and/or ending point not set. Cannot calculate azimuth.'**
  String get errorAzimuthPointsNotSet;

  /// No description provided for @errorAzimuthPointsSame.
  ///
  /// In en, this message translates to:
  /// **'Starting and ending points are the same. Azimuth is undefined or 0.'**
  String get errorAzimuthPointsSame;

  /// No description provided for @errorAzimuthCouldNotRetrievePoints.
  ///
  /// In en, this message translates to:
  /// **'Could not retrieve point data for calculation. Please check points.'**
  String get errorAzimuthCouldNotRetrievePoints;

  /// No description provided for @errorCalculatingAzimuth.
  ///
  /// In en, this message translates to:
  /// **'Error calculating azimuth: {errorMessage}'**
  String errorCalculatingAzimuth(String errorMessage);

  /// No description provided for @azimuthCalculatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Azimuth calculated: {azimuthValue}°'**
  String azimuthCalculatedSnackbar(String azimuthValue);

  /// No description provided for @projectNameCannotBeEmptyValidator.
  ///
  /// In en, this message translates to:
  /// **'Project name cannot be empty.'**
  String get projectNameCannotBeEmptyValidator;

  /// No description provided for @projectSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Project saved successfully.'**
  String get projectSavedSuccessfully;

  /// No description provided for @dialogTitleConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get dialogTitleConfirmDelete;

  /// No description provided for @dialogContentConfirmDeletePoint.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete point P{pointOrdinal}? This action cannot be undone.'**
  String dialogContentConfirmDeletePoint(String pointOrdinal);

  /// No description provided for @buttonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// No description provided for @buttonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get buttonDelete;

  /// No description provided for @pointDeletedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Point P{pointOrdinal} deleted.'**
  String pointDeletedSnackbar(String pointOrdinal);

  /// No description provided for @pointSetAsStartSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Point P{pointOrdinal} set as start.'**
  String pointSetAsStartSnackbar(String pointOrdinal);

  /// No description provided for @pointSetAsEndSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Point P{pointOrdinal} set as end.'**
  String pointSetAsEndSnackbar(String pointOrdinal);
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'it':
      return SIt();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
