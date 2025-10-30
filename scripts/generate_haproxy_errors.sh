#!/usr/bin/env bash
# Generate HAProxy-compatible .http error files from HTML pages
# Usage:
#   ./scripts/generate_haproxy_errors.sh         # generate into pages/haproxy
#   ./scripts/generate_haproxy_errors.sh --install  # generate then copy to /etc/haproxy/errors (requires sudo)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$REPO_ROOT/pages"
OUT_DIR="$SRC_DIR/haproxy"

INSTALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install) INSTALL=true; shift ;;
    --help|-h) echo "Usage: $0 [--install]"; exit 0 ;;
    *) echo "Unknown arg: $1"; echo "Usage: $0 [--install]"; exit 2 ;;
  esac
done

mkdir -p "$OUT_DIR"

echo "Generating HAProxy .http files from HTML in: $SRC_DIR"

shopt -s nullglob
count=0
for file in "$SRC_DIR"/*.html; do
  fname="$(basename "$file")"
  code="${fname%%.*}"

  # Skip index.html or non-numeric filenames
  if [[ ! "$code" =~ ^[0-9]{3}$ ]]; then
    echo " - Skipping non-status file: $fname"
    continue
  fi

  case "$code" in
    400) status_text="Bad Request" ;;
    401) status_text="Unauthorized" ;;
    403) status_text="Forbidden" ;;
    404) status_text="Not Found" ;;
    500) status_text="Internal Server Error" ;;
    502) status_text="Bad Gateway" ;;
    503) status_text="Service Unavailable" ;;
    504) status_text="Gateway Timeout" ;;
    *)   status_text="Error" ;;
  esac

  out_file="$OUT_DIR/$code.http"

  echo " - $fname -> $(basename "$out_file") (HTTP/1.0 $code $status_text)"

  # Write HTTP status line and headers using CRLF as required by many HTTP parsers
  printf 'HTTP/1.0 %s %s\r\n' "$code" "$status_text" > "$out_file"
  printf 'Cache-Control: no-cache\r\n' >> "$out_file"
  printf 'Content-Type: text/html; charset=utf-8\r\n' >> "$out_file"
  printf 'Connection: close\r\n' >> "$out_file"
  printf '\r\n' >> "$out_file"

  # Append the HTML body
  cat "$file" >> "$out_file"

  # Ensure permissions are reasonable
  chmod 644 "$out_file"
  count=$((count+1))
done
shopt -u nullglob

echo "Generated $count .http file(s) into: $OUT_DIR"

if $INSTALL; then
  echo "Installing to /etc/haproxy/errors (requires sudo)"
  if [[ $EUID -ne 0 ]]; then
    echo "Requesting sudo to copy files into /etc/haproxy/errors..."
    sudo mkdir -p /etc/haproxy/errors
    sudo cp -v "$OUT_DIR"/*.http /etc/haproxy/errors/ || true
    sudo chown root:root /etc/haproxy/errors/*.http || true
    sudo chmod 644 /etc/haproxy/errors/*.http || true
  else
    mkdir -p /etc/haproxy/errors
    cp -v "$OUT_DIR"/*.http /etc/haproxy/errors/ || true
    chown root:root /etc/haproxy/errors/*.http || true
    chmod 644 /etc/haproxy/errors/*.http || true
  fi
  echo "Installed .http files to /etc/haproxy/errors"
fi

echo "Done."
