-- Run on the Laravel application database after a verified backup, never on the nutrition schema.
CREATE TABLE nutrition_services (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    issuer VARCHAR(255) COLLATE utf8mb4_bin NOT NULL,
    subject VARCHAR(255) COLLATE utf8mb4_bin NOT NULL,
    admin_user_id BIGINT UNSIGNED NOT NULL,
    scopes JSON NOT NULL,
    active TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    UNIQUE KEY nutrition_services_issuer_subject_unique (issuer, subject),
    CONSTRAINT nutrition_services_admin_user_id_foreign FOREIGN KEY (admin_user_id) REFERENCES users(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
INSERT INTO migrations (migration, batch) SELECT '2026_09_09_120000_create_nutrition_services_table', COALESCE(MAX(batch), 0) + 1 FROM migrations;

-- Substitute only verified, non-secret metadata. Start disabled, check the admin, then activate explicitly.
-- INSERT INTO nutrition_services (name, issuer, subject, admin_user_id, scopes, active, created_at, updated_at) VALUES ('MCP', 'https://YOUR_TENANT/', 'VERIFIED_MACHINE_SUBJECT', YOUR_ADMIN_ID, JSON_ARRAY('nutrition:read'), 0, NOW(), NOW());
-- UPDATE nutrition_services SET active = 1, updated_at = NOW() WHERE id = VERIFIED_SERVICE_ID;
-- Revoke immediately, including already issued JWTs.
-- UPDATE nutrition_services SET active = 0, updated_at = NOW() WHERE id = VERIFIED_SERVICE_ID;
