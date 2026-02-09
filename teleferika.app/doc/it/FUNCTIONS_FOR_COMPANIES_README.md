# Teleferika — Funzionalità che potrebbero aiutare le aziende

Questo documento elenca **funzionalità potenziali** che potrebbero rendere Teleferika più utile per le aziende che usano sistemi a teleferica/gru a cavo per il trasporto del legname. Si basano su strumenti di settore (es. SEILAPLAN, CHPS, Softree, SKYTOWER/SKYMOBILE) e flussi di lavoro comuni. Nessuna di queste è un impegno; sono opzioni per roadmap e priorità.

---

## 1. Meccanica del cavo / della linea (orientata al progetto)

### Freccia e franco di sicurezza

- **Idea:** Usare un modello semplice a catenaria o parabolico per stimare **freccia** e **franco minimo** tra il percorso del carico e il terreno lungo la linea (o per segmento).
- **Perché aiuta:** Strumenti come SEILAPLAN fanno questo controllo come elemento centrale. Anche un “franco OK?” approssimativo nell’app supporterebbe verifiche in campo e passaggio alla progettazione da desktop.
- **Dipende da:** Lunghezza del segmento, dislivello, parametri cavo/carico (vedi “Tipo cavo/attrezzatura” sotto).

### Carico utile vs campata

- **Idea:** Fornire un aiuto **carico/campata**: es. “campata massima per un dato carico” o “carico massimo su questa campata” (o “campata max per questo tipo di fune”).
- **Perché aiuta:** Programmi come SKYTOWER/SKYMOBILE rispondono a queste domande; una versione semplificata aiuterebbe nel posizionamento dei supporti intermedi e nella scelta del tracciato.
- **Dipende da:** Tipo di cavo, pendenza ed eventuali preset dell’attrezzatura.

### Posizioni dei supporti intermedi

- **Idea:** Trattare esplicitamente i **supporti intermedi** (es. tipo punto “torre” o “supporto intermedio”) e mostrare **lunghezza e pendenza del segmento** tra i supporti.
- **Perché aiuta:** Allineato al modo in cui i professionisti descrivono le linee e agli strumenti desktop che ottimizzano le posizioni dei supporti (es. SEILAPLAN).

---

## 2. Terreno e quota

### Profilo longitudinale

- **Idea:** **Profilo altimetrico** lungo la linea: quota vs distanza (visualizzazione in app e/o esportazione come CSV/XY).
- **Perché aiuta:** Modo standard per rivedere una linea; SEILAPLAN e altri accettano profilo o DTM come input per il progetto del tracciato.
- **Dipende da:** Quote attuali dei punti; in futuro opzionale: quota da DTM sotto la linea.

### Import DTM / DEM (lungo periodo)

- **Idea:** Supportare l’**import di un profilo longitudinale** (es. CSV) o, in seguito, la **quota sotto la linea** da raster (DTM/DEM).
- **Perché aiuta:** Collega l’app da campo e gli strumenti di progettazione da ufficio che usano LiDAR/DTM (Softree, CHPS, SEILAPLAN).

---

## 3. Attrezzature e tipi di cavo

### Tipo di gru a cavo / fune

- **Idea:** **“Tipo cavo/attrezzatura” a livello di progetto** (o un piccolo set di preset): es. diametro fune, peso, resistenza o tipo di gru nominato.
- **Perché aiuta:** Consente ipotesi coerenti per eventuali logiche future su freccia, franco o carico e allinea il lessico con il software da desktop (es. tipo gru a cavo di SEILAPLAN).

---

## 4. Esportazione e interoperabilità

### Esportazione compatibile con GIS

- **Idea:** Esportare in formati usati di frequente in ambito forestale/GIS:
  - **KML** — per Google Earth e verifiche in campo.
  - **Shapefile o GeoJSON** — per flussi QGIS/ArcGIS e stile CHPS.
  - **CSV** — coordinate, quota, ordine e attributi principali per profili e strumenti tipo SEILAPLAN.
- **Perché aiuta:** Le aziende usano già QGIS, ArcGIS e CHPS; formati standard riducono conversioni manuali ed errori.

### Report linea / progetto

- **Idea:** **Report semplice** (es. PDF o HTML): nome progetto, elenco punti (coordinate, quota, ordine), lunghezze dei segmenti, lunghezza totale, riepilogo pendenze, eventuali foto/note.
- **Perché aiuta:** Pratiche, documentazione e passaggio ai team di progettazione senza aprire GIS o software di progetto.

---

## 5. Sicurezza e controlli

### Pendenza minima / controlli sulla pendenza

- **Idea:** **Controlli di pendenza** lungo i segmenti: es. “pendenza segmento &lt; X%” o “&gt; Y%” con avvisi o flag.
- **Perché aiuta:** SEILAPLAN verifica la pendenza minima per i sistemi gravitazionali; controlli simili nell’app supportano sicurezza e validazione del tipo di sistema.

### Tipi di punto ancoraggio / torre

- **Idea:** **Tipi o etichette di punto** come “ancoraggio”, “torre”, “piazzale”, “supporto intermedio” (e note come “ancoraggio tirante”).
- **Perché aiuta:** I dati da campo diventano strutturati per l’analisi tiranti/ancoraggi (es. GuylinePC) e per il reporting.

---

## 6. Flusso di lavoro e pianificazione

### Piazzale come concetto di primo piano

- **Idea:** **Piazzale** come tipo di punto o etichetta dedicata (es. “piazzale” a una o entrambe le estremità della linea).
- **Perché aiuta:** Coerente con il modo in cui CHPS/Softree e la documentazione di pianificazione trattano piazzali e corridoi.

### Multi-linea / unità di utilizzazione

- **Idea:** **Raggruppamento di progetti** (es. “Unità di utilizzazione X” o “Blocco Y”) o **esportazione multiselezione** per più linee in una volta.
- **Perché aiuta:** Le aziende spesso pianificano e riferiscono per area di utilizzazione con più linee.

---

## Tabella riepilogativa

| Area        | Esempio di funzionalità              | Beneficio per le aziende                                           |
| ----------- | ------------------------------------ | ------------------------------------------------------------------ |
| Meccanica   | Freccia/franco (semplificato)        | Controllo rapido “franco OK?”; si integra con flussi SEILAPLAN/CHPS |
| Meccanica   | Carico/campata o suggerimento “campata max” | Supporta lunghezza campate e decisioni sui supporti intermedi   |
| Terreno     | Profilo altimetrico (vista o export)  | Revisione standard; input per progettazione da desktop              |
| Modello dati| Tipo cavo/attrezzatura per progetto   | Ipotesi di progetto coerenti; collegamento con strumenti da ufficio |
| Export      | KML, Shapefile/GeoJSON, CSV profilo  | Si integra con GIS e SEILAPLAN/CHPS; passaggio di consegne migliore |
| Reporting   | Report linea (PDF/HTML)               | Pratiche, documentazione, passaggio alla progettazione              |
| Sicurezza   | Controlli pendenza / inclinazione    | Allineato a controlli su sistemi gravitazionali e sicurezza        |
| Struttura   | Tipi punto (ancoraggio, torre, piazzale) | Dati da campo più chiari; pronti per analisi tiranti/progetto   |

---

## Riferimenti (base della ricerca)

- **SEILAPLAN** — Plugin QGIS per il progetto di strade a fune; catenaria, franco, ottimizzazione supporti ([seilaplan.wsl.ch](https://seilaplan.wsl.ch/en/documentation/)).
- **CHPS** — Cable Harvest Planning Solution (ArcGIS); analisi carico e terreno ([cableharvesting.com](https://cableharvesting.com/)).
- **Softree** — Pianificazione cable harvesting con DTM, carico, multi-deflection ([softree.com](https://www.softree.com/products/cable-harvesting-planning)).
- **SKYTOWER / SKYMOBILE** — USDA Forest Service; carico vs campata per layout con torre e yarder mobile.
- **GuylinePC** — Analisi tensioni tiranti per torri da esbosco armate.

Per le funzionalità **attuali** dell’app, vedi **[CURRENT_FEATURES_README.md](./CURRENT_FEATURES_README.md)**.
