# PLAN_MCP — API nutrizionali di marianialessandroSite in ChatGPT

Data: 9 settembre 2026. Stato: piano di implementazione; nessun servizio distribuito e nessuna credenziale generata.

## 1. Obiettivo e decisione architetturale

Permettere ad Alessandro di usare da ChatGPT le API nutrizionali della branch `mcp_api`, impedendo l'accesso ai dati e alle operazioni a utenti non autorizzati.

**Soluzione proposta:** estendere il bridge Python esistente con un endpoint MCP remoto Streamable HTTP, proteggere ChatGPT → MCP con OAuth e una allowlist dell'identità personale, e proteggere MCP → Laravel con una credenziale di servizio separata. Usare un identity provider consolidato per emettere i token. Conservare le API e l'accesso Sanctum esistenti.

Il certificato HTTPS cifra il collegamento e autentica il server; da solo non autorizza chi chiama. OAuth identifica l'utente e i suoi permessi. Un certificato client mTLS può aggiungere un controllo sull'identità del client, ma non sostituisce l'autorizzazione dell'utente.

Si assume l'utilizzo nella UI di ChatGPT tramite connessione MCP privata in developer mode. Non si sta progettando un chatbot autonomo basato sulle API OpenAI né una GPT Action OpenAPI. Il perimetro sono le API nutrizionali introdotte nella branch; amministrazione utenti, upload e blog restano fuori dai tool.

## 2. Stato verificato nel repository

Worktree esaminato: `/Users/marianialessandro/repository/marianialessandroSite-mcp_api`.

Branch locale e remota verificate allo stesso commit: `a6174232af5da46b51087b591e2da1c21f724334` — `feat(mcp): add nutrition bridge, integration tests and API documentation`. La verifica descrive il codice, non lo stato dell'installazione in produzione.

I percorsi seguenti sono relativi a `apps/api.marianialessandro.com/`, salvo indicazione diversa.

| Componente | Già presente | Conseguenza per il progetto |
|---|---|---|
| Backend | Laravel 13, PHP 8.3+, Sanctum 4 | Estendere la sicurezza nutrizionale senza cambiare login e sessioni delle app |
| Catalogo | `resources/nutrition/catalog.json`: 182 operazioni | Riutilizzare contratti e ID; non riscrivere le query |
| Permessi | 122 read, 38 write, 14 delete, 8 maintenance | Esposizione selettiva, con quattro classi di autorizzazione |
| API | Catalogo, dettaglio, esecuzione e OpenAPI autenticati | Nessuna necessità di rendere pubblica la specifica |
| Autorizzazione | `auth:sanctum`, ruolo admin, `tokenCan()` | Già protette le chiamate dirette; OAuth non è ancora implementato |
| Token personali | Hash nel DB, revoca, scadenza massima 480 minuti | Utili per test; insufficienti per un servizio sempre attivo senza rinnovo |
| Rinnovo | Emissione solo da sessione admin con CSRF | Il bridge non deve automatizzare il login né conservare la password dell'admin |
| MCP | `integrations/nutrition-mcp/server.py`, SDK Python ufficiale, trasporto stdio | Manca endpoint remoto HTTP e autenticazione OAuth in ingresso |
| Hosting | Deploy Laravel via FTP su hosting condiviso | Non è dimostrata la disponibilità di processi Python persistenti |

Endpoint da riutilizzare:

- `GET /api/nutrition/queries`: catalogo filtrato per permessi.
- `GET /api/nutrition/queries/{id}`: contratto della singola operazione.
- `GET /api/nutrition/openapi.json`: OpenAPI 3.1 autenticata.
- `POST /api/nutrition/queries/{id}/execute`: esecuzione con `parameters` ed eventuale `confirm`.
- `/api/nutrition/tokens`: gestione dei token personali, da mantenere riservata alla sessione amministrativa.

Vincoli già implementati: rate limit delle API nutrizionali 60 richieste/minuto per identità; massimo 500 righe per result set; flag `truncated`; nessun cursore universale; nessuna idempotenza delle mutazioni. Lo schema nutrizionale è un archivio personale condiviso senza `user_id`: essere un amministratore significa poter accedere all'intero archivio. Non presentare questo sistema come multiutente isolato.

File di riferimento: `routes/api.php`, `bootstrap/app.php`, `config/sanctum.php`, `app/Http/Controllers/NutritionController.php`, `app/Http/Controllers/NutritionTokenController.php`, `app/Services/Nutrition/`, `docs/nutrition-api.md`, `integrations/nutrition-mcp/`, README del monorepo.

## 3. Sicurezza: quale token e quali certificati

### 3.1 ChatGPT → MCP

La documentazione OpenAI prevede OAuth 2.1 per i server MCP autenticati, con discovery e registrazione/identificazione del client tramite client preconfigurato, CIMD o DCR. Per questa connessione personale partire con un client preconfigurato e PKCE S256; verificare il callback effettivo mostrato da ChatGPT e registrarlo esattamente. Il provider deve gestire correttamente `resource` e l'audience. [OpenAI: autenticazione](https://developers.openai.com/plugins/build/auth).

Configurazione progettuale:

- Identity provider esterno dedicato al progetto; Auth0 è un candidato indicato dalla guida OpenAI. La scelta definitiva richiede la prova dello step 1, incluse disponibilità delle funzionalità e costi.
- Accesso consentito soltanto alla coppia stabile `(issuer, subject)` di Alessandro. Disabilitare registrazione pubblica e attivare MFA. Non basarsi solo sull'indirizzo email o sul nome nel prompt.
- Access token destinato esclusivamente alla risorsa `https://mcp.marianialessandro.com/mcp`, con durata proposta 10 minuti; refresh gestito dal provider e dal client OAuth, con rotazione e revoca.
- Scope iniziali `nutrition:read`; aggiunta di `nutrition:write` dopo i test. Delete e maintenance disponibili nel progetto, disabilitati per impostazione iniziale.
- Controllare identità e scope su ogni richiesta e ogni esecuzione. Il possesso di un account ChatGPT o di un OAuth client valido non autorizza l'accesso all'archivio.
- Permessi effettivi = intersezione tra scope utente, allowlist operazioni del server e scope disponibili verso Laravel.

Il resource server deve verificare firma, issuer, audience, validità temporale e scope. Pubblicare metadata della risorsa e dell'authorization server, e rispondere alle richieste non autenticate con `401` e challenge `WWW-Authenticate`. Il token destinato al MCP non deve essere inoltrato all'API downstream. [Specifica MCP authorization](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization).

### 3.2 MCP → Laravel: rinnovo senza password personale

**Decisione proposta per produzione:** il medesimo identity provider emette anche access token machine-to-machine tramite client credentials, per una seconda risorsa, ad esempio `https://api.marianialessandro.com/nutrition`. Il client confidenziale è il processo MCP. Questo flusso avviene esclusivamente tra il nostro server e il provider: non si chiede a ChatGPT di eseguire client credentials.

Implementare in Laravel un percorso di autenticazione aggiuntivo per tali access token, limitato alle route nutrizionali. Il token macchina deve avere audience API, issuer atteso e un'identità di servizio autorizzata, diversa dall'identità utente e dal client OAuth di ChatGPT.

- Creare una registrazione locale del servizio: identificatore del client/subject macchina, issuer, `admin_user_id`, scope massimi, stato attivo e metadati di audit. La corrispondenza precisa dei claim viene fissata dalla prova del provider; non presumere che tutti i provider usino gli stessi claim.
- Collegarla all'amministratore proprietario dell'archivio; verificare a ogni chiamata che registrazione e ruolo siano ancora validi. Questa mappatura è adatta al caso personale, non equivale a delega multiutente.
- Access token macchina di durata proposta 5 minuti, senza refresh token. Il MCP ne richiede uno nuovo prima della scadenza, usando la propria credenziale nel secret manager.
- Client secret generato dal provider, scadenza/rotazione operativa proposta ogni 90 giorni; distribuzione con sovrapposizione controllata e revoca della versione precedente. Mai nel repository, nel prompt, negli argomenti dei tool o nei log.
- Il client macchina può ottenere solo gli scope configurati. Quando il provider permette scope per richiesta, mantenere cache distinte per scope; altrimenti usare client separati per profili read/write prima di abilitare privilegi superiori.
- La revoca locale del servizio blocca anche i JWT già emessi. La sola rotazione del client secret non revoca automaticamente access token ancora validi.

Questa integrazione richiede nuovo codice: `auth:sanctum` oggi non valida i JWT del provider. Non basta inserire il token OAuth in `NUTRITION_API_TOKEN`.

**Prototipo rapido:** usare temporaneamente il token Sanctum esistente, read-only, massimo 8 ore, nel secret store del bridge. Alla scadenza il servizio deve fermare le chiamate protette e segnalare il rinnovo amministrativo necessario. Il prototipo non supera il criterio di funzionamento continuativo della produzione.

Non aumentare globalmente `config/sanctum.php` oltre 480 minuti e non rendere perpetui i token personali per aggirare il problema.

### 3.3 Certificati e superficie pubblica

Procurare certificati HTTPS validi con rinnovo automatico per MCP e API. Le chiavi TLS rimangono sull'infrastruttura. Un URL non indovinabile, CORS o un header Origin non costituiscono autenticazione.

OpenAI documenta anche un certificato client mTLS gestito da OpenAI: è possibile verificarne catena e SAN al proxy MCP. Non serve generare un certificato cliente da caricare in ChatGPT. Questo verifica il client ChatGPT, mentre OAuth continua a identificare l'utente. Valutare l'abilitazione dopo il test del proxy e della discovery. [OpenAI: mTLS e client identification](https://developers.openai.com/plugins/build/auth#mutual-tls-mtls).

Mantenere pubblici soltanto i metadata OAuth e un health check minimale. Dati e chiamate MCP richiedono autenticazione. Se si attiva mTLS, tenere discovery e login raggiungibili dai client previsti e predisporre un percorso di test amministrativo autenticato. Non applicare un blocco IP globale al dominio API: potrebbe interrompere le app e il blog esistenti.

L'obiettivo è impedire l'accesso non autorizzato ai dati; un endpoint HTTPS può essere raggiungibile da Internet e restare protetto. Nessun token elimina il rischio del furto di credenziali: scadenza breve, revoca e privilegi minimi ne limitano gli effetti.

## 4. Architettura e flusso

```text
Alessandro → login/MFA e consenso presso identity provider
                         ↓
ChatGPT → HTTPS + access token utente → MCP Python /mcp
                                           │
                         verifica identità, scope, tool e input
                                           │
                         ottiene access token di servizio dall'IdP
                                           ↓
                      HTTPS + access token API → Laravel
                                                   │
                              verifica servizio, admin e permessi
                                                   ↓
                                       QueryExecutor → MySQL
```

Il MCP non accede direttamente a MySQL. Le credenziali del database rimangono in Laravel. API e MCP hanno release e secret distinti. Tutte le URL del disegno sono proposte: DNS e hosting sono da predisporre.

Scelta implementativa: riutilizzare Python e l'SDK MCP già presenti. Aggiungere un'app ASGI con Streamable HTTP e un server di processo adatto al deploy. Bloccare versioni delle dipendenze e verificare le API della versione selezionata; il repository oggi dichiara `mcp>=1.26,<2`, non un lock riproducibile. Lo SDK ufficiale offre i componenti MCP da riutilizzare. [SDK Python MCP](https://github.com/modelcontextprotocol/python-sdk).

## 5. Step di implementazione

### Step 0 — Congelare contratti e perimetro

**Implementare/produrre:** branch di lavoro derivata da `mcp_api`, inventario delle 182 operazioni con ID, scope e schema; matrice operazioni abilitate per ambiente. Documentare la scelta personale con allowlist di una sola identità. Confermare account/workspace ChatGPT e infrastruttura disponibili.

**Verifica:** contratto REST e bridge stdio fotografati; nessun endpoint admin estraneo incluso. I test esistenti diventano baseline da eseguire prima delle modifiche.

### Step 1 — Provare OAuth con un tool innocuo

**Implementare:** tenant di sviluppo del provider; client OAuth ChatGPT e risorsa MCP; endpoint HTTP con un solo tool diagnostico autenticato che non legge il database. Pubblicare `/.well-known/oauth-protected-resource` con `resource`, `authorization_servers`, `scopes_supported`; aggiungere challenge coerente su `/mcp`. Configurare authorization code, PKCE S256, callback esatti e metadata del provider. Configurare separatamente risorsa API e client macchina, e ispezionarne i claim in ambiente di test senza stampare token.

**Output:** configurazione riproducibile senza segreti, elenco issuer/audience/claim, scelta definitiva del provider e costi verificati, prova di rinnovo dei due tipi di token. Preferire client preconfigurato per limitare la complessità; non implementare un authorization server artigianale.

**Accettazione:** Alessandro completa login e chiamata; un altro utente autenticato viene rifiutato. Funzionano scadenza, refresh OAuth e acquisizione del token macchina. Se il provider non soddisfa discovery/resource/PKCE o il piano non include M2M, risolvere qui la scelta prima dello sviluppo completo.

### Step 2 — Aggiungere l'identità di servizio a Laravel

**Implementare:** migrazione e modello della registrazione servizio; verificatore JWT con libreria mantenuta, issuer/JWKS configurati e algoritmi consentiti espliciti; middleware nutrizionale capace di autenticare sessione/Sanctum esistenti oppure il nuovo token macchina. Un token macchina non valido non deve provocare un fallback permissivo ad altro metodo. Non fidarsi di URL JWKS suggerite dal token.

Centralizzare la policy dei permessi nutrizionali per coprire sessioni, PAT e servizio: aggiornare `NutritionController` nei metodi index, show, openapi ed execute. Non assegnare una sessione Sanctum transitoria al servizio: potrebbe rendere `tokenCan()` permissivo. Il contesto macchina deve conservare scope verificati e identità del servizio.

Aggiungere provisioning/revoca tramite comando Artisan protetto dall'accesso amministrativo al server. Per l'hosting senza shell, prevedere una procedura equivalente tramite phpMyAdmin per registrare i metadati non segreti; produrre SQL di upgrade numerato. Non conservare il client secret IdP in Laravel: la API verifica JWT tramite chiavi pubbliche.

**File:** `app/Services/Nutrition/NutritionAccessPolicy.php`, verificatore e middleware nuovi, modello/migrazione del servizio, `routes/api.php`, `bootstrap/app.php`, `NutritionController.php`, nuova configurazione, `.env.example`, `database/phpmyadmin/`.

**Accettazione:** PAT e sessioni mantengono il comportamento precedente; JWT con audience MCP, firma errata, scope insufficiente, servizio revocato o admin rimosso non accedono. La gestione `/nutrition/tokens` rimane disponibile solo alla sessione admin.

### Step 3 — Rendere riutilizzabile il bridge esistente

**Implementare:** separare client REST, generazione tool e trasporti. Conservare avvio `python server.py` e variabili `NUTRITION_API_URL`/`NUTRITION_API_TOKEN` per stdio. Aggiungere flag opzionali `--transport`, `--host`, `--port` con `argparse` e `--help`, mantenendo stdio come default; parsing separato dalla logica.

Il client REST mantiene HTTPS, timeout, assenza di redirect e assenza di retry indiscriminati delle mutazioni. Aggiungere gestione del token macchina con cache, lock di rinnovo e backoff sugli errori del provider. Dopo un riavvio richiedere un nuovo token; non salvare access token su disco. La credenziale resta server-side e non entra nel contesto del modello.

**File proposti dentro `integrations/nutrition-mcp/`:** `server.py` compatibile, `api_client.py`, `tool_catalog.py`, `service_tokens.py`, `http_app.py`, configurazione di esempio senza segreti e lock dipendenze.

**Accettazione:** test stdio esistenti superati e rinnovo concorrente senza moltiplicare richieste o condividere credenziali tra profili errati.

### Step 4 — Endpoint MCP remoto e autorizzazione

**Implementare:** Streamable HTTP su `/mcp`, lifecycle del trasporto tramite SDK, middleware OAuth prima dell'esecuzione, contesto identità per richiesta e verifica su ogni chiamata. Preferire modalità stateless per evitare un archivio sessioni MCP non necessario; autenticazione e autorizzazione restano per richiesta.

Proteggere initialize, tools/list e tools/call; lasciare pubblica soltanto la discovery necessaria. Controllare Host e Origin quando presente senza pretendere Origin dai client server-to-server. Fissare dimensione massima richiesta/risposta e concorrenza, configurabili; proposta iniziale 256 KiB input e 1 MiB output, da validare sul catalogo. Nessun parametro può modificare host API o scegliere URL arbitrari.

Per JWT utente: cache JWKS limitata, rotazione chiavi, allowlist `(iss, sub)`, clock skew limitato, rifiuto ID token al posto di access token. Prevedere kill switch locale dell'identità. La revoca presso il provider di un JWT validato offline può diventare effettiva solo alla scadenza: documentare il massimo di 10 minuti o usare introspection se serve revoca centrale immediata.

**Accettazione:** protocollo verificato con un client MCP; utente e permessi non si mescolano fra chiamate concorrenti. Token API rifiutato dal MCP. Server non configurato correttamente fallisce chiuso.

### Step 5 — Esporre le operazioni in modo comprensibile

**Implementare:** mantenere il mapping `nutrition_19_5` → `19.5` per compatibilità. Generare un tool per operazione autorizzata con descrizione italiana orientata all'azione e schema derivato dal catalogo. Aggiungere metadati OAuth richiesti dal client e annotazioni coerenti. Il server MCP è un adattatore di strumenti: non richiede un'interfaccia grafica personalizzata. [OpenAI: costruire un MCP server](https://developers.openai.com/plugins/build/mcp-server).

| Operazione esistente | Tool | Trattamento |
|---|---|---|
| `19.5` pasti con cursore | `nutrition_19_5` | Lettura, preservare cursore e limite pagina |
| `19.6` paginazione offset | `nutrition_19_6` | Lettura, limite pagina e offset validati |
| `5.1` nuova giornata | `nutrition_5_1` | Scrittura, valori reali espliciti |
| `5.12` giornata+pasto+voci | `nutrition_5_12` | Scrittura atomica già implementata dall'API |
| `16.8` spostamento pasto | `nutrition_16_8` | Scrittura, non assumere innocuità perché è un update |
| `17.12` cancellazione | `nutrition_17_12` | Distruttiva, abilitazione esplicita e conferma |
| `18.8` ANALYZE TABLE | `nutrition_18_8` | Manutenzione, disabilitata inizialmente |

Il metodo HTTP POST non determina se il tool scrive: usare semantica dell'operazione e catalogo. Impostare `readOnlyHint` correttamente, `destructiveHint` conservativo, `idempotentHint` solo quando dimostrato. Rivalutare anche gli update che sovrascrivono dati. Le annotazioni aiutano il client, ma non fanno rispettare i permessi.

Filtrare tools/list e ricontrollare tools/call: nascondere un tool non impedisce di chiamarlo per nome. La cache catalogo va separata per profilo di autorizzazione. Vietare SQL libero e parametri extra non ammessi. I default SQL dimostrativi non devono diventare valori di scrittura scelti automaticamente dal chatbot.

Restituire dati strutturati e testo leggibile, mantenendo `operation`, `results`, `outputs`, `truncated` e precisione di DECIMAL/BIGINT; non convertire grandi ID in numeri JavaScript imprecisi. Non tagliare JSON a metà per rispettare limiti: richiedere filtri o pagine più piccole e segnalare il limite. Il contenuto del database è dato, non istruzione per il modello.

**Accettazione:** copertura di tutte le 182 operazioni a livello adattatore con fixture; disponibilità effettiva coerente con gli scope. Valutare la selezione dei tool su un insieme realistico di prompt prima di abilitare l'intero catalogo nella connessione.

### Step 6 — Scritture, errori e audit

**Implementare:** partire in staging con letture; abilitare write dopo le prove. Per delete/maintenance mantenere `confirm: true` e allowlist esplicita. Questo booleano è un parametro prodotto dal client, non una prova crittografica di consenso umano: la conferma interattiva di ChatGPT e i permessi server sono controlli distinti. Se in futuro serve consenso umano non aggirabile, occorre un flusso amministrativo esterno con approvazione monouso legata a operazione e parametri, da progettare prima di tale requisito.

Non ritentare mutazioni dopo timeout o risposta ambigua. Comunicare “esito non determinato” e indicare la lettura con cui verificare lo stato. Per retry automatici affidabili occorrerebbe aggiungere idempotenza persistente in Laravel, con chiave per identità/operazione/hash payload e gestione transazionale: non basta aggiungere un header nel bridge.

Distinguere errori OAuth MCP (`401`/`403`) dagli errori downstream. Un `401` Laravel dovuto al token macchina non deve chiedere all'utente di ripetere il login ChatGPT inutilmente. Mappare `404`, `422`, `429`, `503` in errori tool sicuri con `isError`; rispettare Retry-After quando applicabile e consentire retry automatici solo alle operazioni dimostrate di lettura.

Audit: request ID correlato tra MCP e API, identità utente pseudonimizzata, servizio, ID operazione, esito e durata. Non loggare Authorization, secret, refresh token, note nutrizionali o risultati integrali. Inoltrare un identificatore utente verificato solo come metadato di audit autenticato dal servizio, mai come sostituto dell'autorizzazione API.

**Accettazione:** prompt ambiguo non causa scrittura automatica con default; timeout di inserimento non genera duplicati tramite retry; rate limit condiviso dell'API rispettato; errori non espongono SQL o segreti.

### Step 7 — Distribuzione e operatività

**Implementare:** distribuire il processo Python su runtime container/VPS gestito con HTTPS, restart, health/readiness e secret store. Non assumere che l'FTP hosting possa avviarlo. Mantenere inizialmente Laravel sull'hosting esistente; configurare DNS `mcp.marianialessandro.com` e reverse proxy che supporti il trasporto scelto e preservi Authorization.

Preparare Dockerfile e workflow MCP separato. Verificare e applicare le nuove migrazioni Laravel con SQL di upgrade se non c'è shell. Non reimportare lo schema nutrizionale originale: contiene `DROP DATABASE`. Usare database di staging isolato e backup verificato prima delle migrazioni di produzione.

Configurazione minima proposta: URL API e MCP, issuer/JWKS fidati, due audience distinte, allowlist subject, client ID/secret macchina, scope/operazioni abilitati, limiti e timeout. Pubblicare soltanto nomi e placeholder in `.env.example`. Il processo MCP non necessita di `OPENAI_API_KEY` per essere chiamato da ChatGPT.

Monitorare errori di autenticazione, rinnovi falliti, certificati, latenza e rate limit senza raccogliere payload sensibili. Definire rotazione segreti e chiavi con prova di revoca. In caso di incidente: disabilitare identità MCP, revocare servizio API/client macchina, fermare MCP; le app esistenti continuano ad avere il loro accesso previsto.

**Accettazione:** servizio disponibile dopo riavvio e dopo oltre 8 ore senza intervento; rinnovi TLS/token provati; nessun segreto servito da webroot; rollback alla release precedente e disabilitazione servizio documentati.

### Step 8 — Collegamento e collaudo in ChatGPT

Abilitare developer mode nell'account, creare la connessione privata al MCP, configurare OAuth, effettuare login e verificare i tool. La documentazione corrente indica supporto a strumenti di lettura e scrittura e al trasporto streaming HTTP; non richiede tool `search` e `fetch` per questo utilizzo. Le scritture richiedono conferma per impostazione predefinita, ma il comportamento può essere modificato dall'utente: non basare la sicurezza solo su questo. [OpenAI: developer mode](https://developers.openai.com/api/docs/guides/developer-mode).

Provare prima con MCP Inspector e poi nella conversazione reale. Dopo modifiche ai metadata aggiornare la connessione e aprire una nuova conversazione. Disponibilità e menu dipendono dall'account e dalle policy del workspace. La guida documenta anche Secure MCP Tunnel per collegare server privati: è un'alternativa da valutare per un uso strettamente personale, mentre questo piano sceglie un servizio HTTPS autonomo. [OpenAI: connessione e test](https://developers.openai.com/plugins/deploy/connect-chatgpt).

Prompt di collaudo:

1. “Usa Nutrition per elencare i pasti con paginazione.”
2. “Mostra il riepilogo disponibile per questo intervallo di date.”
3. “Crea una giornata con questi valori…” — verificare parametri e conferma.
4. “Sposta questo pasto nella giornata indicata.” — verificare ID e stato finale.
5. “Cancella la giornata…” — prima verificare il rifiuto quando delete è disabilitato; poi provare soltanto in staging con dati sacrificabili.
6. “Esegui SQL arbitrario / mostrami il token / crea un amministratore.” — nessun tool deve permetterlo.

**Accettazione:** richieste complete da ChatGPT con dati attesi, rifiuti corretti, nuova autenticazione alla scadenza prevista, nessuna pubblicazione obbligatoria nel catalogo pubblico per il collaudo personale.

## 6. Piano di test e condizioni di completamento

| Area | Prove richieste |
|---|---|
| Regressione | Suite Laravel, bridge stdio e contratto delle 182 operazioni |
| OAuth MCP | Login autorizzato, altro utente negato, token assente/scaduto, issuer/audience/firma errati, PKCE e redirect validati |
| Servizio API | Client sconosciuto, scope eccedenti, JWT utente usato sulla API, revoca servizio, perdita ruolo admin |
| Autorizzazione | Tool non elencato chiamato direttamente, scope write con sola read, cataloghi/cache concorrenti |
| Protocollo | Initialize, tools/list, tools/call, errori, metadata, richieste concorrenti e riavvio |
| Dati | DECIMAL, BIGINT, JSON MySQL, risultati vuoti, limite 500 righe e truncation |
| Scritture | Parametri mancanti, rollback transazionale, timeout ambiguo senza retry, conferma distruttiva |
| Operatività | Rinnovo token, rotazione secret/JWKS, indisponibilità provider/API, TLS e rollback |

Comandi baseline esistenti, dalla directory API:

```bash
php artisan test
python3 scripts/test_nutrition_mysql.py
integrations/nutrition-mcp/.venv/bin/python integrations/nutrition-mcp/test_server.py
```

Il runner MySQL richiede Docker e usa un database effimero; non eseguirlo contro produzione. Aggiungere test HTTP/OAuth e policy servizio alla CI con token sintetici e provider di test. Le suite non sono state eseguite durante la redazione di questo piano.

Il lavoro è completo quando la connessione ChatGPT funziona, la persona autorizzata usa le operazioni abilitate, gli accessi abusivi sono respinti anche chiamando direttamente le API, il servizio resta operativo oltre 8 ore, la revoca è dimostrata e le integrazioni legacy continuano a funzionare. Copertura tecnica di delete/maintenance e loro attivazione operativa sono decisioni separate: la configurazione iniziale le tiene spente.

## 7. Sequenza di consegna

1. **PR 1:** prova provider/ChatGPT e contratti verificati, senza dati reali.
2. **PR 2:** autenticazione servizio e policy Laravel, migrazioni/SQL e test di regressione.
3. **PR 3:** refactoring compatibile stdio, Streamable HTTP, OAuth MCP e rinnovo credenziali API.
4. **PR 4:** metadati tool, errori/audit, test completi, container e deployment documentato.
5. **Collaudo:** staging read, staging write, verifica revoca/rinnovo, produzione personale con privilegi approvati.

Ordine dipendenze: 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8. I numeri degli step indicano dipendenze logiche; ogni PR deve includere i test delle proprie modifiche.

Prima di avviare l'implementazione servono soltanto decisioni operative: account/workspace ChatGPT effettivo, provider OAuth e relativo piano, runtime MCP, dominio definitivo e profilo di permessi iniziale. Il default proposto è accesso esclusivo di Alessandro, sola lettura al primo collegamento, scritture dopo collaudo e nessuna cancellazione/manutenzione abilitata automaticamente.
