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
  String get azimuthSavedSnackbar => 'Azimut salvato con successo.';

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
  String get export_project_data_title => 'Esporta dati progetto';

  @override
  String export_page_project_name_label(String projectName) {
    return 'Progetto: $projectName';
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
      other: '$countString punti trovati.',
      one: '$countString punto trovato.',
      zero: 'Nessun punto trovato per l\'esportazione.',
    );
    return '$_temp0';
  }

  @override
  String get export_page_select_format_label =>
      'Seleziona formato di esportazione:';

  @override
  String get export_format_dropdown_label => 'Formato';

  @override
  String get export_page_share_button => 'Condividi file';

  @override
  String get export_page_save_locally_button => 'Salva localmente';

  @override
  String get export_failed => 'Esportazione fallita. Riprova.';

  @override
  String get file_shared_successfully => 'File pronto per la condivisione.';

  @override
  String get file_saved_successfully => 'File salvato con successo';

  @override
  String get file_save_cancelled_or_failed =>
      'Salvataggio file annullato o fallito.';

  @override
  String get export_project_data_tooltip => 'Esporta dati progetto';

  @override
  String get unsaved_changes_title => 'Modifiche non salvate';

  @override
  String get unsaved_changes_export_message =>
      'Hai modifiche non salvate. Salva il progetto prima di esportare per assicurarti che tutti i dati siano inclusi.';

  @override
  String get save_button_label => 'Salva';

  @override
  String get dialog_cancel => 'Annulla';

  @override
  String get project_not_loaded_cannot_export =>
      'Progetto non caricato. Impossibile esportare i dati.';

  @override
  String get error_loading_points =>
      'Errore durante il caricamento dei punti per l\'esportazione. Riprova.';

  @override
  String get export_page_note_text =>
      'Nota: assicurati di aver concesso le autorizzazioni di archiviazione necessarie se salvi localmente su dispositivi mobili. Alcuni formati di esportazione potrebbero non includere tutti i tipi di dati (es. immagini).';

  @override
  String get please_save_project_first_to_export =>
      'Salva prima il nuovo progetto per abilitare l\'esportazione.';

  @override
  String get export_requires_licence_title =>
      'Licenza richiesta per l\'esportazione';

  @override
  String get export_requires_licence_message =>
      'Questa funzione richiede una licenza attiva. Importa un file di licenza valido per procedere.';

  @override
  String get action_import_licence => 'Importa licenza';

  @override
  String get edit_project_title => 'Modifica progetto';

  @override
  String edit_project_title_named(String projectName) {
    return 'Modifica progetto: $projectName';
  }

  @override
  String get new_project_title => 'Nuovo progetto';

  @override
  String get delete_project_tooltip => 'Elimina progetto';

  @override
  String get save_project_tooltip => 'Salva progetto';

  @override
  String last_updated_label(String date) {
    return 'Ultimo aggiornamento: $date';
  }

  @override
  String get not_yet_saved_label => 'Non ancora salvato';

  @override
  String get tap_to_set_date => 'Tocca per impostare la data';

  @override
  String get invalid_number_validator => 'Inserisci un numero valido.';

  @override
  String get must_be_359_validator =>
      'Il valore deve essere compreso tra 0 e 359.';

  @override
  String get please_correct_form_errors => 'Correggi gli errori nel modulo.';

  @override
  String get project_created_successfully => 'Progetto creato con successo.';

  @override
  String get project_already_up_to_date => 'Il progetto è già aggiornato.';

  @override
  String get cannot_delete_unsaved_project =>
      'Impossibile eliminare un progetto non salvato.';

  @override
  String get confirm_delete_project_title => 'Conferma eliminazione progetto';

  @override
  String confirm_delete_project_content(Object projectName) {
    return 'Sei sicuro di voler eliminare questo progetto? Questa azione non può essere annullata.';
  }

  @override
  String get project_deleted_successfully => 'Progetto eliminato con successo.';

  @override
  String get project_not_found_or_deleted =>
      'Progetto non trovato o già eliminato.';

  @override
  String error_saving_project(String errorMessage) {
    return 'Errore durante il salvataggio del progetto: $errorMessage';
  }

  @override
  String error_deleting_project(String errorMessage) {
    return 'Errore durante l\'eliminazione del progetto: $errorMessage';
  }

  @override
  String get unsaved_changes_dialog_title => 'Modifiche non salvate';

  @override
  String get unsaved_changes_dialog_content =>
      'Hai modifiche non salvate. Vuoi scartarle e uscire?';

  @override
  String get discard_button_label => 'Scarta';

  @override
  String get details_tab_label => 'Dettagli';

  @override
  String get points_tab_label => 'Punti';

  @override
  String get compass_tab_label => 'Bussola';

  @override
  String get map_tab_label => 'Mappa';

  @override
  String get export_page_title => 'Esporta progetto';

  @override
  String get export_page_description =>
      'Scegli il formato e le opzioni per esportare i dati del progetto.';

  @override
  String get export_format_csv => 'CSV (valori separati da virgola)';

  @override
  String get export_format_kml => 'KML (Google Earth)';

  @override
  String get export_format_geojson => 'GeoJSON';

  @override
  String get unsaved_changes_discard_message =>
      'Hai modifiche non salvate. Scartarle e uscire?';

  @override
  String get unsaved_changes_discard_button => 'Scarta modifiche';

  @override
  String get unsaved_changes_save_button => 'Salva modifiche';

  @override
  String get export_page_no_points =>
      'Nessun punto disponibile per l\'esportazione.';

  @override
  String mapErrorLoadingPoints(String errorMessage) {
    return 'Errore durante il caricamento dei punti sulla mappa: $errorMessage';
  }

  @override
  String mapPointMovedSuccessfully(String ordinalNumber) {
    return 'Punto P$ordinalNumber spostato con successo!';
  }

  @override
  String mapErrorMovingPoint(String ordinalNumber) {
    return 'Errore: Impossibile spostare il punto P$ordinalNumber. Punto non trovato o non aggiornato.';
  }

  @override
  String mapErrorMovingPointGeneric(String ordinalNumber, String errorMessage) {
    return 'Errore durante lo spostamento del punto P$ordinalNumber: $errorMessage';
  }

  @override
  String get mapTooltipMovePoint => 'Sposta Punto';

  @override
  String get mapTooltipSaveChanges => 'Salva Modifiche';

  @override
  String get mapTooltipCancelMove => 'Annulla Spostamento';

  @override
  String get mapTooltipEditPointDetails => 'Modifica Dettagli';

  @override
  String get mapTooltipAddPointFromCompass =>
      'Aggiungi Punto alla Posizione Corrente (da Bussola)';

  @override
  String get mapNoPointsToDisplay =>
      'Nessun punto da visualizzare sulla mappa.';

  @override
  String get mapLocationPermissionDenied =>
      'Permesso di localizzazione negato. Le funzionalità della mappa che richiedono la posizione saranno limitate.';

  @override
  String get mapSensorPermissionDenied =>
      'Permesso sensore (bussola) negato. Le funzionalità di orientamento del dispositivo non saranno disponibili.';

  @override
  String mapErrorGettingLocationUpdates(String errorMessage) {
    return 'Errore durante l\'ottenimento degli aggiornamenti sulla posizione: $errorMessage';
  }

  @override
  String mapErrorGettingCompassUpdates(String errorMessage) {
    return 'Errore durante l\'ottenimento degli aggiornamenti della bussola: $errorMessage';
  }

  @override
  String get mapLoadingPointsIndicator => 'Caricamento punti...';

  @override
  String get mapPermissionsRequiredTitle => 'Permessi Richiesti';

  @override
  String get mapLocationPermissionInfoText =>
      'Il permesso di localizzazione è necessario per mostrare la tua posizione attuale e per alcune funzionalità della mappa.';

  @override
  String get mapSensorPermissionInfoText =>
      'Il permesso del sensore (bussola) è necessario per le funzionalità basate sulla direzione.';

  @override
  String get mapButtonOpenAppSettings => 'Apri Impostazioni App';

  @override
  String get mapButtonRetryPermissions => 'Riprova Permessi';

  @override
  String get mapDeletePointDialogTitle => 'Conferma Eliminazione';

  @override
  String mapDeletePointDialogContent(String pointOrdinalNumber) {
    return 'Sei sicuro di voler eliminare il punto P$pointOrdinalNumber?';
  }

  @override
  String get mapDeletePointDialogCancelButton => 'Annulla';

  @override
  String get mapDeletePointDialogDeleteButton => 'Elimina';

  @override
  String mapPointDeletedSuccessSnackbar(String pointOrdinalNumber) {
    return 'Punto P$pointOrdinalNumber eliminato.';
  }

  @override
  String mapErrorPointNotFoundOrDeletedSnackbar(String pointOrdinalNumber) {
    return 'Errore: Impossibile trovare o eliminare il punto P$pointOrdinalNumber dalla vista mappa.';
  }

  @override
  String mapErrorDeletingPointSnackbar(
    String pointOrdinalNumber,
    String errorMessage,
  ) {
    return 'Errore durante l\'eliminazione del punto P$pointOrdinalNumber: $errorMessage';
  }

  @override
  String get compassHeadingNotAvailable =>
      'Impossibile aggiungere punto: direzione bussola non disponibile.';

  @override
  String projectAzimuthLabel(String azimuth) {
    return 'Azimut Progetto: $azimuth°';
  }

  @override
  String get projectAzimuthRequiresPoints =>
      'Azimut Progetto: (Richiede almeno 2 punti)';

  @override
  String get projectAzimuthNotCalculated =>
      'Azimut Progetto: Non ancora calcolato';

  @override
  String get compassAccuracyHigh => 'Alta Precisione';

  @override
  String get compassAccuracyMedium => 'Precisione Media';

  @override
  String get compassAccuracyLow => 'Bassa Precisione';

  @override
  String get compassPermissionsRequired => 'Permessi Richiesti';

  @override
  String get compassPermissionsMessage =>
      'Questo strumento richiede i permessi di sensore e localizzazione per funzionare correttamente. Concedili nelle impostazioni del dispositivo.';

  @override
  String get openSettingsButton => 'Apri Impostazioni';

  @override
  String get retryButton => 'Riprova';

  @override
  String get mapAcquiringLocation => 'Acquisizione posizione...';

  @override
  String get mapCenterOnLocation => 'Centra sulla mia posizione';

  @override
  String get mapAddNewPoint => 'Aggiungi Nuovo Punto';

  @override
  String get mapCenterOnPoints => 'Centra sui punti';
}
