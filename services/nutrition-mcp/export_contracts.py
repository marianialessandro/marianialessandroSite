"""Freeze the REST discovery contract without reading a database or credentials."""
import json
from pathlib import Path
import subprocess


def main():
    directory = Path(__file__).resolve().parent
    api = directory.parents[1] / 'apps/api.marianialessandro.com'
    code = "require 'vendor/autoload.php'; $app = require 'bootstrap/app.php'; $app->make(Illuminate\\Contracts\\Console\\Kernel::class)->bootstrap(); $catalog = app(App\\Services\\Nutrition\\QueryCatalog::class); echo json_encode(array_values(array_map($catalog->describe(...), $catalog->all())), JSON_THROW_ON_ERROR);"
    catalog = json.loads(subprocess.check_output(['php', '-r', code], cwd=api))
    (directory / 'contracts/catalog.json').write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n')
    lines = ['# Matrice operazioni', '', 'Baseline: `mcp_api` commit `a6174232af5da46b51087b591e2da1c21f724334`.', '', 'Diagnostica: nessuna operazione dati. Primo collegamento: read dopo la prova OAuth. Write/delete/maintenance: scope più ID esplicito e collaudo staging.', '', '| ID | Tool | Scope | Profilo iniziale read |', '|---|---|---|---|']
    for entry in catalog:
        lines.append(f"| {entry['id']} | nutrition_{entry['id'].replace('.', '_')} | {entry['ability']} | {'abilitata' if entry['ability'] == 'nutrition:read' else 'disabilitata'} |")
    (directory / 'contracts/operations.md').write_text('\n'.join(lines) + '\n')


if __name__ == '__main__':
    main()
