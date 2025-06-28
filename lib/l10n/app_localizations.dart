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

  /// No description provided for @formFieldPresumedTotalLengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Presumed Total Length (m)'**
  String get formFieldPresumedTotalLengthLabel;

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

  /// Default note for a point added using the compass tool, showing the altitude.
  ///
  /// In en, this message translates to:
  /// **'Added (H: {altitude}°)'**
  String pointFromCompassDefaultNote(String altitude);

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

  /// Snackbar message when azimuth is successfully saved.
  ///
  /// In en, this message translates to:
  /// **'Azimuth saved successfully.'**
  String get azimuthSavedSnackbar;

  /// Title for the dialog asking for confirmation to overwrite existing azimuth value.
  ///
  /// In en, this message translates to:
  /// **'Overwrite Azimuth?'**
  String get azimuthOverwriteTitle;

  /// Message in the dialog asking for confirmation to overwrite existing azimuth value.
  ///
  /// In en, this message translates to:
  /// **'The azimuth field already has a value. The new calculated value will overwrite the current value. Do you want to continue?'**
  String get azimuthOverwriteMessage;

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

  /// Title for the export data page/dialog.
  ///
  /// In en, this message translates to:
  /// **'Export Project Data'**
  String get export_project_data_title;

  /// Label showing the name of the project being exported.
  ///
  /// In en, this message translates to:
  /// **'Project: {projectName}'**
  String export_page_project_name_label(String projectName);

  /// Label showing the number of points that will be exported.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{No points found for export.} =1{{count} point found.} other{{count} points found.}}'**
  String export_page_points_count_label(int count);

  /// Label for the format selection dropdown.
  ///
  /// In en, this message translates to:
  /// **'Select Export Format:'**
  String get export_page_select_format_label;

  /// Label for the export format dropdown itself.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get export_format_dropdown_label;

  /// Text for the button that initiates sharing the exported file.
  ///
  /// In en, this message translates to:
  /// **'Share File'**
  String get export_page_share_button;

  /// Text for the button that initiates saving the exported file to local device storage.
  ///
  /// In en, this message translates to:
  /// **'Save Locally'**
  String get export_page_save_locally_button;

  /// Error message shown when the export process encounters an issue.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Please try again.'**
  String get export_failed;

  /// Success message shown after the file is ready for sharing via the share dialog.
  ///
  /// In en, this message translates to:
  /// **'File prepared for sharing.'**
  String get file_shared_successfully;

  /// No description provided for @file_saved_successfully.
  ///
  /// In en, this message translates to:
  /// **'File saved successfully'**
  String get file_saved_successfully;

  /// Message shown if the user cancels the save dialog or if saving fails for other reasons.
  ///
  /// In en, this message translates to:
  /// **'File save was cancelled or failed.'**
  String get file_save_cancelled_or_failed;

  /// Tooltip for the export button/icon in the project page app bar.
  ///
  /// In en, this message translates to:
  /// **'Export Project Data'**
  String get export_project_data_tooltip;

  /// Tooltip for the export button in the project page app bar.
  ///
  /// In en, this message translates to:
  /// **'Export Project'**
  String get export_project_tooltip;

  /// Error message when trying to export a project with no points.
  ///
  /// In en, this message translates to:
  /// **'No points to export'**
  String get errorExportNoPoints;

  /// Loading message shown during export process.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get infoExporting;

  /// Success message when export completes successfully.
  ///
  /// In en, this message translates to:
  /// **'Project exported successfully'**
  String get exportSuccess;

  /// Generic error message when export fails.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportError;

  /// Error message when export fails with specific error details.
  ///
  /// In en, this message translates to:
  /// **'Export error: {errorMessage}'**
  String exportErrorWithDetails(String errorMessage);

  /// Error message when export is attempted without a valid licence.
  ///
  /// In en, this message translates to:
  /// **'Valid licence required for export'**
  String get exportRequiresValidLicence;

  /// Title for the dialog warning about unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsaved_changes_title;

  /// Message in the dialog prompting the user to save before exporting due to unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Please save the project before exporting to ensure all data is included.'**
  String get unsaved_changes_export_message;

  /// Generic label for a save button, used in the unsaved changes dialog.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save_button_label;

  /// Generic label for a cancel button in dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialog_cancel;

  /// Error message if export is attempted but the project data isn't available.
  ///
  /// In en, this message translates to:
  /// **'Project not loaded. Cannot export data.'**
  String get project_not_loaded_cannot_export;

  /// Error message if points associated with the project cannot be fetched for export.
  ///
  /// In en, this message translates to:
  /// **'Error loading points for export. Please try again.'**
  String get error_loading_points;

  /// Informational note at the bottom of the export page.
  ///
  /// In en, this message translates to:
  /// **'Note: Ensure you have granted necessary storage permissions if saving locally on mobile devices. Some export formats may not include all data types (e.g., images).'**
  String get export_page_note_text;

  /// Message shown when trying to export a brand new, never-saved project.
  ///
  /// In en, this message translates to:
  /// **'Please save the new project first to enable export.'**
  String get please_save_project_first_to_export;

  /// No description provided for @export_requires_licence_title.
  ///
  /// In en, this message translates to:
  /// **'Licence Required for Export'**
  String get export_requires_licence_title;

  /// No description provided for @export_requires_licence_message.
  ///
  /// In en, this message translates to:
  /// **'This feature requires an active licence. Please import a valid licence file to proceed.'**
  String get export_requires_licence_message;

  /// No description provided for @action_import_licence.
  ///
  /// In en, this message translates to:
  /// **'Import Licence'**
  String get action_import_licence;

  /// No description provided for @edit_project_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get edit_project_title;

  /// No description provided for @edit_project_title_named.
  ///
  /// In en, this message translates to:
  /// **'Edit: {projectName}'**
  String edit_project_title_named(String projectName);

  /// No description provided for @new_project_title.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get new_project_title;

  /// No description provided for @delete_project_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get delete_project_tooltip;

  /// No description provided for @save_project_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Save Project'**
  String get save_project_tooltip;

  /// No description provided for @last_updated_label.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String last_updated_label(String date);

  /// No description provided for @not_yet_saved_label.
  ///
  /// In en, this message translates to:
  /// **'Not yet saved'**
  String get not_yet_saved_label;

  /// No description provided for @tap_to_set_date.
  ///
  /// In en, this message translates to:
  /// **'Tap to set date'**
  String get tap_to_set_date;

  /// No description provided for @invalid_number_validator.
  ///
  /// In en, this message translates to:
  /// **'Invalid number.'**
  String get invalid_number_validator;

  /// No description provided for @must_be_359_validator.
  ///
  /// In en, this message translates to:
  /// **'Must be +/-359.99'**
  String get must_be_359_validator;

  /// No description provided for @please_correct_form_errors.
  ///
  /// In en, this message translates to:
  /// **'Please correct the errors in the form.'**
  String get please_correct_form_errors;

  /// No description provided for @project_created_successfully.
  ///
  /// In en, this message translates to:
  /// **'Project created successfully!'**
  String get project_created_successfully;

  /// No description provided for @project_already_up_to_date.
  ///
  /// In en, this message translates to:
  /// **'Project already up to date or not found.'**
  String get project_already_up_to_date;

  /// No description provided for @cannot_delete_unsaved_project.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete a project that has not been saved yet.'**
  String get cannot_delete_unsaved_project;

  /// No description provided for @confirm_delete_project_title.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirm_delete_project_title;

  /// No description provided for @confirm_delete_project_content.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the project \"{projectName}\"? This action cannot be undone.'**
  String confirm_delete_project_content(Object projectName);

  /// No description provided for @project_deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Project deleted successfully.'**
  String get project_deleted_successfully;

  /// No description provided for @project_not_found_or_deleted.
  ///
  /// In en, this message translates to:
  /// **'Project not found or already deleted.'**
  String get project_not_found_or_deleted;

  /// No description provided for @error_saving_project.
  ///
  /// In en, this message translates to:
  /// **'Error saving project: {errorMessage}'**
  String error_saving_project(String errorMessage);

  /// No description provided for @error_deleting_project.
  ///
  /// In en, this message translates to:
  /// **'Error deleting project: {errorMessage}'**
  String error_deleting_project(String errorMessage);

  /// No description provided for @unsaved_changes_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsaved_changes_dialog_title;

  /// No description provided for @unsaved_changes_dialog_content.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them and leave?'**
  String get unsaved_changes_dialog_content;

  /// No description provided for @discard_button_label.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard_button_label;

  /// No description provided for @details_tab_label.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details_tab_label;

  /// No description provided for @points_tab_label.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points_tab_label;

  /// No description provided for @compass_tab_label.
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get compass_tab_label;

  /// No description provided for @map_tab_label.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map_tab_label;

  /// Title for the export data page.
  ///
  /// In en, this message translates to:
  /// **'Export Project Data'**
  String get export_page_title;

  /// Description text for the export page.
  ///
  /// In en, this message translates to:
  /// **'Export your project data in various formats.'**
  String get export_page_description;

  /// Label for the CSV export format option.
  ///
  /// In en, this message translates to:
  /// **'CSV (Comma-Separated Values)'**
  String get export_format_csv;

  /// Label for the KML export format option.
  ///
  /// In en, this message translates to:
  /// **'KML (Keyhole Markup Language)'**
  String get export_format_kml;

  /// Label for the GeoJSON export format option.
  ///
  /// In en, this message translates to:
  /// **'GeoJSON'**
  String get export_format_geojson;

  /// Message shown in the dialog when there are unsaved changes and the user attempts to leave the page.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Discard them and leave?'**
  String get unsaved_changes_discard_message;

  /// Label for the button that discards unsaved changes in the dialog.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes'**
  String get unsaved_changes_discard_button;

  /// Label for the button that saves unsaved changes in the dialog.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get unsaved_changes_save_button;

  /// Message shown when there are no points to export in the project.
  ///
  /// In en, this message translates to:
  /// **'No points available for export.'**
  String get export_page_no_points;

  /// Error message shown on the map when points cannot be loaded.
  ///
  /// In en, this message translates to:
  /// **'Error loading points for map: {errorMessage}'**
  String mapErrorLoadingPoints(String errorMessage);

  /// Snackbar message when a point is successfully moved on the map.
  ///
  /// In en, this message translates to:
  /// **'Point P{ordinalNumber} moved successfully!'**
  String mapPointMovedSuccessfully(String ordinalNumber);

  /// Snackbar error message when moving a point on the map fails because it's not found or not updated.
  ///
  /// In en, this message translates to:
  /// **'Error: Could not move point P{ordinalNumber}. Point not found or not updated.'**
  String mapErrorMovingPoint(String ordinalNumber);

  /// Generic snackbar error message when moving a point on the map fails.
  ///
  /// In en, this message translates to:
  /// **'Error moving point P{ordinalNumber}: {errorMessage}'**
  String mapErrorMovingPointGeneric(String ordinalNumber, String errorMessage);

  /// Tooltip for the button/icon to activate move point mode for a selected point on the map.
  ///
  /// In en, this message translates to:
  /// **'Move Point'**
  String get mapTooltipMovePoint;

  /// Tooltip for the button/icon to save the new position of a point being moved on the map.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get mapTooltipSaveChanges;

  /// Tooltip for the button/icon to cancel moving a point and revert to its original position.
  ///
  /// In en, this message translates to:
  /// **'Cancel Move'**
  String get mapTooltipCancelMove;

  /// Tooltip for the button/icon to navigate to the point details page for the selected point.
  ///
  /// In en, this message translates to:
  /// **'Edit Details'**
  String get mapTooltipEditPointDetails;

  /// Tooltip for the FAB (Floating Action Button) that uses current compass/GPS data to add a new point. Navigates to compass tab.
  ///
  /// In en, this message translates to:
  /// **'Add Point at Current Location (from Compass)'**
  String get mapTooltipAddPointFromCompass;

  /// Message shown on the map when there are no project points.
  ///
  /// In en, this message translates to:
  /// **'No points to display on the map.'**
  String get mapNoPointsToDisplay;

  /// Message displayed on the map or as a snackbar if location permission is denied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Map features requiring location will be limited.'**
  String get mapLocationPermissionDenied;

  /// Message displayed if compass/sensor permission is denied.
  ///
  /// In en, this message translates to:
  /// **'Sensor (compass) permission denied. Device orientation features will be unavailable.'**
  String get mapSensorPermissionDenied;

  /// Error message if fetching continuous location updates fails.
  ///
  /// In en, this message translates to:
  /// **'Error getting location updates: {errorMessage}'**
  String mapErrorGettingLocationUpdates(String errorMessage);

  /// Error message if fetching compass updates fails.
  ///
  /// In en, this message translates to:
  /// **'Error getting compass updates: {errorMessage}'**
  String mapErrorGettingCompassUpdates(String errorMessage);

  /// Text for the CircularProgressIndicator shown while map points are loading.
  ///
  /// In en, this message translates to:
  /// **'Loading points...'**
  String get mapLoadingPointsIndicator;

  /// Title text for the permissions required overlay/card on the map.
  ///
  /// In en, this message translates to:
  /// **'Permissions Required'**
  String get mapPermissionsRequiredTitle;

  /// Informational text explaining why location permission is needed for the map.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to show your current position and for some map features.'**
  String get mapLocationPermissionInfoText;

  /// Informational text explaining why sensor (compass) permission is needed for the map.
  ///
  /// In en, this message translates to:
  /// **'Sensor (compass) permission is needed for direction-based features.'**
  String get mapSensorPermissionInfoText;

  /// Button text to open the application's settings page.
  ///
  /// In en, this message translates to:
  /// **'Open App Settings'**
  String get mapButtonOpenAppSettings;

  /// Button text to re-try requesting necessary permissions for the map.
  ///
  /// In en, this message translates to:
  /// **'Retry Permissions'**
  String get mapButtonRetryPermissions;

  /// Title for the dialog confirming point deletion from the map view.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get mapDeletePointDialogTitle;

  /// Content/message of the dialog confirming point deletion, asking for user confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete point P{pointOrdinalNumber}?'**
  String mapDeletePointDialogContent(String pointOrdinalNumber);

  /// Text for the 'Cancel' button in the delete point confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get mapDeletePointDialogCancelButton;

  /// Text for the 'Delete' button in the delete point confirmation dialog (often styled differently, e.g., red).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get mapDeletePointDialogDeleteButton;

  /// Snackbar message shown when a point is successfully deleted from the map.
  ///
  /// In en, this message translates to:
  /// **'Point P{pointOrdinalNumber} deleted.'**
  String mapPointDeletedSuccessSnackbar(String pointOrdinalNumber);

  /// Snackbar message shown when an error occurs trying to delete a point from the map because it wasn't found.
  ///
  /// In en, this message translates to:
  /// **'Error: Point P{pointOrdinalNumber} could not be found or deleted from map view.'**
  String mapErrorPointNotFoundOrDeletedSnackbar(String pointOrdinalNumber);

  /// Generic snackbar message for an error occurring during point deletion from the map.
  ///
  /// In en, this message translates to:
  /// **'Error deleting point P{pointOrdinalNumber}: {errorMessage}'**
  String mapErrorDeletingPointSnackbar(
    String pointOrdinalNumber,
    String errorMessage,
  );

  /// Error message shown when trying to add a point but compass heading is not available.
  ///
  /// In en, this message translates to:
  /// **'Cannot add point: Compass heading not available.'**
  String get compassHeadingNotAvailable;

  /// Label showing the project's calculated azimuth value.
  ///
  /// In en, this message translates to:
  /// **'Project Azimuth: {azimuth}°'**
  String projectAzimuthLabel(String azimuth);

  /// Message shown when project azimuth cannot be calculated because there are not enough points.
  ///
  /// In en, this message translates to:
  /// **'Project Azimuth: (Requires at least 2 points)'**
  String get projectAzimuthRequiresPoints;

  /// Message shown when project azimuth exists but hasn't been calculated yet.
  ///
  /// In en, this message translates to:
  /// **'Project Azimuth: Not yet calculated'**
  String get projectAzimuthNotCalculated;

  /// Label for high compass accuracy indicator.
  ///
  /// In en, this message translates to:
  /// **'High Accuracy'**
  String get compassAccuracyHigh;

  /// Label for medium compass accuracy indicator.
  ///
  /// In en, this message translates to:
  /// **'Medium Accuracy'**
  String get compassAccuracyMedium;

  /// Label for low compass accuracy indicator.
  ///
  /// In en, this message translates to:
  /// **'Low Accuracy'**
  String get compassAccuracyLow;

  /// Title for the compass permissions required screen.
  ///
  /// In en, this message translates to:
  /// **'Permissions Required'**
  String get compassPermissionsRequired;

  /// Message explaining why compass permissions are needed.
  ///
  /// In en, this message translates to:
  /// **'This tool requires sensor and location permissions to function correctly. Please grant them in your device settings.'**
  String get compassPermissionsMessage;

  /// Button text to open app settings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettingsButton;

  /// Button text to retry an operation.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// Tooltip text shown when location is being acquired for floating action buttons.
  ///
  /// In en, this message translates to:
  /// **'Acquiring location...'**
  String get mapAcquiringLocation;

  /// Tooltip for the button to center the map on the user's current location.
  ///
  /// In en, this message translates to:
  /// **'Center on my location'**
  String get mapCenterOnLocation;

  /// Tooltip for the button to add a new point from the map.
  ///
  /// In en, this message translates to:
  /// **'Add New Point'**
  String get mapAddNewPoint;

  /// Tooltip for the button to center the map on all project points.
  ///
  /// In en, this message translates to:
  /// **'Center on points'**
  String get mapCenterOnPoints;

  /// Label for street map type.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get mapTypeStreet;

  /// Label for satellite map type.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get mapTypeSatellite;

  /// Label for terrain map type.
  ///
  /// In en, this message translates to:
  /// **'Terrain'**
  String get mapTypeTerrain;

  /// Label for the map type selector.
  ///
  /// In en, this message translates to:
  /// **'Map Type'**
  String get mapTypeSelector;

  /// No description provided for @must_be_positive_validator.
  ///
  /// In en, this message translates to:
  /// **'Must be positive.'**
  String get must_be_positive_validator;

  /// Label for a new unsaved point on the map.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get mapNewPointLabel;

  /// Button text to save a new point.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mapSaveNewPoint;

  /// Button text to discard a new unsaved point.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get mapDiscardNewPoint;

  /// Success message when a new point is saved.
  ///
  /// In en, this message translates to:
  /// **'New point saved successfully!'**
  String get mapNewPointSaved;

  /// Error message when saving a new point fails.
  ///
  /// In en, this message translates to:
  /// **'Error saving new point: {errorMessage}'**
  String mapErrorSavingNewPoint(String errorMessage);

  /// Message shown when trying to add a new point while one is already unsaved.
  ///
  /// In en, this message translates to:
  /// **'You have an unsaved point. Please save or discard it before adding another.'**
  String get mapUnsavedPointExists;
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
