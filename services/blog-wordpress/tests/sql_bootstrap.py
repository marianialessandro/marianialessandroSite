#!/usr/bin/env python3
"""Test the exact phpMyAdmin SQL in a disposable local database."""

from pathlib import Path
import subprocess


def main() -> None:
    compose = ['docker', 'compose', '-f', 'services/blog-wordpress/compose.yml']
    database = 'blog_wordpress_sql_test'

    def mysql(sql: str, selected: bool = True) -> str:
        command = compose + ['exec', '-T', 'mysql', 'mysql', '-uroot', '-plocal-development-root-only', '--batch']
        if selected:
            command.append(database)
        return subprocess.run(command, input=sql, text=True, capture_output=True, check=True).stdout

    # Refuse an existing database instead of touching an unrelated local test session.
    mysql(f'CREATE DATABASE {database} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; GRANT ALL ON {database}.* TO "blog_local"@"%";', False)
    try:
        mysql(Path('apps/api.marianialessandro.com/database/phpmyadmin/000-initial-schema.sql').read_text())
        mysql("INSERT INTO users (id,name,email,password,is_admin) VALUES (41,'SQL Admin','sql-admin@example.test','invalid-hash',1),(42,'Reader','sql-reader@example.test','unused',0); INSERT INTO posts (id,slug,title,content,date,tags,draft) VALUES (71,'sql-fixture-post','SQL migration','**SQL migration**','2026-01-10','[\"Testing\"]',0);")
        sql = Path('services/blog-wordpress/database/phpmyadmin/010-wordpress-bootstrap.sql').read_text()
        assert 'NON ESEGUITO' in mysql(sql)
        count = mysql("SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND LEFT(TABLE_NAME,8)='wp_blog_';").strip().splitlines()[-1]
        assert count == '0'
        print('PASS invalid credentials prevent every WordPress table creation', flush=True)
        digest = subprocess.check_output(compose + ['exec', '-T', 'wordpress', 'php', '-r', 'echo password_hash("sql-fixture-password", PASSWORD_BCRYPT);'], text=True)
        mysql("UPDATE users SET password='" + digest + "' WHERE id=41;")
        assert 'PRONTO' in mysql(sql)
        subprocess.run(compose + ['exec', '-T', '-e', 'WORDPRESS_DB_NAME=' + database, 'wordpress', 'php', '/var/www/tests/sql-bootstrap.php'], check=True)
        tables = mysql('SHOW TABLES;').strip().splitlines()[1:]
        checksum = 'CHECKSUM TABLE ' + ', '.join('`' + table + '`' for table in tables) + ';'
        before = mysql(checksum)
        assert 'NON ESEGUITO' in mysql(sql)
        assert before == mysql(checksum)
        print('PASS repeated SQL import leaves all existing tables unchanged', flush=True)
    finally:
        mysql(f'DROP DATABASE {database};', False)


if __name__ == '__main__':
    main()
