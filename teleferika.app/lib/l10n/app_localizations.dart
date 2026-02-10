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

  /// Label for the cable or equipment type form field (project-level preset).
  ///
  /// In en, this message translates to:
  /// **'Cable / equipment type'**
  String get formFieldCableEquipmentTypeLabel;

  /// Dropdown option when no cable/equipment type is selected.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get cableEquipmentTypeNotSet;

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

  /// Error message when map download is attempted without a valid licence.
  ///
  /// In en, this message translates to:
  /// **'Valid licence required for map download'**
  String get mapDownloadRequiresValidLicence;

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
  /// **'Updated: {date}'**
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

  /// Title for the dialog confirming project deletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirm_delete_project_title;

  /// Content for the dialog confirming project deletion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the project \"{projectName}\"? This action cannot be undone.'**
  String confirm_delete_project_content(String projectName);

  /// Snackbar message when a project is deleted successfully.
  ///
  /// In en, this message translates to:
  /// **'Project deleted successfully.'**
  String get project_deleted_successfully;

  /// Message when a project is not found or already deleted.
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

  /// Title for the dialog warning about unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsaved_changes_dialog_title;

  /// Content for the dialog warning about unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them and leave?'**
  String get unsaved_changes_dialog_content;

  /// Label for the discard button in dialogs.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard_button_label;

  /// Tab label for project details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details_tab_label;

  /// Tab label for project points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points_tab_label;

  /// Tab label for compass view.
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get compass_tab_label;

  /// Tab label for map view.
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

  /// Localized name for map types based on the mapType parameter.
  ///
  /// In en, this message translates to:
  /// **'{mapType}'**
  String mapTypeName(String mapType);

  /// Label for the map type selector.
  ///
  /// In en, this message translates to:
  /// **'Map Type'**
  String get mapTypeSelector;

  /// Validator message for positive number input.
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

  /// Error message when location is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable.'**
  String get errorLocationUnavailable;

  /// Info message when a point is added but not yet saved.
  ///
  /// In en, this message translates to:
  /// **'Point added (pending save)'**
  String get infoPointAddedPendingSave;

  /// Generic error message.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorGeneric;

  /// Title for the edit point page.
  ///
  /// In en, this message translates to:
  /// **'Edit Point'**
  String get edit_point_title;

  /// Section title for coordinates in point details.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates_section_title;

  /// Label for latitude field.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude_label;

  /// Hint for latitude input field.
  ///
  /// In en, this message translates to:
  /// **'e.g. 45.12345'**
  String get latitude_hint;

  /// Validator message for empty latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude cannot be empty'**
  String get latitude_empty_validator;

  /// Validator message for invalid latitude format.
  ///
  /// In en, this message translates to:
  /// **'Invalid number format'**
  String get latitude_invalid_validator;

  /// Validator message for latitude out of range.
  ///
  /// In en, this message translates to:
  /// **'Latitude must be between -90 and 90'**
  String get latitude_range_validator;

  /// Label for longitude field.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude_label;

  /// Hint for longitude input field.
  ///
  /// In en, this message translates to:
  /// **'e.g. -12.54321'**
  String get longitude_hint;

  /// Validator message for empty longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude cannot be empty'**
  String get longitude_empty_validator;

  /// Validator message for invalid longitude format.
  ///
  /// In en, this message translates to:
  /// **'Invalid number format'**
  String get longitude_invalid_validator;

  /// Validator message for longitude out of range.
  ///
  /// In en, this message translates to:
  /// **'Longitude must be between -180 and 180'**
  String get longitude_range_validator;

  /// Section title for additional data in point details.
  ///
  /// In en, this message translates to:
  /// **'Additional Data'**
  String get additional_data_section_title;

  /// Label for altitude field.
  ///
  /// In en, this message translates to:
  /// **'Altitude (m)'**
  String get altitude_label;

  /// Hint for altitude input field.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1203.5 (Optional)'**
  String get altitude_hint;

  /// Validator message for invalid altitude format.
  ///
  /// In en, this message translates to:
  /// **'Invalid number format'**
  String get altitude_invalid_validator;

  /// Validator message for altitude out of range.
  ///
  /// In en, this message translates to:
  /// **'Altitude must be between -1000 and 8849 meters'**
  String get altitude_range_validator;

  /// Label for note field.
  ///
  /// In en, this message translates to:
  /// **'Note (Optional)'**
  String get note_label;

  /// Hint for note input field.
  ///
  /// In en, this message translates to:
  /// **'Any observations or details...'**
  String get note_hint;

  /// Section title for photos in point details.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos_section_title;

  /// Title for unsaved changes dialog in point details.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsaved_point_details_title;

  /// Content for unsaved changes dialog in point details.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes to point details. Save them?'**
  String get unsaved_point_details_content;

  /// Label for discard text changes button.
  ///
  /// In en, this message translates to:
  /// **'Discard Text Changes'**
  String get discard_text_changes;

  /// Label for save all and exit button.
  ///
  /// In en, this message translates to:
  /// **'Save All & Exit'**
  String get save_all_and_exit;

  /// Title for the dialog confirming point deletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirm_deletion_title;

  /// Snackbar message when point details are saved.
  ///
  /// In en, this message translates to:
  /// **'Point details saved!'**
  String get point_details_saved;

  /// Tooltip for undo changes button.
  ///
  /// In en, this message translates to:
  /// **'Undo Changes'**
  String get undo_changes_tooltip;

  /// Message shown when there are no projects yet.
  ///
  /// In en, this message translates to:
  /// **'No projects yet. Tap \'+\' to add one!'**
  String get no_projects_yet;

  /// Tooltip for add new project button.
  ///
  /// In en, this message translates to:
  /// **'Add New Project'**
  String get add_new_project_tooltip;

  /// Label for untitled project.
  ///
  /// In en, this message translates to:
  /// **'Untitled Project'**
  String get untitled_project;

  /// Label for delete selected button.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get delete_selected;

  /// Title for the dialog confirming deletion of multiple projects.
  ///
  /// In en, this message translates to:
  /// **'Delete Project(s)?'**
  String get delete_projects_title;

  /// Title for the licence information dialog.
  ///
  /// In en, this message translates to:
  /// **'Licence Information'**
  String get license_information_title;

  /// Label for close button in dialogs.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close_button;

  /// Label for import new licence button.
  ///
  /// In en, this message translates to:
  /// **'Import New Licence'**
  String get import_new_licence;

  /// Label for import licence button.
  ///
  /// In en, this message translates to:
  /// **'Import Licence'**
  String get import_licence;

  /// Label for request new license button.
  ///
  /// In en, this message translates to:
  /// **'Request New License'**
  String get request_new_license;

  /// Title for premium features section.
  ///
  /// In en, this message translates to:
  /// **'Premium Features'**
  String get premium_features_title;

  /// Message when premium features are available.
  ///
  /// In en, this message translates to:
  /// **'Premium features are available in this build!'**
  String get premium_features_available;

  /// Label for available features list.
  ///
  /// In en, this message translates to:
  /// **'Available Features:'**
  String get available_features;

  /// Message when premium features are not available.
  ///
  /// In en, this message translates to:
  /// **'Premium features are not available in this build.'**
  String get premium_features_not_available;

  /// Message for opensource version of the app.
  ///
  /// In en, this message translates to:
  /// **'This is the opensource version of the app.'**
  String get opensource_version;

  /// Label for try feature button.
  ///
  /// In en, this message translates to:
  /// **'Try Feature'**
  String get try_feature;

  /// Label for install demo license button.
  ///
  /// In en, this message translates to:
  /// **'Install Demo License'**
  String get install_demo_license;

  /// Label for clear license button.
  ///
  /// In en, this message translates to:
  /// **'Clear License'**
  String get clear_license;

  /// Error message for invalid latitude or longitude format.
  ///
  /// In en, this message translates to:
  /// **'Invalid latitude or longitude format.'**
  String get invalid_latitude_or_longitude_format;

  /// Error message for invalid altitude format.
  ///
  /// In en, this message translates to:
  /// **'Invalid altitude format. Please enter a number or leave it empty.'**
  String get invalid_altitude_format;

  /// Label for coordinates section.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// Label for latitude abbreviation.
  ///
  /// In en, this message translates to:
  /// **'Lat:'**
  String get lat;

  /// Label for longitude abbreviation.
  ///
  /// In en, this message translates to:
  /// **'Lon:'**
  String get lon;

  /// Prompt to add a note.
  ///
  /// In en, this message translates to:
  /// **'Add a note...'**
  String get addANote;

  /// Prompt to tap to add a note.
  ///
  /// In en, this message translates to:
  /// **'Tap to add note...'**
  String get tapToAddNote;

  /// Label for save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Label for discard button.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Label for edit button.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Label for move button.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// Label for cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Label for delete button.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Prompt to tap on the map to set a new location.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to set new location'**
  String get tapOnTheMapToSetNewLocation;

  /// Title for location permission dialog.
  ///
  /// In en, this message translates to:
  /// **'Location Permission'**
  String get locationPermissionTitle;

  /// Title for sensor permission dialog.
  ///
  /// In en, this message translates to:
  /// **'Sensor Permission'**
  String get sensorPermissionTitle;

  /// Label for no note present.
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

  /// Label for the angle at a point between two connecting polylines in point details panel.
  ///
  /// In en, this message translates to:
  /// **'Angle:'**
  String get angleLabel;

  /// Title for the dialog to confirm photo deletion.
  ///
  /// In en, this message translates to:
  /// **'Delete Photo?'**
  String get delete_photo_title;

  /// Content for the dialog to confirm photo deletion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {photoNumber} photo(s)?'**
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
  /// **'{platform, select, android{Gallery} ios{Photos} other{Gallery}}'**
  String photo_manager_gallery(String platform);

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

  /// Label showing the number of selected items.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selected_count(int count);

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

  /// Label for the heading angle marker on the map.
  ///
  /// In en, this message translates to:
  /// **'{angle}°'**
  String headingLabel(String angle);

  /// Prefix for project name labels on the map.
  ///
  /// In en, this message translates to:
  /// **'Project: '**
  String get project_label_prefix;

  /// Label for GPS precision (accuracy) in meters.
  ///
  /// In en, this message translates to:
  /// **'GPS Precision:'**
  String get gpsPrecisionLabel;

  /// Section title for the point details (coordinates, altitude, note) in the point editor.
  ///
  /// In en, this message translates to:
  /// **'Point Details'**
  String get pointDetailsSectionTitle;

  /// Message shown when trying to clear a license but none is installed.
  ///
  /// In en, this message translates to:
  /// **'No license installed to clear.'**
  String get no_license_to_clear;

  /// Title for enhanced licence test results dialog.
  ///
  /// In en, this message translates to:
  /// **'Enhanced Licence Test Results'**
  String get enhanced_licence_test_results;

  /// Label for email field.
  ///
  /// In en, this message translates to:
  /// **'Email:'**
  String get email_label;

  /// Label for valid until field.
  ///
  /// In en, this message translates to:
  /// **'Valid Until:'**
  String get valid_until_label;

  /// Label for features field.
  ///
  /// In en, this message translates to:
  /// **'Features:'**
  String get features_label;

  /// Label for algorithm field.
  ///
  /// In en, this message translates to:
  /// **'Algorithm:'**
  String get algorithm_label;

  /// Label for export feature status.
  ///
  /// In en, this message translates to:
  /// **'Has Export Feature:'**
  String get has_export_feature_label;

  /// Label for validity status.
  ///
  /// In en, this message translates to:
  /// **'Is Valid:'**
  String get is_valid_label;

  /// Title for device fingerprint dialog.
  ///
  /// In en, this message translates to:
  /// **'Device Fingerprint'**
  String get device_fingerprint_title;

  /// Label for fingerprint field.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint:'**
  String get fingerprint_label;

  /// Label for device info section.
  ///
  /// In en, this message translates to:
  /// **'Device Info:'**
  String get device_info_label;

  /// Label for copy button.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy_button;

  /// Label for license status.
  ///
  /// In en, this message translates to:
  /// **'License Status'**
  String get license_status_label;

  /// Label for test enhanced licence button.
  ///
  /// In en, this message translates to:
  /// **'Test Enhanced Licence'**
  String get test_enhanced_licence;

  /// Label for generate device fingerprint button.
  ///
  /// In en, this message translates to:
  /// **'Generate Device Fingerprint'**
  String get generate_device_fingerprint;

  /// Label for test licence validation button.
  ///
  /// In en, this message translates to:
  /// **'Test Licence Validation'**
  String get test_licence_validation;

  /// Error message when importing licence fails.
  ///
  /// In en, this message translates to:
  /// **'Error importing licence: {error}'**
  String error_importing_licence(String error);

  /// Error message when importing demo license fails.
  ///
  /// In en, this message translates to:
  /// **'Error importing demo license: {error}'**
  String error_importing_demo_license(String error);

  /// Error message when clearing license fails.
  ///
  /// In en, this message translates to:
  /// **'Error clearing license: {error}'**
  String error_clearing_license(String error);

  /// Error message when saving enhanced licence fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to save enhanced licence'**
  String get failed_to_save_enhanced_licence;

  /// Error message when enhanced licence test fails.
  ///
  /// In en, this message translates to:
  /// **'Enhanced licence test failed: {error}'**
  String enhanced_licence_test_failed(String error);

  /// Success message when fingerprint is copied to clipboard.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint copied to clipboard'**
  String get fingerprint_copied_to_clipboard;

  /// Error message when generating fingerprint fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate fingerprint: {error}'**
  String failed_to_generate_fingerprint(String error);

  /// Error message when invalid licence is incorrectly accepted.
  ///
  /// In en, this message translates to:
  /// **'Invalid licence was accepted - this is wrong!'**
  String get invalid_licence_accepted_error;

  /// Info message when invalid licence is correctly rejected.
  ///
  /// In en, this message translates to:
  /// **'Invalid licence correctly rejected: {code}'**
  String invalid_licence_correctly_rejected(String code);

  /// Generic error message for unexpected errors.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String unexpected_error(String error);

  /// Error message when validation test fails.
  ///
  /// In en, this message translates to:
  /// **'Validation test failed: {error}'**
  String validation_test_failed(String error);

  /// Label for refresh status button.
  ///
  /// In en, this message translates to:
  /// **'Refresh Status'**
  String get refresh_status;

  /// Title for request license dialog.
  ///
  /// In en, this message translates to:
  /// **'Request License'**
  String get request_license;

  /// Label for cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel_button;

  /// Label for request button.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request_button;

  /// Status label for requested license.
  ///
  /// In en, this message translates to:
  /// **'License Requested'**
  String get license_requested;

  /// Status label for expired license.
  ///
  /// In en, this message translates to:
  /// **'License Expired'**
  String get license_expired;

  /// Status label for license expiring soon.
  ///
  /// In en, this message translates to:
  /// **'License Expiring Soon'**
  String get license_expiring_soon;

  /// Status label for active license.
  ///
  /// In en, this message translates to:
  /// **'License Active'**
  String get license_active;

  /// Message shown when license request is pending approval.
  ///
  /// In en, this message translates to:
  /// **'Your license request is pending approval. You will be notified when it is approved or denied.'**
  String get license_pending_approval_message;

  /// Message shown when license has expired.
  ///
  /// In en, this message translates to:
  /// **'This license has expired and needs to be renewed. You can request a new license or import an existing one.'**
  String get license_expired_message;

  /// Message shown when license is expiring soon.
  ///
  /// In en, this message translates to:
  /// **'This license will expire soon. Consider requesting a new license or importing an existing one.'**
  String get license_expiring_soon_message;

  /// Section title for license details.
  ///
  /// In en, this message translates to:
  /// **'License Details'**
  String get license_details;

  /// Label for issued date.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get issued_label;

  /// Label for maximum devices.
  ///
  /// In en, this message translates to:
  /// **'Max Devices'**
  String get max_devices_label;

  /// Label for version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version_label;

  /// Label for requested features.
  ///
  /// In en, this message translates to:
  /// **'Requested Features'**
  String get requested_features;

  /// Section title for technical details.
  ///
  /// In en, this message translates to:
  /// **'Technical Details'**
  String get technical_details;

  /// Label for data hash.
  ///
  /// In en, this message translates to:
  /// **'Data Hash'**
  String get data_hash;

  /// Message when no license is found.
  ///
  /// In en, this message translates to:
  /// **'No License Found'**
  String get no_license_found;

  /// Message when no active license is found.
  ///
  /// In en, this message translates to:
  /// **'No active license found. You can import an existing license file or request a new license from the server.'**
  String get no_active_license_message;

  /// Message when project is deleted.
  ///
  /// In en, this message translates to:
  /// **'Project deleted.'**
  String get project_deleted;

  /// Label for status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status_label;

  /// Label for days remaining.
  ///
  /// In en, this message translates to:
  /// **'Days Remaining'**
  String get days_remaining_label;

  /// Message about features pending approval.
  ///
  /// In en, this message translates to:
  /// **'Features will be available once your license is approved:'**
  String get features_pending_approval;

  /// Label for device fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Device Fingerprint'**
  String get device_fingerprint;

  /// Section title for app information.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get app_information;

  /// Label for requested features list.
  ///
  /// In en, this message translates to:
  /// **'Requested Features:'**
  String get requested_features_label;

  /// Label for basic export feature.
  ///
  /// In en, this message translates to:
  /// **'Basic Export'**
  String get basic_export;

  /// Label for map download feature.
  ///
  /// In en, this message translates to:
  /// **'Map Download'**
  String get map_download;

  /// Label for advanced export feature.
  ///
  /// In en, this message translates to:
  /// **'Advanced Export'**
  String get advanced_export;

  /// Validation message when email is required.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get email_required;

  /// Validation message when at least one feature must be selected.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one feature'**
  String get select_at_least_one_feature;

  /// Example email placeholder.
  ///
  /// In en, this message translates to:
  /// **'your.email@example.com'**
  String get your_email_example;

  /// Hint text for max devices field.
  ///
  /// In en, this message translates to:
  /// **'1-5'**
  String get max_devices_hint;

  /// Suffix for days count.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days_suffix;

  /// Tooltip for download offline maps button.
  ///
  /// In en, this message translates to:
  /// **'Download Offline Maps'**
  String get download_offline_maps_tooltip;

  /// Success message when license is imported.
  ///
  /// In en, this message translates to:
  /// **'Licence for {email} imported successfully!'**
  String license_imported_successfully(String email);

  /// Message when license import is cancelled or fails.
  ///
  /// In en, this message translates to:
  /// **'Licence import cancelled or failed.'**
  String get license_import_cancelled;

  /// Error message when importing license fails.
  ///
  /// In en, this message translates to:
  /// **'Error importing licence: {error}'**
  String error_importing_license(String error);

  /// Message when project is deleted.
  ///
  /// In en, this message translates to:
  /// **'Project deleted.'**
  String get project_deleted_message;

  /// Label for install development license button.
  ///
  /// In en, this message translates to:
  /// **'Install Development License'**
  String get install_development_license;

  /// Label for development and testing section.
  ///
  /// In en, this message translates to:
  /// **'Development & Testing'**
  String get development_testing;

  /// Title for the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// Button text to reset settings to default values.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get reset_to_defaults;

  /// Section title for UI behavior settings.
  ///
  /// In en, this message translates to:
  /// **'UI Behavior'**
  String get ui_behavior_section;

  /// Title for the show save icon always setting.
  ///
  /// In en, this message translates to:
  /// **'Always Show Save Icon'**
  String get show_save_icon_always_title;

  /// Description for the show save icon always setting.
  ///
  /// In en, this message translates to:
  /// **'When enabled, the save icon is always visible. When disabled, it only appears when there are unsaved changes.'**
  String get show_save_icon_always_description;

  /// Section title for map and compass settings.
  ///
  /// In en, this message translates to:
  /// **'Map & Compass'**
  String get map_compass_section;

  /// Title for the angle to red threshold setting.
  ///
  /// In en, this message translates to:
  /// **'Angle to Red Threshold'**
  String get angle_to_red_threshold_title;

  /// Description for the angle to red threshold setting.
  ///
  /// In en, this message translates to:
  /// **'The angle threshold (in degrees) at which the compass angle indicator changes from green to red. Lower values make the indicator more sensitive.'**
  String get angle_to_red_threshold_description;

  /// Label for threshold input field in degrees.
  ///
  /// In en, this message translates to:
  /// **'Threshold (degrees)'**
  String get threshold_degrees;

  /// Legend explaining the color coding for angle thresholds.
  ///
  /// In en, this message translates to:
  /// **'Green: Good angle | Red: Poor angle'**
  String get angle_threshold_legend;

  /// Section title for information section.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information_section;

  /// Title for the settings information section.
  ///
  /// In en, this message translates to:
  /// **'About Settings'**
  String get settings_info_title;

  /// Description explaining how settings work.
  ///
  /// In en, this message translates to:
  /// **'These settings are stored locally on your device and will persist between app sessions. Changes take effect immediately.'**
  String get settings_info_description;

  /// Success message when settings are saved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settings_saved_successfully;

  /// Error message when saving settings fails.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings: {error}'**
  String error_saving_settings(String error);

  /// Success message when settings are reset to defaults.
  ///
  /// In en, this message translates to:
  /// **'Settings reset to defaults'**
  String get settings_reset_to_defaults;

  /// Error message when resetting settings fails.
  ///
  /// In en, this message translates to:
  /// **'Error resetting settings: {error}'**
  String error_resetting_settings(String error);

  /// Section title for map display settings.
  ///
  /// In en, this message translates to:
  /// **'Map Display'**
  String get map_display_section;

  /// Title for the show all projects on map setting.
  ///
  /// In en, this message translates to:
  /// **'Show All Projects on Map'**
  String get show_all_projects_on_map_title;

  /// Description for the show all projects on map setting.
  ///
  /// In en, this message translates to:
  /// **'When enabled, all projects will be displayed on the map as grey markers and lines. When disabled, only the current project is shown.'**
  String get show_all_projects_on_map_description;

  /// Title for the show BLE satellite button setting.
  ///
  /// In en, this message translates to:
  /// **'Show RTK Device Button'**
  String get show_ble_satellite_button_title;

  /// Description for the show BLE satellite button setting.
  ///
  /// In en, this message translates to:
  /// **'When enabled, a satellite button appears on the map when connected to an RTK device. Tap it to view device information.'**
  String get show_ble_satellite_button_description;

  /// Title for the RTK devices screen.
  ///
  /// In en, this message translates to:
  /// **'RTK Devices'**
  String get bleScreenTitle;

  /// Button label to start BLE scanning.
  ///
  /// In en, this message translates to:
  /// **'Start Scan'**
  String get bleButtonStartScan;

  /// Button label to stop BLE scanning.
  ///
  /// In en, this message translates to:
  /// **'Stop Scan'**
  String get bleButtonStopScan;

  /// Button label to connect to a BLE device.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get bleButtonConnect;

  /// Button label to disconnect from a BLE device.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get bleButtonDisconnect;

  /// Button label to request larger MTU.
  ///
  /// In en, this message translates to:
  /// **'Request MTU'**
  String get bleButtonRequestMtu;

  /// Message shown when BLE scan starts.
  ///
  /// In en, this message translates to:
  /// **'Scan started...'**
  String get bleScanStarted;

  /// Message shown when BLE scan stops.
  ///
  /// In en, this message translates to:
  /// **'Scan stopped.'**
  String get bleScanStopped;

  /// Error message when BLE scan fails to start.
  ///
  /// In en, this message translates to:
  /// **'Error starting scan'**
  String get bleScanError;

  /// Message shown when connecting to a BLE device.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {deviceName}...'**
  String bleConnecting(String deviceName);

  /// Error message when BLE connection fails.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get bleConnectionError;

  /// Message shown when BLE device disconnects.
  ///
  /// In en, this message translates to:
  /// **'Device disconnected.'**
  String get bleDisconnected;

  /// Message shown when MTU request is sent.
  ///
  /// In en, this message translates to:
  /// **'MTU requested.'**
  String get bleMtuRequested;

  /// Label for connection status section.
  ///
  /// In en, this message translates to:
  /// **'Connection Status'**
  String get bleConnectionStatus;

  /// Status text when BLE device is connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get bleStatusConnected;

  /// Status text when connecting to BLE device.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get bleStatusConnecting;

  /// Status text when BLE connection error occurs.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get bleStatusError;

  /// Status text when BLE operation is waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting...'**
  String get bleStatusWaiting;

  /// Status text when BLE device is disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get bleStatusDisconnected;

  /// Label showing connected device name.
  ///
  /// In en, this message translates to:
  /// **'Device: {deviceName}'**
  String bleConnectedDevice(String deviceName);

  /// Message shown when no BLE devices are found.
  ///
  /// In en, this message translates to:
  /// **'No devices found.\nStart scanning to discover devices.'**
  String get bleNoDevicesFound;

  /// Label for devices without a name.
  ///
  /// In en, this message translates to:
  /// **'Unknown Device'**
  String get bleUnknownDevice;

  /// Title for device details dialog.
  ///
  /// In en, this message translates to:
  /// **'Device Details'**
  String get bleDeviceDetails;

  /// Label for device name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get bleDeviceName;

  /// Label for device ID field.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get bleDeviceId;

  /// Label for RSSI (signal strength) field.
  ///
  /// In en, this message translates to:
  /// **'RSSI'**
  String get bleRssi;

  /// Label for advertised name field.
  ///
  /// In en, this message translates to:
  /// **'Advertised Name'**
  String get bleAdvertisedName;

  /// Label for connectable status field.
  ///
  /// In en, this message translates to:
  /// **'Connectable'**
  String get bleConnectable;

  /// Label for service UUIDs list.
  ///
  /// In en, this message translates to:
  /// **'Service UUIDs:'**
  String get bleServiceUuids;

  /// Text shown when a value is not available.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get bleNotAvailable;

  /// Text for yes/true value.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get bleYes;

  /// Text for no/false value.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get bleNo;

  /// Title for Bluetooth permission request.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Permission'**
  String get bluetooth_permission_title;

  /// Description for Bluetooth permission request.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth and location permissions are needed to scan and connect to BLE devices.'**
  String get bluetooth_permission_description;

  /// Section header for positioning devices (RTK/NTRIP) in settings.
  ///
  /// In en, this message translates to:
  /// **'Positioning devices'**
  String get ble_devices_section;

  /// Title for RTK devices entry in settings.
  ///
  /// In en, this message translates to:
  /// **'RTK Devices'**
  String get ble_devices_title;

  /// Description for RTK devices entry in settings.
  ///
  /// In en, this message translates to:
  /// **'Scan and connect to RTK receivers via Bluetooth or USB'**
  String get ble_devices_description;

  /// Title for the GPS data card in BLE screen.
  ///
  /// In en, this message translates to:
  /// **'GPS Data from RTK Receiver'**
  String get bleGpsDataTitle;

  /// Label for latitude in GPS data.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get bleGpsLatitude;

  /// Label for longitude in GPS data.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get bleGpsLongitude;

  /// Label for altitude in GPS data.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get bleGpsAltitude;

  /// Label for accuracy in GPS data.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get bleGpsAccuracy;

  /// Label for satellite count in GPS data.
  ///
  /// In en, this message translates to:
  /// **'Satellites'**
  String get bleGpsSatellites;

  /// Label for HDOP (Horizontal Dilution of Precision) in GPS data.
  ///
  /// In en, this message translates to:
  /// **'HDOP'**
  String get bleGpsHdop;

  /// Label for fix quality in GPS data.
  ///
  /// In en, this message translates to:
  /// **'Fix Quality'**
  String get bleGpsFixQuality;

  /// Label for speed in GPS data.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get bleGpsSpeed;

  /// Label for GPS data update timestamp.
  ///
  /// In en, this message translates to:
  /// **'Updated:'**
  String get bleGpsUpdated;

  /// Label for time since last DGPS/RTK correction (seconds).
  ///
  /// In en, this message translates to:
  /// **'DGPS age'**
  String get bleGpsDgpsAge;

  /// Label for DGPS/RTK reference station ID.
  ///
  /// In en, this message translates to:
  /// **'DGPS station'**
  String get bleGpsDgpsStation;

  /// Label for magnetic variation (declination) in degrees.
  ///
  /// In en, this message translates to:
  /// **'Mag. var.'**
  String get bleGpsMagneticVariation;

  /// Fix quality text for invalid fix.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get bleGpsFixQualityInvalid;

  /// Fix quality text for GPS fix.
  ///
  /// In en, this message translates to:
  /// **'GPS Fix'**
  String get bleGpsFixQualityGps;

  /// Fix quality text for DGPS fix.
  ///
  /// In en, this message translates to:
  /// **'DGPS Fix'**
  String get bleGpsFixQualityDgps;

  /// Fix quality text for PPS fix.
  ///
  /// In en, this message translates to:
  /// **'PPS Fix'**
  String get bleGpsFixQualityPps;

  /// Fix quality text for RTK fix.
  ///
  /// In en, this message translates to:
  /// **'RTK Fix'**
  String get bleGpsFixQualityRtk;

  /// Fix quality text for RTK float fix.
  ///
  /// In en, this message translates to:
  /// **'RTK Float'**
  String get bleGpsFixQualityRtkFloat;

  /// Fix quality text for estimated fix.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get bleGpsFixQualityEstimated;

  /// Fix quality text for manual fix.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get bleGpsFixQualityManual;

  /// Fix quality text for simulation fix.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get bleGpsFixQualitySimulation;

  /// Fix quality text for unknown fix quality.
  ///
  /// In en, this message translates to:
  /// **'Unknown ({quality})'**
  String bleGpsFixQualityUnknown(int quality);

  /// Title for the fix quality explanation dialog.
  ///
  /// In en, this message translates to:
  /// **'Fix Quality Explanation'**
  String get bleGpsFixQualityExplanationTitle;

  /// Explanation text for fix quality values in the dialog.
  ///
  /// In en, this message translates to:
  /// **'Fix Quality indicates the type and reliability of GPS positioning:\n\n• 0 - Invalid: No position available\n• 1 - GPS Fix: Standard GPS (3-5m accuracy)\n• 2 - DGPS Fix: Differential GPS (1-3m accuracy)\n• 3 - PPS Fix: Precise Positioning Service\n• 4 - RTK Fix: Real-Time Kinematic with fixed ambiguity (1-5cm accuracy) - BEST\n• 5 - RTK Float: RTK without fixed ambiguity (10-50cm accuracy)\n• 6 - Estimated: Estimated position\n• 7 - Manual: Manually entered\n• 8 - Simulation: Test data'**
  String get bleGpsFixQualityExplanation;

  /// Text shown in the pulsing indicator when data is being received but no position yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for initial position...'**
  String get bleReceivingData;

  /// Hint shown under the waiting message when connected but no position yet.
  ///
  /// In en, this message translates to:
  /// **'If the receiver has no fix, ensure it has a clear view of the sky.'**
  String get bleReceivingDataHint;

  /// Title for the NTRIP corrections card.
  ///
  /// In en, this message translates to:
  /// **'NTRIP Corrections'**
  String get bleNtripTitle;

  /// Status text when NTRIP is connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get bleNtripConnected;

  /// Status text when connecting to NTRIP.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get bleNtripConnecting;

  /// Status text when NTRIP connection error occurs.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get bleNtripError;

  /// Status text when NTRIP is disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get bleNtripDisconnected;

  /// Label for NTRIP host input field.
  ///
  /// In en, this message translates to:
  /// **'NTRIP Caster Host'**
  String get bleNtripHost;

  /// Label for NTRIP port input field.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get bleNtripPort;

  /// Label for NTRIP mount point input field.
  ///
  /// In en, this message translates to:
  /// **'Mount Point'**
  String get bleNtripMountPoint;

  /// Label for NTRIP username input field.
  ///
  /// In en, this message translates to:
  /// **'Username (Email)'**
  String get bleNtripUsername;

  /// Label for NTRIP password input field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get bleNtripPassword;

  /// Button label to connect to NTRIP caster.
  ///
  /// In en, this message translates to:
  /// **'Connect to NTRIP'**
  String get bleNtripConnect;

  /// Button label to disconnect from NTRIP caster.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get bleNtripDisconnect;

  /// Text shown when RTCM corrections are being forwarded.
  ///
  /// In en, this message translates to:
  /// **'Forwarding RTCM corrections'**
  String get bleNtripForwarding;

  /// Error message when NTRIP host is missing.
  ///
  /// In en, this message translates to:
  /// **'NTRIP host is required'**
  String get bleNtripErrorHostRequired;

  /// Error message when NTRIP port is missing.
  ///
  /// In en, this message translates to:
  /// **'Port is required'**
  String get bleNtripErrorPortRequired;

  /// Error message when NTRIP port is invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid port number'**
  String get bleNtripErrorInvalidPort;

  /// Error message when NTRIP mount point is missing.
  ///
  /// In en, this message translates to:
  /// **'Mount point is required'**
  String get bleNtripErrorMountPointRequired;

  /// Error message when NTRIP username is missing.
  ///
  /// In en, this message translates to:
  /// **'Username (email) is required'**
  String get bleNtripErrorUsernameRequired;

  /// Success message when NTRIP connection is established.
  ///
  /// In en, this message translates to:
  /// **'Connected to NTRIP caster'**
  String get bleNtripConnectedSuccess;

  /// Success message when NTRIP disconnection is successful.
  ///
  /// In en, this message translates to:
  /// **'Disconnected from NTRIP caster'**
  String get bleNtripDisconnectedSuccess;

  /// Error message when NTRIP connection fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to NTRIP caster'**
  String get bleNtripConnectionFailed;

  /// Checkbox label for enabling SSL/TLS connection.
  ///
  /// In en, this message translates to:
  /// **'Use SSL/TLS'**
  String get bleNtripUseSsl;

  /// Hint text for SSL/TLS checkbox.
  ///
  /// In en, this message translates to:
  /// **'Enable for secure connections (port 2102)'**
  String get bleNtripUseSslHint;

  /// Message shown when NTRIP connect is disabled until position data is received from BLE.
  ///
  /// In en, this message translates to:
  /// **'Wait for GPS position from device before connecting to NTRIP.'**
  String get bleNtripWaitForPosition;

  /// Message when USB connection fails due to permission.
  ///
  /// In en, this message translates to:
  /// **'USB permission required. If Android showed a dialog, tap Allow and try Connect again.'**
  String get usbPermissionRequired;

  /// Message when USB connection fails.
  ///
  /// In en, this message translates to:
  /// **'USB connection failed.{message}'**
  String usbConnectionFailedWithMessage(String message);

  /// No description provided for @ntripError.
  ///
  /// In en, this message translates to:
  /// **'NTRIP Error: {error}'**
  String ntripError(String error);

  /// No description provided for @usbConnectingTo.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {deviceName}...'**
  String usbConnectingTo(String deviceName);

  /// No description provided for @usbConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'USB connection failed'**
  String get usbConnectionFailed;

  /// No description provided for @usbDeviceDisconnected.
  ///
  /// In en, this message translates to:
  /// **'USB device disconnected.'**
  String get usbDeviceDisconnected;

  /// No description provided for @ntripReconnectedOnNewDevice.
  ///
  /// In en, this message translates to:
  /// **'NTRIP reconnected on new device'**
  String get ntripReconnectedOnNewDevice;

  /// No description provided for @bleConnectionModeBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get bleConnectionModeBluetooth;

  /// No description provided for @bleConnectionModeUsb.
  ///
  /// In en, this message translates to:
  /// **'USB'**
  String get bleConnectionModeUsb;

  /// No description provided for @usbDisconnectFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from USB device'**
  String get usbDisconnectFromDevice;

  /// No description provided for @usbLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get usbLoading;

  /// No description provided for @usbRefreshDevices.
  ///
  /// In en, this message translates to:
  /// **'Refresh USB devices'**
  String get usbRefreshDevices;

  /// No description provided for @usbNoDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No USB devices found'**
  String get usbNoDevicesFound;

  /// No description provided for @usbNoDevicesHint.
  ///
  /// In en, this message translates to:
  /// **'Connect your RTK receiver with a USB cable (USB OTG). The phone must support USB host (OTG). Then tap Refresh.'**
  String get usbNoDevicesHint;

  /// No description provided for @usbConnectButton.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get usbConnectButton;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithMessage(String error);

  /// No description provided for @errorDisconnecting.
  ///
  /// In en, this message translates to:
  /// **'Error disconnecting: {error}'**
  String errorDisconnecting(String error);

  /// No description provided for @gpsInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'GPS Information'**
  String get gpsInfoTitle;

  /// No description provided for @gpsWaitingForData.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS data...'**
  String get gpsWaitingForData;

  /// No description provided for @gpsDeviceInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Device Information'**
  String get gpsDeviceInfoSection;

  /// No description provided for @gpsSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get gpsSourceLabel;

  /// No description provided for @gpsRtkDevice.
  ///
  /// In en, this message translates to:
  /// **'RTK Device'**
  String get gpsRtkDevice;

  /// No description provided for @gpsStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get gpsStatusLabel;

  /// No description provided for @gpsDeviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get gpsDeviceLabel;

  /// No description provided for @gpsRtkReceiver.
  ///
  /// In en, this message translates to:
  /// **'RTK Receiver'**
  String get gpsRtkReceiver;

  /// No description provided for @gpsInternalGps.
  ///
  /// In en, this message translates to:
  /// **'Internal GPS'**
  String get gpsInternalGps;

  /// No description provided for @gpsStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get gpsStatusActive;

  /// No description provided for @gpsConnectRtkDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect RTK Device'**
  String get gpsConnectRtkDevice;

  /// No description provided for @gpsCourseLabel.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get gpsCourseLabel;

  /// No description provided for @mapRtkDisconnectedUsingDeviceGps.
  ///
  /// In en, this message translates to:
  /// **'RTK device disconnected. Using device GPS.'**
  String get mapRtkDisconnectedUsingDeviceGps;

  /// No description provided for @mapBleConnectionError.
  ///
  /// In en, this message translates to:
  /// **'BLE connection error occurred.'**
  String get mapBleConnectionError;

  /// Section header for cable types in settings.
  ///
  /// In en, this message translates to:
  /// **'Cable Types'**
  String get cableTypesSection;

  /// Title for the cable types management screen.
  ///
  /// In en, this message translates to:
  /// **'Cable Types'**
  String get cableTypesTitle;

  /// Description for cable types entry in settings.
  ///
  /// In en, this message translates to:
  /// **'Add or remove cable types used in projects'**
  String get cableTypesDescription;

  /// Button label to add a cable type.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get cableTypeAddButton;

  /// Title for the add cable type dialog.
  ///
  /// In en, this message translates to:
  /// **'Add Cable Type'**
  String get cableTypeAddTitle;

  /// Title for the edit cable type dialog.
  ///
  /// In en, this message translates to:
  /// **'Edit Cable Type'**
  String get cableTypeEditTitle;

  /// Button/tooltip for editing a cable type.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get cableTypeEditButton;

  /// Snackbar when a cable type is added.
  ///
  /// In en, this message translates to:
  /// **'Cable type added.'**
  String get cableTypeAddedSnackbar;

  /// Snackbar when a cable type is updated.
  ///
  /// In en, this message translates to:
  /// **'Cable type updated.'**
  String get cableTypeUpdatedSnackbar;

  /// Snackbar when a cable type is deleted.
  ///
  /// In en, this message translates to:
  /// **'Cable type deleted.'**
  String get cableTypeDeletedSnackbar;

  /// Label for the list of projects that use the cable type being deleted.
  ///
  /// In en, this message translates to:
  /// **'Projects using this type:'**
  String get cableTypeDeleteProjectsLabel;

  /// Title for cable type delete confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete Cable Type?'**
  String get cableTypeDeleteConfirmTitle;

  /// Message for cable type delete confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? Projects using this type will have it cleared. This cannot be undone.'**
  String cableTypeDeleteConfirmMessage(String name);

  /// No description provided for @errorAddingCableType.
  ///
  /// In en, this message translates to:
  /// **'Error adding cable type: {error}'**
  String errorAddingCableType(String error);

  /// No description provided for @errorUpdatingCableType.
  ///
  /// In en, this message translates to:
  /// **'Error updating cable type: {error}'**
  String errorUpdatingCableType(String error);

  /// No description provided for @errorDeletingCableType.
  ///
  /// In en, this message translates to:
  /// **'Error deleting: {error}'**
  String errorDeletingCableType(String error);

  /// No description provided for @errorLoadingCableTypes.
  ///
  /// In en, this message translates to:
  /// **'Error loading cable types: {error}'**
  String errorLoadingCableTypes(String error);

  /// Empty state message on cable types screen.
  ///
  /// In en, this message translates to:
  /// **'No cable types yet.'**
  String get cableTypesEmpty;

  /// Hint when cable types list is empty.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a cable type for use in projects.'**
  String get cableTypesEmptyHint;

  /// Validation message for required field.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// Retry button label.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
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
