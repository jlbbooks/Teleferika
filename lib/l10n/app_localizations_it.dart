// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class SIt extends S {
  SIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'TeleferiKa';

  @override
  String loadingScreenMessage(String appName) {
    return 'Caricamento $appName...';
  }

  @override
  String get projectPageTitle => 'Dettagli Progetto';

  @override
  String get tabDetails => 'Dettagli';

  @override
  String get tabPoints => 'Punti';

  @override
  String get tabCompass => 'Bussola';

  @override
  String get tabMap => 'Mappa';

  @override
  String get formFieldNameLabel => 'Nome Progetto';

  @override
  String get formFieldNoteLabel => 'Note';

  @override
  String get formFieldAzimuthLabel => 'Azimut (°)';

  @override
  String get formFieldProjectDateLabel => 'Data Progetto';

  @override
  String get formFieldLastUpdatedLabel => 'Ultimo Aggiornamento';

  @override
  String get buttonSave => 'Salva';

  @override
  String get buttonCalculateAzimuth => 'Calcola Azimut';

  @override
  String get buttonCalculate => 'Calcola';

  @override
  String get buttonSelectDate => 'Seleziona Data';

  @override
  String get compassAddPointButton => 'Aggiungi Punto';

  @override
  String get compassAddAsEndPointButton => 'Aggiungi come Fine';

  @override
  String get pointsSetAsStartButton => 'Imposta come Inizio';

  @override
  String get pointsSetAsEndButton => 'Imposta come Fine';

  @override
  String get pointsDeleteButton => 'Elimina';

  @override
  String get errorSaveProjectBeforeAddingPoints =>
      'Salvare il progetto prima di aggiungere punti.';

  @override
  String get infoFetchingLocation => 'Recupero posizione...';

  @override
  String pointAddedSnackbar(String ordinalNumber) {
    return 'Punto P$ordinalNumber aggiunto.';
  }

  @override
  String get pointAddedSetAsEndSnackbarSuffix => 'Impostato come punto FINALE.';

  @override
  String get pointAddedInsertedBeforeEndSnackbarSuffix =>
      'Inserito prima del punto finale corrente.';

  @override
  String pointFromCompassDefaultNote(String altitude) {
    return 'Punto da Bussola (A: $altitude°)';
  }

  @override
  String errorAddingPoint(String errorMessage) {
    return 'Errore durante l\'aggiunta del punto: $errorMessage';
  }

  @override
  String errorLoadingProjectDetails(String errorMessage) {
    return 'Errore durante il caricamento dei dettagli del progetto: $errorMessage';
  }

  @override
  String get errorAzimuthPointsNotSet =>
      'Punto iniziale e/o finale non impostato. Impossibile calcolare l\'azimut.';

  @override
  String get errorAzimuthPointsSame =>
      'I punti iniziale e finale sono uguali. L\'azimut è indefinito o 0.';

  @override
  String get errorAzimuthCouldNotRetrievePoints =>
      'Impossibile recuperare i dati dei punti per il calcolo. Controllare i punti.';

  @override
  String errorCalculatingAzimuth(String errorMessage) {
    return 'Errore durante il calcolo dell\'azimut: $errorMessage';
  }

  @override
  String azimuthCalculatedSnackbar(String azimuthValue) {
    return 'Azimut calcolato: $azimuthValue°';
  }

  @override
  String get projectNameCannotBeEmptyValidator =>
      'Il nome del progetto non può essere vuoto.';

  @override
  String get projectSavedSuccessfully => 'Progetto salvato con successo.';

  @override
  String get dialogTitleConfirmDelete => 'Conferma Eliminazione';

  @override
  String dialogContentConfirmDeletePoint(String pointOrdinal) {
    return 'Sei sicuro di voler eliminare il punto P$pointOrdinal? Questa azione non può essere annullata.';
  }

  @override
  String get buttonCancel => 'Annulla';

  @override
  String get buttonDelete => 'Elimina';

  @override
  String pointDeletedSnackbar(String pointOrdinal) {
    return 'Punto P$pointOrdinal eliminato.';
  }

  @override
  String pointSetAsStartSnackbar(String pointOrdinal) {
    return 'Punto P$pointOrdinal impostato come inizio.';
  }

  @override
  String pointSetAsEndSnackbar(String pointOrdinal) {
    return 'Punto P$pointOrdinal impostato come fine.';
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
