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
}
