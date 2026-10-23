# WordPress come CMS del blog

Il frontend PHP legge i contenuti da WordPress a ogni richiesta e mantiene la grafica e gli URL esistenti. Gli stili vengono estratti dai componenti Svelte originali durante il deploy del codice, senza ricopiarli manualmente. Articoli e metadati sono già presenti nell’HTML, anche senza JavaScript. Non serve alcun token GitHub e non si ricostruisce il frontend quando cambia un articolo. WordPress gestisce articoli, tag, media e account sotto `https://blog.marianialessandro.com/cms/`. L’API Laravel continua a servire le altre applicazioni.

## Database e credenziali

WordPress usa lo stesso database MySQL/MariaDB dell’API, in tabelle separate con prefisso `wp_blog_`. Non importare nuovamente `000-initial-schema.sql`: quello script serve solo per un database Laravel vuoto.

L’importatore copia gli account con `is_admin = 1`, conservando email, nome e hash BCrypt/Argon2 della password. Puoi quindi accedere a WordPress con **la stessa email e password**. Le tabelle Laravel rimangono intatte; gli altri utenti non vengono importati. Dopo la migrazione le modifiche alle password nei due sistemi sono indipendenti. WordPress aggiorna il proprio hash dopo l’accesso, senza modificare quello Laravel.

Gli articoli mantengono slug, data, bozze, programmazione, tag, descrizione, copertina, evidenza e ordine. Il Markdown viene convertito in HTML in un blocco classico modificabile con Gutenberg; l’originale resta in metadati privati. I file media già ospitati dall’API continuano a usare i loro URL: conserva lo storage Laravel. I nuovi upload appartengono a WordPress.

## Prova locale

Dal root del monorepo:

```bash
npm ci
composer install --working-dir services/blog-wordpress
python3 services/blog-wordpress/deploy/build.py --output services/blog-wordpress/build
python3 services/blog-wordpress/deploy/build_frontend.py --output services/blog-wordpress/public/build
docker compose -f services/blog-wordpress/compose.yml up -d --wait
```

Il builder richiede una directory nuova e verifica lo SHA-256 dell’archivio WordPress indicato in `deploy/wordpress-release.json`. Se hai già un artifact, usa una nuova directory oppure riutilizza quello presente; non serve ricostruirlo a ogni avvio Docker. Non versionare il core scaricato.

Per un collaudo con dati fittizi, su questo database locale isolato:

```bash
docker compose -f services/blog-wordpress/compose.yml exec -T wordpress php /var/www/tests/integration.php
python3 services/blog-wordpress/tests/dynamic_blog.py
python3 services/blog-wordpress/tests/sql_bootstrap.py
```

Blog dinamico: `http://localhost:8081/`. WordPress sullo stesso dominio: `http://localhost:8081/cms/wp-admin/`. Il servizio di collaudo CMS separato resta su `http://localhost:8080/wp-admin/`. Il test crea l’account fittizio `legacy@example.test` con password `legacy-password-only-for-test`; non sono credenziali di produzione. L’installazione e i test richiedono Docker avviato. Il database di questo compose è indipendente da quello del compose principale.

```bash
docker compose -f services/blog-wordpress/compose.yml down
```

Questo comando ferma i container e conserva il database locale. Il workflow CI include anche il percorso Laravel preesistente e un test HTTP del blog dinamico: pubblica, modifica e ritira un articolo verificando ogni aggiornamento senza rebuild.

## Passaggio manuale in phpMyAdmin

Il file unico da eseguire è [`database/phpmyadmin/010-wordpress-bootstrap.sql`](database/phpmyadmin/010-wordpress-bootstrap.sql). È stato generato dallo schema realmente installato dal core WordPress 7.1.3, senza esportare utenti, password o contenuti del database di prova.

1. In phpMyAdmin seleziona il database già utilizzato dall’API Laravel, quello che contiene `users` e `posts`.
2. Esporta un backup del database.
3. Apri **Importa**, seleziona `010-wordpress-bootstrap.sql` ed esegui il file intero. Non occorre sostituire nomi di database, email o password nel file.
4. Controlla l’ultimo risultato: `esito = PRONTO`, con `account_copiati` maggiore di zero. A questo punto avvisa per riprendere configurazione, importazione degli articoli e deploy. Se compare `NON ESEGUITO` o un errore, riporta il messaggio prima di proseguire.

Lo script crea le dodici tabelle `wp_blog_`, le opzioni iniziali, i ruoli e la categoria predefinita. Copia solo gli amministratori Laravel, leggendo direttamente gli hash password già presenti in `users`, e li registra come già importati per evitare duplicazioni. Mantiene intatte tutte le tabelle Laravel. Il controllo preliminare salta ogni modifica se trova tabelle `wp_blog_` già presenti, se manca un amministratore oppure se gli account non sono compatibili. Una riesecuzione dopo l’installazione non aggiorna né sovrascrive dati.

Gli articoli rimangono nelle tabelle originali fino all’importazione tramite WordPress: la conversione Markdown → HTML richiede il parser PHP. Non serve altro SQL manuale per quella fase. Il file non esegue il caricamento dei file CMS, non contiene la password MySQL dell’hosting e non abilita il passaggio pubblico del blog a WordPress.

Il generatore versionato è `deploy/export_sql.php` (`--help` descrive l’interfaccia). Richiede un database vuoto, isolato e chiamato esattamente `blog_wordpress_sql_export`; rifiuta il database di produzione e un file di output già esistente. Il collaudo `tests/sql-bootstrap.php` verifica bootstrap, autenticazione, ruoli, importazione successiva e integrità dei dati Laravel su un database di prova separato.

## Installazione sul server FTP

1. Esegui un backup del database e dei file del blog prima del passaggio. Verifica PHP 8.3+, estensioni `mysqli` e `mbstring`, MySQL/MariaDB e Apache con `mod_rewrite`. L’utente MySQL esistente deve poter creare le tabelle WordPress.
2. Dopo aver pubblicato il codice, esegui **CD - Deploy blog.marianialessandro.com** dal branch scelto con `BLOG_CMS_PROVIDER=wordpress` (il valore predefinito). Il workflow prepara il runtime CMS e il frontend PHP senza collegarsi al database durante la build, poi li carica via FTP usando stati separati per la root e `cms/`. Prima della pubblicazione del codice puoi caricare i due artifact con il file manager dell’hosting. Il workflow **CD - Deploy WordPress CMS** resta disponibile per aggiornare soltanto il CMS.
3. Crea `cms/blog-config.php` sul server con le credenziali MySQL già presenti nella `.env` dell’API e chiavi casuali. Puoi generarlo da una copia privata della `.env` di produzione, senza stamparne i valori:

   ```bash
   php services/blog-wordpress/deploy/configure.php --api-env=/percorso/privato/api.env --output=/percorso/privato/blog-config.php --allow-legacy-import
   ```

   Installa prima le dipendenze Composer dell’API: il generatore usa il suo parser Dotenv. Il generatore rifiuta SQLite e file di destinazione già esistenti e crea il file con permessi `0600`. Non legge né salva token GitHub. Carica il risultato esclusivamente in `cms/blog-config.php`; è ignorato da Git, escluso dal deploy e protetto da Apache. Non caricare la `.env` nel blog.
4. Se hai eseguito il bootstrap SQL, apri direttamente `/cms/wp-admin/` e accedi con l’email e la password dell’amministratore Laravel: l’installazione è già inizializzata, senza un account temporaneo né post dimostrativi. In alternativa al bootstrap SQL, apri `/cms/wp-admin/install.php` e crea un amministratore temporaneo con **email diversa da ogni account Laravel esistente**; rimuovi il post dimostrativo “Hello world” prima dell’importazione se il suo slug appartiene al blog. Non eseguire entrambe le procedure. Verifica lingua e fuso orario in WordPress.
5. Apri **Strumenti → Importa blog Laravel** e premi **Importa il prossimo lotto** finché l’importazione risulta completata. Ogni richiesta tratta al massimo 20 record. Puoi riprovare dopo un errore: gli elementi già importati vengono saltati, preservando eventuali modifiche fatte in WordPress. Gli slug riservati `admin`, `archive`, `preview`, `cms` e quelli già occupati vanno risolti esplicitamente. In caso di conflitto preesistente, rimuovi/rinomina solo il contenuto WordPress temporaneo dopo averlo verificato.
6. Verifica l’accesso con l’email e la password attuali, apri gli articoli, controlla bozze, programmazione, tag e copertine. Disabilita `BLOG_ALLOW_LEGACY_IMPORT` nel file privato. Se hai usato l’installatore web alternativo, elimina l’amministratore temporaneo solo dopo aver effettuato l’accesso con l’account migrato e riassegna gli articoli al nuovo account quando WordPress lo chiede.
7. Il file `blog-config.php` richiede soltanto database, URL, chiavi di autenticazione e impostazioni dell’importazione. Le vecchie chiavi `BLOG_DEPLOY_*`, se ancora presenti sul server, vengono ignorate e possono essere rimosse. Non occorre generare nuove chiavi o ripetere l’SQL già eseguito.
8. Il frontend legge direttamente lo stesso database attraverso WordPress. Una modifica pubblicata è visibile dalla richiesta successiva. Il workflow GitHub serve solo per distribuire modifiche al codice; l’esecuzione oraria viene saltata in modalità WordPress. La variabile `BLOG_CMS_PROVIDER=laravel` conserva il precedente percorso statico come alternativa esplicita.
9. Controlla home, archivio, vecchi URL, `/admin/`, un nuovo upload e un articolo di prova. Verifica che `/cms/blog-config.php` e `/cms/wp-config.php` rispondano `403`, che un file PHP negli upload non venga eseguito e che le bozze restino escluse dal frontend.

Il workflow del blog esclude tutto `cms/**`. Il workflow CMS preserva configurazione, upload, cache e directory di aggiornamento. Prima di sostituire il frontend, il deploy controlla `/cms/?rest_route=/portfolio/v1/health` e la protezione dei file privati. L’endpoint espone solo lo stato di disponibilità, verificando versione dello schema, ruoli e PHP 8.3 con DOM/mbstring. Se la verifica fallisce, il frontend pubblico precedente resta al suo posto. Il deploy FTP non modifica il database e non esegue l’importazione. Non è previsto alcun endpoint pubblico di installazione o migrazione personalizzato.

La CI valida i workflow con actionlint e collauda l’azione FTP 4.3.6 effettiva contro un server FTPS locale temporaneo con TLS obbligatorio e verifica del certificato (`tests/ftp_workflow.py`, dipendenze in `tests/requirements.txt`). Il test verifica trigger manuali, push, chiamata dal deploy API e cron, conservazione di configurazione e media, caricamento della protezione upload e rimozione del vecchio HTML gestito. Non usa credenziali né server di produzione. Il percorso Laravel viene chiamato dall’API con `after_api: true`, perché i workflow riutilizzabili ereditano l’evento del chiamante.

Il deploy usa tre job in sequenza: preparazione e caricamento del CMS, verifica HTTP del CMS, caricamento del frontend pubblico. La verifica dei file privati viene eseguita su un runner separato: le richieste a `wp-config.php` possono attivare la challenge list BitNinja dell’hosting e interrompere i successivi trasferimenti FTP da quello stesso indirizzo IP. Il frontend viene caricato solo se la verifica riesce; la modalità Laravel conserva il proprio percorso senza la verifica CMS. L’artifact tra i runner include esplicitamente i file nascosti, compreso `.htaccess`.

Il trasferimento del blog e del CMS usa FTPS esplicito sulla porta 21 con verifica rigorosa del certificato. Il nome predefinito `biff.dnshigh.com` corrisponde al certificato del server hosting; `BLOG_FTP_SERVER` permette di cambiarlo quando cambia hosting, scegliendo un nome presente nel certificato. Le credenziali rimangono nei secret `FTP_USERNAME` e `FTP_PASSWORD`. Dal workflow del blog puoi selezionare `diagnose_ftp` per confrontare FTP/FTPS ed EPSV/PASV senza modificare file sul server; il deploy viene saltato in questa modalità. La diagnostica legge solo lo stato di sincronizzazione e non ne stampa il contenuto né le credenziali. Un timeout del canale dati va distinto da credenziali rifiutate e da un certificato non valido: il login FTP riuscito da solo non prova che i trasferimenti funzionino.

## Pubblicazione e aggiornamenti

Una pubblicazione, modifica o rimozione aggiorna il blog senza chiamare GitHub. In WordPress l’opzione **Fissa in cima al blog** corrisponde agli articoli in evidenza; il box **Portfolio blog** aggiunge descrizione, ordine e copertina alternativa. WordPress gestisce tag e immagini in evidenza normalmente.

Home, archivio, filtri, articoli, titoli e metadati vengono renderizzati dal server in PHP. JavaScript serve soltanto per inviare automaticamente i filtri e aggiornare la voce attiva dell’indice dell’articolo; i contenuti e la navigazione funzionano anche senza JavaScript. Le risposte HTML evitano la cache, e il routing passa da PHP anche se sul server restano vecchi file HTML. Eventuali cache esterne/CDN vanno configurate coerentemente.

Per gli articoli programmati vale WP-Cron: per l’orario puntuale configura nel pannello hosting una chiamata periodica a `https://blog.marianialessandro.com/cms/wp-cron.php`. La preview WordPress usa il suo tema. Il frontend pubblico applica il rendering dei blocchi e poi la sanificazione WordPress: script e iframe non vengono eseguiti, e non è prevista l’integrazione automatica di widget JavaScript di plugin.

Gli aggiornamenti del core vanno riportati in `deploy/wordpress-release.json` con versione e SHA-256 verificati, ricostruiti e collaudati prima del nuovo deploy CMS. Se WordPress si aggiorna direttamente sul server, aggiorna anche il pin prima del successivo deploy, per evitare un downgrade. Il codice del plugin di integrazione e il suo lock Composer restano versionati.

Per tornare alla sorgente precedente, ripristina `BLOG_CMS_PROVIDER=laravel` e ridistribuisci il frontend. Le nuove modifiche create in WordPress dopo il passaggio non vengono sincronizzate indietro verso Laravel: il rollback mostra l’ultima versione presente nell’API.
