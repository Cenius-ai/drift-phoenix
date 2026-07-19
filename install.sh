#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Drift — install script (idempotent: safe to re-run)
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")"

echo "=== Drift install ==="
echo ""

# ---------------------------------------------------------------------------
# 1. Elixir tooling (non-interactive)
# ---------------------------------------------------------------------------
echo "→ Installing Hex + Rebar…"
mix local.hex --force
mix local.rebar --force

# ---------------------------------------------------------------------------
# 2. Dependencies
# ---------------------------------------------------------------------------
echo "→ Fetching dependencies…"
mix deps.get

# ---------------------------------------------------------------------------
# 3. Download fonts (install phase has network access)
# ---------------------------------------------------------------------------
FONTS_DIR="priv/static/assets/fonts"
mkdir -p "$FONTS_DIR"

download_google_font() {
  local family="$1" dest="$2"
  if [ -f "$dest" ]; then
    echo "   Font $dest already present — skipping."
    return 0
  fi
  echo "   Downloading $family variable font…"
  local css
  css=$(curl -sSfL "https://fonts.googleapis.com/css2?family=${family}:wght@100..900&display=swap" 2>/dev/null || true)
  if [ -z "$css" ]; then
    echo "   WARNING: Could not download $family — using system fallback."
    return 0
  fi
  local url
  url=$(echo "$css" | grep -oP 'url\(\K[^)]*\.woff2' | head -1 || true)
  if [ -z "$url" ]; then
    echo "   WARNING: No woff2 URL found for $family — using system fallback."
    return 0
  fi
  curl -sSfL "$url" -o "$dest" 2>/dev/null || {
    echo "   WARNING: Download failed for $family — using system fallback."
    rm -f "$dest"
    return 0
  }
  echo "   Downloaded $family → $dest"
}

echo "→ Downloading web fonts…"
download_google_font "Outfit" "$FONTS_DIR/outfit-var.woff2"
download_google_font "Inter" "$FONTS_DIR/inter-var.woff2"

# ---------------------------------------------------------------------------
# 4. Database setup (idempotent: create + migrate + seed)
# ---------------------------------------------------------------------------
echo "→ Setting up database…"
mix ecto.create 2>/dev/null || true
mix ecto.migrate
mix run priv/repo/seeds.exs

# ---------------------------------------------------------------------------
# 5. Compile (catches .heex errors before boot)
# ---------------------------------------------------------------------------
echo "→ Compiling…"
mix compile

echo ""
echo "=== Install complete ==="
echo "Start the server:  mix phx.server"
echo "Open in browser:   http://localhost:4000"
