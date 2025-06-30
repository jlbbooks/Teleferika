// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TeleferiKa';

  @override
  String loadingScreenMessage(String appName) {
    return 'Loading $appName...';
  }

  @override
  String get projectPageTitle => 'Project Details';

  @override
  String get tabDetails => 'Details';

  @override
  String get tabPoints => 'Points';

  @override
  String get tabCompass => 'Compass';

  @override
  String get tabMap => 'Map';

  @override
  String get formFieldNameLabel => 'Project Name';

  @override
  String get formFieldNoteLabel => 'Note';

  @override
  String get formFieldAzimuthLabel => 'Azimuth (°)';

  @override
  String get formFieldProjectDateLabel => 'Project Date';

  @override
  String get formFieldLastUpdatedLabel => 'Last Updated';

  @override
  String get formFieldPresumedTotalLengthLabel => 'Presumed Total Length (m)';

  @override
  String get buttonSave => 'Save';

  @override
  String get buttonCalculateAzimuth => 'Calculate Azimuth';

  @override
  String get buttonCalculate => 'Calculate';

  @override
  String get buttonSelectDate => 'Select Date';

  @override
  String get compassAddPointButton => 'Add Point';

  @override
  String get compassAddAsEndPointButton => 'Add as End Point';

  @override
  String get pointsSetAsStartButton => 'Set as Start';

  @override
  String get pointsSetAsEndButton => 'Set as End';

  @override
  String get pointsDeleteButton => 'Delete';

  @override
  String get errorSaveProjectBeforeAddingPoints =>
      'Please save the project before adding points.';

  @override
  String get infoFetchingLocation => 'Fetching location...';

  @override
  String pointAddedSnackbar(String ordinalNumber) {
    return 'Point P$ordinalNumber added.';
  }

  @override
  String get pointAddedSetAsEndSnackbarSuffix => 'Set as END point.';

  @override
  String get pointAddedInsertedBeforeEndSnackbarSuffix =>
      'Inserted before current end point.';

  @override
  String pointFromCompassDefaultNote(String altitude) {
    return 'Added (H: $altitude°)';
  }

  @override
  String errorAddingPoint(String errorMessage) {
    return 'Error adding point: $errorMessage';
  }

  @override
  String errorLoadingProjectDetails(String errorMessage) {
    return 'Error loading project details: $errorMessage';
  }

  @override
  String get errorAzimuthPointsNotSet =>
      'Starting and/or ending point not set. Cannot calculate azimuth.';

  @override
  String get errorAzimuthPointsSame =>
      'Starting and ending points are the same. Azimuth is undefined or 0.';

  @override
  String get errorAzimuthCouldNotRetrievePoints =>
      'Could not retrieve point data for calculation. Please check points.';

  @override
  String errorCalculatingAzimuth(String errorMessage) {
    return 'Error calculating azimuth: $errorMessage';
  }

  @override
  String azimuthCalculatedSnackbar(String azimuthValue) {
    return 'Azimuth calculated: $azimuthValue°';
  }

  @override
  String get azimuthSavedSnackbar => 'Azimuth saved successfully.';

  @override
  String get azimuthOverwriteTitle => 'Overwrite Azimuth?';

  @override
  String get azimuthOverwriteMessage =>
      'The azimuth field already has a value. The new calculated value will overwrite the current value. Do you want to continue?';

  @override
  String get projectNameCannotBeEmptyValidator =>
      'Project name cannot be empty.';

  @override
  String get projectSavedSuccessfully => 'Project saved successfully.';

  @override
  String get dialogTitleConfirmDelete => 'Confirm Delete';

  @override
  String dialogContentConfirmDeletePoint(String pointOrdinal) {
    return 'Are you sure you want to delete point P$pointOrdinal? This action cannot be undone.';
  }

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get buttonDelete => 'Delete';

  @override
  String pointDeletedSnackbar(String pointOrdinal) {
    return 'Point P$pointOrdinal deleted.';
  }

  @override
  String pointSetAsStartSnackbar(String pointOrdinal) {
    return 'Point P$pointOrdinal set as start.';
  }

  @override
  String pointSetAsEndSnackbar(String pointOrdinal) {
    return 'Point P$pointOrdinal set as end.';
  }

  @override
  String get export_project_data_title => 'Export Project Data';

  @override
  String export_page_project_name_label(String projectName) {
    return 'Project: $projectName';
  }

  @override
  String export_page_points_count_label(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString points found.',
      one: '$countString point found.',
      zero: 'No points found for export.',
    );
    return '$_temp0';
  }

  @override
  String get export_page_select_format_label => 'Select Export Format:';

  @override
  String get export_format_dropdown_label => 'Format';

  @override
  String get export_page_share_button => 'Share File';

  @override
  String get export_page_save_locally_button => 'Save Locally';

  @override
  String get export_failed => 'Export failed. Please try again.';

  @override
  String get file_shared_successfully => 'File prepared for sharing.';

  @override
  String get file_saved_successfully => 'File saved successfully';

  @override
  String get file_save_cancelled_or_failed =>
      'File save was cancelled or failed.';

  @override
  String get export_project_data_tooltip => 'Export Project Data';

  @override
  String get export_project_tooltip => 'Export Project';

  @override
  String get errorExportNoPoints => 'No points to export';

  @override
  String get infoExporting => 'Exporting...';

  @override
  String get exportSuccess => 'Project exported successfully';

  @override
  String get exportError => 'Export failed';

  @override
  String exportErrorWithDetails(String errorMessage) {
    return 'Export error: $errorMessage';
  }

  @override
  String get exportRequiresValidLicence => 'Valid licence required for export';

  @override
  String get unsaved_changes_title => 'Unsaved Changes';

  @override
  String get unsaved_changes_export_message =>
      'You have unsaved changes. Please save the project before exporting to ensure all data is included.';

  @override
  String get save_button_label => 'Save';

  @override
  String get dialog_cancel => 'Cancel';

  @override
  String get project_not_loaded_cannot_export =>
      'Project not loaded. Cannot export data.';

  @override
  String get error_loading_points =>
      'Error loading points for export. Please try again.';

  @override
  String get export_page_note_text =>
      'Note: Ensure you have granted necessary storage permissions if saving locally on mobile devices. Some export formats may not include all data types (e.g., images).';

  @override
  String get please_save_project_first_to_export =>
      'Please save the new project first to enable export.';

  @override
  String get export_requires_licence_title => 'Licence Required for Export';

  @override
  String get export_requires_licence_message =>
      'This feature requires an active licence. Please import a valid licence file to proceed.';

  @override
  String get action_import_licence => 'Import Licence';

  @override
  String get edit_project_title => 'Edit Project';

  @override
  String edit_project_title_named(String projectName) {
    return 'Edit: $projectName';
  }

  @override
  String get new_project_title => 'New Project';

  @override
  String get delete_project_tooltip => 'Delete Project';

  @override
  String get save_project_tooltip => 'Save Project';

  @override
  String last_updated_label(String date) {
    return 'Last updated: $date';
  }

  @override
  String get not_yet_saved_label => 'Not yet saved';

  @override
  String get tap_to_set_date => 'Tap to set date';

  @override
  String get invalid_number_validator => 'Invalid number.';

  @override
  String get must_be_359_validator => 'Must be +/-359.99';

  @override
  String get please_correct_form_errors =>
      'Please correct the errors in the form.';

  @override
  String get project_created_successfully => 'Project created successfully!';

  @override
  String get project_already_up_to_date =>
      'Project already up to date or not found.';

  @override
  String get cannot_delete_unsaved_project =>
      'Cannot delete a project that has not been saved yet.';

  @override
  String get confirm_delete_project_title => 'Confirm Delete';

  @override
  String confirm_delete_project_content(Object projectName) {
    return 'Are you sure you want to delete the project \"$projectName\"? This action cannot be undone.';
  }

  @override
  String get project_deleted_successfully => 'Project deleted successfully.';

  @override
  String get project_not_found_or_deleted =>
      'Project not found or already deleted.';

  @override
  String error_saving_project(String errorMessage) {
    return 'Error saving project: $errorMessage';
  }

  @override
  String error_deleting_project(String errorMessage) {
    return 'Error deleting project: $errorMessage';
  }

  @override
  String get unsaved_changes_dialog_title => 'Unsaved Changes';

  @override
  String get unsaved_changes_dialog_content =>
      'You have unsaved changes. Do you want to discard them and leave?';

  @override
  String get discard_button_label => 'Discard';

  @override
  String get details_tab_label => 'Details';

  @override
  String get points_tab_label => 'Points';

  @override
  String get compass_tab_label => 'Compass';

  @override
  String get map_tab_label => 'Map';

  @override
  String get export_page_title => 'Export Project Data';

  @override
  String get export_page_description =>
      'Export your project data in various formats.';

  @override
  String get export_format_csv => 'CSV (Comma-Separated Values)';

  @override
  String get export_format_kml => 'KML (Keyhole Markup Language)';

  @override
  String get export_format_geojson => 'GeoJSON';

  @override
  String get unsaved_changes_discard_message =>
      'You have unsaved changes. Discard them and leave?';

  @override
  String get unsaved_changes_discard_button => 'Discard Changes';

  @override
  String get unsaved_changes_save_button => 'Save Changes';

  @override
  String get export_page_no_points => 'No points available for export.';

  @override
  String mapErrorLoadingPoints(String errorMessage) {
    return 'Error loading points for map: $errorMessage';
  }

  @override
  String mapPointMovedSuccessfully(String ordinalNumber) {
    return 'Point P$ordinalNumber moved successfully!';
  }

  @override
  String mapErrorMovingPoint(String ordinalNumber) {
    return 'Error: Could not move point P$ordinalNumber. Point not found or not updated.';
  }

  @override
  String mapErrorMovingPointGeneric(String ordinalNumber, String errorMessage) {
    return 'Error moving point P$ordinalNumber: $errorMessage';
  }

  @override
  String get mapTooltipMovePoint => 'Move Point';

  @override
  String get mapTooltipSaveChanges => 'Save Changes';

  @override
  String get mapTooltipCancelMove => 'Cancel Move';

  @override
  String get mapTooltipEditPointDetails => 'Edit Details';

  @override
  String get mapTooltipAddPointFromCompass =>
      'Add Point at Current Location (from Compass)';

  @override
  String get mapNoPointsToDisplay => 'No points to display on the map.';

  @override
  String get mapLocationPermissionDenied =>
      'Location permission denied. Map features requiring location will be limited.';

  @override
  String get mapSensorPermissionDenied =>
      'Sensor (compass) permission denied. Device orientation features will be unavailable.';

  @override
  String mapErrorGettingLocationUpdates(String errorMessage) {
    return 'Error getting location updates: $errorMessage';
  }

  @override
  String mapErrorGettingCompassUpdates(String errorMessage) {
    return 'Error getting compass updates: $errorMessage';
  }

  @override
  String get mapLoadingPointsIndicator => 'Loading points...';

  @override
  String get mapPermissionsRequiredTitle => 'Permissions Required';

  @override
  String get mapLocationPermissionInfoText =>
      'Location permission is needed to show your current position and for some map features.';

  @override
  String get mapSensorPermissionInfoText =>
      'Sensor (compass) permission is needed for direction-based features.';

  @override
  String get mapButtonOpenAppSettings => 'Open App Settings';

  @override
  String get mapButtonRetryPermissions => 'Retry Permissions';

  @override
  String get mapDeletePointDialogTitle => 'Confirm Deletion';

  @override
  String mapDeletePointDialogContent(String pointOrdinalNumber) {
    return 'Are you sure you want to delete point P$pointOrdinalNumber?';
  }

  @override
  String get mapDeletePointDialogCancelButton => 'Cancel';

  @override
  String get mapDeletePointDialogDeleteButton => 'Delete';

  @override
  String mapPointDeletedSuccessSnackbar(String pointOrdinalNumber) {
    return 'Point P$pointOrdinalNumber deleted.';
  }

  @override
  String mapErrorPointNotFoundOrDeletedSnackbar(String pointOrdinalNumber) {
    return 'Error: Point P$pointOrdinalNumber could not be found or deleted from map view.';
  }

  @override
  String mapErrorDeletingPointSnackbar(
    String pointOrdinalNumber,
    String errorMessage,
  ) {
    return 'Error deleting point P$pointOrdinalNumber: $errorMessage';
  }

  @override
  String get compassHeadingNotAvailable =>
      'Cannot add point: Compass heading not available.';

  @override
  String projectAzimuthLabel(String azimuth) {
    return 'Project Azimuth: $azimuth°';
  }

  @override
  String get projectAzimuthRequiresPoints =>
      'Project Azimuth: (Requires at least 2 points)';

  @override
  String get projectAzimuthNotCalculated =>
      'Project Azimuth: Not yet calculated';

  @override
  String get compassAccuracyHigh => 'High Accuracy';

  @override
  String get compassAccuracyMedium => 'Medium Accuracy';

  @override
  String get compassAccuracyLow => 'Low Accuracy';

  @override
  String get compassPermissionsRequired => 'Permissions Required';

  @override
  String get compassPermissionsMessage =>
      'This tool requires sensor and location permissions to function correctly. Please grant them in your device settings.';

  @override
  String get openSettingsButton => 'Open Settings';

  @override
  String get retryButton => 'Retry';

  @override
  String get mapAcquiringLocation => 'Acquiring location...';

  @override
  String get mapCenterOnLocation => 'Center on my location';

  @override
  String get mapAddNewPoint => 'Add New Point';

  @override
  String get mapCenterOnPoints => 'Center on points';

  @override
  String get mapTypeStreet => 'Street';

  @override
  String get mapTypeSatellite => 'Satellite';

  @override
  String get mapTypeTerrain => 'Terrain';

  @override
  String get mapTypeSelector => 'Map Type';

  @override
  String get must_be_positive_validator => 'Must be positive.';

  @override
  String get mapNewPointLabel => 'NEW';

  @override
  String get mapSaveNewPoint => 'Save';

  @override
  String get mapDiscardNewPoint => 'Discard';

  @override
  String get mapNewPointSaved => 'New point saved successfully!';

  @override
  String mapErrorSavingNewPoint(String errorMessage) {
    return 'Error saving new point: $errorMessage';
  }

  @override
  String get mapUnsavedPointExists =>
      'You have an unsaved point. Please save or discard it before adding another.';

  @override
  String get mapCompassDirectionTooltip => 'Compass Direction';

  @override
  String get mapCompassNorthIndicator => 'North';

  @override
  String get errorLocationUnavailable => 'Location unavailable.';

  @override
  String get infoPointAddedPendingSave => 'Point added (pending save)';

  @override
  String get errorGeneric => 'Error';
}
