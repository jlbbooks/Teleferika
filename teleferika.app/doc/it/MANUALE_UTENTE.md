# Teleferika — Manuale utente (bozza)

Questa è una **bozza** del manuale utente di `teleferika.app`, pensata come struttura da espandere sezione per sezione.

> Obiettivo dell’app: supportare il **rilievo in campo** e l’organizzazione di **linee a teleferica/gru a cavo** per il trasporto del legname: raccolta punti GPS, visualizzazione su mappa, calcoli geometrici (distanze/direzioni), profili di linea, uso offline e (se abilitato) esportazione dati.

---

## Indice

- [1. Concetti base](#1-concetti-base)
- [2. Schermate principali (panoramica)](#2-schermate-principali-panoramica)
- [3. Schermata “Progetti” (elenco)](#3-schermata-progetti-elenco)
- [4. Punti (rilievo, modifica, ordine)](#4-punti-rilievo-modifica-ordine)
- [5. Mappa](#5-mappa)
- [6. “Profilo” (grafici della linea)](#6-profilo-grafici-della-linea)
- [7. Foto e allegati ai punti](#7-foto-e-allegati-ai-punti)
- [8. Calcoli e misure](#8-calcoli-e-misure)
- [9. “Scarica mappe offline” e cache](#9-scarica-mappe-offline-e-cache)
- [10. Esportazione dati (se disponibile)](#10-esportazione-dati-se-disponibile)
- [11. “Dispositivi Bluetooth” (RTK/NTRIP)](#11-dispositivi-bluetooth-rtkntrip)
- [12. “Impostazioni”](#12-impostazioni)
- [13. Licenze e funzionalità avanzate](#13-licenze-e-funzionalità-avanzate)
- [14. Risoluzione problemi (FAQ)](#14-risoluzione-problemi-faq)
- [15. Glossario](#15-glossario)

---

## 1. Concetti base

### 1.1 Che cosa gestisce Teleferika

- **Progetto**: contenitore che rappresenta una linea/operazione (es. una teleferica specifica).
- **Punto**: elemento ordinato lungo la linea (es. ancoraggio, supporto intermedio, estremità, piazzale).
- **Linea**: rappresentazione dei punti collegati in sequenza (polilinea) con misure e indicatori.

### 1.2 Dati raccolti per ogni punto (panoramica)

- Coordinate (latitudine, longitudine)
- Quota (se disponibile)
- Accuratezza/precisione della posizione (quando disponibile)
- Note e foto (se usate)

### 1.3 Buone pratiche di rilievo

Questa sezione raccoglie suggerimenti pratici per ottenere dati più affidabili e un progetto più “pulito” già in campo.

#### 1.3.1 Prima di iniziare (preparazione rapida)

- **Definisci lo scopo del progetto**: una linea = un progetto (in genere). Se hai più linee/corridoi, crea più progetti.
- **Decidi il verso della linea**: stabilisci subito qual è **Inizio** e qual è **Fine** (anche solo mentalmente) per mantenere coerente l’ordine dei punti.
- **Scegli lo sfondo mappa adatto**:
  - **Satellite** per riconoscere ostacoli/piazzali/linee di taglio.
  - **Topografico** (es. curve di livello) per leggere il terreno e la pendenza.
- **Se lavori senza rete**: usa **Scarica mappe offline** prima di andare in zona.

#### 1.3.2 Quando acquisire un punto (e quando aspettare)

- **Controlla l’accuratezza**: se la precisione è scarsa, è spesso meglio **attendere** qualche secondo/minuto prima di salvare.
- **Resta fermo al momento del fix**: piccoli spostamenti mentre acquisisci possono degradare la qualità.
- **Evita schermature** (quando possibile): pareti rocciose, chiome fitte e canaloni riducono la qualità GNSS.
- **Se usi un ricevitore RTK**:
  - aspetta un **fix stabile** (es. “Fix RTK” è migliore di “RTK Float”, che è migliore del GNSS standard),
  - verifica che i dati stiano arrivando (posizione/aggiornamento) prima di procedere,
  - se previsto, configura le **correzioni NTRIP** solo dopo aver ricevuto la posizione dal ricevitore.

#### 1.3.3 Coerenza di ordine e numerazione dei punti

- **Mantieni l’ordine lungo la linea**: i punti dovrebbero seguire la progressione naturale dal punto di **Inizio** al punto di **Fine**.
- **Usa una convenzione semplice**: ad esempio P1, P2, P3… (o una nomenclatura interna aziendale), evitando nomi ambigui tipo “punto nuovo”.
- **Segna esplicitamente gli estremi**: quando possibile, imposta chiaramente i punti come **Inizio** e **Fine** (utile per azimut, lettura della linea e controlli).
- **Inserisci i supporti intermedi in sequenza**: se aggiungi torri/supporti dopo, verifica che siano posizionati correttamente nell’ordine.

#### 1.3.4 Azimut e orientamento in campo

- **Azimut del progetto**: impostalo quando hai già identificato Inizio/Fine (o quando hai punti sufficienti per calcolarlo) per avere un riferimento coerente.
- **Ricalcola se cambi gli estremi**: se modifichi quali punti sono Inizio/Fine, aggiorna l’azimut del progetto.

#### 1.3.5 Correzioni e pulizia del dato in campo

- **Correzioni su mappa (“Marker Slide”)**: usale per piccoli aggiustamenti (es. dopo un controllo visivo su satellite), evitando di “inventare” spostamenti grandi senza evidenze.
- **Quote**: se alcune quote mancano, il **Profilo altimetrico** potrebbe non essere disponibile o risultare incompleto; preferisci acquisizioni che includano quota quando possibile.

#### 1.3.6 Note e foto: rendile utili (non solo “belle”)

- **Foto**: scatta in modo ripetibile (es. 1 foto generale + 1 dettaglio ancoraggio/supporto).
- **Note**: registra ciò che non si vede dalle coordinate (tipo ancoraggio, accesso, vincoli, ostacoli, prescrizioni operative).
- **Coerenza**: usa parole chiave standard (es. “ancoraggio”, “torre”, “piazzale”, “ostacolo”, “attraversamento”) per ritrovare informazioni rapidamente.

---

## 2. Schermate principali (panoramica)

### 2.1 “Progetti” (elenco)

Schermata iniziale dell’app: **elenco dei progetti**.

- **Aggiungi nuovo progetto**: pulsante `+` (tooltip: “Aggiungi nuovo progetto”).
- **Selezione multipla**: pressione lunga su un progetto per entrare in modalità selezione (es. “\(n\) selezionati”), poi possibile eliminare i selezionati.
- **Azioni in alto** (AppBar):
  - **Scarica mappe offline** (icona mappa con download)
  - **Impostazioni** (icona ingranaggio)
  - **Licenza** (icona scudo/utente verificato, se la licenza è abilitata)

### 2.2 Editor progetto (schermata con tab)

Aprendo/creando un progetto, si entra nell’editor con 4 tab:
- **Dettagli**
- **Punti**
- **Mappa**
- **Profilo**

Nella barra in alto possono comparire azioni contestuali come **Salva progetto**, **Esporta progetto**, **Elimina progetto** e (se presenti modifiche) **Annulla modifiche**.

---

## 3. Schermata “Progetti” (elenco)

### 3.1 Creare un progetto

- **Aggiungi nuovo progetto**: tocca il pulsante `+` (in basso a destra).
- Si apre l’editor del nuovo progetto. Nella tab **Dettagli** inserisci almeno:
  - **Nome Progetto**
  - (opzionale) **Note**
  - (opzionale) **Data Progetto**
  - (opzionale) **Azimut (°)** e/o **Calcola Azimut**
  - (opzionale) **Lunghezza totale presunta (m)**
  - (opzionale) **Tipo cavo / attrezzatura**
- Per confermare, usa **Salva progetto**.

**Stato vuoto**: se non ci sono progetti, la schermata mostra un messaggio tipo “Nessun progetto ancora. Tocca '+' per aggiungerne uno!”.

### 3.2 Aprire un progetto

- Tocca un progetto nell’elenco per aprire l’editor (tab **Dettagli / Punti / Mappa / Profilo**).
- In alto puoi trovare azioni contestuali come:
  - **Salva progetto** (sempre o solo quando ci sono modifiche, a seconda di Impostazioni)
  - **Esporta progetto** (se disponibile e con licenza valida)
  - **Elimina progetto**
  - **Annulla modifiche** (quando presenti modifiche non salvate)

Suggerimento: se stai per fare rilievi in campo, conviene aprire il progetto prima di iniziare e verificare che la mappa/area siano disponibili (online o offline).

### 3.3 Selezione multipla ed eliminazione

- **Entrare in selezione multipla**: fai una pressione lunga su un progetto.
- In alto compare il conteggio (es. “\(n\) selezionati”) e puoi:
  - **Selezionare altri progetti** con un tap
  - **Uscire** dalla selezione (icona chiudi)
  - **Eliminare** i selezionati (icona cestino)

#### Cosa viene eliminato insieme al progetto

Quando **elimini un progetto**, vengono rimossi **tutti i dati collegati a quel progetto**, ad esempio:

- tutti i **punti** del progetto (coordinate, quote, note, attributi),
- tutte le **foto/allegati** associati ai punti del progetto,
- le impostazioni specifiche del progetto (es. tipo di cavo, lunghezza totale presunta),
- i dati necessari a generare **profili** e **export** relativi a quel progetto.

L’operazione è **irreversibile**: dopo la conferma, i dati non sono più recuperabili dall’app.

### 3.4 Azioni dalla barra in alto (AppBar)

Nella schermata **Progetti** sono disponibili azioni rapide:

- **Scarica mappe offline**: apre la funzione per scaricare in anticipo le mappe (utile prima di andare in zone senza copertura).
- **Impostazioni**: apre la schermata **Impostazioni**.
- **Licenza** (se abilitata): consente di vedere lo stato licenza e gestire operazioni come import/richiesta/aggiornamento stato.

### 3.5 Buone pratiche di gestione progetti

- **Un progetto = una linea**: evita di mescolare linee diverse nello stesso progetto.
- **Nome chiaro**: includi località/cantiere e verso (es. “Valle X — Monte→Valle”).
- **Aggiorna spesso**: salva quando hai completato un blocco di lavoro (es. dopo aver inserito una serie di punti).

---

## 4. Punti (rilievo, modifica, ordine)

### 4.1 Aggiungere un punto con GPS

L’aggiunta di punti avviene preferibilmente dalla tab **Mappa**, usando la posizione GPS corrente (eventualmente fornita da un dispositivo RTK); in alternativa puoi usare la tab **Punti** o strumenti collegati (es. bussola).

#### 4.1.1 Flusso tipico di acquisizione

1. **Seleziona il progetto** dalla schermata **Progetti** e aprilo.
2. Vai alla tab **Mappa** (o alla tab **Punti**).
3. Posizionati fisicamente sul punto che vuoi rilevare.
4. Attendi che il GPS mostri una **buona accuratezza** (vedi sezione 1.3).
5. Usa l’azione **Aggiungi punto**.
6. Controlla e, se necessario, completa:
   - nome/etichetta del punto (es. P1, P2, “Ancora Sx”),
   - eventuali **note** descrittive,
   - eventuali **foto** (vedi sezione 7).
7. Conferma/salva il punto.

#### 4.1.2 Accuratezza e qualità del fix

- Se disponibile, osserva il valore di **accuratezza/precisione**: valori più bassi indicano un fix migliore.
- Con ricevitore **RTK**, preferisci stati di fix come “Fix RTK” rispetto a “RTK Float” o GPS standard.
- Se la precisione è instabile, attendi qualche istante o valuta se spostarti di pochi metri in zona più aperta (se compatibile con l’obiettivo del punto).

#### 4.1.3 Aggiunta punti da strumenti specifici

- **Da tab “Punti”**: puoi aggiungere e gestire i punti partendo da un elenco ordinato, utile per controllare rapidamente nomi, ordine e attributi.
- **Da bussola/azimut**: puoi aggiungere punti allineati rispetto a Inizio/Fine, sfruttando la direzione di progetto.
- **Da mappa**: puoi aggiungere o rifinire punti direttamente sulla mappa (vedi 4.4) quando ti serve un controllo visivo sul tracciato.

### 4.2 Ordinare e numerare i punti

L’ordine dei punti è fondamentale per la lettura della linea, per i profili e per i calcoli.

#### 4.2.1 Convenzioni di numerazione

- Usa una sequenza semplice: **P1, P2, P3…** lungo il verso di lavoro (Inizio → Fine).
- Evita duplicati/confusioni (es. “punto nuovo”, “prova”) nei nomi definitivi del progetto.
- Se necessario, integra con suffissi chiari (es. P3a, P3b per varianti o supporti aggiuntivi).

#### 4.2.2 Riordinare i punti

- Se i punti non sono nell’ordine corretto lungo la linea, riordinare in tab **Punti**:
  - sposta i punti nella sequenza corretta (ad es. tramite comandi di spostamento o trascinamento, a seconda dell’interfaccia),
  - verifica che i **primi/ultimi punti** corrispondano davvero a Inizio/Fine della linea.
- Dopo riordino/importanti modifiche, controlla:
  - la **polilinea** in tab **Mappa**,
  - il **Profilo** (quota vs distanza, deviazione laterale) per vedere se la linea ha un andamento coerente.

#### 4.2.3 Punti intermedi e punti speciali

- Inserisci i **supporti intermedi** (torri, sostegni) nel punto giusto della sequenza.
- Usa note/etichette per distinguere:
  - **ancoraggi**,
  - **torri/supporti**,
  - **piazzali/atterraggi**,
  - **ostacoli** significativi.

### 4.3 Modificare un punto

La modifica è utile quando:

- hai nuove informazioni (es. migliore misura, rilievo ufficio),
- devi correggere un errore (nome, quota, tipo di punto),
- vuoi completare con note o foto aggiuntive.

#### 4.3.1 Cosa puoi modificare

Per ogni punto, a seconda della configurazione, puoi aggiornare:

- **Nome/etichetta** del punto.
- **Coordinate** (tramite nuova acquisizione o tramite spostamento su mappa, vedi 4.4).
- **Quota** (se disponi di un valore più affidabile).
- **Note testuali**.
- **Foto/allegati** (aggiungere/rimuovere).

#### 4.3.2 Quando modificare e quando creare un nuovo punto

- **Modifica** il punto esistente se rappresenta esattamente lo stesso oggetto reale (ancoraggio, supporto, ecc.).
- **Crea un nuovo punto** e, se serve, elimina il vecchio se:
  - il punto originale è stato posizionato su un oggetto diverso,
  - stai cambiando il tracciato in modo sostanziale (nuovo ancoraggio, spostamento piazzale).

### 4.4 Correzione posizione su mappa (Marker Slide)

La funzione **Marker Slide** permette di rifinire la posizione di un punto direttamente sulla mappa.

#### 4.4.1 Come funziona il Marker Slide

- Vai alla tab **Mappa** dell’editor progetto.
- **Tocca e tieni premuto** il marker di un punto sulla mappa.
- **Trascina** il marker nella nuova posizione desiderata (ad es. miglior allineamento su una foto satellitare o topografia).
- Rilascia il marker per confermare il nuovo posizionamento.
- Le **coordinate** del punto vengono aggiornate in base alla nuova posizione.

#### 4.4.2 Quando usare (e quando no)

Usa Marker Slide per:
- piccoli aggiustamenti basati su confronto con **immagini satellitari** o **mappe topografiche**,
- allineare una serie di punti a un tracciato chiaramente visibile in mappa.

Evita di usarlo per:
- grandi spostamenti senza riscontro sul terreno o sui dati (potresti introdurre errori di interpretazione),
- “spostare” punti solo per far quadrare visivamente la linea, senza una base tecnica.

Suggerimento: dopo correzioni importanti, verifica sempre:
- la **forma della linea** in tab **Mappa**,
- il **Profilo**, se usi le quote per valutare pendenza e franco.

---

## 5. Mappa

### 5.1 Visualizzare la linea

- **Polilinea** che collega i punti nell’ordine del progetto.
- **Indicazione del verso** (freccia/arrowhead) lungo la linea.
- **Colorazione della linea** (se attiva) per leggere a colpo d’occhio i tratti più “critici”.
  - **Nota**: al momento la colorazione è basata **solo sull’angolo** (tra segmenti/punti) e **non** su una vera **pendenza**/gradient lungo il terreno. La colorazione per pendenza è un possibile sviluppo futuro.

### 5.2 Tipi di mappa (sfondi)

Teleferika può offrire diversi **sfondi cartografici**. La scelta dello sfondo non cambia i tuoi dati (punti/linea), ma cambia **come li vedi** e quanto è facile interpretare terreno e ostacoli.

#### 5.2.1 Sfondi disponibili (panoramica e quando usarli)

- **OpenStreetMap (stradale)**  
  Utile per strade, toponimi e accessi; spesso il migliore per navigazione “logistica”.

- **Esri Satellite (immagini aeree)**  
  Utile per identificare visivamente **piazzali**, radure, linee di esbosco, infrastrutture e ostacoli evidenti.

- **Esri World Topo (topografico)**  
  Base topografica generale con informazioni sul terreno; buona scelta “tuttofare”.

- **OpenTopoMap (topografico, consigliato in Europa)**  
  Molto utile per leggere **curve di livello** e morfologia in rilievi europei.

- **Thunderforest Outdoors**  
  Orientata al lavoro outdoor: sentieri/contesto e curve di livello (quando disponibili).

- **Thunderforest Landscape**  
  Stile “paesaggio” più leggibile e gradevole per una visione d’insieme del terreno.

- **CartoDB Positron (base pulita)**  
  Base minimale: ottima quando vuoi mettere in evidenza i tuoi marker/linee senza “rumore” grafico.

> Nota: l’elenco esatto può variare in base alla versione/configurazione e alla disponibilità dei provider.

#### 5.2.2 Come scegliere lo sfondo giusto (regole rapide)

- **Rilievo tecnico della linea**: preferisci **topografico** (OpenTopoMap / World Topo) per leggere pendenze, valichi e andamento del terreno.
- **Controllo ostacoli e posizioni reali**: usa **Satellite** per verifiche visive (radure, edifici, linee elettriche visibili, ecc.).
- **Accessi e strade**: usa **OpenStreetMap**.
- **Pulizia visiva**: usa **Positron** quando i dati della linea devono risaltare.

#### 5.2.3 Cambiare tipo di mappa

- Dalla tab **Mappa**, usa il selettore del **tipo di mappa** (icona/menù dedicato) e scegli lo sfondo desiderato.
- Il cambio è immediato: i tuoi punti e la linea restano invariati.

#### 5.2.4 Attribuzioni e uso offline

- Alcuni sfondi richiedono **attribuzione** (crediti) mostrata in mappa: è normale e dipende dal provider.
- Per lavorare in aree senza connessione, usa **Scarica mappe offline** (vedi sezione 9) e scarica in anticipo le mappe per la zona di lavoro e per il tipo di mappa che intendi usare.

### 5.3 Indicatore posizione e accuratezza

Nella tab **Mappa** vedi la tua **posizione corrente** e (quando disponibile) un indicatore di **accuratezza**. Questo ti aiuta a capire se è il momento giusto per acquisire un punto.

#### 5.3.1 Posizione corrente

- La posizione mostra dove si trova il dispositivo (o il **ricevitore RTK**, se connesso e attivo).
- Se la posizione “salta” o si muove in modo irrealistico, è probabile che la qualità GNSS sia bassa o che il segnale sia schermato (vedi 1.3).

#### 5.3.2 Cerchio di accuratezza (come leggerlo)

- Il cerchio rappresenta l’**incertezza** della posizione: più è **grande**, meno la misura è affidabile.
- Regola pratica:
  - **cerchio piccolo** → buon momento per acquisire un punto,
  - **cerchio grande** → meglio attendere o migliorare le condizioni di ricezione.

> Nota: l’accuratezza è una stima e può variare in base a dispositivo, ambiente e correzioni RTK.

#### 5.3.3 GPS interno vs Dispositivo RTK

- Se è connesso un **Dispositivo RTK**, la mappa può usare la posizione del ricevitore invece del GPS interno.
- In caso di disconnessione, l’app tornerà a usare il **GPS del dispositivo** (lo stato sarà indicato a schermo).

#### 5.3.4 Suggerimenti pratici

- Prima di acquisire un punto, controlla che:
  - la posizione sia stabile per alcuni secondi,
  - l’accuratezza sia coerente con l’obiettivo (es. rilievo preciso vs stima rapida),
  - se usi RTK/NTRIP, le correzioni siano attive e il fix sia stabile.

- Se devi acquisire punti sotto copertura (bosco fitto) o in aree critiche:
  - acquisisci più punti/repliche (se il flusso operativo lo consente),
  - aggiungi una **nota** che descriva le condizioni (es. “copertura fitta, possibile errore”).

---

## 6. “Profilo” (grafici della linea)

La tab **Profilo** dell’editor progetto mostra grafici per leggere la linea definita dai punti ordinati del progetto. È utile per:

- capire l’andamento **altimetrico** lungo la linea,
- verificare se la linea è “pulita” (niente punti fuori ordine),
- vedere eventuali deviazioni laterali rispetto a una linea ideale Inizio→Fine.

### 6.0 Quando la tab “Profilo” è disponibile

- In generale la tab è visibile nell’editor progetto come quarta tab (Dettagli, Punti, Mappa, **Profilo**).
- I grafici richiedono **almeno 2 punti** nel progetto.
- **Profilo altimetrico**: richiede che almeno un punto abbia una **quota** disponibile.
- **Vista in pianta**: richiede solo 2 punti (la quota non serve).

Se l’altimetrico non è disponibile (quote mancanti) ma la pianta sì, l’app mostra la **Vista in pianta**.

### 6.1 Profilo altimetrico (quota vs distanza)

Mostra come varia la **quota** lungo la linea.

#### 6.1.1 Cosa mostra il grafico

- **Asse X**: distanza lungo la linea, dal primo punto (0) all’ultimo (lunghezza totale).
- **Asse Y**: quota (metri s.l.m.), scalata tra quota minima e quota massima dei punti che hanno quota.
- **Linea**: unisce i punti che hanno quota; se un punto non ha quota, il segmento corrispondente può risultare “interrotto”.
- **Punti ed etichette**: i punti sono marcati e riportano nome (es. P1, P2) e valori sugli assi con linee guida tratteggiate.

#### 6.1.2 Nota sulla distanza (importante)

La distanza lungo l’asse X è calcolata come **distanza 3D** tra punti consecutivi (quindi include anche la componente verticale), più simile a una “lunghezza fune” che a una distanza puramente orizzontale.

#### 6.1.3 Quando usarlo

- per controllare i **salti di quota** e l’andamento complessivo,
- per individuare punti anomali (quota errata o punto fuori sequenza),
- come base per valutazioni tecniche preliminari (da affinare con strumenti dedicati).

### 6.2 Vista in pianta (deviazione laterale)

Mostra la linea “vista dall’alto”, evidenziando quanto i punti deviano lateralmente rispetto alla retta che unisce **Inizio** e **Fine**.

#### 6.2.1 Cosa mostra il grafico

- **Linea di riferimento**: la retta tra primo e ultimo punto.
- **Asse X**: distanza **lungo** la linea di riferimento (orizzontale), da 0 all’ultimo punto.
- **Asse Y**: **offset laterale** (metri) rispetto alla linea di riferimento (positivo da un lato, negativo dall’altro).
- **Punti**: vengono mostrati tutti i punti (la quota è ignorata).

#### 6.2.2 Interpretazione pratica

- Se l’offset laterale è vicino a **0**, la linea è quasi rettilinea rispetto a Inizio→Fine.
- Offset grandi indicano curve o deviazioni: può essere normale (vincoli di terreno) oppure segnale di punti fuori posto/ordine.

#### 6.2.3 Nota sulle distanze

La vista in pianta usa distanze e direzioni **orizzontali** (latitudine/longitudine), ignorando la quota, così anche punti senza quota vengono rappresentati correttamente.

### 6.3 Ridimensionare il grafico e stato salvato

Entrambi i grafici hanno una maniglia di **ridimensionamento** verticale.

#### 6.3.1 Altezza del grafico

- Puoi aumentare/diminuire l’altezza trascinando la maniglia sotto il grafico.
- L’altezza viene **salvata** per quel progetto, separatamente per:
  - profilo altimetrico,
  - vista in pianta.

#### 6.3.2 Modalità selezionata (Altimetrico vs Pianta)

- Quando entrambi sono disponibili, puoi passare da una modalità all’altra (controllo a segmenti).
- La modalità scelta viene ricordata **solo in memoria**: tornando alla tab durante la stessa sessione, l’app ripristina l’ultima scelta, ma non è un’impostazione persistente a lungo termine.

#### 6.3.3 Stati vuoti (casi in cui non vedi un grafico)

- meno di 2 punti nel progetto,
- per l’altimetrico: nessun punto con quota disponibile.

---

## 7. Foto e allegati ai punti

### 7.1 Aggiungere foto a un punto

Le foto servono a documentare ciò che **non è evidente dalle coordinate**: tipo ancoraggio, condizioni del sito, ostacoli, accessi, dettagli costruttivi.

#### 7.1.1 Flusso tipico

1. Apri il progetto e vai alla tab **Punti**.
2. Apri il **dettaglio** del punto (quello a cui vuoi associare la foto).
3. Nella sezione **Foto/Immagini/Allegati** (a seconda della schermata), scegli:
   - **Scatta foto** (fotocamera), oppure
   - **Seleziona da galleria** (se disponibile).
4. Verifica che la foto sia stata aggiunta e, se necessario, completa le **note** del punto per contestualizzare l’immagine.

#### 7.1.2 Organizzazione e visualizzazione

- Le foto sono **legate al singolo punto**: quando apri quel punto, ritrovi la sua galleria/allegati.
- Puoi usare più foto per lo stesso punto (es. panoramica + dettaglio).

#### 7.1.3 Modifica e rimozione

- Se una foto è sbagliata o non utile, puoi **rimuoverla** dal punto (azione irreversibile).
- Se elimini il **punto** o l’intero **progetto**, vengono eliminati anche i relativi allegati (vedi sezione 3.3).

#### 7.1.4 Note operative (permessi e campo)

- Su alcuni dispositivi potrebbe essere necessario concedere permessi per **fotocamera** e/o **archiviazione**.
- In condizioni di luce difficili (bosco fitto), preferisci una foto “leggibile” a una foto scura: può fare la differenza in ufficio.

### 7.2 Buone pratiche

#### 7.2.1 Cosa fotografare (checklist rapida)

- **Ancoraggi**: dettaglio del punto di ancoraggio + panoramica dell’area.
- **Supporti intermedi (torri/sostegni)**: base/attacco + direzione linea.
- **Estremi linea / piazzali**: area di lavoro, accessi, vincoli.
- **Ostacoli**: attraversamenti (strade, linee elettriche), alberi notevoli, edifici, corsi d’acqua.
- **Punti “dubbi”**: dove il GPS era scarso o la posizione è stata corretta manualmente (Marker Slide).

#### 7.2.2 Come scattare per renderle utili

- **Punto fisso + orientamento**: se possibile, scatta guardando lungo la linea (Inizio→Fine) per coerenza.
- **Due foto meglio di una**: 1 panoramica + 1 dettaglio.
- **Evita zoom digitali estremi**: riducono leggibilità; meglio avvicinarsi quando sicuro.

#### 7.2.3 Note associate alla foto (il vero valore)

Le foto sono molto più utili se accompagnate da note brevi e standardizzate, ad esempio:
- “Ancoraggio su ceppaia / roccia / pianta viva”
- “Accesso: strada forestale a 50 m, pendenza alta”
- “Ostacolo: linea elettrica visibile a valle”
- “GPS scarso (copertura fitta), punto stimato”

#### 7.2.4 Impatto su esportazioni e report

- Se usi l’**esportazione** (quando disponibile), le foto e le note possono diventare parte del pacchetto informativo del progetto.
- Per questo motivo, mantieni foto e note **pulite e pertinenti**: meno quantità, più qualità.

---

## 8. Calcoli e misure

### 8.1 Distanze e direzioni tra punti

Teleferika calcola automaticamente misure tra **punti consecutivi** (nell’ordine del progetto). Queste misure servono per leggere la linea su mappa, controllare coerenza del rilievo e preparare la fase di progettazione.

#### 8.1.1 Distanza tra punti consecutivi

- La distanza tra P\(i\) e P\(i+1\) rappresenta la **lunghezza del segmento** tra due punti della linea.
- In pratica la distanza dipende dai dati disponibili (coordinate e, quando presenti, quota). In alcuni grafici (Profilo altimetrico) viene usata una distanza “lungo linea” che considera anche la quota (vedi 6.1.2).

Uso tipico:
- verificare le **campate** tra supporti/ancoraggi,
- stimare la distanza tra punti per organizzare il rilievo (dove mettere un punto intermedio),
- individuare errori grossolani (segmento troppo lungo o improvvisamente molto corto).

#### 8.1.2 Direzione (bearing/azimut) tra punti

- La direzione indica “verso dove” va il segmento successivo.
- È utile per:
  - controllare in campo se stai seguendo la linea prevista,
  - confrontare il tracciato reale con l’**Azimut (°)** del progetto (vedi sezione 3.1 e 1.3.4).

Nota: “azimut del progetto” è un valore di riferimento a livello progetto; la direzione tra punti è una misura locale tra due punti specifici.

### 8.2 Lunghezza fune / lunghezza linea

La lunghezza complessiva della linea può essere vista come somma delle distanze tra punti in sequenza. In fase di rilievo spesso servono due concetti:

#### 8.2.1 Lunghezza “lungo linea”

- È la somma delle lunghezze dei segmenti tra punti consecutivi, seguendo l’ordine del progetto.
- È la misura più utile per una stima della **lunghezza del percorso** reale della linea e, in molti casi, per ragionare in termini di “lunghezza fune” (stima).

#### 8.2.2 Distanza orizzontale vs distanza con quota (3D)

- In alcune analisi la quota è importante (dislivelli) e la distanza può essere intesa come “3D”.
- In altre analisi (vista in pianta, allineamenti), interessa solo la componente **orizzontale**.

Suggerimento:
- se stai valutando **campate** e sviluppo complessivo, usa la lunghezza “lungo linea”;
- se stai valutando deviazioni laterali o layout planimetrico, ragiona in termini orizzontali (vedi 6.2).

#### 8.2.3 “Lunghezza totale presunta (m)”

- Nei **Dettagli** del progetto puoi inserire una **Lunghezza totale presunta (m)** per stime rapide quando non hai ancora tutti i punti.
- Quando il rilievo è completo, la lunghezza calcolata dai punti diventa il riferimento più affidabile.

### 8.3 Pendenza e angoli

Questa sezione riguarda due concetti che spesso vengono confusi:

#### 8.3.1 Angolo (cambi di direzione)

- L’**angolo** descrive quanto la linea “cambia direzione” tra segmenti consecutivi (es. una curva o una deviazione).
- È utile per evidenziare tratti dove la linea non è rettilinea e dove potrebbe essere necessario un punto/supporto intermedio o una revisione del tracciato.

La **colorazione della linea** (quando attiva) è, al momento, basata su questo concetto (vedi nota in 5.1).

#### 8.3.2 Pendenza (dislivello lungo la linea)

- La **pendenza** riguarda il dislivello tra punti e l’andamento altimetrico.
- Per leggerla in modo pratico, usa:
  - il **Profilo altimetrico** (sezione 6.1),
  - la mappa topografica (curve di livello) e le quote dei punti.

Sviluppo futuro: una colorazione basata su pendenza/gradient può essere introdotta in seguito (vedi 5.1).

---

## 9. “Scarica mappe offline” e cache

La funzione **Scarica mappe offline** è accessibile dalla schermata **Progetti** (icona mappa con download).

### 9.0 Requisiti e note importanti

- **Connettività**: il download delle mappe richiede una connessione dati (Wi‑Fi consigliato).
- **Spazio su disco**: le mappe offline possono occupare molto spazio; verifica di avere memoria libera.
- **Licenza** (se applicabile): in alcune versioni la funzione di download mappe può richiedere una **licenza valida**.

### 9.1 Uso offline

Quando sei offline (senza rete dati):

- puoi continuare a usare **Progetti** e **Punti** (dati salvati localmente),
- puoi aprire la tab **Mappa** e visualizzare lo sfondo **solo** nelle aree/tipi di mappa che sono stati scaricati in cache,
- le funzionalità che richiedono servizi online (tile non scaricate, validazioni o servizi remoti) potrebbero non funzionare o mostrare sfondi vuoti.

Suggerimento: considera l’offline come “**dati del progetto sempre disponibili** + mappe disponibili **solo se scaricate prima**”.

### 9.2 Scaricare mappe in anticipo

Lo scopo è salvare le **tile** della mappa per poterle visualizzare anche senza rete.

#### 9.2.1 Aprire la schermata di download

1. Vai alla schermata **Progetti**.
2. Tocca l’icona **Scarica mappe offline** (mappa con download).
3. Se richiesto, verifica che la **licenza** sia valida.

#### 9.2.2 Scegliere cosa scaricare

(L’interfaccia può variare, ma i concetti sono gli stessi.)

- **Tipo di mappa**: scegli lo sfondo che userai sul campo (es. Satellite o OpenTopoMap).  
  Nota: la cache è legata anche al tipo di mappa; scaricare “Satellite” non implica avere anche “Topografico”.
- **Area**: seleziona una zona che copra l’intera area di lavoro, includendo margine.
- **Livelli di zoom**: più zoom = più dettaglio, ma anche **molte più tile** e più spazio occupato.

#### 9.2.3 Consigli pratici (per non scaricare troppo)

- Inizia con **un’area piccola** e 2–3 livelli di zoom che usi davvero.
- Per rilievi:
  - zoom medio per orientamento,
  - zoom più alto solo per dettagli in prossimità di punti/ancoraggi.
- Se usi sia **Satellite** sia **Topografico**, valuta di scaricare entrambi (ma solo l’area necessaria).

#### 9.2.4 Durante e dopo il download

- Lascia l’app aperta finché il download non è completato (se possibile).
- Prima di andare in campo, fai una prova:
  - attiva modalità aereo o disattiva i dati,
  - apri la tab **Mappa** sul progetto,
  - verifica che lo sfondo si veda nell’area prevista.

### 9.3 Gestione cache (pulizia, spazio, problemi)

#### 9.3.1 Quando pulire la cache

- se lo spazio su disco è basso,
- se cambi area di lavoro e non ti servono più le mappe scaricate,
- se vedi comportamenti anomali (tile mancanti/vecchie) dopo aggiornamenti o cambi provider.

#### 9.3.2 Impatto su prestazioni e batteria

- Scaricare molte tile consuma **batteria** e **dati**: meglio Wi‑Fi e telefono in carica quando possibile.
- Una cache ampia migliora la fluidità offline, ma può occupare memoria.

#### 9.3.3 Problemi comuni e soluzioni rapide

- **Tile vuote offline**: probabilmente non hai scaricato quell’area o quel tipo di mappa (o lo zoom usato).
- **Provider che non consente download preventivo**: alcuni provider non permettono (per **licenza d’uso/termini legali**) il download preventivo o massivo delle tile. In questi casi, cambia tipo di mappa/provider oppure limita l’uso all’online nel rispetto dei termini.
- **Download non disponibile**: potrebbe mancare una licenza valida (se prevista) o la funzionalità non è abilitata nella tua versione.
- **Spazio insufficiente**: riduci area/zoom o pulisci cache.

---

## 10. Esportazione dati (se disponibile)

### 10.1 Quando serve l’esportazione

L’esportazione serve per portare i dati del progetto fuori dall’app, ad esempio per:

- **lavoro in ufficio** (revisione, archiviazione, condivisione con colleghi),
- integrazione con strumenti **GIS** (QGIS/ArcGIS) e cartografia aziendale,
- predisposizione di **report** e documentazione,
- invio a software/consulenti per la **progettazione** o verifiche tecniche.

Suggerimento: esporta quando il progetto è “stabile” (punti in ordine, nomi/quote verificate, note/foto principali inserite).

### 10.2 Cosa viene esportato

In generale, l’export include:

- **Dati progetto** (nome, note, data, parametri principali come azimut e lunghezza presunta quando presenti),
- **Elenco punti** ordinato (coordinate, quota se disponibile, note e attributi),
- **Geometria della linea** (connessione tra i punti nell’ordine),
- eventuali metadati utili (es. conteggio punti).

**Immagini/foto**: non tutti i formati includono le immagini. La schermata di export può avvisarti che alcuni formati potrebbero non includere tutti i tipi di dati (es. immagini).

### 10.3 Formati e compatibilità

Nella schermata di export puoi selezionare un **formato** e poi scegliere se:
- **Condividi file** (invio con app di condivisione), oppure
- **Salva localmente** (richiede permessi/abilitazioni di archiviazione su alcuni dispositivi).

Formati tipici (in base alla configurazione/versione):

- **CSV**: utile per fogli di calcolo, controlli rapidi e import in strumenti custom.
- **KML**: utile per visualizzazione in **Google Earth**.
- **GeoJSON**: utile per flussi **GIS** moderni (QGIS, strumenti web).

#### 10.3.1 Come avviare l’esportazione (flusso)

1. Apri il progetto.
2. Assicurati che il progetto sia **salvato** (se hai modifiche non salvate, salva prima).
3. Tocca l’icona **Esporta progetto** nell’AppBar dell’editor progetto.
4. Scegli il **formato** e l’opzione di uscita (Condividi/Salva localmente).

#### 10.3.2 Requisiti e limitazioni comuni

- **Serve almeno 1 punto**: se il progetto non ha punti, l’export non è possibile.
- **Progetto nuovo**: salva il progetto almeno una volta per abilitare l’esportazione.
- **Licenza**: in alcune versioni l’export richiede una **licenza valida**.
- **Permessi**: per “Salva localmente” potrebbe essere necessario concedere permessi di archiviazione.

---

## 11. “Dispositivi Bluetooth” (RTK/NTRIP)

Quando la funzione è presente/abilitata, l’app può connettersi a un **ricevitore RTK** via **Bluetooth** o **USB** e usare i suoi dati GPS al posto di quelli del telefono. Può inoltre gestire **correzioni NTRIP** per ottenere posizioni di precisione centimetrica (quando supportato).

La schermata dedicata si chiama **Dispositivi Bluetooth** ed è raggiungibile da **Impostazioni → Dispositivi di posizionamento → Dispositivi Bluetooth** o dall’icona del dispositivo RTK sulla mappa (se abilitata).

### 11.1 Scopo dell’integrazione RTK

L’obiettivo è migliorare la **precisione del rilievo** rispetto al solo GPS del telefono:

- **GNSS standard (telefono)**: precisione tipica 3–5 m (in condizioni buone), sufficiente per molti usi ma non per rilievi di dettaglio.
- **RTK con correzioni**: precisione potenziale 1–5 cm (fix RTK) o decimetrica (RTK float), adatta a rilievi tecnici dove la posizione dei punti deve essere molto precisa.

Questo è particolarmente utile quando:
- devi posizionare ancoraggi/supporti in modo ripetibile,
- vuoi allineare i dati di campo con rilievi di ufficio (DTM, LiDAR, GIS),
- lavori in contesti dove pochi metri di errore cambiano le scelte di tracciato.

### 11.2 Collegamento e uso

#### 11.2.1 Apertura e scelta modalità (Bluetooth/USB)

1. Vai in **Impostazioni → Dispositivi di posizionamento → Dispositivi Bluetooth**.
2. Nella schermata puoi selezionare la **modalità di connessione**:
   - **Bluetooth** (BLE),
   - **USB** (se il dispositivo e il telefono supportano OTG/USB host).

#### 11.2.2 Collegamento via Bluetooth (BLE)

- Assicurati che il ricevitore RTK sia:
  - acceso,
  - in modalità Bluetooth visibile/accoppiabile.
- Nella schermata **Dispositivi Bluetooth**:
  - avvia la **scansione**,
  - attendi la comparsa del ricevitore in elenco,
  - selezionalo per avviare la **connessione**.
- Una volta connesso:
  - lo **stato** passa a connesso,
  - dovresti iniziare a vedere i **dati GPS** del ricevitore (latitudine, longitudine, quota, qualità fix, ecc.).

#### 11.2.3 Collegamento via USB

- Collega il ricevitore RTK al dispositivo (es. telefono Android) tramite cavo **USB OTG** compatibile.
- Se Android mostra una richiesta di **permesso USB**, consenti l’accesso.
- Nella schermata **Dispositivi Bluetooth**:
  - passa alla modalità **USB**,
  - cerca/aggiorna l’elenco dispositivi USB,
  - scegli il ricevitore e avvia la connessione.

> Nota: il collegamento RTK via **USB** non è supportato su dispositivi **iOS/Apple**; su questi dispositivi puoi usare solo la modalità **Bluetooth**.

#### 11.2.4 Visualizzazione dei dati GPS RTK

- Una volta che il dispositivo è connesso e sta trasmettendo:
  - la sezione **Dati GPS da Ricevitore RTK** mostra i valori ricevuti (coordinate, quota, qualità fix, satelliti, ecc.),
  - sulla mappa, la **posizione corrente** può provenire dal ricevitore anziché dal GPS interno.
- È possibile avere indicatori aggiuntivi (es. qualità fix RTK, età correzioni DGPS/RTK) per capire quanto il segnale è affidabile.

#### 11.2.5 Quando la connessione non funziona

- Controlla:
  - permessi Bluetooth/Posizione (per BLE),
  - permesso USB (per USB),
  - stato del dispositivo RTK (acceso, in modalità corretta),
  - eventuali messaggi di errore in schermata.

In caso di problemi ripeti:
- disconnessione/riconnessione,
- riavvio del dispositivo RTK o del telefono,
- verifica dei cavi (USB) o della portata Bluetooth.

### 11.3 Correzioni NTRIP

Le **correzioni NTRIP** permettono al ricevitore RTK di usare dati di una rete di stazioni di riferimento per migliorare la precisione.

#### 11.3.1 Cosa serve per usare NTRIP

- Un **caster NTRIP** (server) raggiungibile via rete dati,
- i parametri di connessione:
  - **Host**,
  - **Porta**,
  - **Mount point**,
  - **Nome utente** (spesso un’email),
  - **Password**,
- eventualmente l’opzione **SSL/TLS** (porta o impostazioni specifiche del servizio).

#### 11.3.2 Configurazione base

Nella schermata **Dispositivi Bluetooth**, nella sezione **Correzioni NTRIP**:

1. Inserisci host, porta, mount point, utente e password forniti dal servizio NTRIP.
2. (Se necessario) abilita **SSL/TLS**.
3. Avvia la connessione NTRIP quando:
   - il ricevitore RTK è connesso,
   - è disponibile una prima posizione dal ricevitore.

Se la connessione va a buon fine:
- lo stato passa a **Connesso**,
- l’app inoltra le correzioni RTCM al dispositivo RTK (quando supportato).

#### 11.3.3 Troubleshooting NTRIP

- **Errore di connessione**:
  - verifica host/porta/mount point/credenziali,
  - controlla la connettività dati del telefono,
  - verifica se il servizio NTRIP richiede SSL/TLS o altre impostazioni.
- **Nessun miglioramento della qualità fix**:
  - verifica che le correzioni vengano effettivamente inoltrate (stato di inoltro RTCM, se mostrato),
  - controlla il tipo di abbonamento NTRIP e l’area di copertura,
  - considera che possono volerci alcuni minuti perché la qualità del fix migliori.
- **Cambio dispositivo RTK**:
  - se cambi ricevitore, potresti dover ristabilire la connessione NTRIP e l’inoltro correzioni.

---

## 12. Impostazioni

La schermata si chiama **Impostazioni** ed è accessibile dalla schermata **Progetti** (icona ingranaggio).

### 12.1 “Comportamento UI”

Questa sezione controlla come si comportano alcuni elementi dell’interfaccia.

#### 12.1.1 Mostra Sempre Icona Salva

- **Mostra Sempre Icona Salva**: quando abilitato, l’icona di **salvataggio** è sempre visibile nella barra in alto dell’editor progetto.
- Quando è disabilitato, l’icona appare **solo** quando ci sono **modifiche non salvate**.

Suggerimenti:
- abilita l’opzione se preferisci avere sempre il pulsante Salva “a portata di mano”,
- disabilitala se vuoi un’AppBar più pulita e affidarti all’indicazione di “modifiche non salvate”.

### 12.2 “Mappa e Bussola”

Questa sezione gestisce le impostazioni collegate alla lettura visiva della linea su mappa e bussola.

#### 12.2.1 Soglia Angolo a Rosso

- **Soglia Angolo a Rosso**: imposta, in gradi, il valore oltre il quale l’indicatore di angolo cambia da **verde** a **rosso**.
- Valori **più bassi** rendono il sistema **più sensibile** (diventa rosso con deviazioni più piccole),
- valori **più alti** lo rendono **più tollerante**.

È utile per personalizzare quanto severamente vuoi che l’app evidenzi angoli “sfavorevoli” o curve nella linea.

#### 12.2.2 Visualizzazione Mappa (tutti i progetti)

- **Mostra Tutti i Progetti sulla Mappa**:
  - quando abilitato, sulla mappa vedi **tutti i progetti** come marcatori/linee grigie, oltre al progetto corrente,
  - quando disabilitato, vedi **solo il progetto corrente**.

Questo è utile se vuoi:
- una visione d’insieme delle linee in una zona,
- evitare di “affollare” la mappa quando lavori su un singolo progetto.

#### 12.2.3 Pulsante Dispositivo RTK sulla mappa

- **Mostra Pulsante Dispositivo RTK**:
  - quando abilitato, sulla mappa appare un piccolo pulsante (icona “satellite”/RTK) quando sei connesso a un dispositivo RTK,
  - toccandolo puoi aprire rapidamente le **informazioni del dispositivo** e della connessione.

Se non usi mai dispositivi RTK, puoi disabilitare l’opzione per semplificare l’interfaccia.

### 12.3 “Dispositivi di posizionamento”

Questa sezione collega alle impostazioni avanzate per dispositivi RTK e NTRIP.

#### 12.3.1 Dispositivi Bluetooth (RTK)

- La voce **Dispositivi Bluetooth** apre la schermata descritta nella sezione 11:
  - scansione e connessione a ricevitori RTK via Bluetooth/USB,
  - visualizzazione dati GPS da RTK,
  - configurazione delle **correzioni NTRIP**.

In ambienti senza RTK puoi ignorare questa sezione; in contesti professionali di rilievo preciso è invece uno snodo centrale.

### 12.4 “Tipi di cavo”

Qui puoi gestire l’elenco dei **Tipi di cavo** usati nei progetti.

#### 12.4.1 Cosa sono i “Tipi di cavo”

- Si tratta di voci come “fune portante”, “fune traente”, “skyline”, “mainline” ecc., con attributi tecnici associati (diametro, peso, carico di rottura, ecc. a seconda della configurazione).
- L’app fornisce un insieme di **tipi predefiniti** (seed) coerenti con la pratica italiana/europea, e permette di aggiungerne di nuovi.

#### 12.4.2 Aggiungere / modificare / eliminare tipi di cavo

- Dalla sezione **Tipi di cavo** puoi:
  - **Aggiungere** un nuovo tipo di cavo (ad es. modello specifico di una ditta),
  - **Modificare** le proprietà di un tipo esistente (quando consentito),
  - **Eliminare** un tipo di cavo non più utilizzato.

Quando elimini un tipo di cavo:
- i progetti che lo usano vengono aggiornati secondo la logica dell’app (ad es. potrebbero passare a “Non impostato” o a un tipo alternativo, a seconda dell’implementazione),
- l’operazione non è pensata per essere frequente: usala quando sei sicuro che il tipo non debba essere più utilizzato in futuro.

Suggerimento: mantieni l’elenco dei tipi di cavo **pulito ma stabile**, per evitare ambiguità nelle letture tecniche e nell’esportazione dati.

---

## 13. Licenze e funzionalità avanzate

### 13.1 Panoramica

Alcune funzionalità (ad esempio **Esportazione dati**, **Scarica mappe offline** in certe configurazioni, o modalità avanzate) sono controllate da un sistema di **licenze**.

In questa app:

- la versione corrente di Teleferika utilizza una **licenza permanente gratuita** fornita con l’app,
- questo significa che le funzionalità disponibili sono utilizzabili **senza scadenza** e senza canone,
- il sistema di licenze è presente per permettere in futuro varianti (es. versioni aziendali, moduli aggiuntivi) senza cambiare il flusso base per chi usa la licenza gratuita.

Se in futuro verranno introdotte varianti, la schermata licenze ti aiuterà a capire quali funzioni sono attive per la tua installazione.

### 13.2 Attivazione e gestione licenza

La gestione licenze è accessibile dalla schermata **Progetti**, tramite l’icona **scudo/utente** accanto alle **Impostazioni** (se il sistema licenze non è disabilitato).

Nella versione attuale:

- l’app include già una **licenza permanente gratuita** valida per le funzionalità disponibili,
- non è necessario **attivare**, **rinnovare** o **importare** una licenza per l’uso standard.

La schermata licenze può comunque mostrare:

- informazioni sulla licenza attuale (email/ID, stato),
- strumenti per importare o testare licenze (pensati per scenari avanzati o futuri).

Se in futuro verranno introdotte licenze a pagamento o legate ad account aziendali, questa sezione del manuale potrà essere aggiornata con istruzioni specifiche (attivazione, rinnovo, gestione errori).

---

## 14. Risoluzione problemi (FAQ)

- **Non vedo la mappa / tile vuote**
  - verifica la **connessione dati** (se non hai scaricato mappe offline),
  - controlla di essere nell’**area per cui hai scaricato** le mappe (vedi sezione 9),
  - prova un diverso **tipo di mappa** (alcuni provider possono avere problemi temporanei),
  - prova a **chiudere e riaprire** l’app; se il problema persiste, valuta la pulizia cache per quel provider.

- **GPS poco preciso**
  - controlla che i **servizi di localizzazione** siano attivi per l’app,
  - attendi qualche minuto in una zona con **cielo più aperto**,
  - se disponibile, collega un **dispositivo RTK** e attendi un **fix stabile** (vedi sezione 11),
  - consulta le buone pratiche di rilievo in sezione 1.3.

- **Punti fuori ordine**
  - vai nella tab **Punti** e controlla la sequenza (P1, P2, …),
  - riordina i punti in modo che seguano il verso Inizio→Fine della linea (vedi sezione 4.2),
  - verifica il risultato in tab **Mappa** e **Profilo** per assicurarti che la linea abbia un andamento coerente.

- **Profilo non disponibile**
  - assicurati che il progetto abbia **almeno 2 punti**,
  - per il **Profilo altimetrico**, verifica che almeno alcuni punti abbiano una **quota**,
  - se mancano le quote, potrai vedere solo la **Vista in pianta** (quando disponibile) o un messaggio che indica l’assenza di dati sufficienti (vedi sezione 6).

- **Esportazione non disponibile**
  - verifica di aver **salvato** il progetto almeno una volta,
  - assicurati che il progetto contenga **almeno 1 punto**,
  - controlla lo stato della **licenza** (se il sistema licenze è attivo) in schermata Progetti,
  - alcuni formati/azioni (es. “Salva localmente”) possono richiedere permessi di **archiviazione** sul dispositivo.

---

## 15. Glossario

- **Azimut**: direzione (in gradi) rispetto al Nord, usata per orientare la linea.
- **Bearing (direzione)**: direzione dal punto A al punto B.
- **Polilinea**: linea spezzata che unisce i punti in sequenza.
- **RTK**: tecnica GNSS per aumentare la precisione tramite correzioni.
- **Tile**: tassello di mappa (immagine) usato dagli sfondi cartografici.
- **NTRIP**: protocollo che permette a un ricevitore GNSS/RTK di ricevere correzioni da un server (caster) tramite internet.
- **DTM/DEM**: modelli digitali del terreno (Digital Terrain/Elevation Model) usati per rappresentare quota/altimetria in forma raster.
- **Profilo altimetrico**: grafico che mostra la quota in funzione della distanza lungo la linea.
- **Vista in pianta**: rappresentazione “dall’alto” della linea rispetto a una retta Inizio→Fine, con indicazione delle deviazioni laterali.

