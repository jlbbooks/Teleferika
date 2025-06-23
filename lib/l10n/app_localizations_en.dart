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
  String pointFromCompassDefaultNote(String heading) {
    return 'Point from Compass (H: $heading°)';
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
}
