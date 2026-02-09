# Teleferika — Funzionalità attuali per professionisti della teleferica / trasporto legname

Questo documento riassume le funzionalità **attuali** dell’app rilevanti per chi progetta e gestisce teleferiche (gru a cavo, cable yarding) per il trasporto del legname e le operazioni forestali.

---

## 1. Raccolta punti basata su GPS

- **Inserimento e memorizzazione di punti** (es. ancoraggi, supporti intermedi, estremità) con latitudine, longitudine e quota.
- **Precisione/accuratezza GPS** e timestamp memorizzati per ogni punto per valutare l’affidabilità di ogni rilevamento.
- I punti sono ordinati all’interno di un progetto e modificabili (coordinate, note, immagini).

**Caso d’uso:** Rilevare ancoraggi e supporti in campo con un unico flusso di lavoro coerente.

---

## 2. Bussola e azimut

- **Integrazione bussola** per il riferimento direzionale in campo.
- **Azimut del progetto** — la direzione prevista della linea a cavo — è memorizzata a livello di progetto.
- **Marcatore dinamico** che mostra l’azimut del progetto come freccia sovrapposta alla posizione corrente del dispositivo, per allineare la linea prevista mentre ci si sposta.

**Caso d’uso:** Orientare la linea e verificare l’allineamento al terreno senza strumenti aggiuntivi.

---

## 3. Direzione, distanza e lunghezza della fune

- **Direzione e distanza** tra punti consecutivi calcolate (livello geometria) e usate nella mappa e nell’interfaccia punti.
- **Calcolo della lunghezza della fune** nel modello di progetto per stimare la lunghezza del cavo lungo la linea rilevata.
- **Lunghezza totale presunta** impostabile a livello di progetto per stime rapide prima o dopo il rilievo dettagliato.

**Caso d’uso:** Lunghezze delle campate, distanza tra torri e lunghezza approssimativa del cavo per pianificazione e ordini.

---

## 4. Quota e pendenza lungo la linea

- Ogni punto memorizza la **quota**, quindi l’elevazione è disponibile lungo tutta la linea.
- **Angolo nel punto** e **colorazione in base all’angolo** sulla polilinea per visualizzare pendenza/ripidezza tra i punti (es. per sicurezza o limiti della macchina).

**Caso d’uso:** Valutare pendenza e variazione di quota per freccia del cavo, franco e idoneità dell’attrezzatura.

---

## 5. Sfondi cartografici topografici e aerei

- **Open Topo Map** — curve di livello e terreno; adatto al lavoro in campo in Europa.
- **Thunderforest Outdoors** — orientato all’outdoor con sentieri e curve di livello.
- **Esri World Topo** — base topografica generica.
- **Esri Satellite** — immagini aeree per ostacoli, piazzali e linea di vista.
- **CartoDB Positron** — base minimalista per sovrapporre i dati della linea.
- **Thunderforest Landscape** — stile visivo centrato sul terreno.

**Caso d’uso:** Scegliere la base giusta (topo vs satellite) per pianificazione e verifiche in campo.

---

## 6. Funzionamento offline

- **Funzionamento offline** per usare l’app senza dati mobili.
- **Cache delle tile** con eventuale download in blocco per tipo di mappa e per le zone di lavoro.

**Caso d’uso:** Uso affidabile in foresta remota con assenza o scarsa connettività.

---

## 7. Tipo cavo / attrezzatura (livello progetto)

- **Selezione del tipo di cavo a livello di progetto** — ogni progetto può essere assegnato a un tipo di cavo/attrezzatura (es. diametro fune, peso, carico di rottura).
- **Tabella tipi di cavo** — una tabella DB dedicata memorizza i tipi di cavo con UUID; i tipi incorporati (pratica italiana/europea: fune portante, fune traente, skyline, mainline) vengono inseriti al primo avvio.
- **Dati di seed** — `cable_equipment_presets.dart` definisce i tipi di cavo incorporati con UUID fissi; il seed viene eseguito solo quando la tabella è vuota.
- **Tipi aggiunti dall’utente** — il DB supporta l’aggiunta di tipi di cavo personalizzati a runtime (UI da implementare); i dettagli del progetto leggono sempre dal DB, non dai preset.

**Caso d’uso:** Ipotesi coerenti per future logiche di freccia, franco o carico; allinea il lessico con gli strumenti desktop (es. SEILAPLAN).

---

## 8. Organizzazione di progetti e linee

- **Progetti** che raggruppano i punti in linee o operazioni distinte.
- **Elenco e editor dei punti** per ordinare, numerare e modificare i punti (es. sequenza degli ancoraggi lungo la linea).

**Caso d’uso:** Un progetto per linea; gestire più linee con più progetti.

---

## 9. Rifinitura delle posizioni dei punti (Marker Slide)

- **Marker slide:** pressione lunga e trascinamento di un marcatore sulla mappa per spostarlo; le coordinate vengono aggiornate al rilascio.
- La posizione originale può essere mostrata durante il trascinamento; la conversione delle coordinate usa la proiezione della mappa per un posizionamento accurato.

**Caso d’uso:** Correggere i punti dopo un GPS migliore o una revisione in ufficio senza rilevare di nuovo.

---

## 10. Foto ai punti

- **Immagini collegate ai punti** (allegato fotografico per punto) per documentare ancoraggi, supporti, ostacoli e piazzali.

**Caso d’uso:** Documentazione visiva in ogni punto critico per report e passaggio di consegne.

---

## 11. Visualizzazione della linea sulla mappa

- **Polilinee** che collegano i punti in sequenza lungo la linea.
- **Frecce sulla polilinea** per indicare il verso della linea.
- **Colorazione in base all’angolo** sui segmenti per mostrare pendenza/angolo lungo la linea.

**Caso d’uso:** Vedere in un colpo d’occhio l’intera linea e la pendenza sulla mappa.

---

## 12. Esportazione dati

- **Esportazione dati** (nella versione completa/con licenza) per usare dati di progetti e punti in altri strumenti, report o pratiche.

**Caso d’uso:** Trasferire i dati nei flussi ufficio, GIS o software di progettazione.

---

## 13. Feedback sull’accuratezza della posizione

- **Marcatore di posizione con cerchio di accuratezza** per vedere la qualità GPS corrente quando si inseriscono o controllano i punti (es. per RTK o GNSS standard).

**Caso d’uso:** Decidere quando acquisire un punto o attendere una qualità di fix migliore.

---

## Riepilogo

Teleferika supporta oggi il **rilievo in campo delle linee a fune**: raccolta punti GPS con quota, allineamento bussola/azimut, direzione/distanza e lunghezza della fune, selezione del tipo di cavo/attrezzatura a livello di progetto, più tipi di mappa (inclusi topo e satellite), uso offline, documentazione fotografica per punto e visualizzazione della linea con colorazione legata alla pendenza. È pensata per tecnici forestali, topografi, project manager e pianificatori ambientali che devono tracciare e documentare linee a gru a cavo per il trasporto del legname.

Per possibili funzionalità future che potrebbero aiutare ulteriormente le aziende, vedi **[FUNCTIONS_FOR_COMPANIES_README.md](./FUNCTIONS_FOR_COMPANIES_README.md)**.
