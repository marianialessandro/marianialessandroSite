# Nutrition MCP — PHP/FTP con OAuth sulla propria infrastruttura

Questo è il server destinato a `https://mcp.marianialessandro.com/mcp` sull'hosting PHP/FTP. La directory è indipendente dalla API e dal bridge Python. Usa Laravel MCP 0.7.2 e Laravel Passport 13.8.0, con versioni nel lock Composer. Non richiede processi Python persistenti, container o un provider OAuth esterno.

Il server usa lo stesso database Laravel per autenticare l'amministratore già esistente, con un modello Passport e un cookie dedicati. Il modello Sanctum dell'API rimane invariato. I dati nutrizionali continuano a essere letti e modificati esclusivamente tramite la API REST; il server MCP non esegue le query nutrizionali direttamente.

## SQL sul Desktop

`/Users/marianialessandro/Desktop/INSTALLAZIONE_NUTRIZIONE_MCP.sql` è lo script completo per il database Laravel **già installato**. In phpMyAdmin selezionare quel database, verificare di avere un backup, quindi importare il file. Le strutture nutrizionali devono ancora essere assenti: è una prima installazione di tali strutture, non un aggiornamento di uno schema nutrizionale già popolato.

Il file aggiunge 9 tabelle nutrizionali, 5 viste, 4 trigger, 3 procedure, `nutrition_services` e le 5 tabelle OAuth di Passport. Non modifica lo schema `users` né le tabelle Sanctum. Inserisce i record delle nuove migrazioni in `migrations`, senza duplicarli. Le procedure vengono definite, non chiamate: gli INSERT/UPDATE/DELETE degli esempi nel catalogo non vengono eseguiti.

Target MySQL 8.0.16+, con privilegi per tabelle, viste, trigger e routine. Non contiene `DROP DATABASE`, `DROP TABLE`, `TRUNCATE`, importazioni distruttive o dati dimostrativi. `nutrizionista_query_catalog_mysql.sql` è un catalogo di esempi e non deve essere importato in blocco.

Lo script è riproducibile dalla radice del repository:

```bash
python3 services/nutrition-mcp-php/deploy/export_sql.py --output /Users/marianialessandro/Desktop/INSTALLAZIONE_NUTRIZIONE_MCP.sql
```

La sezione finale di provisioning resta inattiva con `@mcp_admin_id = NULL` e callback vuoto. Dopo aver ottenuto il callback esatto da ChatGPT, compilare quei due valori e rieseguire **solo quella sezione**. Crea un client pubblico PKCE senza secret e registra il servizio API read-only. Copiare gli ID mostrati nel `.env` del MCP. Nessun amministratore viene creato e non viene scelto automaticamente un account.

## Configurazione privata del MCP

Creare sul server `.env` da `.env.example`, nella radice `mcp.marianialessandro.com/`. Usare le credenziali del database Laravel esistente. Il file è escluso dal workflow e protetto via Apache.

Generare le chiavi localmente, nella directory di questo servizio, con un `.env` privato:

```bash
composer install --no-dev --no-interaction
php artisan key:generate
php artisan passport:keys
```

Caricare `.env`, `storage/oauth-private.key` e `storage/oauth-public.key` tramite il proprio accesso amministrativo. Non inserire le chiavi nel database o nei secret FTP condivisi. Il workflow non le distribuisce né le cancella. Il file privato dovrebbe essere leggibile soltanto dall'utente che esegue PHP. Il dominio deve avere HTTPS funzionante.

Configurare `MCP_ALLOWED_USER_ID` con il proprio amministratore e `MCP_CLIENT_ID` con l'ID del client creato. Mantenere `MCP_SCOPES=nutrition:read` e `MCP_DIAGNOSTIC_ONLY=true` per il primo collegamento. Impostare `MCP_ENABLED=true` soltanto quando chiavi e credenziali sono pronte. Con `false` le chiamate protette restituiscono 503; health e metadata restano raggiungibili.

Gli account non autorizzati sono respinti anche se amministratori. Il login usa la password Laravel esistente, senza registrazione pubblica. Questo servizio non aggiunge automaticamente MFA all'account: il requisito MFA del piano originario resta da completare prima di dichiarare completato il collaudo di sicurezza in produzione.

## Configurazione privata della API

Dopo il deploy della branch e l'importazione SQL, configurare il `.env` di `api.marianialessandro.com`:

```dotenv
NUTRITION_DB_HOST=localhost
NUTRITION_DB_DATABASE=LO_STESSO_DATABASE_LARAVEL
NUTRITION_DB_USERNAME=UTENTE_DATABASE
NUTRITION_DB_PASSWORD=PASSWORD_DATABASE
NUTRITION_OAUTH_ENABLED=true
NUTRITION_OAUTH_ISSUER=https://mcp.marianialessandro.com
NUTRITION_OAUTH_AUDIENCE=https://api.marianialessandro.com/nutrition
NUTRITION_OAUTH_JWKS_URL=https://mcp.marianialessandro.com/.well-known/jwks.json
NUTRITION_OAUTH_SERVICE_CLAIM=sub
NUTRITION_OAUTH_ACCESS_CLAIM=gty
NUTRITION_OAUTH_ACCESS_VALUE=mcp-service
```

Il subject registrato dal SQL è `nutrition-mcp-php`, uguale a `MCP_SERVICE_SUBJECT`. L'issuer non ha slash finale: deve coincidere esattamente nei due `.env` e nella registrazione del servizio.

Passport emette access token utente di 10 minuti, legati alla risorsa MCP, con PKCE S256 e refresh token ruotati di 7 giorni. I metadata pubblici espongono authorization/token endpoint, JWKS e scope. Il client OAuth è preconfigurato, senza DCR pubblico. Il parametro `resource` viene validato sia in autorizzazione sia nello scambio/rinnovo. I token utente sono verificati anche contro il registro Passport: la revoca locale è immediata.

Poiché il provider OAuth è ora ospitato nello stesso processo PHP, il servizio genera internamente un JWT API di 5 minuti a ogni richiesta REST, con audience API, subject macchina e scope separati. Non usa client credentials verso un provider esterno e non inoltra il token ChatGPT. Laravel verifica questo JWT con JWKS e la registrazione `nutrition_services`, compresi stato attivo e ruolo amministrativo. Non occorre un client secret M2M né una cache di rinnovo in un processo persistente. Questa è una modifica esplicita all'architettura Python/IdP esterno del piano originale.

## Workflow e collaudo

`.github/workflows/deploy-mcp.yml` segue gli altri deploy: push su `main` oppure avvio manuale, test PHP, audit Composer, artifact protetto e FTP verso `mcp.marianialessandro.com/` usando `FTP_SERVER`, `FTP_USERNAME`, `FTP_PASSWORD`. Verifica health, discovery, rifiuto di richieste anonime e protezione di `.env` e chiave privata. Il workflow non esegue migrazioni né configura credenziali sul server.

```bash
composer install --no-interaction
vendor/bin/phpunit --no-progress
```

I test coprono protocollo MCP, credenziali errate, ruolo e revoca, login/CSRF, authorization code con PKCE, resource/audience, rinnovo e riutilizzo del refresh token, tutte le 182 descrizioni, filtri read/write, precisione e separazione del token macchina. La suite PHP conta 10 test e 798 assert, superati sia su PHP 8.5 sia su PHP 8.3. Il file SQL è stato importato in MySQL effimero e verificato con i 193 assert del runner nutrizionale esistente. La prova Apache/PHP 8.3 verifica anche discovery, health e protezione dei file privati.

Restano prove online: callback/account ChatGPT effettivo, MFA, login dal dominio pubblico, revoca e rotazione chiavi reali, disponibilità oltre otto ore. Nessun deploy online è stato avviato durante questa implementazione. Il bridge Python/stdio resta disponibile per compatibilità, ma il workflow del dominio usa questo servizio PHP.

Dopo il tool diagnostico, impostare `MCP_DIAGNOSTIC_ONLY=false` per le letture. Write richiede scope aggiunto sia nel MCP sia nella registrazione API e gli ID espliciti in `MCP_OPERATIONS`. Delete/maintenance richiedono inoltre `confirm: true`. Tutti i valori delle mutazioni sono espliciti; nessun retry automatico dopo errori o timeout. Limiti: 256 KiB input, 1 MiB output, rate limit MCP/API di 60 richieste/minuto. La concorrenza dei processi è gestita dal piano PHP dell'hosting.

Per fermare l'accesso, impostare `MCP_ENABLED=false`, revocare i token Passport e disattivare il servizio API. Per revocare i token dell'account, impostare `revoked=1` in `oauth_access_tokens` per il proprio `user_id` e nei relativi `oauth_refresh_tokens`. Non condividere le chiavi RSA con altri servizi; la loro rotazione invalida i token precedenti quando la cache JWKS API viene aggiornata.

Riferimenti: [Laravel Passport](https://laravel.com/framework/docs/13.x/passport), [Laravel MCP](https://laravel.com/framework/docs/13.x/mcp), [OAuth ChatGPT](https://developers.openai.com/plugins/build/auth).
