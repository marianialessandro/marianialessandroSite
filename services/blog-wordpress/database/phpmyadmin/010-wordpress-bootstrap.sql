-- INSTALLAZIONE WORDPRESS BLOG — phpMyAdmin
-- WordPress 7.1.3; database schema 61833; prefisso wp_blog_.
-- Seleziona LO STESSO database MySQL dell’API Laravel e importa questo file intero.
-- Prima esporta un backup da phpMyAdmin. Non importare nuovamente 000-initial-schema.sql.
-- Nessuna password in chiaro e nessun dato personale sono contenuti in questo file.
-- Le credenziali vengono copiate tramite SELECT da users; vengono importati SOLO is_admin = 1.
-- Le tabelle Laravel users/posts e tutte le altre tabelle esistenti restano intatte.
-- Gli articoli saranno convertiti dal successivo importatore WordPress, senza altro SQL manuale.
-- Se esistono già tabelle wp_blog_, tutti i cambiamenti vengono saltati: non cancellare nulla.
-- Al termine controlla la riga esito: deve essere PRONTO e account_copiati deve essere > 0.

SET NAMES utf8mb4;
SET @blog_wp_saved_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'NO_ENGINE_SUBSTITUTION';
SET @blog_wp_existing = (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND LEFT(TABLE_NAME, 8) = 'wp_blog_');
SET @blog_wp_source_ok = (SELECT COUNT(*) = 2 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN ('users', 'posts'));
SET @blog_wp_admin_count = 0;
SET @blog_wp_invalid_admin_count = 0;
SET @blog_wp_statement = IF(@blog_wp_source_ok, 'SELECT COUNT(*), COALESCE(SUM(CHAR_LENGTH(email) > 100 OR email = '''' OR password IS NULL OR NOT (LEFT(password, 4) IN (''$2y$'', ''$2a$'', ''$2b$'') OR password LIKE ''$argon2id$%'' OR password LIKE ''$argon2i$%'')), 0) INTO @blog_wp_admin_count, @blog_wp_invalid_admin_count FROM users WHERE is_admin = 1', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;
SET @blog_wp_can_install = DATABASE() IS NOT NULL AND @blog_wp_source_ok AND @blog_wp_existing = 0 AND @blog_wp_admin_count > 0 AND @blog_wp_invalid_admin_count = 0;
SELECT DATABASE() AS database_selezionato, @blog_wp_existing AS tabelle_wordpress_preesistenti, @blog_wp_admin_count AS amministratori_legacy, @blog_wp_invalid_admin_count AS account_non_compatibili, IF(@blog_wp_can_install, 'PROCEDO', 'NON ESEGUITO: database errato, WordPress gia presente, nessun amministratore o account non compatibili') AS controllo_preliminare;

-- Tabella wp_blog_users.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'CREATE TABLE `wp_blog_users` (
  `ID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_login` varchar(60) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `user_pass` varchar(255) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `user_nicename` varchar(50) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `user_email` varchar(100) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `user_url` varchar(100) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `user_registered` datetime NOT NULL DEFAULT ''0000-00-00 00:00:00'',
  `user_activation_key` varchar(255) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `user_status` int NOT NULL DEFAULT ''0'',
  `display_name` varchar(250) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  PRIMARY KEY (`ID`),
  KEY `user_login_key` (`user_login`),
  KEY `user_nicename` (`user_nicename`),
  KEY `user_email` (`user_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Tabella wp_blog_usermeta.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'CREATE TABLE `wp_blog_usermeta` (
  `umeta_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL DEFAULT ''0'',
  `meta_key` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `meta_value` longtext COLLATE utf8mb4_unicode_520_ci,
  PRIMARY KEY (`umeta_id`),
  KEY `user_id` (`user_id`),
  KEY `meta_key` (`meta_key`(191))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Tabella wp_blog_posts.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'CREATE TABLE `wp_blog_posts` (
  `ID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `post_author` bigint unsigned NOT NULL DEFAULT ''0'',
  `post_date` datetime NOT NULL DEFAULT ''0000-00-00 00:00:00'',
  `post_date_gmt` datetime NOT NULL DEFAULT ''0000-00-00 00:00:00'',
  `post_content` longtext COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `post_title` text COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `post_excerpt` text COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `post_status` varchar(20) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT ''publish'',
  `comment_status` varchar(20) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT ''open'',
  `ping_status` varchar(20) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT ''open'',
  `post_password` varchar(255) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `post_name` varchar(200) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `to_ping` text COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `pinged` text COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `post_modified` datetime NOT NULL DEFAULT ''0000-00-00 00:00:00'',
  `post_modified_gmt` datetime NOT NULL DEFAULT ''0000-00-00 00:00:00'',
  `post_content_filtered` longtext COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `post_parent` bigint unsigned NOT NULL DEFAULT ''0'',
  `guid` varchar(255) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `menu_order` int NOT NULL DEFAULT ''0'',
  `post_type` varchar(20) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT ''post'',
  `post_mime_type` varchar(100) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `comment_count` bigint NOT NULL DEFAULT ''0'',
  PRIMARY KEY (`ID`),
  KEY `post_name` (`post_name`(191)),
  KEY `type_status_date` (`post_type`,`post_status`,`post_date`,`ID`),
  KEY `post_parent` (`post_parent`),
  KEY `post_author` (`post_author`),
  KEY `type_status_author` (`post_type`,`post_status`,`post_author`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Tabella wp_blog_comments.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'CREATE TABLE `wp_blog_comments` (
  `comment_ID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `comment_post_ID` bigint unsigned NOT NULL DEFAULT ''0'',
  `comment_author` tinytext COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `comment_author_email` varchar(100) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `comment_author_url` varchar(200) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `comment_author_IP` varchar(100) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `comment_date` datetime NOT NULL DEFAULT ''0000-00-00 00:00:00'',
  `comment_date_gmt` datetime NOT NULL DEFAULT ''0000-00-00 00:00:00'',
  `comment_content` text COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `comment_karma` int NOT NULL DEFAULT ''0'',
  `comment_approved` varchar(20) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT ''1'',
  `comment_agent` varchar(255) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `comment_type` varchar(20) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT ''comment'',
  `comment_parent` bigint unsigned NOT NULL DEFAULT ''0'',
  `user_id` bigint unsigned NOT NULL DEFAULT ''0'',
  PRIMARY KEY (`comment_ID`),
  KEY `comment_post_ID` (`comment_post_ID`),
  KEY `comment_approved_date_gmt` (`comment_approved`,`comment_date_gmt`),
  KEY `comment_date_gmt` (`comment_date_gmt`),
  KEY `comment_parent` (`comment_parent`),
  KEY `comment_author_email` (`comment_author_email`(10))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Tabella wp_blog_links.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'CREATE TABLE `wp_blog_links` (
  `link_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `link_url` varchar(255) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `link_name` varchar(255) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `link_image` varchar(255) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `link_target` varchar(25) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `link_description` varchar(255) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `link_visible` varchar(20) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT ''Y'',
  `link_owner` bigint unsigned NOT NULL DEFAULT ''1'',
  `link_rating` int NOT NULL DEFAULT ''0'',
  `link_updated` datetime NOT NULL DEFAULT ''0000-00-00 00:00:00'',
  `link_rel` varchar(255) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `link_notes` mediumtext COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `link_rss` varchar(255) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  PRIMARY KEY (`link_id`),
  KEY `link_visible` (`link_visible`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Tabella wp_blog_options.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'CREATE TABLE `wp_blog_options` (
  `option_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `option_name` varchar(191) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `option_value` longtext COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `autoload` varchar(20) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT ''yes'',
  PRIMARY KEY (`option_id`),
  UNIQUE KEY `option_name` (`option_name`),
  KEY `autoload` (`autoload`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Tabella wp_blog_postmeta.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'CREATE TABLE `wp_blog_postmeta` (
  `meta_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `post_id` bigint unsigned NOT NULL DEFAULT ''0'',
  `meta_key` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `meta_value` longtext COLLATE utf8mb4_unicode_520_ci,
  PRIMARY KEY (`meta_id`),
  KEY `post_id` (`post_id`),
  KEY `meta_key` (`meta_key`(191))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Tabella wp_blog_terms.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'CREATE TABLE `wp_blog_terms` (
  `term_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(200) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `slug` varchar(200) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `term_group` bigint NOT NULL DEFAULT ''0'',
  PRIMARY KEY (`term_id`),
  KEY `slug` (`slug`(191)),
  KEY `name` (`name`(191))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Tabella wp_blog_term_taxonomy.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'CREATE TABLE `wp_blog_term_taxonomy` (
  `term_taxonomy_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `term_id` bigint unsigned NOT NULL DEFAULT ''0'',
  `taxonomy` varchar(32) COLLATE utf8mb4_unicode_520_ci NOT NULL DEFAULT '''',
  `description` longtext COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `parent` bigint unsigned NOT NULL DEFAULT ''0'',
  `count` bigint NOT NULL DEFAULT ''0'',
  PRIMARY KEY (`term_taxonomy_id`),
  UNIQUE KEY `term_id_taxonomy` (`term_id`,`taxonomy`),
  KEY `taxonomy` (`taxonomy`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Tabella wp_blog_term_relationships.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'CREATE TABLE `wp_blog_term_relationships` (
  `object_id` bigint unsigned NOT NULL DEFAULT ''0'',
  `term_taxonomy_id` bigint unsigned NOT NULL DEFAULT ''0'',
  `term_order` int NOT NULL DEFAULT ''0'',
  PRIMARY KEY (`object_id`,`term_taxonomy_id`),
  KEY `term_taxonomy_id` (`term_taxonomy_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Tabella wp_blog_termmeta.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'CREATE TABLE `wp_blog_termmeta` (
  `meta_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `term_id` bigint unsigned NOT NULL DEFAULT ''0'',
  `meta_key` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `meta_value` longtext COLLATE utf8mb4_unicode_520_ci,
  PRIMARY KEY (`meta_id`),
  KEY `term_id` (`term_id`),
  KEY `meta_key` (`meta_key`(191))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Tabella wp_blog_commentmeta.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'CREATE TABLE `wp_blog_commentmeta` (
  `meta_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `comment_id` bigint unsigned NOT NULL DEFAULT ''0'',
  `meta_key` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `meta_value` longtext COLLATE utf8mb4_unicode_520_ci,
  PRIMARY KEY (`meta_id`),
  KEY `comment_id` (`comment_id`),
  KEY `meta_key` (`meta_key`(191))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

START TRANSACTION;

-- Opzione siteurl.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''siteurl'', ''https://blog.marianialessandro.com/cms'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione home.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''home'', ''https://blog.marianialessandro.com/cms'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione blogname.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''blogname'', ''Alessandro Mariani — Blog'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione blogdescription.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''blogdescription'', '''', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione users_can_register.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''users_can_register'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione start_of_week.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''start_of_week'', ''1'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione use_balanceTags.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''use_balanceTags'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione use_smilies.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''use_smilies'', ''1'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione require_name_email.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''require_name_email'', ''1'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione comments_notify.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''comments_notify'', ''1'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione posts_per_rss.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''posts_per_rss'', ''10'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione rss_use_excerpt.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''rss_use_excerpt'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione mailserver_url.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''mailserver_url'', ''mail.example.com'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione mailserver_login.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''mailserver_login'', ''login@example.com'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione mailserver_pass.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''mailserver_pass'', '''', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione mailserver_port.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''mailserver_port'', ''110'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione default_category.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''default_category'', ''1'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione default_comment_status.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''default_comment_status'', ''open'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione default_ping_status.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''default_ping_status'', ''open'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione default_pingback_flag.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''default_pingback_flag'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione posts_per_page.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''posts_per_page'', ''10'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione date_format.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''date_format'', ''F j, Y'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione time_format.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''time_format'', ''g:i a'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione links_updated_date_format.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''links_updated_date_format'', ''F j, Y g:i a'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione comment_moderation.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''comment_moderation'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione moderation_notify.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''moderation_notify'', ''1'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione permalink_structure.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''permalink_structure'', '''', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione hack_file.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''hack_file'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione blog_charset.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''blog_charset'', ''UTF-8'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione moderation_keys.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''moderation_keys'', '''', ''off'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione active_plugins.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''active_plugins'', ''a:0:{}'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione category_base.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''category_base'', '''', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione ping_sites.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''ping_sites'', ''https://rpc.pingomatic.com/'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione comment_max_links.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''comment_max_links'', ''2'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione gmt_offset.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''gmt_offset'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione default_email_category.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''default_email_category'', ''1'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione template.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''template'', ''twentytwentyfive'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione stylesheet.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''stylesheet'', ''twentytwentyfive'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione comment_registration.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''comment_registration'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione html_type.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''html_type'', ''text/html'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione use_trackback.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''use_trackback'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione default_role.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''default_role'', ''subscriber'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione db_version.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''db_version'', ''61833'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione uploads_use_yearmonth_folders.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''uploads_use_yearmonth_folders'', ''1'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione upload_path.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''upload_path'', '''', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione blog_public.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''blog_public'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione default_link_category.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''default_link_category'', ''2'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione show_on_front.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''show_on_front'', ''posts'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione tag_base.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''tag_base'', '''', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione show_avatars.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''show_avatars'', ''1'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione avatar_rating.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''avatar_rating'', ''G'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione upload_url_path.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''upload_url_path'', '''', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione thumbnail_size_w.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''thumbnail_size_w'', ''150'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione thumbnail_size_h.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''thumbnail_size_h'', ''150'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione thumbnail_crop.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''thumbnail_crop'', ''1'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione medium_size_w.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''medium_size_w'', ''300'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione medium_size_h.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''medium_size_h'', ''300'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione avatar_default.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''avatar_default'', ''mystery'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione large_size_w.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''large_size_w'', ''1024'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione large_size_h.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''large_size_h'', ''1024'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione image_default_link_type.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''image_default_link_type'', ''none'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione image_default_size.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''image_default_size'', '''', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione image_default_align.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''image_default_align'', '''', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione close_comments_for_old_posts.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''close_comments_for_old_posts'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione close_comments_days_old.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''close_comments_days_old'', ''14'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione thread_comments.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''thread_comments'', ''1'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione thread_comments_depth.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''thread_comments_depth'', ''5'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione page_comments.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''page_comments'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione comments_per_page.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''comments_per_page'', ''50'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione default_comments_page.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''default_comments_page'', ''newest'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione comment_order.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''comment_order'', ''asc'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione sticky_posts.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''sticky_posts'', ''a:0:{}'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione widget_categories.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''widget_categories'', ''a:0:{}'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione widget_text.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''widget_text'', ''a:0:{}'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione widget_rss.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''widget_rss'', ''a:0:{}'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione uninstall_plugins.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''uninstall_plugins'', ''a:0:{}'', ''off'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione timezone_string.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''timezone_string'', ''Europe/Rome'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione page_for_posts.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''page_for_posts'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione page_on_front.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''page_on_front'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione default_post_format.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''default_post_format'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione link_manager_enabled.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''link_manager_enabled'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione finished_splitting_shared_terms.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''finished_splitting_shared_terms'', ''1'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione site_icon.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''site_icon'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione medium_large_size_w.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''medium_large_size_w'', ''768'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione medium_large_size_h.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''medium_large_size_h'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione wp_page_for_privacy_policy.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''wp_page_for_privacy_policy'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione show_comments_cookies_opt_in.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''show_comments_cookies_opt_in'', ''1'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione admin_email_lifespan.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''admin_email_lifespan'', ''1808211267'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione disallowed_keys.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''disallowed_keys'', '''', ''off'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione comment_previously_approved.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''comment_previously_approved'', ''1'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione auto_plugin_theme_update_emails.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''auto_plugin_theme_update_emails'', ''a:0:{}'', ''off'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione auto_update_core_dev.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''auto_update_core_dev'', ''enabled'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione auto_update_core_minor.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''auto_update_core_minor'', ''enabled'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione auto_update_core_major.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''auto_update_core_major'', ''enabled'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione wp_force_deactivated_plugins.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''wp_force_deactivated_plugins'', ''a:0:{}'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione wp_attachment_pages_enabled.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''wp_attachment_pages_enabled'', ''0'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione wp_notes_notify.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''wp_notes_notify'', ''1'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione initial_db_version.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''initial_db_version'', ''61833'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione wp_blog_user_roles.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''wp_blog_user_roles'', ''a:5:{s:13:"administrator";a:2:{s:4:"name";s:13:"Administrator";s:12:"capabilities";a:61:{s:13:"switch_themes";b:1;s:11:"edit_themes";b:1;s:16:"activate_plugins";b:1;s:12:"edit_plugins";b:1;s:10:"edit_users";b:1;s:10:"edit_files";b:1;s:14:"manage_options";b:1;s:17:"moderate_comments";b:1;s:17:"manage_categories";b:1;s:12:"manage_links";b:1;s:12:"upload_files";b:1;s:6:"import";b:1;s:15:"unfiltered_html";b:1;s:10:"edit_posts";b:1;s:17:"edit_others_posts";b:1;s:20:"edit_published_posts";b:1;s:13:"publish_posts";b:1;s:10:"edit_pages";b:1;s:4:"read";b:1;s:8:"level_10";b:1;s:7:"level_9";b:1;s:7:"level_8";b:1;s:7:"level_7";b:1;s:7:"level_6";b:1;s:7:"level_5";b:1;s:7:"level_4";b:1;s:7:"level_3";b:1;s:7:"level_2";b:1;s:7:"level_1";b:1;s:7:"level_0";b:1;s:17:"edit_others_pages";b:1;s:20:"edit_published_pages";b:1;s:13:"publish_pages";b:1;s:12:"delete_pages";b:1;s:19:"delete_others_pages";b:1;s:22:"delete_published_pages";b:1;s:12:"delete_posts";b:1;s:19:"delete_others_posts";b:1;s:22:"delete_published_posts";b:1;s:20:"delete_private_posts";b:1;s:18:"edit_private_posts";b:1;s:18:"read_private_posts";b:1;s:20:"delete_private_pages";b:1;s:18:"edit_private_pages";b:1;s:18:"read_private_pages";b:1;s:12:"delete_users";b:1;s:12:"create_users";b:1;s:17:"unfiltered_upload";b:1;s:14:"edit_dashboard";b:1;s:14:"update_plugins";b:1;s:14:"delete_plugins";b:1;s:15:"install_plugins";b:1;s:13:"update_themes";b:1;s:14:"install_themes";b:1;s:11:"update_core";b:1;s:10:"list_users";b:1;s:12:"remove_users";b:1;s:13:"promote_users";b:1;s:18:"edit_theme_options";b:1;s:13:"delete_themes";b:1;s:6:"export";b:1;}}s:6:"editor";a:2:{s:4:"name";s:6:"Editor";s:12:"capabilities";a:34:{s:17:"moderate_comments";b:1;s:17:"manage_categories";b:1;s:12:"manage_links";b:1;s:12:"upload_files";b:1;s:15:"unfiltered_html";b:1;s:10:"edit_posts";b:1;s:17:"edit_others_posts";b:1;s:20:"edit_published_posts";b:1;s:13:"publish_posts";b:1;s:10:"edit_pages";b:1;s:4:"read";b:1;s:7:"level_7";b:1;s:7:"level_6";b:1;s:7:"level_5";b:1;s:7:"level_4";b:1;s:7:"level_3";b:1;s:7:"level_2";b:1;s:7:"level_1";b:1;s:7:"level_0";b:1;s:17:"edit_others_pages";b:1;s:20:"edit_published_pages";b:1;s:13:"publish_pages";b:1;s:12:"delete_pages";b:1;s:19:"delete_others_pages";b:1;s:22:"delete_published_pages";b:1;s:12:"delete_posts";b:1;s:19:"delete_others_posts";b:1;s:22:"delete_published_posts";b:1;s:20:"delete_private_posts";b:1;s:18:"edit_private_posts";b:1;s:18:"read_private_posts";b:1;s:20:"delete_private_pages";b:1;s:18:"edit_private_pages";b:1;s:18:"read_private_pages";b:1;}}s:6:"author";a:2:{s:4:"name";s:6:"Author";s:12:"capabilities";a:10:{s:12:"upload_files";b:1;s:10:"edit_posts";b:1;s:20:"edit_published_posts";b:1;s:13:"publish_posts";b:1;s:4:"read";b:1;s:7:"level_2";b:1;s:7:"level_1";b:1;s:7:"level_0";b:1;s:12:"delete_posts";b:1;s:22:"delete_published_posts";b:1;}}s:11:"contributor";a:2:{s:4:"name";s:11:"Contributor";s:12:"capabilities";a:5:{s:10:"edit_posts";b:1;s:4:"read";b:1;s:7:"level_1";b:1;s:7:"level_0";b:1;s:12:"delete_posts";b:1;}}s:10:"subscriber";a:2:{s:4:"name";s:10:"Subscriber";s:12:"capabilities";a:2:{s:4:"read";b:1;s:7:"level_0";b:1;}}}'', ''on'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione fresh_site.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''fresh_site'', ''1'', ''off'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione user_count.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''user_count'', ''1'', ''off'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione widget_block.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''widget_block'', ''a:6:{i:2;a:1:{s:7:"content";s:19:"<!-- wp:search /-->";}i:3;a:1:{s:7:"content";s:154:"<!-- wp:group --><div class="wp-block-group"><!-- wp:heading --><h2>Recent Posts</h2><!-- /wp:heading --><!-- wp:latest-posts /--></div><!-- /wp:group -->";}i:4;a:1:{s:7:"content";s:227:"<!-- wp:group --><div class="wp-block-group"><!-- wp:heading --><h2>Recent Comments</h2><!-- /wp:heading --><!-- wp:latest-comments {"displayAvatar":false,"displayDate":false,"displayExcerpt":false} /--></div><!-- /wp:group -->";}i:5;a:1:{s:7:"content";s:146:"<!-- wp:group --><div class="wp-block-group"><!-- wp:heading --><h2>Archives</h2><!-- /wp:heading --><!-- wp:archives /--></div><!-- /wp:group -->";}i:6;a:1:{s:7:"content";s:150:"<!-- wp:group --><div class="wp-block-group"><!-- wp:heading --><h2>Categories</h2><!-- /wp:heading --><!-- wp:categories /--></div><!-- /wp:group -->";}s:12:"_multiwidget";i:1;}'', ''auto'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

-- Opzione sidebars_widgets.
SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) VALUES (''sidebars_widgets'', ''a:4:{s:19:"wp_inactive_widgets";a:0:{}s:9:"sidebar-1";a:3:{i:0;s:7:"block-2";i:1;s:7:"block-3";i:2;s:7:"block-4";}s:9:"sidebar-2";a:2:{i:0;s:7:"block-5";i:1;s:7:"block-6";}s:13:"array_version";i:3;}'', ''auto'')', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_terms (term_id, name, slug, term_group) VALUES (1, ''Senza categoria'', ''senza-categoria'', 0)', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_term_taxonomy (term_taxonomy_id, term_id, taxonomy, description, parent, count) VALUES (1, 1, ''category'', '''', 0, 0)', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_options (option_name, option_value, autoload) SELECT ''admin_email'', email, ''on'' FROM users WHERE is_admin = 1 ORDER BY id LIMIT 1', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_users (ID, user_login, user_pass, user_nicename, user_email, user_url, user_registered, user_activation_key, user_status, display_name) SELECT id, CONCAT(''legacy-'', id), password, CONCAT(''legacy-'', id), email, '''', UTC_TIMESTAMP(), '''', 0, LEFT(name, 250) FROM users WHERE is_admin = 1 ORDER BY id', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_usermeta (user_id, meta_key, meta_value) SELECT ID, ''wp_blog_capabilities'', ''a:1:{s:13:"administrator";b:1;}'' FROM wp_blog_users', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_usermeta (user_id, meta_key, meta_value) SELECT ID, ''wp_blog_user_level'', ''10'' FROM wp_blog_users', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_usermeta (user_id, meta_key, meta_value) SELECT ID, ''_portfolio_legacy_user_id'', CAST(ID AS CHAR) FROM wp_blog_users', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

SET @blog_wp_statement = IF(@blog_wp_can_install, 'INSERT INTO wp_blog_usermeta (user_id, meta_key, meta_value) SELECT ID, ''nickname'', display_name FROM wp_blog_users', 'DO 0');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;

COMMIT;
SET SESSION sql_mode = @blog_wp_saved_sql_mode;

SET @blog_wp_statement = IF(@blog_wp_can_install, 'SELECT ''PRONTO'' AS esito, (SELECT COUNT(*) FROM wp_blog_users) AS account_copiati, (SELECT COUNT(*) FROM wp_blog_posts) AS articoli_wordpress, ''Tabelle Laravel conservate. Ora avvisa per proseguire con configurazione CMS e importazione articoli.'' AS prossimo_passo', 'SELECT ''NON ESEGUITO'' AS esito, ''Controlla il risultato del controllo preliminare. Nessuna tabella esistente e stata modificata.'' AS prossimo_passo');
PREPARE blog_wp_step FROM @blog_wp_statement;
EXECUTE blog_wp_step;
DEALLOCATE PREPARE blog_wp_step;
