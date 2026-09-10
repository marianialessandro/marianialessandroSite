"""Build a single shared-hosting upgrade without executing the query examples."""
import argparse
from pathlib import Path
import re


def build(root):
    api = root / 'apps/api.marianialessandro.com'
    service = root / 'services/nutrition-mcp-php'
    source = (api / 'resources/nutrition/nutrizionista_schema_mysql.sql').read_text()
    source = source[source.index('-- ============================================================================\n-- 1. TABELLE'):source.index('-- ============================================================================\n-- 24. NOTE')]
    source = re.sub(r'^DROP PROCEDURE IF EXISTS .+\n', '', source, flags=re.MULTILINE)
    source = source.replace('CREATE OR REPLACE VIEW ', 'CREATE SQL SECURITY INVOKER VIEW ')
    source = source.replace(') ENGINE=InnoDB;', ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;')
    service_sql = (api / 'database/phpmyadmin/001-nutrition-services.sql').read_text().split('-- Substitute only')[0]
    service_sql = service_sql.replace('CREATE TABLE nutrition_services', 'CREATE TABLE IF NOT EXISTS nutrition_services')
    service_sql = service_sql.replace("SELECT '2026_09_09_120000_create_nutrition_services_table', COALESCE(MAX(batch), 0) + 1 FROM migrations;", "SELECT '2026_09_09_120000_create_nutrition_services_table', (SELECT COALESCE(MAX(batch), 0) + 1 FROM migrations) WHERE NOT EXISTS (SELECT 1 FROM migrations WHERE migration = '2026_09_09_120000_create_nutrition_services_table');")
    oauth = (service / 'database/phpmyadmin/002-oauth-passport.sql').read_text()
    header = '''-- INSTALLAZIONE NUTRIZIONE + MCP PHP/OAUTH — 9 settembre 2026.
-- Target: MySQL 8.0.16+; selezionare in phpMyAdmin il DATABASE LARAVEL ESISTENTE dell'API.
-- Le 9 tabelle nutrizionali, 5 viste, 4 trigger e 3 procedure vengono create nello stesso database.
-- Aggiunge nutrition_services e le 5 tabelle di Laravel Passport v13.8.0; aggiorna solo il registro migrations.
-- Presuppone users, migrations, sessions, cache e cache_locks già presenti dall'installazione Laravel.
-- Non crea/cancella database, non modifica users, non inserisce pasti o altri dati dimostrativi.
-- Prima installazione delle strutture nutrizionali: se esistono già, confrontare lo schema prima dell'importazione.
-- Salvare un backup del database. Il DDL MySQL non è annullabile con ROLLBACK.
-- Sono necessari privilegi CREATE, REFERENCES, CREATE VIEW, TRIGGER, CREATE ROUTINE ed EXECUTE.
-- Il catalogo in Downloads è una raccolta di esempi e NON va importato insieme a questo file.
-- Dopo l'importazione configurare NUTRITION_DB_DATABASE sull'API con lo stesso nome di DB_DATABASE.
-- Nessuna password, chiave privata o client secret viene generato o salvato da questo script.

SET NAMES utf8mb4;
SET @mcp_previous_time_zone = @@session.time_zone;
SET time_zone = '+02:00';
SELECT DATABASE() AS database_destinazione;
-- Controllo preliminare delle tabelle Laravel richieste; non vengono modificate.
SELECT COUNT(*) AS utenti_esistenti FROM users;
SELECT COUNT(*) AS migrazioni_esistenti FROM migrations;

'''
    footer = '''
-- CONFIGURAZIONE DEL CLIENT E DEL SERVIZIO: i valori sotto sono disattivati finché non compilati.
-- 1. Copiare qui l'ID del proprio amministratore esistente, senza crearne uno nuovo.
-- 2. Copiare l'URL callback ESATTO mostrato da ChatGPT quando si crea la connessione OAuth.
-- 3. Rieseguire soltanto questa sezione dopo aver compilato i due valori.
SET @mcp_admin_id = NULL;
SET @chatgpt_callback = '';
SET @mcp_client_id = UUID();

INSERT INTO oauth_clients (id, name, secret, provider, redirect_uris, grant_types, revoked, created_at, updated_at)
SELECT @mcp_client_id, 'Nutrition ChatGPT', NULL, 'users', JSON_ARRAY(@chatgpt_callback), JSON_ARRAY('authorization_code', 'refresh_token'), 0, NOW(), NOW()
WHERE @chatgpt_callback LIKE 'https://chatgpt.com/%'
  AND EXISTS (SELECT 1 FROM users WHERE id = @mcp_admin_id AND is_admin = 1)
  AND NOT EXISTS (SELECT 1 FROM oauth_clients WHERE name = 'Nutrition ChatGPT' AND revoked = 0);

INSERT INTO nutrition_services (name, issuer, subject, admin_user_id, scopes, active, created_at, updated_at)
SELECT 'Nutrition MCP PHP', 'https://mcp.marianialessandro.com', 'nutrition-mcp-php', id, JSON_ARRAY('nutrition:read'), 1, NOW(), NOW()
FROM users
WHERE id = @mcp_admin_id AND is_admin = 1
  AND EXISTS (SELECT 1 FROM oauth_clients WHERE name = 'Nutrition ChatGPT' AND revoked = 0)
  AND NOT EXISTS (SELECT 1 FROM nutrition_services WHERE issuer = 'https://mcp.marianialessandro.com' AND subject = 'nutrition-mcp-php');

-- Copiare l'ID cliente risultante in MCP_CLIENT_ID e l'ID admin in MCP_ALLOWED_USER_ID nel .env privato del MCP.
-- Il client è pubblico con PKCE S256: secret NULL è intenzionale, la password dell'utente resta nel login Laravel.
SELECT id AS MCP_CLIENT_ID, name FROM oauth_clients WHERE name = 'Nutrition ChatGPT' AND revoked = 0;
SELECT @mcp_admin_id AS MCP_ALLOWED_USER_ID;
SET time_zone = @mcp_previous_time_zone;
'''
    return header + service_sql + '\n' + oauth + '\n' + source + footer


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True, help='Destination SQL file; parent directory must exist.')
    args = parser.parse_args()
    args.output.write_text(build(Path(__file__).resolve().parents[3]))


if __name__ == '__main__':
    main()
