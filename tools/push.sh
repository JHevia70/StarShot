#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
DEFAULT_BRANCH="main"
# Pon aquí tu URL si quieres fijarla por defecto y evitar el prompt la 1ª vez:
# GITHUB_URL="https://github.com/TU_USUARIO/starshot3d.git"
: "${GITHUB_URL:=}"

# --- Helpers ---
timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

ensure_repo() {
  if [ ! -d .git ]; then
    echo "[i] Inicializando repo..."
    git init
  fi
  # aseguramos rama principal
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [ "$current_branch" != "$DEFAULT_BRANCH" ]; then
    git checkout -B "$DEFAULT_BRANCH"
  fi
  # remoto origin
  if ! git remote get-url origin >/dev/null 2>&1; then
    if [ -z "$GITHUB_URL" ]; then
      read -rp "URL del repo (HTTPS o SSH): " GITHUB_URL
    fi
    git remote add origin "$GITHUB_URL"
  fi
}

main() {
  ensure_repo
  # .gitignore si no existe
  if [ ! -f .gitignore ]; then
    cat > .gitignore <<'IGN'
.godot/
.import/
.export/
mono/
.DS_Store
Thumbs.db
bin/
*.tmp
*.bak
*.old
IGN
    git add .gitignore
  fi

  msg="${*:-"update: $(timestamp)"}"
  git add -A
  if ! git diff --cached --quiet; then
    git commit -m "$msg"
  else
    echo "[i] No hay cambios que commitear."
  fi
  # primer push puede requerir upstream
  if git rev-parse --symbolic-full-name --verify -q @{u} >/dev/null; then
    git push
  else
    git push -u origin "$DEFAULT_BRANCH"
  fi
  echo "[✓] Push completado."
}

main "$@"
