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

cp assets/images/brand_v3_segunda_logo.svg build/web/boot-logo.svg

python3 - <<'PY'
import re
from pathlib import Path

index_path = Path("build/web/index.html")
index_content = index_path.read_text(encoding="utf-8")
marker = "__BOOT_SPLASH_DATA__"
if marker not in index_content:
    raise RuntimeError("Marcador da imagem de inicializacao nao encontrado")
encoded_splash = Path("web/boot-splash.b64").read_text(encoding="ascii").strip()
index_path.write_text(
    index_content.replace(marker, f"data:image/jpeg;base64,{encoded_splash}"),
    encoding="utf-8",
)

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

index_path = Path("build/web/index.html")
index_content = index_path.read_text(encoding="utf-8")
marker = "__GESTAO_BOOT_SPLASH_DATA__"
if marker not in index_content:
    raise RuntimeError("Marcador da splash da Gestao nao encontrado")
encoded_splash = Path("../cliente/web/boot-splash.b64").read_text(encoding="ascii").strip()
index_path.write_text(
    index_content.replace(marker, f"data:image/jpeg;base64,{encoded_splash}"),
    encoding="utf-8",
)

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
