# Teleferika

## 🚀 Contributors

Please refer to our [Contribution Guidelines](./CONTRIBUTING.md)
   

## Note per gli sviluppatori JLB

* Per la chiave di firma Android, creare una cartella `keys` e inserire il file delle chiavi `jlb-keystore.jks` e un file `keystore.properties` nella cartella.

* Nel file `keystore.properties` inserire:

```
properties
    storePassword=...la password...
    keyAlias=upload
    keyPassword=...la password...
    storeFile=../../keys/jlb-keystore.jks
#   Path relative to android directory
```

## Descrizione

L’utilizzo della gru a cavo per le operazioni di esbosco sta prendendo sempre più diffusione anche nel settore forestale italiano, in particolare nel nord del paese, e ben si presta alla morfologia del territorio laddove, ovviamente, il regime gestionale del soprassuolo boscato si presta dal punto di vista economico. L’asporto del legname tramite gru a cavo, indipendentemente essa sia convenzionale o mobile, richiede una pianificazione della linea di cavo impegnativa e laboriosa, affinché siano rispettati criteri di sostenibilità economica, sicurezza sul lavoro, limitazione dei danni al rimboschimento. La ricerca di soluzioni è spesso iterativa nella pratica; in particolare, per linee di cavo lunghe, possono essere necessari diversi tentativi prima di trovare una soluzione ottimale e, tale soluzione spesso non viene quindi raggiunta. Una progettazione della linea non ottimale può portare ad un impatto notevole del cantiere per quanto riguarda i danni al suolo, al soprassuolo con risvolti, durante e dopo le operazioni, al paesaggio. Impatti che potrebbero essere notevolmente ridotti se tale ottimizzazione potesse essere realizzata in modo preventivo e la gru a cavo riposizionata il minimo numero di volte necessario all’espletamento del cantiere.

A livello estero esistono diversi applicativi per la progettazione delle linee per le gru a cavo volti a superare i problemi sopra descritti e a rendere accessibili ai tecnici, anche solo con una formazione di base nell’utilizzo dei GIS, metodologie di progettazione che richiedono complesse analisi della morfologia del terreno e della copertura forestale.
Tuttavia, questi applicativi sono affetti da diversi vincoli per quanto attiene il contesto italiano, dei quali in primo luogo una specializzazione per contesti che possono essere associati a quelli del nord Italia, ovvero alla zona alpina. Un secondo aspetto è quello che, pur avendo alcuni di essi una licenza open-source, gli applicativi presenti hanno una implementazione che vede prioritario un loro utilizzo desktop per ufficio, aspetto che non facilita il tecnico in una operatività prettamente di campo.
L'azienda JLB Books s.a.s. possiede una applicazione mobile già sviluppata e fornita ad enti pubblici e aziende private che li aiuta nella elaborazione di dati rilevati nei boschi per diversi usi professionali.

L’obiettivo di questo WP vede l’implementazione di tecnologie digitali per la progettazione di precisione di linee per gru a cavo finalizzate a dare supporto alla minimizzazione dei danni al suolo, soprassuolo e paesaggio, in particolare la realizzazione di un insieme di librerie software (Application Programming Interface – API) che implementino la raccolta dei dati per la progettazione delle linee per gru a cavo. 
Le API, sviluppate con licenza open-source, potranno essere utilizzate per la realizzazione di web application, software desktop e applicazioni mobile che permetteranno di operare sia in modalità on-line che off-line 
Le attività previste per il WP sono:

•    la re-ingegnerizzazione e implementazione di API esistenti sulla base di applicazioni desktop open-source che implementano modelli per la progettazione delle linee di gru a cavo
•    Indagine sulle normali modalità utilizzate dagli operatori per il rilievo sul campo e l’elaborazione dei dati caratteristici per la progettazione di una linea per gru a cavo
•    Progettazione della API per garantire la perfetta aderenza ai requisiti funzionali dell’attività di raccolta dei dati 
•    Sviluppo delle API con tecnologia adeguata e che garantisca la più ampia compatibilità con altre tecnologie o sistemi in cui esse potrebbero essere integrate 
•    Test delle API sugli scenari previsti dal progetto
•    Rilascio della versione definitiva delle API su ambiente pubblico corredate della relativa completa documentazione utente e di sviluppo

Nell’ambito delle attività previste nel WP si effettuerà l’implementazione di una applicazione mobile assistente con le API sviluppate dando luogo ad una prima implementazione con possiblità utilizzo su campo reale.

Queste soluzioni tecnologiche mirano a ottimizzare il processo di progettazione e installazione delle gru a cavo, garantendo precisione ed efficienza nell’ambito di operazioni forestali.
