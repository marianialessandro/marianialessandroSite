"""Compile the reviewed SQL examples into a fixed, parameterized API catalog."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / 'resources' / 'nutrition'
TOKEN = re.compile(r"'(?:\\.|''|[^'\\])*'|@[a-zA-Z_][a-zA-Z_0-9]*|[A-Za-z_][A-Za-z_0-9]*|\b\d+(?:\.\d+)?\b|;|.", re.S)

def data_fields(statement):
    fields = {}
    insert = re.match(r'INSERT INTO \w+\s*\((.*?)\)\s*VALUES\s*', statement, re.S)
    if insert:
        columns = [column.strip() for column in insert.group(1).split(',')]
        depth, column, row, start, position = 0, 0, 0, 0, insert.end()
        for token in TOKEN.findall(statement[insert.end():]):
            if token == '(':
                if depth == 0:
                    row += 1
                    column = 0
                    start = position + 1
                depth += 1
            elif token == ')':
                depth -= 1
                if depth == 0:
                    fields[(start, position)] = columns[column] + (f'_{row}' if row > 1 else '')
            elif token == ',' and depth == 1:
                fields[(start, position)] = columns[column] + (f'_{row}' if row > 1 else '')
                column += 1
                start = position + 1
            if depth == 0 and token.upper() == 'ON':
                break
            position += len(token)
    if statement.startswith('UPDATE '):
        for match in re.finditer(r'(?:SET|,)\s*(?:\w+\.)?(\w+)\s*=\s*', statement):
            start = match.end()
            token = TOKEN.match(statement, start)
            if token:
                fields[(start, token.end())] = match.group(1)
    return fields

def build():
    source = (ROOT / 'nutrizionista_query_catalog_mysql.sql').read_text()
    headings = list(re.finditer(r'^-- (\d+\.\d+) (.+)$', source, re.M))
    catalog = {}
    for index, heading in enumerate(headings):
        key, title = heading.groups()
        block = source[heading.end():headings[index + 1].start() if index + 1 < len(headings) else source.index('-- 23.')]
        block = re.sub(r'^--.*$', '', block, flags=re.M).strip()
        if key == '16.8':
            block = block.replace('SET @nuova_giornata_id = @giornata_id;', '')
            block += '\nUPDATE osservazioni_apprendimenti SET giornata_id = @nuova_giornata_id WHERE pasto_id = @pasto_id;'
        if key == '16.9':
            block = block.replace('WHERE id = 1', 'WHERE id = @voce_id')
        if key == '17.12':
            block = block.replace('ROLLBACK;', 'DELETE FROM diario_giornaliero WHERE id = @giornata_id;')
        if key == '19.8':
            block = block.replace("'id', x.id", "'id', x.pasto_id")
        if key == '19.5':
            block = block.replace('LIMIT 50', 'LIMIT @page_size')
        if key == '19.6':
            block = block.replace('LIMIT 50 OFFSET 0', 'LIMIT @page_size OFFSET @offset')
        statements, current = [], ''
        for token in TOKEN.findall(block):
            if token == ';':
                if current.strip():
                    statements.append(current.strip())
                current = ''
            else:
                current += token
        params, steps, assigned = {}, [], set()
        section = int(key.split('.')[0])
        ability = 'delete' if section == 17 else 'maintenance' if section == 18 else 'write' if section in (5, 16) or key == '19.2' else 'read'
        for statement in statements:
            if statement in ('START TRANSACTION', 'COMMIT', 'ROLLBACK'):
                continue
            assignment = re.fullmatch(r'SET @(\w+) = (.+)', statement, re.S)
            capture = None
            if assignment:
                name, expression = assignment.groups()
                if expression != 'LAST_INSERT_ID()':
                    continue
                capture = name
                statement = 'SELECT LAST_INSERT_ID() AS value'
            into = re.search(r'\s+INTO @(\w+)', statement)
            if into:
                capture = into.group(1)
                statement = statement[:into.start()] + statement[into.end():]
            bindings, compiled = [], ''
            # Only data literals in mutations and filter values in reads become public inputs.
            filter_start = re.search(r'\bWHERE\b', statement)
            fields = data_fields(statement)
            position = 0
            literal_index = 0
            for token in TOKEN.findall(statement):
                field = next((name for (start, end), name in fields.items() if start <= position < end and statement[start:end].strip() == token), None)
                is_literal = (token == 'NULL' and field is not None) or token.startswith("'") or re.fullmatch(r'\d+(?:\.\d+)?', token)
                # Read expressions and the product recalculation retain their original constants.
                customizable = key not in ('16.10',) and is_literal and ((ability in ('write', 'delete') and not capture) or (filter_start and position > filter_start.start() and token.startswith("'")))
                if token.startswith('@'):
                    name = token[1:]
                    if name not in assigned:
                        params.setdefault(name, {'type': 'integer' if name.endswith('_id') or name in ('ultimo_id', 'page_size', 'offset', 'n_giorni') else 'number' if name in ('quantita_g', 'soglia_sazieta', 'soglia_kcal') else 'string'})
                    bindings.append(name)
                    compiled += '?'
                elif customizable:
                    literal_index += 1
                    name = f'arg_{len(steps) + 1}_{literal_index}'
                    field = next((name for (start, end), name in fields.items() if start <= position < end and statement[start:end].strip() == token), None)
                    if field:
                        name = field if field not in params else f'{field}_{len(steps) + 1}'
                    value = None if token == 'NULL' else token[1:-1].replace("''", "'").replace('\\n', '\n') if token.startswith("'") else float(token) if '.' in token else int(token)
                    params[name] = {'type': ['number' if field and re.search(r'(_cm|_kg|_pct|_g|_kcal)$', field) else 'string', 'null'] if value is None else 'string' if isinstance(value, str) else 'number', 'default': value, 'description': (field + ': ' if field else 'SQL value: ') + statement[max(0, position - 65):position + len(token) + 35].strip()}
                    bindings.append(name)
                    compiled += '?'
                else:
                    compiled += token
                position += len(token)
            steps.append({'sql': compiled, 'bindings': bindings, 'capture': capture})
            if capture:
                assigned.add(capture)
        catalog[key] = {'id': key, 'description': title, 'ability': 'nutrition:' + ability, 'parameters': params, 'steps': steps}
    # Procedure-equivalent operations use the same transactional implementation without requiring routines.
    for key, original, title in [('23.1', '19.2', 'sp_get_or_create_giornata'), ('23.2', '16.10', 'sp_ricalcola_voce_da_prodotto'), ('23.3', '17.10', 'sp_delete_giornata')]:
        catalog[key] = dict(catalog[original], id=key, description=title)
    (ROOT / 'catalog.json').write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n')
    print(f'Compiled {len(catalog)} operations')

if __name__ == '__main__':
    build()
