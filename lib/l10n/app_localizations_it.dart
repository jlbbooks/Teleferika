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
  String pointFromCompassDefaultNote(String heading) {
    return 'Punto da Bussola (A: $heading°)';
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
}
