# API MySQL nutrizionista e MCP

L'API espone tutte le **179 query numerate** del catalogo SQL e tre equivalenti delle procedure (`23.1`–`23.3`), per **182 operazioni**. Gli ID conservano la numerazione originale. Il database nutrizionale usa una connessione MySQL 8 separata dal database Laravel di utenti e sessioni.

## Configurazione

1. Installare le dipendenze PHP con `composer install` e applicare le migrazioni Laravel con `php artisan migrate`. La migrazione Sanctum dei token è già presente su `main`.
2. Configurare le variabili `NUTRITION_DB_*` di `.env.example` e, per TLS, `NUTRITION_MYSQL_SSL_CA`. Usare un account MySQL dedicato al solo database nutrizionale. La timezone predefinita è `+02:00`, coerente con il file fornito; configurarla esplicitamente in base ai timestamp archiviati.
3. Su un database nuovo, predisporre tabelle, viste e trigger dello schema fornito. **Il file originale `resources/nutrition/nutrizionista_schema_mysql.sql` contiene `DROP DATABASE`: non importarlo su un database esistente con dati.** L'applicazione non esegue automaticamente questo file né il catalogo di esempi. Per un database già predisposto è sufficiente configurare la connessione.
4. Svuotare/ricreare la cache di configurazione durante il deploy. Servire l'API via HTTPS.

Le query di metadati e `ANALYZE TABLE` richiedono i corrispondenti privilegi MySQL; assegnarli solo se si intende usare le operazioni di manutenzione. Le procedure sono implementate usando le stesse query parametrizzate del catalogo: non è necessario concedere `EXECUTE`.

## Autenticazione e autorizzazione

Tutti gli endpoint `/api/nutrition/*`, compresi catalogo e OpenAPI, richiedono autenticazione. Lo schema è un archivio personale condiviso senza `user_id`: l'accesso è limitato agli amministratori, come le app esistenti. Non offre isolamento multiutente.

- **App interne:** sessione Laravel esistente, cookie e flusso CSRF Sanctum. Prima del login ottenere `/sanctum/csrf-cookie`, poi chiamare `/api/auth/login`; inviare `X-XSRF-TOKEN` per le mutazioni.
- **Client esterni e MCP:** `Authorization: Bearer <token>`. Non richiedono cookie, Origin o CSRF. I token sono associati a un amministratore, memorizzati come hash, revocabili e soggetti a scadenza. Un utente che perde il ruolo admin perde l'accesso anche con token ancora valido.
- **Browser esterni:** aggiungere l'origine esatta a `CORS_ALLOWED_ORIGINS`. `Authorization` è tra gli header consentiti. Non aggiungere i client Bearer esterni a `SANCTUM_STATEFUL_DOMAINS`; quella lista è per le app con sessione. CORS non limita le richieste server-to-server e non sostituisce l'autenticazione.

Permessi dei token: `nutrition:read`, `nutrition:write`, `nutrition:delete`, `nutrition:maintenance`. Il catalogo e OpenAPI mostrano solo operazioni autorizzate. Le sessioni amministrative possono usare tutte le operazioni. Limite: 60 richieste/minuto per identità sulle query, 10/minuto sulla gestione token.

## Emissione e revoca dei token

Dalla sessione amministrativa autenticata e con CSRF:

```http
POST /api/nutrition/tokens
Content-Type: application/json
X-XSRF-TOKEN: <valore del cookie XSRF-TOKEN decodificato>

{"name":"nutrition-mcp","abilities":["nutrition:read","nutrition:write"],"expires_in_minutes":480}
```

La risposta `201` restituisce `id`, `token` (visibile solo alla creazione) ed `expires_at`. `GET /api/nutrition/tokens` elenca i propri token senza segreti; `DELETE /api/nutrition/tokens/{id}` revoca un proprio token. Un Bearer token non può creare altri token. Durata massima: 480 minuti, coerente con la configurazione Sanctum esistente; predisporre il rinnovo tramite sessione amministrativa e aggiornare il segreto del client prima della scadenza. Non è implementato un refresh token OAuth.

## Scoperta ed esecuzione

- `GET /api/nutrition/queries`: catalogo con descrizione, permesso richiesto, parametri e JSON Schema.
- `GET /api/nutrition/queries/{id}`: contratto della singola operazione.
- `GET /api/nutrition/openapi.json`: specifica OpenAPI 3.1 delle operazioni accessibili.
- `POST /api/nutrition/queries/{id}/execute`: esecuzione con `{"parameters":{...}}`.

Esempio server-to-server:

```bash
curl --fail-with-body 'https://api.marianialessandro.com/api/nutrition/queries/19.5/execute' \
  -H "Authorization: Bearer $NUTRITION_API_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"parameters":{"ultimo_id":9223372036854775807,"page_size":50}}'
```

Le variabili SQL `@...` diventano parametri obbligatori, eccetto gli ID calcolati internamente. I valori letterali degli esempi sono personalizzabili: quando possibile il nome è quello della colonna (`giorno`, `tipo_giornata`, `alimento_prodotto`, `peso_kg`, ecc.); nelle espressioni complesse si usa `arg_<statement>_<posizione>`, corredato dal contesto SQL. Il JSON Schema indica i default conservati dagli esempi: **controllarli e sostituirli con i dati reali prima di una scrittura**. Le costanti del ricalcolo nutrizionale `16.10` rimangono fisse. Non sono accettati SQL, nomi di tabelle o colonne arbitrari.

Esempio inserimento giornata: operazione `5.1` con `{"parameters":{"data_rif":"2026-09-11","giorno":"Venerdì","tipo_giornata":"Allenamento","target_kcal":2300,"note":"Allenamento serale"}}`.

Le operazioni `nutrition:delete` e `nutrition:maintenance` richiedono anche `"confirm":true`. Per `17.12`, il controllo preventivo e la cancellazione avvengono nella stessa transazione con lock; i conteggi precedenti sono restituiti nel primo result set. Per un'anteprima senza cancellare usare i report di lettura.

Le risposte contengono `operation`, `results` (righe oppure conteggio modifiche e ultimo ID) e `outputs` (ID prodotti dalla transazione). Ogni result set è limitato a 500 righe con `truncated`; `19.5` offre paginazione cursor per pasti e `19.6` offset per voci. Per gli altri report usare filtri/intervalli quando previsti; non esiste un cursore universale dei report. Le colonne JSON MySQL restano stringhe JSON e i DECIMAL possono essere stringhe per preservare precisione.

Errori: `401` autenticazione, `403` ruolo/permessi, `404` operazione sconosciuta, `422` parametri o vincoli DB, `429` limite richieste, `503` database/operazione non disponibile. Le risposte d'errore DB non espongono SQL o credenziali. Le mutazioni non hanno retry automatici né chiavi di idempotenza: dopo un timeout verificare lo stato prima di ripetere un inserimento.

## Adattamenti degli esempi

- `5.12`: intera sequenza atomica, con ID intermedi locali alla richiesta.
- `16.8`: aggiorna pasto, voci e osservazioni nella stessa transazione.
- `16.9`: riceve `voce_id` invece dell'ID di esempio `1`.
- `17.12`: esegue la cancellazione confermata dopo la SELECT con lock, al posto del rollback dimostrativo.
- `19.5`/`19.6`: dimensione pagina e offset diventano parametri reali (massimo 500 righe).
- `19.8`: usa `x.pasto_id`, nome effettivo della colonna della vista; il file originale usava `x.id`.
- `18.8`: `ANALYZE TABLE` fuori transazione perché MySQL esegue un commit implicito.
- `23.1`/`23.2`/`23.3`: equivalenti delle tre procedure dello schema.

I file SQL originali sono conservati senza alterazioni. Il catalogo eseguibile è versionato in `resources/nutrition/catalog.json`, rigenerabile con `python3 scripts/build_nutrition_catalog.py`; non viene compilato da input HTTP.

## Bridge MCP incluso

Il server Python in `integrations/nutrition-mcp/server.py` usa l'SDK MCP ufficiale via **stdio** e pubblica un tool per ogni query autorizzata (es. `nutrition_19_5`). Interroga l'API HTTP a ogni discovery e inoltra il token a ogni chiamata. Non accede direttamente a MySQL. Il protocollo MCP gestisce inizializzazione, `tools/list`, `tools/call`, JSON Schema, annotazioni di lettura/distruzione ed errori. I tool distruttivi richiedono `confirm: true`.

```bash
python3 -m venv integrations/nutrition-mcp/.venv
integrations/nutrition-mcp/.venv/bin/pip install -r integrations/nutrition-mcp/requirements.txt
```

Configurazione del client MCP (sostituire percorsi e segreto):

```json
{
  "mcpServers": {
    "nutrition": {
      "command": "/percorso/api/integrations/nutrition-mcp/.venv/bin/python",
      "args": ["/percorso/api/integrations/nutrition-mcp/server.py"],
      "env": {
        "NUTRITION_API_URL": "https://api.marianialessandro.com/api/nutrition",
        "NUTRITION_API_TOKEN": "<token>"
      }
    }
  }
}
```

Conservare il token nel gestore segreti del client, senza committarlo. Il bridge richiede HTTPS salvo loopback, non segue redirect e non ritenta automaticamente le mutazioni. Non è un endpoint MCP remoto Streamable HTTP/OAuth: un MCP server già esistente può integrare direttamente gli endpoint REST autenticati, oppure il client può avviare questo bridge stdio.

## Verifiche

```bash
php artisan test
python3 scripts/test_nutrition_mysql.py
integrations/nutrition-mcp/.venv/bin/python integrations/nutrition-mcp/test_server.py
```

Il test MySQL crea un container effimero su porta locale casuale, importa lo schema esclusivamente lì, esercita tutte le 182 operazioni e verifica transazioni, sincronizzazione delle relazioni, cascata, ricalcolo e SQL injection. Richiede Docker e rimuove il container al termine. La suite ordinaria verifica login esistente, autenticazione su tutte le operazioni, scope, scadenza/revoca, gestione token, validazione e copertura del catalogo; il test MySQL viene saltato finché non è avviato dal runner dedicato.

Riferimenti: [Laravel Sanctum](https://github.com/laravel/docs/blob/13.x/sanctum.md), [MCP tools](https://modelcontextprotocol.io/specification/2025-06-18/server/tools), [SDK Python MCP](https://github.com/modelcontextprotocol/python-sdk).
