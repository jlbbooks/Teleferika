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
  String get mapTypeStreet => 'Strada';

  @override
  String get mapTypeSatellite => 'Satellite';

  @override
  String get mapTypeTerrain => 'Terreno';

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
  String get delete_photo_title => 'Eliminare foto?';

  @override
  String delete_photo_content(String photoNumber) {
    return 'Sei sicuro di voler eliminare la foto $photoNumber?';
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
  String get photo_manager_gallery => 'Galleria';

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
}
