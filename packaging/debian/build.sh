#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="${WORK:-$ROOT/build-deb}"
STAGE="$WORK/stage"
VERSION="$(python3 -c "import re;print(re.search(r\"version: '([^']+)'\", open('$ROOT/meson.build').read()).group(1))")"

rm -rf "$WORK"
mkdir -p "$STAGE/DEBIAN"

BYEDPI_TAG="$(python3 -c "import json;print(json.load(open('$ROOT/packaging/byedpi-upstream.json'))['tag'])")"

meson setup "$WORK/meson" "$ROOT" --prefix=/usr -Dbuildtype=release
meson install -C "$WORK/meson" --destdir "$STAGE"

bash "$ROOT/packaging/fetch-ciadpi-all.sh" "$BYEDPI_TAG" "$STAGE/usr/lib/byedpi-gtk"

cat > "$STAGE/DEBIAN/control" <<EOF
Package: byedpi-gtk
Version: ${VERSION}
Section: net
Priority: optional
Architecture: all
Depends: python3 (>= 3.10), python3-gi, gir1.2-gtk-4.0, gir1.2-adw-1
Maintainer: duckesteles <176202616+duckesteles@users.noreply.github.com>
Description: GTK frontend for byedpi to bypass DPI restrictions
 A graphical frontend that manages a local byedpi SOCKS proxy.
EOF

dpkg-deb --root-owner-group --build "$STAGE" \
  "$ROOT/byedpi-gtk_${VERSION}_all.deb"
