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

  /// Tab label for project details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get tabDetails;

  /// Tab label for project points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get tabPoints;

  /// Tab label for compass view.
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get tabCompass;

  /// Tab label for map view.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tabMap;

  /// Label for the project name form field.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get formFieldNameLabel;

  /// Label for the project note form field.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get formFieldNoteLabel;

  /// Label for the azimuth form field.
  ///
  /// In en, this message translates to:
  /// **'Azimuth (°)'**
  String get formFieldAzimuthLabel;

  /// Label for the project date form field.
  ///
  /// In en, this message translates to:
  /// **'Project Date'**
  String get formFieldProjectDateLabel;

  /// Label for the last updated form field.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get formFieldLastUpdatedLabel;

  /// Label for the presumed total length form field.
  ///
  /// In en, this message translates to:
  /// **'Presumed Total Length (m)'**
  String get formFieldPresumedTotalLengthLabel;

  /// Label for the save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get buttonSave;

  /// Label for the calculate azimuth button.
  ///
  /// In en, this message translates to:
  /// **'Calculate Azimuth'**
  String get buttonCalculateAzimuth;

  /// Label for the calculate button.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get buttonCalculate;

  /// Label for the select date button.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get buttonSelectDate;

  /// Button label to add a point from the compass tool.
  ///
  /// In en, this message translates to:
  /// **'Add Point'**
  String get compassAddPointButton;

  /// Button label to add a point as the end point from the compass tool.
  ///
  /// In en, this message translates to:
  /// **'Add as End Point'**
  String get compassAddAsEndPointButton;

  /// Button label to set a point as the start point.
  ///
  /// In en, this message translates to:
  /// **'Set as Start'**
  String get pointsSetAsStartButton;

  /// Button label to set a point as the end point.
  ///
  /// In en, this message translates to:
  /// **'Set as End'**
  String get pointsSetAsEndButton;

  /// Button label to delete a point.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get pointsDeleteButton;

  /// Error message shown when trying to add points before saving the project.
  ///
  /// In en, this message translates to:
  /// **'Please save the project before adding points.'**
  String get errorSaveProjectBeforeAddingPoints;

  /// Message shown when fetching the user's location.
  ///
  /// In en, this message translates to:
  /// **'Fetching location...'**
  String get infoFetchingLocation;

  /// Snackbar message when a point is successfully added. The ordinalNumber is the point's number.
  ///
  /// In en, this message translates to:
  /// **'Point P{ordinalNumber} added.'**
  String pointAddedSnackbar(String ordinalNumber);

  /// Suffix for snackbar when a point is set as the end point.
  ///
  /// In en, this message translates to:
  /// **'Set as END point.'**
  String get pointAddedSetAsEndSnackbarSuffix;

  /// Suffix for snackbar when a point is inserted before the end point.
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

  /// Error message when azimuth calculation is attempted without start/end points.
  ///
  /// In en, this message translates to:
  /// **'Starting and/or ending point not set. Cannot calculate azimuth.'**
  String get errorAzimuthPointsNotSet;

  /// Error message when start and end points are the same for azimuth calculation.
  ///
  /// In en, this message translates to:
  /// **'Starting and ending points are the same. Azimuth is undefined or 0.'**
  String get errorAzimuthPointsSame;

  /// Error message when point data cannot be retrieved for azimuth calculation.
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

  /// Validator message for empty project name.
  ///
  /// In en, this message translates to:
  /// **'Project name cannot be empty.'**
  String get projectNameCannotBeEmptyValidator;

  /// Snackbar message when a project is saved successfully.
  ///
  /// In en, this message translates to:
  /// **'Project saved successfully.'**
  String get projectSavedSuccessfully;

  /// Title for the dialog confirming deletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get dialogTitleConfirmDelete;

  /// No description provided for @dialogContentConfirmDeletePoint.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete point P{pointOrdinal}? This action cannot be undone.'**
  String dialogContentConfirmDeletePoint(String pointOrdinal);

  /// Label for the cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// Label for the delete button.
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

  /// Snackbar message when a file is saved successfully.
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

  /// Title for the dialog shown when a licence is required for export.
  ///
  /// In en, this message translates to:
  /// **'Licence Required for Export'**
  String get export_requires_licence_title;

  /// Message shown when a licence is required for export.
  ///
  /// In en, this message translates to:
  /// **'This feature requires an active licence. Please import a valid licence file to proceed.'**
  String get export_requires_licence_message;

  /// Label for the import licence action.
  ///
  /// In en, this message translates to:
  /// **'Import Licence'**
  String get action_import_licence;

  /// Title for the edit project page.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get edit_project_title;

  /// No description provided for @edit_project_title_named.
  ///
  /// In en, this message translates to:
  /// **'Edit: {projectName}'**
  String edit_project_title_named(String projectName);

  /// Title for the new project page.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get new_project_title;

  /// Tooltip for the delete project button.
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get delete_project_tooltip;

  /// Tooltip for the save project button.
  ///
  /// In en, this message translates to:
  /// **'Save Project'**
  String get save_project_tooltip;

  /// Label for the last updated date and time in the project list card.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String last_updated_label(String date);

  /// Label shown when there is no last update for a project.
  ///
  /// In en, this message translates to:
  /// **'No updates'**
  String get no_updates;

  /// Label for projects that have not yet been saved.
  ///
  /// In en, this message translates to:
  /// **'Not yet saved'**
  String get not_yet_saved_label;

  /// Prompt to tap to set the project date.
  ///
  /// In en, this message translates to:
  /// **'Tap to set date'**
  String get tap_to_set_date;

  /// Validator message for invalid number input.
  ///
  /// In en, this message translates to:
  /// **'Invalid number.'**
  String get invalid_number_validator;

  /// Validator message for azimuth field range.
  ///
  /// In en, this message translates to:
  /// **'Must be +/-359.99'**
  String get must_be_359_validator;

  /// Message prompting user to correct form errors.
  ///
  /// In en, this message translates to:
  /// **'Please correct the errors in the form.'**
  String get please_correct_form_errors;

  /// Snackbar message when a project is created successfully.
  ///
  /// In en, this message translates to:
  /// **'Project created successfully!'**
  String get project_created_successfully;

  /// Message when a project is already up to date.
  ///
  /// In en, this message translates to:
  /// **'Project already up to date or not found.'**
  String get project_already_up_to_date;

  /// Error message when trying to delete an unsaved project.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete a project that has not been saved yet.'**
  String get cannot_delete_unsaved_project;

  /// No description provided for @confirm_delete_project_title.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirm_delete_project_title;

  /// Content for the dialog confirming project deletion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the project \"{projectName}\"? This action cannot be undone.'**
  String confirm_delete_project_content(String projectName);

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

  /// Tooltip for the compass direction arrow on the map.
  ///
  /// In en, this message translates to:
  /// **'Compass Direction'**
  String get mapCompassDirectionTooltip;

  /// Label for the north indicator on the compass arrow.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get mapCompassNorthIndicator;

  /// No description provided for @errorLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable.'**
  String get errorLocationUnavailable;

  /// No description provided for @infoPointAddedPendingSave.
  ///
  /// In en, this message translates to:
  /// **'Point added (pending save)'**
  String get infoPointAddedPendingSave;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorGeneric;

  /// No description provided for @edit_point_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Point'**
  String get edit_point_title;

  /// No description provided for @coordinates_section_title.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates_section_title;

  /// No description provided for @latitude_label.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude_label;

  /// No description provided for @latitude_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 45.12345'**
  String get latitude_hint;

  /// No description provided for @latitude_empty_validator.
  ///
  /// In en, this message translates to:
  /// **'Latitude cannot be empty'**
  String get latitude_empty_validator;

  /// No description provided for @latitude_invalid_validator.
  ///
  /// In en, this message translates to:
  /// **'Invalid number format'**
  String get latitude_invalid_validator;

  /// No description provided for @latitude_range_validator.
  ///
  /// In en, this message translates to:
  /// **'Latitude must be between -90 and 90'**
  String get latitude_range_validator;

  /// No description provided for @longitude_label.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude_label;

  /// No description provided for @longitude_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. -12.54321'**
  String get longitude_hint;

  /// No description provided for @longitude_empty_validator.
  ///
  /// In en, this message translates to:
  /// **'Longitude cannot be empty'**
  String get longitude_empty_validator;

  /// No description provided for @longitude_invalid_validator.
  ///
  /// In en, this message translates to:
  /// **'Invalid number format'**
  String get longitude_invalid_validator;

  /// No description provided for @longitude_range_validator.
  ///
  /// In en, this message translates to:
  /// **'Longitude must be between -180 and 180'**
  String get longitude_range_validator;

  /// No description provided for @additional_data_section_title.
  ///
  /// In en, this message translates to:
  /// **'Additional Data'**
  String get additional_data_section_title;

  /// No description provided for @altitude_label.
  ///
  /// In en, this message translates to:
  /// **'Altitude (m)'**
  String get altitude_label;

  /// No description provided for @altitude_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1203.5 (Optional)'**
  String get altitude_hint;

  /// No description provided for @altitude_invalid_validator.
  ///
  /// In en, this message translates to:
  /// **'Invalid number format'**
  String get altitude_invalid_validator;

  /// No description provided for @altitude_range_validator.
  ///
  /// In en, this message translates to:
  /// **'Altitude must be between -1000 and 8849 meters'**
  String get altitude_range_validator;

  /// No description provided for @note_label.
  ///
  /// In en, this message translates to:
  /// **'Note (Optional)'**
  String get note_label;

  /// No description provided for @note_hint.
  ///
  /// In en, this message translates to:
  /// **'Any observations or details...'**
  String get note_hint;

  /// No description provided for @photos_section_title.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos_section_title;

  /// No description provided for @unsaved_point_details_title.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsaved_point_details_title;

  /// No description provided for @unsaved_point_details_content.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes to point details. Save them?'**
  String get unsaved_point_details_content;

  /// No description provided for @discard_text_changes.
  ///
  /// In en, this message translates to:
  /// **'Discard Text Changes'**
  String get discard_text_changes;

  /// No description provided for @save_all_and_exit.
  ///
  /// In en, this message translates to:
  /// **'Save All & Exit'**
  String get save_all_and_exit;

  /// No description provided for @confirm_deletion_title.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirm_deletion_title;

  /// Dialog content asking for confirmation to delete a point.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete point {pointName}? This action cannot be undone.'**
  String confirm_deletion_content(String pointName);

  /// Snackbar message when a point is deleted successfully.
  ///
  /// In en, this message translates to:
  /// **'Point {pointName} deleted successfully!'**
  String point_deleted_success(String pointName);

  /// Error message when deleting a point fails.
  ///
  /// In en, this message translates to:
  /// **'Error deleting point {pointName}: {errorMessage}'**
  String error_deleting_point(String pointName, String errorMessage);

  /// Error message when saving a point fails.
  ///
  /// In en, this message translates to:
  /// **'Error saving point: {errorMessage}'**
  String error_saving_point(String errorMessage);

  /// No description provided for @point_details_saved.
  ///
  /// In en, this message translates to:
  /// **'Point details saved!'**
  String get point_details_saved;

  /// No description provided for @undo_changes_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Undo Changes'**
  String get undo_changes_tooltip;

  /// No description provided for @no_projects_yet.
  ///
  /// In en, this message translates to:
  /// **'No projects yet. Tap \'+\' to add one!'**
  String get no_projects_yet;

  /// No description provided for @add_new_project_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Add New Project'**
  String get add_new_project_tooltip;

  /// No description provided for @untitled_project.
  ///
  /// In en, this message translates to:
  /// **'Untitled Project'**
  String get untitled_project;

  /// No description provided for @delete_selected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get delete_selected;

  /// Label showing the number of selected items.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selected_count(int count);

  /// No description provided for @delete_projects_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Project(s)?'**
  String get delete_projects_title;

  /// Content for the dialog confirming deletion of multiple projects.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected project(s)? This action cannot be undone.'**
  String delete_projects_content(int count);

  /// Label showing the project ID and last update text.
  ///
  /// In en, this message translates to:
  /// **'ID: {id} | {lastUpdateText}'**
  String project_id_label(String id, String lastUpdateText);

  /// No description provided for @license_information_title.
  ///
  /// In en, this message translates to:
  /// **'Licence Information'**
  String get license_information_title;

  /// No description provided for @close_button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close_button;

  /// No description provided for @import_new_licence.
  ///
  /// In en, this message translates to:
  /// **'Import New Licence'**
  String get import_new_licence;

  /// No description provided for @import_licence.
  ///
  /// In en, this message translates to:
  /// **'Import Licence'**
  String get import_licence;

  /// No description provided for @premium_features_title.
  ///
  /// In en, this message translates to:
  /// **'Premium Features'**
  String get premium_features_title;

  /// No description provided for @premium_features_available.
  ///
  /// In en, this message translates to:
  /// **'Premium features are available in this build!'**
  String get premium_features_available;

  /// No description provided for @available_features.
  ///
  /// In en, this message translates to:
  /// **'Available Features:'**
  String get available_features;

  /// No description provided for @premium_features_not_available.
  ///
  /// In en, this message translates to:
  /// **'Premium features are not available in this build.'**
  String get premium_features_not_available;

  /// No description provided for @opensource_version.
  ///
  /// In en, this message translates to:
  /// **'This is the opensource version of the app.'**
  String get opensource_version;

  /// No description provided for @try_feature.
  ///
  /// In en, this message translates to:
  /// **'Try Feature'**
  String get try_feature;

  /// No description provided for @install_demo_license.
  ///
  /// In en, this message translates to:
  /// **'Install Demo License'**
  String get install_demo_license;

  /// No description provided for @clear_license.
  ///
  /// In en, this message translates to:
  /// **'Clear License'**
  String get clear_license;

  /// No description provided for @invalid_latitude_or_longitude_format.
  ///
  /// In en, this message translates to:
  /// **'Invalid latitude or longitude format.'**
  String get invalid_latitude_or_longitude_format;

  /// No description provided for @invalid_altitude_format.
  ///
  /// In en, this message translates to:
  /// **'Invalid altitude format. Please enter a number or leave it empty.'**
  String get invalid_altitude_format;

  /// No description provided for @coordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// No description provided for @lat.
  ///
  /// In en, this message translates to:
  /// **'Lat:'**
  String get lat;

  /// No description provided for @lon.
  ///
  /// In en, this message translates to:
  /// **'Lon:'**
  String get lon;

  /// No description provided for @addANote.
  ///
  /// In en, this message translates to:
  /// **'Add a note...'**
  String get addANote;

  /// No description provided for @tapToAddNote.
  ///
  /// In en, this message translates to:
  /// **'Tap to add note...'**
  String get tapToAddNote;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @tapOnTheMapToSetNewLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to set new location'**
  String get tapOnTheMapToSetNewLocation;

  /// Label for the heading angle marker on the map.
  ///
  /// In en, this message translates to:
  /// **'{angle}°'**
  String headingLabel(String angle);

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Permission'**
  String get locationPermissionTitle;

  /// No description provided for @sensorPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sensor Permission'**
  String get sensorPermissionTitle;

  /// No description provided for @noNote.
  ///
  /// In en, this message translates to:
  /// **'No note'**
  String get noNote;

  /// Label for the distance from the previous point in the point details panel.
  ///
  /// In en, this message translates to:
  /// **'Distance from {pointName}:'**
  String distanceFromPrevious(String pointName);

  /// Label for the offset (distance from point to first-last line) in point details and point list UI.
  ///
  /// In en, this message translates to:
  /// **'Offset:'**
  String get offsetLabel;

  /// Title for the dialog to confirm photo deletion.
  ///
  /// In en, this message translates to:
  /// **'Delete Photo?'**
  String get delete_photo_title;

  /// Content for the dialog to confirm photo deletion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete photo {photoNumber}?'**
  String delete_photo_content(String photoNumber);

  /// Title for camera permission request.
  ///
  /// In en, this message translates to:
  /// **'Camera Permission'**
  String get camera_permission_title;

  /// Description for camera permission request.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is needed to take photos.'**
  String get camera_permission_description;

  /// Title for microphone permission request.
  ///
  /// In en, this message translates to:
  /// **'Microphone Permission'**
  String get microphone_permission_title;

  /// Description for microphone permission request.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is needed to record audio.'**
  String get microphone_permission_description;

  /// Title for storage permission request.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission'**
  String get storage_permission_title;

  /// Description for storage permission request.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is needed to save files.'**
  String get storage_permission_description;

  /// Label for the current rope length statistic.
  ///
  /// In en, this message translates to:
  /// **'Current Rope Length'**
  String get current_rope_length_label;

  /// Abbreviation for meters.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get unit_meter;

  /// Abbreviation for kilometers.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unit_kilometer;

  /// Snackbar message when a point is deleted but not yet saved.
  ///
  /// In en, this message translates to:
  /// **'Point {pointName} deleted (pending save).'**
  String point_deleted_pending_save(String pointName);

  /// Error message when deleting a point fails.
  ///
  /// In en, this message translates to:
  /// **'Error deleting point {pointName}: {errorMessage}'**
  String error_deleting_point_generic(String pointName, String errorMessage);

  /// Notice to the user to calibrate the compass sensor.
  ///
  /// In en, this message translates to:
  /// **'Compass sensor needs calibration. Please move your device in a figure-8 motion.'**
  String get compass_calibration_notice;

  /// Title for the project statistics section in the project details tab.
  ///
  /// In en, this message translates to:
  /// **'Project Statistics'**
  String get project_statistics_title;

  /// Label for the number of points in the project statistics section.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get project_statistics_points;

  /// Label for the number of images in the project statistics section.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get project_statistics_images;

  /// Label for the current length in the project statistics section.
  ///
  /// In en, this message translates to:
  /// **'Current Length'**
  String get project_statistics_current_length;

  /// Label for the measurements section in the project details tab.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get project_statistics_measurements;

  /// Title for the points list section in PointsToolView.
  ///
  /// In en, this message translates to:
  /// **'Points List'**
  String get points_list_title;

  /// Title for the photo manager section, shown above the photo list.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photo_manager_title;

  /// Message shown when there are no photos in the photo manager.
  ///
  /// In en, this message translates to:
  /// **'No photos yet.'**
  String get photo_manager_no_photos;

  /// Label for the gallery option in the add photo menu.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get photo_manager_gallery;

  /// Label for the camera option in the add photo menu.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get photo_manager_camera;

  /// Tooltip for the add photo button.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get photo_manager_add_photo_tooltip;

  /// Snackbar message when a photo is deleted.
  ///
  /// In en, this message translates to:
  /// **'Photo deleted'**
  String get photo_manager_photo_deleted;

  /// Snackbar message when photo changes are auto-saved.
  ///
  /// In en, this message translates to:
  /// **'Photo changes saved automatically.'**
  String get photo_manager_photo_changes_saved;

  /// Error message when saving photo changes fails.
  ///
  /// In en, this message translates to:
  /// **'Error saving photo changes: {errorMessage}'**
  String photo_manager_error_saving_photo_changes(String errorMessage);

  /// Error message when saving an image fails.
  ///
  /// In en, this message translates to:
  /// **'Error saving image: {errorMessage}'**
  String photo_manager_error_saving_image(String errorMessage);

  /// Error message when picking an image fails.
  ///
  /// In en, this message translates to:
  /// **'Error picking image: {errorMessage}'**
  String photo_manager_error_picking_image(String errorMessage);

  /// Error message when deleting a photo fails.
  ///
  /// In en, this message translates to:
  /// **'Error deleting photo: {errorMessage}'**
  String photo_manager_error_deleting_photo(String errorMessage);

  /// Snackbar message shown when photos are being saved and user tries to interact.
  ///
  /// In en, this message translates to:
  /// **'Please wait, photos are being saved...'**
  String get photo_manager_wait_saving;

  /// Label for displaying the app version in dialogs.
  ///
  /// In en, this message translates to:
  /// **'App Version: {version}'**
  String app_version_label(String version);

  /// Content for active licence info dialog.
  ///
  /// In en, this message translates to:
  /// **'Licensed to: {email}\nStatus: Active\nValid Until: {validUntil}'**
  String licence_active_content(String email, String validUntil);

  /// Content for expired licence info dialog.
  ///
  /// In en, this message translates to:
  /// **'Licensed to: {email}\nStatus: Expired\nValid Until: {validUntil}\n\nPlease import a valid licence.'**
  String licence_expired_content(String email, String validUntil);

  /// Content for no licence found in info dialog.
  ///
  /// In en, this message translates to:
  /// **'No active licence found. Please import a licence file to unlock premium features.'**
  String get licence_none_content;

  /// Status line for licence status.
  ///
  /// In en, this message translates to:
  /// **'Licence Status: {status}'**
  String licence_status(String status);

  /// Error message for failed feature demo.
  ///
  /// In en, this message translates to:
  /// **'Feature demonstration failed: {error}'**
  String feature_demo_failed(String error);

  /// Snackbar for successful licence import.
  ///
  /// In en, this message translates to:
  /// **'Licence for {email} imported successfully!'**
  String licence_imported_successfully(String email);

  /// Snackbar for cancelled or failed licence import.
  ///
  /// In en, this message translates to:
  /// **'Licence import cancelled or failed.'**
  String get licence_import_cancelled;

  /// Snackbar for successful demo license import.
  ///
  /// In en, this message translates to:
  /// **'Demo license imported successfully!'**
  String get demo_license_imported_successfully;

  /// Snackbar for successful license clear action.
  ///
  /// In en, this message translates to:
  /// **'License cleared successfully!'**
  String get license_cleared_successfully;
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
