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
  String get mapDownloadRequiresValidLicence =>
      'Valid licence required for map download';

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
    return 'Updated: $date';
  }

  @override
  String get no_updates => 'No updates';

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
  String confirm_delete_project_content(String projectName) {
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
  String mapTypeName(String mapType) {
    return '$mapType';
  }

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

  @override
  String get edit_point_title => 'Edit Point';

  @override
  String get coordinates_section_title => 'Coordinates';

  @override
  String get latitude_label => 'Latitude';

  @override
  String get latitude_hint => 'e.g. 45.12345';

  @override
  String get latitude_empty_validator => 'Latitude cannot be empty';

  @override
  String get latitude_invalid_validator => 'Invalid number format';

  @override
  String get latitude_range_validator => 'Latitude must be between -90 and 90';

  @override
  String get longitude_label => 'Longitude';

  @override
  String get longitude_hint => 'e.g. -12.54321';

  @override
  String get longitude_empty_validator => 'Longitude cannot be empty';

  @override
  String get longitude_invalid_validator => 'Invalid number format';

  @override
  String get longitude_range_validator =>
      'Longitude must be between -180 and 180';

  @override
  String get additional_data_section_title => 'Additional Data';

  @override
  String get altitude_label => 'Altitude (m)';

  @override
  String get altitude_hint => 'e.g. 1203.5 (Optional)';

  @override
  String get altitude_invalid_validator => 'Invalid number format';

  @override
  String get altitude_range_validator =>
      'Altitude must be between -1000 and 8849 meters';

  @override
  String get note_label => 'Note (Optional)';

  @override
  String get note_hint => 'Any observations or details...';

  @override
  String get photos_section_title => 'Photos';

  @override
  String get unsaved_point_details_title => 'Unsaved Changes';

  @override
  String get unsaved_point_details_content =>
      'You have unsaved changes to point details. Save them?';

  @override
  String get discard_text_changes => 'Discard Text Changes';

  @override
  String get save_all_and_exit => 'Save All & Exit';

  @override
  String get confirm_deletion_title => 'Confirm Deletion';

  @override
  String get point_details_saved => 'Point details saved!';

  @override
  String get undo_changes_tooltip => 'Undo Changes';

  @override
  String get no_projects_yet => 'No projects yet. Tap \'+\' to add one!';

  @override
  String get add_new_project_tooltip => 'Add New Project';

  @override
  String get untitled_project => 'Untitled Project';

  @override
  String get delete_selected => 'Delete Selected';

  @override
  String get delete_projects_title => 'Delete Project(s)?';

  @override
  String get license_information_title => 'Licence Information';

  @override
  String get close_button => 'Close';

  @override
  String get import_new_licence => 'Import New Licence';

  @override
  String get import_licence => 'Import Licence';

  @override
  String get request_new_license => 'Request New License';

  @override
  String get premium_features_title => 'Premium Features';

  @override
  String get premium_features_available =>
      'Premium features are available in this build!';

  @override
  String get available_features => 'Available Features:';

  @override
  String get premium_features_not_available =>
      'Premium features are not available in this build.';

  @override
  String get opensource_version => 'This is the opensource version of the app.';

  @override
  String get try_feature => 'Try Feature';

  @override
  String get install_demo_license => 'Install Demo License';

  @override
  String get clear_license => 'Clear License';

  @override
  String get invalid_latitude_or_longitude_format =>
      'Invalid latitude or longitude format.';

  @override
  String get invalid_altitude_format =>
      'Invalid altitude format. Please enter a number or leave it empty.';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get lat => 'Lat:';

  @override
  String get lon => 'Lon:';

  @override
  String get addANote => 'Add a note...';

  @override
  String get tapToAddNote => 'Tap to add note...';

  @override
  String get save => 'Save';

  @override
  String get discard => 'Discard';

  @override
  String get edit => 'Edit';

  @override
  String get move => 'Move';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get tapOnTheMapToSetNewLocation =>
      'Tap on the map to set new location';

  @override
  String get locationPermissionTitle => 'Location Permission';

  @override
  String get sensorPermissionTitle => 'Sensor Permission';

  @override
  String get noNote => 'No note';

  @override
  String distanceFromPrevious(String pointName) {
    return 'Distance from $pointName:';
  }

  @override
  String get offsetLabel => 'Offset:';

  @override
  String get angleLabel => 'Angle:';

  @override
  String get delete_photo_title => 'Delete Photo?';

  @override
  String delete_photo_content(String photoNumber) {
    return 'Are you sure you want to delete $photoNumber photo(s)?';
  }

  @override
  String get camera_permission_title => 'Camera Permission';

  @override
  String get camera_permission_description =>
      'Camera permission is needed to take photos.';

  @override
  String get microphone_permission_title => 'Microphone Permission';

  @override
  String get microphone_permission_description =>
      'Microphone permission is needed to record audio.';

  @override
  String get storage_permission_title => 'Storage Permission';

  @override
  String get storage_permission_description =>
      'Storage permission is needed to save files.';

  @override
  String get current_rope_length_label => 'Current Rope Length';

  @override
  String get unit_meter => 'm';

  @override
  String get unit_kilometer => 'km';

  @override
  String point_deleted_pending_save(String pointName) {
    return 'Point $pointName deleted (pending save).';
  }

  @override
  String error_deleting_point_generic(String pointName, String errorMessage) {
    return 'Error deleting point $pointName: $errorMessage';
  }

  @override
  String get compass_calibration_notice =>
      'Compass sensor needs calibration. Please move your device in a figure-8 motion.';

  @override
  String get project_statistics_title => 'Project Statistics';

  @override
  String get project_statistics_points => 'Points';

  @override
  String get project_statistics_images => 'Images';

  @override
  String get project_statistics_current_length => 'Current Length';

  @override
  String get project_statistics_measurements => 'Measurements';

  @override
  String get points_list_title => 'Points List';

  @override
  String get photo_manager_title => 'Photos';

  @override
  String get photo_manager_no_photos => 'No photos yet.';

  @override
  String photo_manager_gallery(String platform) {
    String _temp0 = intl.Intl.selectLogic(platform, {
      'android': 'Gallery',
      'ios': 'Photos',
      'other': 'Gallery',
    });
    return '$_temp0';
  }

  @override
  String get photo_manager_camera => 'Camera';

  @override
  String get photo_manager_add_photo_tooltip => 'Add Photo';

  @override
  String get photo_manager_photo_deleted => 'Photo deleted';

  @override
  String get photo_manager_photo_changes_saved =>
      'Photo changes saved automatically.';

  @override
  String photo_manager_error_saving_photo_changes(String errorMessage) {
    return 'Error saving photo changes: $errorMessage';
  }

  @override
  String photo_manager_error_saving_image(String errorMessage) {
    return 'Error saving image: $errorMessage';
  }

  @override
  String photo_manager_error_picking_image(String errorMessage) {
    return 'Error picking image: $errorMessage';
  }

  @override
  String photo_manager_error_deleting_photo(String errorMessage) {
    return 'Error deleting photo: $errorMessage';
  }

  @override
  String get photo_manager_wait_saving =>
      'Please wait, photos are being saved...';

  @override
  String app_version_label(String version) {
    return 'App Version: $version';
  }

  @override
  String licence_active_content(String email, String validUntil) {
    return 'Licensed to: $email\nStatus: Active\nValid Until: $validUntil';
  }

  @override
  String licence_expired_content(String email, String validUntil) {
    return 'Licensed to: $email\nStatus: Expired\nValid Until: $validUntil\n\nPlease import a valid licence.';
  }

  @override
  String get licence_none_content =>
      'No active licence found. Please import a licence file to unlock premium features.';

  @override
  String licence_status(String status) {
    return 'Licence Status: $status';
  }

  @override
  String feature_demo_failed(String error) {
    return 'Feature demonstration failed: $error';
  }

  @override
  String licence_imported_successfully(String email) {
    return 'Licence for $email imported successfully!';
  }

  @override
  String get licence_import_cancelled => 'Licence import cancelled or failed.';

  @override
  String get demo_license_imported_successfully =>
      'Demo license imported successfully!';

  @override
  String get license_cleared_successfully => 'License cleared successfully!';

  @override
  String confirm_deletion_content(String pointName) {
    return 'Are you sure you want to delete point $pointName? This action cannot be undone.';
  }

  @override
  String point_deleted_success(String pointName) {
    return 'Point $pointName deleted successfully!';
  }

  @override
  String error_deleting_point(String pointName, String errorMessage) {
    return 'Error deleting point $pointName: $errorMessage';
  }

  @override
  String error_saving_point(String errorMessage) {
    return 'Error saving point: $errorMessage';
  }

  @override
  String selected_count(int count) {
    return '$count selected';
  }

  @override
  String delete_projects_content(int count) {
    return 'Are you sure you want to delete $count selected project(s)? This action cannot be undone.';
  }

  @override
  String project_id_label(String id, String lastUpdateText) {
    return 'ID: $id | $lastUpdateText';
  }

  @override
  String headingLabel(String angle) {
    return '$angle°';
  }

  @override
  String get project_label_prefix => 'Project: ';

  @override
  String get gpsPrecisionLabel => 'GPS Precision:';

  @override
  String get pointDetailsSectionTitle => 'Point Details';

  @override
  String get no_license_to_clear => 'No license installed to clear.';

  @override
  String get enhanced_licence_test_results => 'Enhanced Licence Test Results';

  @override
  String get email_label => 'Email:';

  @override
  String get valid_until_label => 'Valid Until:';

  @override
  String get features_label => 'Features:';

  @override
  String get algorithm_label => 'Algorithm:';

  @override
  String get has_export_feature_label => 'Has Export Feature:';

  @override
  String get is_valid_label => 'Is Valid:';

  @override
  String get device_fingerprint_title => 'Device Fingerprint';

  @override
  String get fingerprint_label => 'Fingerprint:';

  @override
  String get device_info_label => 'Device Info:';

  @override
  String get copy_button => 'Copy';

  @override
  String get license_status_label => 'License Status';

  @override
  String get test_enhanced_licence => 'Test Enhanced Licence';

  @override
  String get generate_device_fingerprint => 'Generate Device Fingerprint';

  @override
  String get test_licence_validation => 'Test Licence Validation';

  @override
  String error_importing_licence(String error) {
    return 'Error importing licence: $error';
  }

  @override
  String error_importing_demo_license(String error) {
    return 'Error importing demo license: $error';
  }

  @override
  String error_clearing_license(String error) {
    return 'Error clearing license: $error';
  }

  @override
  String get failed_to_save_enhanced_licence =>
      'Failed to save enhanced licence';

  @override
  String enhanced_licence_test_failed(String error) {
    return 'Enhanced licence test failed: $error';
  }

  @override
  String get fingerprint_copied_to_clipboard =>
      'Fingerprint copied to clipboard';

  @override
  String failed_to_generate_fingerprint(String error) {
    return 'Failed to generate fingerprint: $error';
  }

  @override
  String get invalid_licence_accepted_error =>
      'Invalid licence was accepted - this is wrong!';

  @override
  String invalid_licence_correctly_rejected(String code) {
    return 'Invalid licence correctly rejected: $code';
  }

  @override
  String unexpected_error(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String validation_test_failed(String error) {
    return 'Validation test failed: $error';
  }

  @override
  String get refresh_status => 'Refresh Status';

  @override
  String get request_license => 'Request License';

  @override
  String get cancel_button => 'Cancel';

  @override
  String get request_button => 'Request';

  @override
  String get license_requested => 'License Requested';

  @override
  String get license_expired => 'License Expired';

  @override
  String get license_expiring_soon => 'License Expiring Soon';

  @override
  String get license_active => 'License Active';

  @override
  String get license_pending_approval_message =>
      'Your license request is pending approval. You will be notified when it is approved or denied.';

  @override
  String get license_expired_message =>
      'This license has expired and needs to be renewed. You can request a new license or import an existing one.';

  @override
  String get license_expiring_soon_message =>
      'This license will expire soon. Consider requesting a new license or importing an existing one.';

  @override
  String get license_details => 'License Details';

  @override
  String get issued_label => 'Issued';

  @override
  String get max_devices_label => 'Max Devices';

  @override
  String get version_label => 'Version';

  @override
  String get requested_features => 'Requested Features';

  @override
  String get technical_details => 'Technical Details';

  @override
  String get data_hash => 'Data Hash';

  @override
  String get no_license_found => 'No License Found';

  @override
  String get no_active_license_message =>
      'No active license found. You can import an existing license file or request a new license from the server.';

  @override
  String get project_deleted => 'Project deleted.';

  @override
  String get status_label => 'Status';

  @override
  String get days_remaining_label => 'Days Remaining';

  @override
  String get features_pending_approval =>
      'Features will be available once your license is approved:';

  @override
  String get device_fingerprint => 'Device Fingerprint';

  @override
  String get app_information => 'App Information';

  @override
  String get requested_features_label => 'Requested Features:';

  @override
  String get basic_export => 'Basic Export';

  @override
  String get map_download => 'Map Download';

  @override
  String get advanced_export => 'Advanced Export';

  @override
  String get email_required => 'Email is required';

  @override
  String get select_at_least_one_feature =>
      'Please select at least one feature';

  @override
  String get your_email_example => 'your.email@example.com';

  @override
  String get max_devices_hint => '1-5';

  @override
  String get days_suffix => 'days';

  @override
  String get download_offline_maps_tooltip => 'Download Offline Maps';

  @override
  String license_imported_successfully(String email) {
    return 'Licence for $email imported successfully!';
  }

  @override
  String get license_import_cancelled => 'Licence import cancelled or failed.';

  @override
  String error_importing_license(String error) {
    return 'Error importing licence: $error';
  }

  @override
  String get project_deleted_message => 'Project deleted.';

  @override
  String get install_development_license => 'Install Development License';

  @override
  String get development_testing => 'Development & Testing';

  @override
  String get settings_title => 'Settings';

  @override
  String get reset_to_defaults => 'Reset to Defaults';

  @override
  String get ui_behavior_section => 'UI Behavior';

  @override
  String get show_save_icon_always_title => 'Always Show Save Icon';

  @override
  String get show_save_icon_always_description =>
      'When enabled, the save icon is always visible. When disabled, it only appears when there are unsaved changes.';

  @override
  String get map_compass_section => 'Map & Compass';

  @override
  String get angle_to_red_threshold_title => 'Angle to Red Threshold';

  @override
  String get angle_to_red_threshold_description =>
      'The angle threshold (in degrees) at which the compass angle indicator changes from green to red. Lower values make the indicator more sensitive.';

  @override
  String get threshold_degrees => 'Threshold (degrees)';

  @override
  String get angle_threshold_legend => 'Green: Good angle | Red: Poor angle';

  @override
  String get information_section => 'Information';

  @override
  String get settings_info_title => 'About Settings';

  @override
  String get settings_info_description =>
      'These settings are stored locally on your device and will persist between app sessions. Changes take effect immediately.';

  @override
  String get settings_saved_successfully => 'Settings saved successfully';

  @override
  String error_saving_settings(String error) {
    return 'Error saving settings: $error';
  }

  @override
  String get settings_reset_to_defaults => 'Settings reset to defaults';

  @override
  String error_resetting_settings(String error) {
    return 'Error resetting settings: $error';
  }

  @override
  String get map_display_section => 'Map Display';

  @override
  String get show_all_projects_on_map_title => 'Show All Projects on Map';

  @override
  String get show_all_projects_on_map_description =>
      'When enabled, all projects will be displayed on the map as grey markers and lines. When disabled, only the current project is shown.';

  @override
  String get bleScreenTitle => 'Bluetooth Devices';

  @override
  String get bleButtonStartScan => 'Start Scan';

  @override
  String get bleButtonStopScan => 'Stop Scan';

  @override
  String get bleButtonConnect => 'Connect';

  @override
  String get bleButtonDisconnect => 'Disconnect';

  @override
  String get bleButtonRequestMtu => 'Request MTU';

  @override
  String get bleScanStarted => 'Scan started...';

  @override
  String get bleScanStopped => 'Scan stopped.';

  @override
  String get bleScanError => 'Error starting scan';

  @override
  String bleConnecting(String deviceName) {
    return 'Connecting to $deviceName...';
  }

  @override
  String get bleConnectionError => 'Connection error';

  @override
  String get bleDisconnected => 'Device disconnected.';

  @override
  String get bleMtuRequested => 'MTU requested.';

  @override
  String get bleConnectionStatus => 'Connection Status';

  @override
  String get bleStatusConnected => 'Connected';

  @override
  String get bleStatusConnecting => 'Connecting...';

  @override
  String get bleStatusError => 'Connection Error';

  @override
  String get bleStatusWaiting => 'Waiting...';

  @override
  String get bleStatusDisconnected => 'Disconnected';

  @override
  String bleConnectedDevice(String deviceName) {
    return 'Device: $deviceName';
  }

  @override
  String get bleNoDevicesFound =>
      'No devices found.\nStart scanning to discover devices.';

  @override
  String get bleUnknownDevice => 'Unknown Device';

  @override
  String get bleDeviceDetails => 'Device Details';

  @override
  String get bleDeviceName => 'Name';

  @override
  String get bleDeviceId => 'Device ID';

  @override
  String get bleRssi => 'RSSI';

  @override
  String get bleAdvertisedName => 'Advertised Name';

  @override
  String get bleConnectable => 'Connectable';

  @override
  String get bleServiceUuids => 'Service UUIDs:';

  @override
  String get bleNotAvailable => 'N/A';

  @override
  String get bleYes => 'Yes';

  @override
  String get bleNo => 'No';

  @override
  String get bluetooth_permission_title => 'Bluetooth Permission';

  @override
  String get bluetooth_permission_description =>
      'Bluetooth and location permissions are needed to scan and connect to BLE devices.';

  @override
  String get ble_devices_section => 'Bluetooth Devices';

  @override
  String get ble_devices_title => 'Bluetooth Devices';

  @override
  String get ble_devices_description =>
      'Scan and connect to Bluetooth Low Energy devices';

  @override
  String get bleGpsDataTitle => 'GPS Data from RTK Receiver';

  @override
  String get bleGpsLatitude => 'Latitude';

  @override
  String get bleGpsLongitude => 'Longitude';

  @override
  String get bleGpsAltitude => 'Altitude';

  @override
  String get bleGpsAccuracy => 'Accuracy';

  @override
  String get bleGpsSatellites => 'Satellites';

  @override
  String get bleGpsHdop => 'HDOP';

  @override
  String get bleGpsFixQuality => 'Fix Quality';

  @override
  String get bleGpsSpeed => 'Speed';

  @override
  String get bleGpsUpdated => 'Updated:';

  @override
  String get bleGpsFixQualityInvalid => 'Invalid';

  @override
  String get bleGpsFixQualityGps => 'GPS Fix';

  @override
  String get bleGpsFixQualityDgps => 'DGPS Fix';

  @override
  String get bleGpsFixQualityPps => 'PPS Fix';

  @override
  String get bleGpsFixQualityRtk => 'RTK Fix';

  @override
  String get bleGpsFixQualityRtkFloat => 'RTK Float';

  @override
  String get bleGpsFixQualityEstimated => 'Estimated';

  @override
  String get bleGpsFixQualityManual => 'Manual';

  @override
  String get bleGpsFixQualitySimulation => 'Simulation';

  @override
  String bleGpsFixQualityUnknown(int quality) {
    return 'Unknown ($quality)';
  }

  @override
  String get bleGpsFixQualityExplanationTitle => 'Fix Quality Explanation';

  @override
  String get bleGpsFixQualityExplanation =>
      'Fix Quality indicates the type and reliability of GPS positioning:\n\n• 0 - Invalid: No position available\n• 1 - GPS Fix: Standard GPS (3-5m accuracy)\n• 2 - DGPS Fix: Differential GPS (1-3m accuracy)\n• 3 - PPS Fix: Precise Positioning Service\n• 4 - RTK Fix: Real-Time Kinematic with fixed ambiguity (1-5cm accuracy) - BEST\n• 5 - RTK Float: RTK without fixed ambiguity (10-50cm accuracy)\n• 6 - Estimated: Estimated position\n• 7 - Manual: Manually entered\n• 8 - Simulation: Test data';

  @override
  String get bleReceivingData => 'Receiving data...';

  @override
  String get bleNtripTitle => 'NTRIP Corrections';

  @override
  String get bleNtripConnected => 'Connected';

  @override
  String get bleNtripConnecting => 'Connecting...';

  @override
  String get bleNtripError => 'Error';

  @override
  String get bleNtripDisconnected => 'Disconnected';

  @override
  String get bleNtripHost => 'NTRIP Caster Host';

  @override
  String get bleNtripPort => 'Port';

  @override
  String get bleNtripMountPoint => 'Mount Point';

  @override
  String get bleNtripUsername => 'Username (Email)';

  @override
  String get bleNtripPassword => 'Password';

  @override
  String get bleNtripConnect => 'Connect to NTRIP';

  @override
  String get bleNtripDisconnect => 'Disconnect';

  @override
  String get bleNtripForwarding => 'Forwarding RTCM corrections';

  @override
  String get bleNtripErrorHostRequired => 'NTRIP host is required';

  @override
  String get bleNtripErrorPortRequired => 'Port is required';

  @override
  String get bleNtripErrorInvalidPort => 'Invalid port number';

  @override
  String get bleNtripErrorMountPointRequired => 'Mount point is required';

  @override
  String get bleNtripErrorUsernameRequired => 'Username (email) is required';

  @override
  String get bleNtripConnectedSuccess => 'Connected to NTRIP caster';

  @override
  String get bleNtripDisconnectedSuccess => 'Disconnected from NTRIP caster';

  @override
  String get bleNtripConnectionFailed => 'Failed to connect to NTRIP caster';
}
