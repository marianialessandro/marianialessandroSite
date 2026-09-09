"""Run integration tests against a disposable Docker MySQL instance."""
import argparse
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]

def run(image):
    container = subprocess.check_output(['docker', 'run', '-d', '--rm', '-e', 'MYSQL_ALLOW_EMPTY_PASSWORD=yes', '-p', '127.0.0.1::3306', image], text=True).strip()
    try:
        for _ in range(120):
            ready = subprocess.run(['docker', 'exec', container, 'mysqladmin', '-h127.0.0.1', '--protocol=tcp', 'ping', '--silent'], capture_output=True)
            if ready.returncode == 0:
                break
            time.sleep(0.5)
        else:
            raise RuntimeError('MySQL did not become ready within 60 seconds.')
        schema = (ROOT / 'resources/nutrition/nutrizionista_schema_mysql.sql').read_bytes()
        subprocess.run(['docker', 'exec', '-i', container, 'mysql', '-uroot'], input=schema, check=True)
        port = subprocess.check_output(['docker', 'port', container, '3306'], text=True).strip().rsplit(':', 1)[1]
        environment = dict(os.environ, NUTRITION_MYSQL_TEST='1', NUTRITION_MYSQL_TEST_PORT=port, APP_KEY='base64:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=')
        subprocess.run(['php', 'artisan', 'test', '--filter=NutritionMysqlTest', '--compact'], cwd=ROOT, env=environment, check=True)
    finally:
        subprocess.run(['docker', 'rm', '-f', container], stdout=subprocess.DEVNULL, check=False)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--image', default='mysql:8.0', help='MySQL 8 Docker image used exclusively for disposable tests.')
    run(parser.parse_args().image)
