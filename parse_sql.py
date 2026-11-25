import re
import os

sql_files = [
    'database/001_pawcare_mysql_schema.sql',
    'database/005_wallet_escrow_ledger.sql',
    'database/008_bonita_booking_orchestration.sql'
]

tables_meta = {}

for sf in sql_files:
    if not os.path.exists(sf): continue
    with open(sf, 'r', encoding='utf-8') as f:
        text = f.read()
    
    # parse CREATE TABLE statements
    matches = re.finditer(r'CREATE\s+TABLE(?:\s+IF\s+NOT\s+EXISTS)?\s+[`"]?([a-zA-Z0-9_]+)[`"]?\s*\(([\s\S]*?)\)\s*(?:ENGINE|;)', text, re.IGNORECASE)
    for m in matches:
        tname = m.group(1)
        body = m.group(2)
        cols = []
        for line in body.split('\n'):
            line = line.strip().rstrip(',')
            if not line or line.startswith('--') or line.startswith('/*'): continue
            if re.match(r'^(PRIMARY\s+KEY|FOREIGN\s+KEY|UNIQUE|KEY|INDEX|CONSTRAINT)', line, re.IGNORECASE):
                continue
            # Column line
            parts = line.split()
            cname = parts[0].strip('`"[]')
            ctype = parts[1] if len(parts) > 1 else ''
            rest = ' '.join(parts[2:]) if len(parts) > 2 else ''
            cols.append((cname, ctype, rest))
        tables_meta[tname] = cols

print(f'Parsed {len(tables_meta)} tables successfully:')
for t, cols in tables_meta.items():
    print(f'Table {t}: {len(cols)} columns')
