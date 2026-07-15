#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="${WORK:-$ROOT/build-deb}"
STAGE="$WORK/stage"
VERSION="$(python3 -c "import re;print(re.search(r\"version: '([^']+)'\", open('$ROOT/meson.build').read()).group(1))")"
ARCH="$(dpkg --print-architecture)"

rm -rf "$WORK"
mkdir -p "$STAGE/DEBIAN"

BYEDPI_TAG="$(python3 -c "import json;print(json.load(open('$ROOT/packaging/byedpi-upstream.json'))['tag'])")"
BYEDPI_VER="${BYEDPI_TAG#v}"
case "$ARCH" in
  amd64) BYEDPI_ARCH=x86_64 ;;
  arm64) BYEDPI_ARCH=aarch64 ;;
  armhf) BYEDPI_ARCH=armv7l ;;
  i386) BYEDPI_ARCH=i686 ;;
  *) BYEDPI_ARCH="" ;;
esac

meson setup "$WORK/meson" "$ROOT" --prefix=/usr -Dbuildtype=release
meson install -C "$WORK/meson" --destdir "$STAGE"

if [ -n "$BYEDPI_ARCH" ]; then
  curl -fSL -o "$WORK/byedpi.tar.gz" \
    "https://github.com/hufrea/byedpi/releases/download/${BYEDPI_TAG}/byedpi-${BYEDPI_VER}-${BYEDPI_ARCH}.tar.gz"
  tar -xzf "$WORK/byedpi.tar.gz" -C "$WORK"
  install -Dm755 "$WORK/ciadpi-${BYEDPI_ARCH}" "$STAGE/usr/bin/ciadpi"
fi

cat > "$STAGE/DEBIAN/control" <<EOF
Package: byedpi-gtk
Version: ${VERSION}
Section: net
Priority: optional
Architecture: ${ARCH}
Depends: python3 (>= 3.10), python3-gi, gir1.2-gtk-4.0, gir1.2-adw-1
Maintainer: duckesteles <176202616+duckesteles@users.noreply.github.com>
Description: GTK frontend for byedpi to bypass DPI restrictions
 A graphical frontend that manages a local byedpi SOCKS proxy.
EOF

dpkg-deb --root-owner-group --build "$STAGE" \
  "$ROOT/byedpi-gtk_${VERSION}_${ARCH}.deb"
