#!/usr/bin/env bash
# Local dev loop for the carbuncle site. Renders with blog-generate.sh straight
# into .dev-site/ (gitignored) and serves it — no nix build, so edits show up in
# well under a second. Run it from inside `nix develop`, which provides the
# tools (cmark-gfm, gawk, python3, entr) and $LORA for the served fonts.
#
#   ./dev.sh build   render once into .dev-site/
#   ./dev.sh serve   serve .dev-site/ on :8000 (default)
#   ./dev.sh watch   build, serve, and re-render on every change (default action)
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
out="$here/.dev-site"
port="${2:-8000}"

# Re-exec inside `nix develop` if the toolchain isn't on PATH, so this works
# whether or not you've already entered the dev shell. The guard var stops a loop.
if [ -z "${IN_CARBUNCLE_DEVSHELL:-}" ] && ! command -v cmark-gfm >/dev/null 2>&1; then
  echo "entering dev shell..."
  exec nix develop "$here" --command env IN_CARBUNCLE_DEVSHELL=1 "$here/dev.sh" "$@"
fi

cd "$here"   # anchor CWD to the repo (the served tree gets swapped out under us)

build() {
  local tmp="$out.tmp"
  rm -rf "$tmp"
  bash "$here/blog-generate.sh" "$here/site/blog" "$tmp"
  cp -r "$here/site/terminal" "$tmp/terminal"
  mkdir -p "$tmp/fonts"
  cp "$here/fonts/OFL.txt" "$tmp/fonts/OFL.txt"
  cp "$here/fonts/Hack-LICENSE.md" "$tmp/fonts/Hack-LICENSE.md"
  if [ -n "${LORA:-}" ]; then
    cp "$LORA/share/fonts/truetype/Lora[wght].ttf" "$tmp/fonts/Lora.ttf"
    cp "$LORA/share/fonts/truetype/Lora-Italic[wght].ttf" "$tmp/fonts/Lora-Italic.ttf"
  else
    echo "note: \$LORA unset — fonts will 404. run inside 'nix develop'." >&2
  fi
  if [ -n "${HACK:-}" ]; then
    cp "$HACK/share/fonts/truetype/Hack-Regular.ttf" "$tmp/fonts/Hack-Regular.ttf"
    cp "$HACK/share/fonts/truetype/Hack-Bold.ttf" "$tmp/fonts/Hack-Bold.ttf"
  else
    echo "note: \$HACK unset — Hack font will 404. run inside 'nix develop'." >&2
  fi
  # swap the freshly built tree into place; the server serves via --directory
  # (re-resolved per request), so a rebuild never pulls the tree out from under it
  rm -rf "$out.prev"
  [ -e "$out" ] && mv "$out" "$out.prev"
  mv "$tmp" "$out"
  rm -rf "$out.prev"
  echo "built -> $out"
}

serve() {
  [ -d "$out" ] || build
  echo "serving $out at http://localhost:$port  (Ctrl-C to stop)"
  exec python3 -m http.server "$port" --directory "$out"
}

watch() {
  build
  python3 -m http.server "$port" --directory "$out" &
  server=$!
  trap 'kill "$server" 2>/dev/null || true' EXIT
  echo "serving http://localhost:$port — watching for changes (Ctrl-C to stop)"
  # entr -d exits when a dir changes / a new file appears; the loop re-arms it,
  # so newly added posts get picked up too. blog-generate.sh is watched as well.
  while true; do
    find "$here/site" "$here/blog-generate.sh" -type f \
      | entr -nd "$here/dev.sh" build || true
    sleep 0.5   # if entr exits (e.g. no TTY), don't spin the CPU re-arming
  done
}

case "${1:-watch}" in
  build) build ;;
  serve) serve ;;
  watch) watch ;;
  *) echo "usage: $0 {build|serve|watch} [port]" >&2; exit 1 ;;
esac
