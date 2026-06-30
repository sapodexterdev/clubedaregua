#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.24.5}"
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

cd apps/cliente

flutter config --enable-web
flutter pub get

flutter build web \
  --release \
  --web-renderer html \
  --no-tree-shake-icons \
  --pwa-strategy=none \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"

python3 - <<'PY'
import re
from pathlib import Path

path = Path("build/web/flutter_bootstrap.js")
content = path.read_text(encoding="utf-8")
content = re.sub(
    r"""serviceWorkerSettings:\s*\{\s*serviceWorkerVersion:\s*["'][^"']*["']\s*\}""",
    "serviceWorkerSettings: null",
    content,
)
path.write_text(content, encoding="utf-8")
PY

cd ../gestao

flutter pub get

flutter build web \
  --release \
  --web-renderer html \
  --no-tree-shake-icons \
  --pwa-strategy=none \
  --base-href=/gestao/ \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"

python3 - <<'PY'
import re
from pathlib import Path

path = Path("build/web/flutter_bootstrap.js")
content = path.read_text(encoding="utf-8")
content = re.sub(
    r"""serviceWorkerSettings:\s*\{\s*serviceWorkerVersion:\s*["'][^"']*["']\s*\}""",
    "serviceWorkerSettings: null",
    content,
)
path.write_text(content, encoding="utf-8")
PY

mkdir -p ../cliente/build/web/gestao
cp -R build/web/. ../cliente/build/web/gestao/
