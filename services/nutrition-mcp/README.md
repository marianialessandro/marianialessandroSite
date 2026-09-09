# Nutrition MCP remoto

**Aggiornamento hosting:** per il dominio PHP/FTP usare [`../nutrition-mcp-php`](../nutrition-mcp-php/README.md), con OAuth locale e workflow FTP. Questo server Python resta disponibile per stdio o runtime ASGI.

Processo Python indipendente in `services/nutrition-mcp`, derivato dal bridge della branch `mcp_api`. Laravel rimane in `apps/api.marianialessandro.com`. Il bridge storico mantiene `python server.py`, trasporto stdio e `NUTRITION_API_URL`/`NUTRITION_API_TOKEN`.

L'implementazione locale è disponibile; la connessione reale ChatGPT, la scelta definitiva del provider/piano, DNS, TLS e il collaudo operativo richiedono gli account e l'infrastruttura. Non sono stati creati tenant, credenziali o servizi online. L'archivio nutrizionale resta personale e condiviso: non offre isolamento multiutente.

## Avvio e test

Python 3.12 per HTTP, PHP 8.3+ per Laravel. Dalla radice del monorepo:

```bash
uv venv --python 3.12 services/nutrition-mcp/.venv
uv pip sync --python services/nutrition-mcp/.venv/bin/python --require-hashes services/nutrition-mcp/requirements-dev.lock
services/nutrition-mcp/.venv/bin/python -m pytest services/nutrition-mcp/tests -q
services/nutrition-mcp/.venv/bin/python apps/api.marianialessandro.com/integrations/nutrition-mcp/test_server.py
services/nutrition-mcp/.venv/bin/python services/nutrition-mcp/server.py --help
```

Per HTTP iniettare le variabili di `.env.example` dal secret manager e avviare:

```bash
services/nutrition-mcp/.venv/bin/python services/nutrition-mcp/server.py --transport streamable-http --host 127.0.0.1 --port 8000
```

Il programma non carica automaticamente `.env`. Docker Compose usa un file privato esterno al repository. Nessuna `OPENAI_API_KEY` necessaria. Non stampare token o configurazioni complete durante il debug.

Da `apps/api.marianialessandro.com`, installare Composer ed eseguire la suite con una chiave esclusivamente di test:

```bash
composer install --no-interaction
APP_KEY=base64:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA= php artisan test
python3 scripts/test_nutrition_mysql.py
```

Il runner MySQL avvia Docker e usa un database effimero; non punta al database di produzione. La suite PHP senza Docker salta il caso MySQL dedicato.

## Contratto e autorizzazione

`contracts/catalog.json` fotografa i 182 contratti REST; `contracts/operations.md` ne elenca scope e abilitazione. `export_contracts.py` aggiorna entrambi senza accesso ai dati; CI controlla che non divergano da Laravel.

`MCP_DIAGNOSTIC_ONLY=true` espone soltanto `nutrition_status`, autenticato e senza database. Dopo il collaudo OAuth impostare `false`: con `MCP_SCOPES=nutrition:read` e `MCP_OPERATIONS` vuoto vengono esposte le 122 letture. Un elenco non vuoto limita esattamente gli ID disponibili. Write/delete/maintenance richiedono sia scope sia ID espliciti; le ultime due classi richiedono anche `confirm: true`. I parametri di ogni mutazione sono obbligatori, senza default dimostrativi.

Esempio di abilitazione staging: `MCP_SCOPES="nutrition:read nutrition:write"`, `MCP_OPERATIONS="19.5 19.6 5.1 5.12 16.8"`. L'identità di servizio Laravel e il client IdP devono autorizzare gli stessi scope. Nessun scope wildcard. Il booleano di conferma non prova un consenso umano indipendente.

Ogni richiesta `/mcp` verifica firma RS256, issuer, audience MCP, subject esatto, scadenza, durata massima 600 secondi e claim esclusivo degli access token. Clock skew massimo 15 secondi. Nessun ID token accettato. JWT API e MCP hanno audience distinte. La coppia issuer/subject ammessa è unica. Host esatto; Origin, se presente, deve appartenere a `MCP_ORIGINS`. Assenza di Origin consentita. Discovery pubblica alla radice e al percorso `/.well-known/oauth-protected-resource/mcp`; metadata dell'authorization server pubblicati dal provider indicato in `authorization_servers`, senza inventare endpoint locali.

Il catalogo ha cache di 30 secondi separata per profilo di scope. Ogni chiamata ricontrolla gli scope e l'allowlist; Laravel riverifica servizio, ruolo e scope anche con JWT già emessi. Il middleware macchina precede il rate limit per identità. Non assegna token Sanctum transitori e non modifica sessioni o PAT. Le route `/nutrition/tokens` mantengono `auth:web` e admin.

Le chiavi JWKS provengono soltanto da URL HTTPS configurate, con cache di 5 minuti, limite dimensione/numero chiavi e backoff di refresh; una nuova `kid` attiva il rinnovo, al massimo ogni 10 secondi. Il servizio usa RS256 con chiavi RSA almeno 2048 bit. URL nel token non vengono seguite. Provider e API non possono redirigere le richieste.

Il token macchina è richiesto tramite client credentials, con cache in memoria e lock per profilo esatto, rinnovo anticipato di 30 secondi, durata fra 60 e 300 secondi e backoff di 30 secondi in caso di errore. Il provider deve restituire `scope` uguale al profilo richiesto. Provider che restituiscono token con scope più ampi vengono rifiutati; usare client distinti per profilo o configurare scope per richiesta prima di abilitare write. Nessun refresh token o password amministrativa memorizzati.

Limiti iniziali: 256 KiB input, 1 MiB risposta MCP e 8 richieste concorrenti per processo. Le risposte REST di esecuzione sono limitate a un terzo del budget per lasciare spazio alle rappresentazioni testo e strutturata; superare il limite restituisce un errore completo. I dati DECIMAL e gli interi oltre la precisione JavaScript diventano stringhe. Il JSON non viene troncato. Il client non ritenta automaticamente alcuna operazione: in particolare, un timeout di scrittura produce “esito non determinato”, con richiesta di verificare tramite lettura. Per `429`/`503` viene riportato Retry-After numerico; nessun errore downstream richiede il login ChatGPT.

Audit JSON: request ID generato al confine MCP, pseudonimo HMAC, ID operazione, esito, durata; Laravel aggiunge ID servizio. Il pseudonimo dipende dal secret macchina e cambia alla rotazione. Non vengono registrati payload, dati nutrizionali, Authorization o secret. I log di accesso Uvicorn sono disattivati; non abilitare log HTTP dettagliati in produzione. Laravel non usa l'attore di audit come autorizzazione.

## Provider e collegamento ChatGPT

Auth0 è un candidato, non un provider già approvato o collaudato. La disponibilità delle funzionalità e i costi del piano devono essere verificati sull'account effettivo. Il codice può usare un IdP con il contratto JWT qui descritto, senza authorization server artigianale.

1. Creare in staging due risorse: `MCP_RESOURCE` e `NUTRITION_API_AUDIENCE`, con scope nutrizionali e durate rispettivamente 600 e 300 secondi. Configurare RS256 e annotare issuer/JWKS/token endpoint dai metadata fidati.
2. Creare un client ChatGPT preconfigurato, authorization code + PKCE S256. Registrare esattamente il callback mostrato nella connessione privata. Disabilitare iscrizione pubblica, attivare MFA e limitare l'accesso all'identità personale. Verificare che `resource`, discovery, consenso, refresh, rotazione e revoca funzionino nel tenant scelto.
3. Per Auth0, configurare l'Action di esempio `deploy/auth0-post-login.js` con l'issuer/subject verificati e collegarla al flusso Post Login. Essa limita la risorsa MCP all'utente e aggiunge un claim solo all'access token. Le variabili `OAUTH_ACCESS_CLAIM`/`OAUTH_ACCESS_VALUE` devono corrispondere. Non usare email per l'allowlist. MFA resta una policy da configurare nel tenant.
4. Creare un client macchina separato autorizzato esclusivamente sulla risorsa API. Verificare i claim firmati senza stampare il token: per l'esempio Auth0, `sub` è il subject macchina e `gty=client-credentials`; Laravel offre configurazione esplicita dei claim per altri provider. `OAUTH_AUDIENCE_PARAMETER=audience` riguarda soltanto client credentials Auth0; non elimina la prova del parametro `resource` di ChatGPT.
5. Provisionare il servizio Laravel come descritto sotto. Provare il rinnovo del token macchina e la revoca locale, poi il tool diagnostico con MCP Inspector e ChatGPT developer mode. Verificare anche un secondo utente autenticato, che deve essere rifiutato.
6. Abilitare read in staging, provare paginazione, precisione e prompt del piano. Abilitare solo gli ID write collaudati. Delete/maintenance restano disabilitati. Aggiornare la connessione e aprire una conversazione nuova dopo cambi dei metadata.

Le prove live di login/PKCE/refresh e dei menu ChatGPT non sono sostituibili dai test con JWT sintetici. Registrare evidenze e date in `ACCEPTANCE.md`.

## Upgrade Laravel e revoca

Configurare `NUTRITION_OAUTH_*` nell'ambiente API, con OAuth disabilitato fino al provisioning. Il client secret rimane esclusivamente nel runtime MCP. Con shell amministrativa:

```bash
php artisan migrate --force
php artisan nutrition:service VERIFIED_MACHINE_SUBJECT --issuer=https://YOUR_TENANT/ --admin=ADMIN_ID --scope=nutrition:read
php artisan nutrition:service VERIFIED_MACHINE_SUBJECT --issuer=https://YOUR_TENANT/ --revoke
```

Eseguire prima migrazione e prove in staging con backup verificato. Senza shell usare `database/phpmyadmin/001-nutrition-services.sql` nel database applicativo Laravel: crea la sola tabella nuova e registra la migrazione; include istruzioni commentate per i metadati. Eseguire una sola volta, verificando che la migrazione non sia già applicata. Non reimportare `nutrizionista_schema_mysql.sql`, che contiene `DROP DATABASE`. Non modificare la scadenza Sanctum di 480 minuti.

## Deploy, controllo e rollback

```bash
docker build -t nutrition-mcp:RELEASE services/nutrition-mcp
MCP_IMAGE=nutrition-mcp:RELEASE MCP_ENV_FILE=/secure/nutrition-mcp.env docker compose -f services/nutrition-mcp/deploy/compose.yaml up -d
```

Il workflow dedicato esegue test e build; non distribuisce automaticamente su infrastruttura non configurata. Caricare l'immagine sul registry privato scelto e usare tag immutabile/digest. Configurare DNS e il Caddyfile su VPS/container con HTTPS e rinnovo TLS automatico, mantenendo `/data` Caddy persistente. Il backend è esposto solo su loopback, Authorization preservato, Host originale richiesto. Health/readiness sono controlli minimi del processo e del kill switch, non attestano la disponibilità del provider o del database: monitorare separatamente chiamate diagnostiche e letture sintetiche autenticate. Nessun blocco IP globale sul dominio API. mTLS OpenAI è un'opzione successiva, da collaudare con discovery e login.

Kill switch immediato del processo: creare il percorso `MCP_DISABLED_FILE` nel container oppure fermare il container. Per una disabilitazione persistente arrestare il servizio o cambiare il subject consentito e ricrearlo; `/tmp` non sopravvive alla ricreazione. Revocare anche la registrazione Laravel e il client IdP in caso di incidente. La revoca IdP di un JWT utente offline può richiedere fino a 600 secondi più 15 secondi di skew; il kill switch è locale e immediato. La rotazione del secret macchina non revoca i JWT API già emessi, la revoca locale del servizio sì.

Rotazione secret proposta ogni 90 giorni: emettere la nuova versione nel provider, aggiornarla nel secret store, ricreare MCP, provare lettura/rinnovo, quindi revocare la precedente. Non mantenere due versioni oltre la finestra di verifica. Testare rotazione JWKS e rinnovo TLS. Dopo più di 8 ore verificare che le chiamate continuino senza intervento; il test locale simula il rinnovo ma non dimostra disponibilità infrastrutturale.

Rollback: disabilitare MCP e la registrazione API, distribuire l'immagine precedente e il codice Laravel precedente; conservare la tabella additiva per non perdere le registrazioni. La migrazione `down()` elimina solo questa tabella e richiede valutazione separata dei dati registrati. Sessioni, PAT, blog e app conservano i loro percorsi.

Fonti del contratto: [OpenAI OAuth](https://developers.openai.com/plugins/build/auth), [MCP authorization](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization), [SDK MCP Python](https://github.com/modelcontextprotocol/python-sdk), [OpenAI MCP server](https://developers.openai.com/plugins/build/mcp-server). Le API SDK utilizzate sono state controllate anche nel pacchetto installato `mcp==1.26.0`.
