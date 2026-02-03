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
  String get formFieldPresumedTotalLengthLabel =>
      'Lunghezza totale presunta (m)';

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
  String get azimuthOverwriteTitle => 'Sovrascrivere l\'azimut?';

  @override
  String get azimuthOverwriteMessage =>
      'Il campo azimut ha già un valore. Il nuovo valore calcolato sovrascriverà quello attuale. Vuoi continuare?';

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
  String get export_project_tooltip => 'Esporta progetto';

  @override
  String get errorExportNoPoints => 'Nessun punto da esportare';

  @override
  String get infoExporting => 'Esportazione in corso...';

  @override
  String get exportSuccess => 'Progetto esportato con successo';

  @override
  String get exportError => 'Esportazione fallita';

  @override
  String exportErrorWithDetails(String errorMessage) {
    return 'Errore di esportazione: $errorMessage';
  }

  @override
  String get exportRequiresValidLicence =>
      'Licenza valida richiesta per l\'esportazione';

  @override
  String get mapDownloadRequiresValidLicence =>
      'Licenza valida richiesta per il download delle mappe';

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
    return 'Aggiornato: $date';
  }

  @override
  String get no_updates => 'Nessun aggiornamento';

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
  String confirm_delete_project_content(String projectName) {
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

  @override
  String mapTypeName(String mapType) {
    return '$mapType';
  }

  @override
  String get mapTypeSelector => 'Tipo Mappa';

  @override
  String get must_be_positive_validator => 'Deve essere positivo.';

  @override
  String get mapNewPointLabel => 'NUOVO';

  @override
  String get mapSaveNewPoint => 'Salva';

  @override
  String get mapDiscardNewPoint => 'Scarta';

  @override
  String get mapNewPointSaved => 'Nuovo punto salvato con successo!';

  @override
  String mapErrorSavingNewPoint(String errorMessage) {
    return 'Errore durante il salvataggio del nuovo punto: $errorMessage';
  }

  @override
  String get mapUnsavedPointExists =>
      'Hai un punto non salvato. Salvalo o scartalo prima di aggiungerne un altro.';

  @override
  String get mapCompassDirectionTooltip => 'Direzione Bussola';

  @override
  String get mapCompassNorthIndicator => 'Nord';

  @override
  String get errorLocationUnavailable => 'Posizione non disponibile.';

  @override
  String get infoPointAddedPendingSave =>
      'Punto aggiunto (in attesa di salvataggio)';

  @override
  String get errorGeneric => 'Errore';

  @override
  String get edit_point_title => 'Modifica Punto';

  @override
  String get coordinates_section_title => 'Coordinate';

  @override
  String get latitude_label => 'Latitudine';

  @override
  String get latitude_hint => 'es. 45.12345';

  @override
  String get latitude_empty_validator => 'La latitudine non può essere vuota';

  @override
  String get latitude_invalid_validator => 'Formato numero non valido';

  @override
  String get latitude_range_validator =>
      'La latitudine deve essere tra -90 e 90';

  @override
  String get longitude_label => 'Longitudine';

  @override
  String get longitude_hint => 'es. -12.54321';

  @override
  String get longitude_empty_validator => 'La longitudine non può essere vuota';

  @override
  String get longitude_invalid_validator => 'Formato numero non valido';

  @override
  String get longitude_range_validator =>
      'La longitudine deve essere tra -180 e 180';

  @override
  String get additional_data_section_title => 'Dati aggiuntivi';

  @override
  String get altitude_label => 'Altitudine (m)';

  @override
  String get altitude_hint => 'es. 1203.5 (Opzionale)';

  @override
  String get altitude_invalid_validator => 'Formato numero non valido';

  @override
  String get altitude_range_validator =>
      'L\'altitudine deve essere tra -1000 e 8849 metri';

  @override
  String get note_label => 'Note (Opzionale)';

  @override
  String get note_hint => 'Osservazioni o dettagli...';

  @override
  String get photos_section_title => 'Foto';

  @override
  String get unsaved_point_details_title => 'Modifiche non salvate';

  @override
  String get unsaved_point_details_content =>
      'Hai modifiche non salvate ai dettagli del punto. Vuoi salvarle?';

  @override
  String get discard_text_changes => 'Scarta modifiche testo';

  @override
  String get save_all_and_exit => 'Salva tutto ed esci';

  @override
  String get confirm_deletion_title => 'Conferma eliminazione';

  @override
  String get point_details_saved => 'Dettagli punto salvati!';

  @override
  String get undo_changes_tooltip => 'Annulla modifiche';

  @override
  String get no_projects_yet =>
      'Nessun progetto ancora. Tocca \'+\' per aggiungerne uno!';

  @override
  String get add_new_project_tooltip => 'Aggiungi nuovo progetto';

  @override
  String get untitled_project => 'Progetto senza titolo';

  @override
  String get delete_selected => 'Elimina selezionati';

  @override
  String get delete_projects_title => 'Eliminare progetti?';

  @override
  String get license_information_title => 'Informazioni licenza';

  @override
  String get close_button => 'Chiudi';

  @override
  String get import_new_licence => 'Importa nuova licenza';

  @override
  String get import_licence => 'Importa licenza';

  @override
  String get request_new_license => 'Richiedi Nuova Licenza';

  @override
  String get premium_features_title => 'Funzionalità Premium';

  @override
  String get premium_features_available =>
      'Le funzionalità premium sono disponibili in questa versione!';

  @override
  String get available_features => 'Funzionalità disponibili:';

  @override
  String get premium_features_not_available =>
      'Le funzionalità premium non sono disponibili in questa versione.';

  @override
  String get opensource_version =>
      'Questa è la versione open source dell\'app.';

  @override
  String get try_feature => 'Prova funzionalità';

  @override
  String get install_demo_license => 'Installa licenza demo';

  @override
  String get clear_license => 'Cancella licenza';

  @override
  String get invalid_latitude_or_longitude_format =>
      'Formato latitudine o longitudine non valido.';

  @override
  String get invalid_altitude_format =>
      'Formato altitudine non valido. Inserisci un numero o lascia vuoto.';

  @override
  String get coordinates => 'Coordinate';

  @override
  String get lat => 'Lat:';

  @override
  String get lon => 'Lon:';

  @override
  String get addANote => 'Aggiungi una nota...';

  @override
  String get tapToAddNote => 'Tocca per aggiungere una nota...';

  @override
  String get save => 'Salva';

  @override
  String get discard => 'Scarta';

  @override
  String get edit => 'Modifica';

  @override
  String get move => 'Sposta';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get tapOnTheMapToSetNewLocation =>
      'Tocca sulla mappa per impostare la nuova posizione';

  @override
  String get locationPermissionTitle => 'Permesso di localizzazione';

  @override
  String get sensorPermissionTitle => 'Permesso sensore';

  @override
  String get noNote => 'Nessuna nota';

  @override
  String distanceFromPrevious(String pointName) {
    return 'Distanza da $pointName:';
  }

  @override
  String get offsetLabel => 'Scostamento:';

  @override
  String get angleLabel => 'Angolo:';

  @override
  String get delete_photo_title => 'Eliminare foto?';

  @override
  String delete_photo_content(String photoNumber) {
    return 'Sei sicuro di voler eliminare $photoNumber foto?';
  }

  @override
  String get camera_permission_title => 'Permesso fotocamera';

  @override
  String get camera_permission_description =>
      'Il permesso fotocamera è necessario per scattare foto.';

  @override
  String get microphone_permission_title => 'Permesso microfono';

  @override
  String get microphone_permission_description =>
      'Il permesso microfono è necessario per registrare audio.';

  @override
  String get storage_permission_title => 'Permesso archiviazione';

  @override
  String get storage_permission_description =>
      'Il permesso archiviazione è necessario per salvare file.';

  @override
  String get current_rope_length_label => 'Lunghezza attuale della fune';

  @override
  String get unit_meter => 'm';

  @override
  String get unit_kilometer => 'km';

  @override
  String point_deleted_pending_save(String pointName) {
    return 'Punto $pointName eliminato (in attesa di salvataggio).';
  }

  @override
  String error_deleting_point_generic(String pointName, String errorMessage) {
    return 'Errore durante l\'eliminazione del punto $pointName: $errorMessage';
  }

  @override
  String get compass_calibration_notice =>
      'Il sensore bussola necessita di calibrazione. Muovi il dispositivo a forma di 8.';

  @override
  String get project_statistics_title => 'Statistiche Progetto';

  @override
  String get project_statistics_points => 'Punti';

  @override
  String get project_statistics_images => 'Immagini';

  @override
  String get project_statistics_current_length => 'Lunghezza Attuale';

  @override
  String get project_statistics_measurements => 'Misurazioni';

  @override
  String get points_list_title => 'Elenco Punti';

  @override
  String get photo_manager_title => 'Foto';

  @override
  String get photo_manager_no_photos => 'Nessuna foto ancora.';

  @override
  String photo_manager_gallery(String platform) {
    String _temp0 = intl.Intl.selectLogic(platform, {
      'android': 'Galleria',
      'ios': 'Foto',
      'other': 'Galleria',
    });
    return '$_temp0';
  }

  @override
  String get photo_manager_camera => 'Fotocamera';

  @override
  String get photo_manager_add_photo_tooltip => 'Aggiungi foto';

  @override
  String get photo_manager_photo_deleted => 'Foto eliminata';

  @override
  String get photo_manager_photo_changes_saved =>
      'Modifiche alle foto salvate automaticamente.';

  @override
  String photo_manager_error_saving_photo_changes(String errorMessage) {
    return 'Errore durante il salvataggio delle modifiche alle foto: $errorMessage';
  }

  @override
  String photo_manager_error_saving_image(String errorMessage) {
    return 'Errore durante il salvataggio dell\'immagine: $errorMessage';
  }

  @override
  String photo_manager_error_picking_image(String errorMessage) {
    return 'Errore durante la selezione dell\'immagine: $errorMessage';
  }

  @override
  String photo_manager_error_deleting_photo(String errorMessage) {
    return 'Errore durante l\'eliminazione della foto: $errorMessage';
  }

  @override
  String get photo_manager_wait_saving =>
      'Attendere, salvataggio foto in corso...';

  @override
  String app_version_label(String version) {
    return 'Versione app: $version';
  }

  @override
  String licence_active_content(String email, String validUntil) {
    return 'Licenza a: $email\nStato: Attiva\nValida fino a: $validUntil';
  }

  @override
  String licence_expired_content(String email, String validUntil) {
    return 'Licenza a: $email\nStato: Scaduta\nValida fino a: $validUntil\n\nImporta una licenza valida.';
  }

  @override
  String get licence_none_content =>
      'Nessuna licenza attiva trovata. Importa un file di licenza per sbloccare le funzionalità premium.';

  @override
  String licence_status(String status) {
    return 'Stato licenza: $status';
  }

  @override
  String feature_demo_failed(String error) {
    return 'Dimostrazione funzionalità fallita: $error';
  }

  @override
  String licence_imported_successfully(String email) {
    return 'Licenza per $email importata con successo!';
  }

  @override
  String get licence_import_cancelled =>
      'Importazione licenza annullata o fallita.';

  @override
  String get demo_license_imported_successfully =>
      'Licenza demo importata con successo!';

  @override
  String get license_cleared_successfully => 'Licenza rimossa con successo!';

  @override
  String confirm_deletion_content(String pointName) {
    return 'Sei sicuro di voler eliminare il punto $pointName? Questa azione non può essere annullata.';
  }

  @override
  String point_deleted_success(String pointName) {
    return 'Punto $pointName eliminato con successo!';
  }

  @override
  String error_deleting_point(String pointName, String errorMessage) {
    return 'Errore durante l\'eliminazione del punto $pointName: $errorMessage';
  }

  @override
  String error_saving_point(String errorMessage) {
    return 'Errore durante il salvataggio del punto: $errorMessage';
  }

  @override
  String selected_count(int count) {
    return '$count selezionati';
  }

  @override
  String delete_projects_content(int count) {
    return 'Sei sicuro di voler eliminare $count progetti selezionati? Questa azione non può essere annullata.';
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
  String get project_label_prefix => 'Progetto: ';

  @override
  String get gpsPrecisionLabel => 'Precisione GPS:';

  @override
  String get pointDetailsSectionTitle => 'Dettagli Punto';

  @override
  String get no_license_to_clear => 'Nessuna licenza installata da rimuovere.';

  @override
  String get enhanced_licence_test_results => 'Risultati Test Licenza Avanzata';

  @override
  String get email_label => 'Email:';

  @override
  String get valid_until_label => 'Valida fino a:';

  @override
  String get features_label => 'Funzionalità:';

  @override
  String get algorithm_label => 'Algoritmo:';

  @override
  String get has_export_feature_label => 'Ha funzionalità di esportazione:';

  @override
  String get is_valid_label => 'È valida:';

  @override
  String get device_fingerprint_title => 'Impronta Digitale Dispositivo';

  @override
  String get fingerprint_label => 'Impronta digitale:';

  @override
  String get device_info_label => 'Informazioni Dispositivo:';

  @override
  String get copy_button => 'Copia';

  @override
  String get license_status_label => 'Stato Licenza';

  @override
  String get test_enhanced_licence => 'Test Licenza Avanzata';

  @override
  String get generate_device_fingerprint =>
      'Genera Impronta Digitale Dispositivo';

  @override
  String get test_licence_validation => 'Test Validazione Licenza';

  @override
  String error_importing_licence(String error) {
    return 'Errore durante l\'importazione della licenza: $error';
  }

  @override
  String error_importing_demo_license(String error) {
    return 'Errore durante l\'importazione della licenza demo: $error';
  }

  @override
  String error_clearing_license(String error) {
    return 'Errore durante la rimozione della licenza: $error';
  }

  @override
  String get failed_to_save_enhanced_licence =>
      'Impossibile salvare la licenza avanzata';

  @override
  String enhanced_licence_test_failed(String error) {
    return 'Test licenza avanzata fallito: $error';
  }

  @override
  String get fingerprint_copied_to_clipboard =>
      'Impronta digitale copiata negli appunti';

  @override
  String failed_to_generate_fingerprint(String error) {
    return 'Impossibile generare l\'impronta digitale: $error';
  }

  @override
  String get invalid_licence_accepted_error =>
      'Licenza non valida accettata - questo è sbagliato!';

  @override
  String invalid_licence_correctly_rejected(String code) {
    return 'Licenza non valida correttamente rifiutata: $code';
  }

  @override
  String unexpected_error(String error) {
    return 'Errore imprevisto: $error';
  }

  @override
  String validation_test_failed(String error) {
    return 'Test di validazione fallito: $error';
  }

  @override
  String get refresh_status => 'Aggiorna stato';

  @override
  String get request_license => 'Richiedi licenza';

  @override
  String get cancel_button => 'Annulla';

  @override
  String get request_button => 'Richiedi';

  @override
  String get license_requested => 'Licenza richiesta';

  @override
  String get license_expired => 'Licenza scaduta';

  @override
  String get license_expiring_soon => 'Licenza in scadenza';

  @override
  String get license_active => 'Licenza attiva';

  @override
  String get license_pending_approval_message =>
      'La tua richiesta di licenza è in attesa di approvazione. Riceverai una notifica quando sarà approvata o negata.';

  @override
  String get license_expired_message =>
      'Questa licenza è scaduta e deve essere rinnovata. Puoi richiedere una nuova licenza o importarne una esistente.';

  @override
  String get license_expiring_soon_message =>
      'Questa licenza scadrà presto. Considera di richiedere una nuova licenza o importarne una esistente.';

  @override
  String get license_details => 'Dettagli licenza';

  @override
  String get issued_label => 'Emessa';

  @override
  String get max_devices_label => 'Dispositivi massimi';

  @override
  String get version_label => 'Versione';

  @override
  String get requested_features => 'Funzionalità richieste';

  @override
  String get technical_details => 'Dettagli tecnici';

  @override
  String get data_hash => 'Hash dati';

  @override
  String get no_license_found => 'Nessuna licenza trovata';

  @override
  String get no_active_license_message =>
      'Nessuna licenza attiva trovata. Puoi importare un file di licenza esistente o richiedere una nuova licenza dal server.';

  @override
  String get project_deleted => 'Progetto eliminato.';

  @override
  String get status_label => 'Stato';

  @override
  String get days_remaining_label => 'Giorni rimanenti';

  @override
  String get features_pending_approval =>
      'Le funzionalità saranno disponibili una volta che la licenza sarà approvata:';

  @override
  String get device_fingerprint => 'Impronta digitale dispositivo';

  @override
  String get app_information => 'Informazioni app';

  @override
  String get requested_features_label => 'Funzionalità richieste:';

  @override
  String get basic_export => 'Esportazione base';

  @override
  String get map_download => 'Scarica mappe';

  @override
  String get advanced_export => 'Esportazione avanzata';

  @override
  String get email_required => 'Email richiesta';

  @override
  String get select_at_least_one_feature => 'Seleziona almeno una funzionalità';

  @override
  String get your_email_example => 'tua.email@esempio.com';

  @override
  String get max_devices_hint => '1-5';

  @override
  String get days_suffix => 'giorni';

  @override
  String get download_offline_maps_tooltip => 'Scarica mappe offline';

  @override
  String license_imported_successfully(String email) {
    return 'Licenza per $email importata con successo!';
  }

  @override
  String get license_import_cancelled =>
      'Importazione licenza annullata o fallita.';

  @override
  String error_importing_license(String error) {
    return 'Errore nell\'importazione della licenza: $error';
  }

  @override
  String get project_deleted_message => 'Progetto eliminato.';

  @override
  String get install_development_license => 'Installa Licenza di Sviluppo';

  @override
  String get development_testing => 'Sviluppo e Test';

  @override
  String get settings_title => 'Impostazioni';

  @override
  String get reset_to_defaults => 'Ripristina Predefiniti';

  @override
  String get ui_behavior_section => 'Comportamento UI';

  @override
  String get show_save_icon_always_title => 'Mostra Sempre Icona Salva';

  @override
  String get show_save_icon_always_description =>
      'Quando abilitato, l\'icona salva è sempre visibile. Quando disabilitato, appare solo quando ci sono modifiche non salvate.';

  @override
  String get map_compass_section => 'Mappa e Bussola';

  @override
  String get angle_to_red_threshold_title => 'Soglia Angolo a Rosso';

  @override
  String get angle_to_red_threshold_description =>
      'La soglia dell\'angolo (in gradi) alla quale l\'indicatore dell\'angolo della bussola cambia da verde a rosso. Valori più bassi rendono l\'indicatore più sensibile.';

  @override
  String get threshold_degrees => 'Soglia (gradi)';

  @override
  String get angle_threshold_legend =>
      'Verde: Angolo buono | Rosso: Angolo scarso';

  @override
  String get information_section => 'Informazioni';

  @override
  String get settings_info_title => 'Informazioni Impostazioni';

  @override
  String get settings_info_description =>
      'Queste impostazioni sono memorizzate localmente sul tuo dispositivo e persisteranno tra le sessioni dell\'app. Le modifiche hanno effetto immediato.';

  @override
  String get settings_saved_successfully => 'Impostazioni salvate con successo';

  @override
  String error_saving_settings(String error) {
    return 'Errore nel salvataggio delle impostazioni: $error';
  }

  @override
  String get settings_reset_to_defaults =>
      'Impostazioni ripristinate ai predefiniti';

  @override
  String error_resetting_settings(String error) {
    return 'Errore nel ripristino delle impostazioni: $error';
  }

  @override
  String get map_display_section => 'Visualizzazione Mappa';

  @override
  String get show_all_projects_on_map_title =>
      'Mostra Tutti i Progetti sulla Mappa';

  @override
  String get show_all_projects_on_map_description =>
      'Quando abilitato, tutti i progetti saranno visualizzati sulla mappa come marcatori e linee grigie. Quando disabilitato, viene mostrato solo il progetto corrente.';

  @override
  String get show_ble_satellite_button_title => 'Show RTK Device Button';

  @override
  String get show_ble_satellite_button_description =>
      'When enabled, a satellite button appears on the map when connected to an RTK device. Tap it to view device information.';

  @override
  String get bleScreenTitle => 'Dispositivi Bluetooth';

  @override
  String get bleButtonStartScan => 'Avvia Scansione';

  @override
  String get bleButtonStopScan => 'Ferma Scansione';

  @override
  String get bleButtonConnect => 'Connetti';

  @override
  String get bleButtonDisconnect => 'Disconnetti';

  @override
  String get bleButtonRequestMtu => 'Richiedi MTU';

  @override
  String get bleScanStarted => 'Scansione avviata...';

  @override
  String get bleScanStopped => 'Scansione fermata.';

  @override
  String get bleScanError => 'Errore nell\'avvio della scansione';

  @override
  String bleConnecting(String deviceName) {
    return 'Connessione a $deviceName...';
  }

  @override
  String get bleConnectionError => 'Errore di connessione';

  @override
  String get bleDisconnected => 'Dispositivo disconnesso.';

  @override
  String get bleMtuRequested => 'MTU richiesto.';

  @override
  String get bleConnectionStatus => 'Stato Connessione';

  @override
  String get bleStatusConnected => 'Connesso';

  @override
  String get bleStatusConnecting => 'Connessione in corso...';

  @override
  String get bleStatusError => 'Errore di Connessione';

  @override
  String get bleStatusWaiting => 'In attesa...';

  @override
  String get bleStatusDisconnected => 'Disconnesso';

  @override
  String bleConnectedDevice(String deviceName) {
    return 'Dispositivo: $deviceName';
  }

  @override
  String get bleNoDevicesFound =>
      'Nessun dispositivo trovato.\nAvvia la scansione per scoprire i dispositivi.';

  @override
  String get bleUnknownDevice => 'Dispositivo Sconosciuto';

  @override
  String get bleDeviceDetails => 'Dettagli Dispositivo';

  @override
  String get bleDeviceName => 'Nome';

  @override
  String get bleDeviceId => 'ID Dispositivo';

  @override
  String get bleRssi => 'RSSI';

  @override
  String get bleAdvertisedName => 'Nome Pubblicizzato';

  @override
  String get bleConnectable => 'Connessibile';

  @override
  String get bleServiceUuids => 'UUID Servizi:';

  @override
  String get bleNotAvailable => 'N/D';

  @override
  String get bleYes => 'Sì';

  @override
  String get bleNo => 'No';

  @override
  String get bluetooth_permission_title => 'Permesso Bluetooth';

  @override
  String get bluetooth_permission_description =>
      'I permessi Bluetooth e posizione sono necessari per scansionare e connettersi ai dispositivi BLE.';

  @override
  String get ble_devices_section => 'Dispositivi Bluetooth';

  @override
  String get ble_devices_title => 'Dispositivi Bluetooth';

  @override
  String get ble_devices_description =>
      'Scansiona e connetti dispositivi Bluetooth Low Energy';

  @override
  String get bleGpsDataTitle => 'Dati GPS da Ricevitore RTK';

  @override
  String get bleGpsLatitude => 'Latitudine';

  @override
  String get bleGpsLongitude => 'Longitudine';

  @override
  String get bleGpsAltitude => 'Altitudine';

  @override
  String get bleGpsAccuracy => 'Precisione';

  @override
  String get bleGpsSatellites => 'Satelliti';

  @override
  String get bleGpsHdop => 'HDOP';

  @override
  String get bleGpsFixQuality => 'Qualità Fix';

  @override
  String get bleGpsSpeed => 'Velocità';

  @override
  String get bleGpsUpdated => 'Aggiornato:';

  @override
  String get bleGpsFixQualityInvalid => 'Non valido';

  @override
  String get bleGpsFixQualityGps => 'Fix GPS';

  @override
  String get bleGpsFixQualityDgps => 'Fix DGPS';

  @override
  String get bleGpsFixQualityPps => 'Fix PPS';

  @override
  String get bleGpsFixQualityRtk => 'Fix RTK';

  @override
  String get bleGpsFixQualityRtkFloat => 'RTK Float';

  @override
  String get bleGpsFixQualityEstimated => 'Stimato';

  @override
  String get bleGpsFixQualityManual => 'Manuale';

  @override
  String get bleGpsFixQualitySimulation => 'Simulazione';

  @override
  String bleGpsFixQualityUnknown(int quality) {
    return 'Sconosciuto ($quality)';
  }

  @override
  String get bleGpsFixQualityExplanationTitle => 'Spiegazione Qualità Fix';

  @override
  String get bleGpsFixQualityExplanation =>
      'La Qualità Fix indica il tipo e l\'affidabilità del posizionamento GPS:\n\n• 0 - Non valido: Nessuna posizione disponibile\n• 1 - Fix GPS: GPS standard (precisione 3-5m)\n• 2 - Fix DGPS: GPS differenziale (precisione 1-3m)\n• 3 - Fix PPS: Servizio di posizionamento preciso\n• 4 - Fix RTK: Cinematica in tempo reale con ambiguità risolta (precisione 1-5cm) - MIGLIORE\n• 5 - RTK Float: RTK senza ambiguità risolta (precisione 10-50cm)\n• 6 - Stimato: Posizione stimata\n• 7 - Manuale: Inserito manualmente\n• 8 - Simulazione: Dati di test';

  @override
  String get bleReceivingData => 'Ricezione dati...';

  @override
  String get bleNtripTitle => 'Correzioni NTRIP';

  @override
  String get bleNtripConnected => 'Connesso';

  @override
  String get bleNtripConnecting => 'Connessione...';

  @override
  String get bleNtripError => 'Errore';

  @override
  String get bleNtripDisconnected => 'Disconnesso';

  @override
  String get bleNtripHost => 'Host Caster NTRIP';

  @override
  String get bleNtripPort => 'Porta';

  @override
  String get bleNtripMountPoint => 'Mount Point';

  @override
  String get bleNtripUsername => 'Nome utente (Email)';

  @override
  String get bleNtripPassword => 'Password';

  @override
  String get bleNtripConnect => 'Connetti a NTRIP';

  @override
  String get bleNtripDisconnect => 'Disconnetti';

  @override
  String get bleNtripForwarding => 'Inoltro correzioni RTCM';

  @override
  String get bleNtripErrorHostRequired => 'L\'host NTRIP è obbligatorio';

  @override
  String get bleNtripErrorPortRequired => 'La porta è obbligatoria';

  @override
  String get bleNtripErrorInvalidPort => 'Numero di porta non valido';

  @override
  String get bleNtripErrorMountPointRequired => 'Il mount point è obbligatorio';

  @override
  String get bleNtripErrorUsernameRequired =>
      'Il nome utente (email) è obbligatorio';

  @override
  String get bleNtripConnectedSuccess => 'Connesso al caster NTRIP';

  @override
  String get bleNtripDisconnectedSuccess => 'Disconnesso dal caster NTRIP';

  @override
  String get bleNtripConnectionFailed => 'Connessione al caster NTRIP fallita';
}
