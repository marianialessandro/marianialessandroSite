# Stato di implementazione e collaudo — 9 settembre 2026

Questo documento registra la versione Python iniziale. Dopo la conferma di hosting solo PHP/FTP è stato aggiunto [`../nutrition-mcp-php`](../nutrition-mcp-php/README.md), che è ora il target del dominio e usa Passport locale; lo stato qui sotto rimane storico.

Branch: `feat/nutrition-mcp-oauth`, derivata da `mcp_api` (`a6174232af5da46b51087b591e2da1c21f724334`). Worktree: `/Users/marianialessandro/repository/marianialessandroSite-mcp-oauth`. Server nuovo: `services/nutrition-mcp`.

## Verificato localmente

| Verifica | Risultato |
|---|---|
| Baseline Laravel prima delle modifiche | 23 superati, 1 MySQL saltato nella suite generale; 1051 assert |
| Baseline MySQL effimero | 1 superato, 193 assert |
| Baseline bridge stdio | 1 superato |
| Laravel con identità servizio | 29 superati, 1 MySQL saltato nella suite generale; 1080 assert |
| MySQL effimero dopo modifica | 1 superato, 193 assert |
| MCP remoto | 25 test superati, incluse esecuzioni simulate di tutte le 182 operazioni |
| Bridge stdio dopo refactor | 1 superato, entry point e variabili storiche |
| Protocollo SDK | Initialize, tools/list, tools/call, tool nascosti rifiutati; due client HTTP concorrenti con scope separati |
| JWT sintetici | Firma, issuer, audience, scadenza, durata, subject, claim access token; JWKS ruotata e kill switch |
| Credenziali API | Rinnovo anticipato, richieste concorrenti accorpate, profili distinti, scope eccedenti rifiutati, backoff |
| Laravel sicurezza | Nessun fallback JWT→sessione admin, revoca immediata, perdita ruolo, scope, provisioning Artisan e token management escluso |
| Errori e dati | Timeout mutazioni senza retry, errori HTTP sicuri, Retry-After, niente redirect, precisione DECIMAL/BIGINT, limite output |
| Build Docker | Superata con dipendenze fissate e hash verificati |
| Avvio container con configurazione sintetica | Processo senza root e filesystem read-only; health 200, discovery 200, MCP senza token 401; container rimosso al termine |
| Composer audit | Nessun advisory dopo aggiornamento puntuale di `league/commonmark` da 2.9.1 a 2.10.1 |
| Diff | Nessun errore di whitespace |

Il test MySQL usa Docker e il runner già presente. Non sono stati eseguiti comandi sui dati reali. Le prove del protocollo usano l'SDK client ufficiale con ASGI e JWT sintetici. Il container è stato verificato anche tramite socket HTTP locale. Il file dei contratti contiene ID, scope e schemi, senza risultati del database.

La dipendenza CommonMark era già vulnerabile nella baseline (`GHSA-8rr7-cvq3-gmfh`); Composer l'ha segnalata installando il verificatore JWT. È stato aggiornato il solo pacchetto necessario e rieseguita la regressione Laravel.

## Collaudo online ancora necessario

| Voce | Stato / evidenza da aggiungere |
|---|---|
| Account/workspace ChatGPT e developer mode | Da indicare e verificare sul relativo account |
| Provider e costo del piano | Auth0 candidato con Action di esempio; nessun tenant/piano scelto o acquistato |
| Client OAuth e callback | Da registrare esattamente dal collegamento ChatGPT |
| Login MFA, PKCE S256, resource e refresh utente | Da provare con tenant reale e secondo utente rifiutato |
| Contratto claim macchina e rinnovo reale | Da verificare sul provider prima di attivare OAuth Laravel |
| Runtime, registry, DNS e certificato TLS | Da predisporre; nessun servizio distribuito |
| Migrazione staging e produzione | Script Laravel/SQL pronti, applicazione non eseguita online |
| Inspector e conversazione ChatGPT | Da eseguire; nessuna connessione creata |
| Selezione tool su prompt realistici | Usare i sei prompt nel piano, prima diagnostica e read, poi write esplicite in staging |
| Continuità oltre 8 ore | Da osservare sul runtime con rinnovi reali; cache/rinnovo simulati non ne provano la disponibilità |
| Rotazione secret/JWKS/TLS e revoca operativa | Meccanismi locali testati e runbook pronto; prova infrastrutturale pendente |
| Produzione con dati personali | Non attivata; delete/maintenance disabilitati |

Il vincolo sequenziale dello step 1 del piano (prova provider prima dello sviluppo completo) non è stato dichiarato soddisfatto: è stata realizzata e collaudata la parte locale usando il contratto esplicito configurabile. Attivazione e collegamento restano subordinati alla prova reale del provider. Questo documento non certifica il completamento end-to-end del piano.

Il workflow CI verifica codice e costruisce l'immagine; non contiene credenziali né pubblica automaticamente su un runtime. Il percorso di deploy manuale è in `README.md`. Nessuna modifica alla knowledge base.
