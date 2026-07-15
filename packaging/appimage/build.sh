#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="${WORK:-$ROOT/build-appimage}"
APPDIR="$WORK/AppDir"
ARCH="${ARCH:-x86_64}"
BYEDPI_TAG="$(python3 -c "import json,sys;print(json.load(open('$ROOT/packaging/byedpi-upstream.json'))['tag'])")"

rm -rf "$WORK"
mkdir -p "$APPDIR"

meson setup "$WORK/meson" "$ROOT" --prefix=/usr -Dbuildtype=release
meson install -C "$WORK/meson" --destdir "$APPDIR"

install -d "$APPDIR/usr/bin"
ASSET_URL="$(curl -fsSL "https://api.github.com/repos/hufrea/byedpi/releases/tags/${BYEDPI_TAG}" \
  | SUFFIX="-${ARCH}.tar.gz" python3 -c "
import json, os, sys
release = json.load(sys.stdin)
suffix = os.environ['SUFFIX']
print(next(a['browser_download_url'] for a in release['assets'] if a['name'].endswith(suffix)))
")"
curl -fSL -o "$WORK/byedpi.tar.gz" "$ASSET_URL"
tar -xzf "$WORK/byedpi.tar.gz" -C "$WORK"
install -Dm755 "$WORK/ciadpi-${ARCH}" "$APPDIR/usr/bin/ciadpi"

cp "$ROOT/data/icons/hicolor/scalable/apps/io.github.duckesteles.byedpigtk.svg" \
  "$APPDIR/io.github.duckesteles.byedpigtk.svg"
cp "$APPDIR/usr/share/applications/io.github.duckesteles.byedpigtk.desktop" \
  "$APPDIR/io.github.duckesteles.byedpigtk.desktop"

cat > "$APPDIR/AppRun" <<'EOF'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="$HERE/usr/bin:$PATH"
export PYTHONPATH="$HERE/usr/lib/python3/dist-packages:$HERE/usr/lib/python3.12/site-packages:$PYTHONPATH"
export XDG_DATA_DIRS="$HERE/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
exec "$HERE/usr/bin/byedpi-gtk" "$@"
EOF
chmod +x "$APPDIR/AppRun"

if [ ! -x "$WORK/appimagetool" ]; then
  curl -fSL -o "$WORK/appimagetool" \
    "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH}.AppImage"
  chmod +x "$WORK/appimagetool"
fi

ARCH="$ARCH" "$WORK/appimagetool" --no-appstream "$APPDIR" \
  "$ROOT/byedpi-gtk-${ARCH}.AppImage"
