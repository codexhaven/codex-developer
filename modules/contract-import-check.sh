#!/usr/bin/env bash
# CODES-DEVELOPER v12.6 — Codex Developer
# ctx: codexhaven
# Contract Import Check — validates imports against contract
# Only flags PROJECT imports, not stdlib or known third-party packages

REPODIR="${1:-${REPODIR:-.}}"
FILEPATH="${2:-}"
CONTRACTFILE="${REPODIR}/.codex/contract.json"

[ -f "$CONTRACTFILE" ] || exit 0
[ -n "$FILEPATH" ] || exit 0
[ -f "$REPODIR/$FILEPATH" ] || exit 0

python3 << 'PYEOF'
import json, os, re, sys

repodir = os.environ.get('REPODIR', '.')
contract_file = os.path.join(repodir, '.codex', 'contract.json')
filepath = os.environ.get('FILEPATH', '')

# Known external packages — never flag these
EXTERNAL = {
    'sqlalchemy', 'sqlalchemy.orm', 'sqlalchemy.ext', 'sqlalchemy.ext.asyncio',
    'sqlalchemy.future', 'sqlalchemy.exc',
    'fastapi', 'fastapi.security', 'fastapi.middleware', 'fastapi.middleware.cors',
    'fastapi.responses', 'fastapi.encoders',
    'pydantic', 'pydantic_settings', 'pydantic.networks',
    'passlib', 'passlib.context', 'passlib.hash',
    'jose', 'jose.jwt', 'jose.jwe',
    'starlette', 'starlette.config',
    'uvicorn',
    'datetime', 'typing', 'os', 'sys', 'json', 're', 'logging', 'pathlib',
    'subprocess', 'argparse', 'io', 'base64', 'hashlib', 'hmac',
    'email_validator', 'requests', 'aiohttp', 'asyncio',
    'numpy', 'pandas', 'matplotlib',
    'dotenv', 'python-dotenv',
    'supabase',  # External SDK
    'stripe', 'stripe.api',
    'redis', 'celery',
    'dataclasses', 'enum', 'collections', 'functools', 'itertools',
    'contextlib', 'abc', 'copy', 'warnings', 'traceback',
}

with open(contract_file) as f:
    contract = json.load(f)
contract_modules = set(contract.get('modules', {}).keys())

with open(os.path.join(repodir, filepath)) as f:
    content = f.read()

imports = re.findall(r'from\s+(\S+)\s+import|import\s+(\S+)', content)
all_imports = set()
for imp_tuple in imports:
    for imp in imp_tuple:
        if imp:
            all_imports.add(imp)

violations = []
for imp in all_imports:
    # Skip external packages
    if imp in EXTERNAL or imp.split('.')[0] in EXTERNAL:
        continue
    # Check if it's a project module
    mod_path = imp.replace('.', '/') + '.py'
    if mod_path not in contract_modules and imp not in contract_modules:
        violations.append(imp)

if violations:
    print(f"  IMPORT ISSUE: {filepath} imports not in contract:")
    for v in violations:
        print(f"    - {v} (not a known external package, not in contract)")
else:
    print(f"  Import check: OK")
PYEOF
