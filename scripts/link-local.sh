#!/bin/sh
set -eu

usage() {
  printf 'Usage: %s [package-directory]\n' "$0"
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac
if [ "$#" -gt 1 ]; then usage >&2; exit 2; fi

repo=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
if [ "$#" -eq 1 ]; then
  packages=$1
elif [ -n "${TYPST_PACKAGE_PATH:-}" ]; then
  packages=$TYPST_PACKAGE_PATH
elif [ "$(uname -s)" = Darwin ]; then
  packages="$HOME/Library/Application Support/typst/packages"
else
  packages="${XDG_DATA_HOME:-$HOME/.local/share}/typst/packages"
fi

parent="$packages/local/better-math-spacing"
mkdir -p -- "$parent"
link="$parent/0.1.1"
if [ -L "$link" ] && [ "$(readlink "$link")" = "$repo" ]; then
  printf '%s\n' "$link"
  exit 0
fi
# Create exactly this path, even if a file or directory already occupies it.
# ln -T is unavailable on macOS, so use the POSIX symlink operation via Python.
python3 - "$repo" "$link" <<'PY'
import os
import sys

source, target = sys.argv[1:]
try:
    os.symlink(source, target)
except FileExistsError:
    sys.exit(f"Package location already exists: {target}")
print(target)
PY
