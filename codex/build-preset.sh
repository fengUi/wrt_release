#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${1:-action_build}"
PLAIN_DIR="${2:-firmware-plain}"
PRESET_DIR="${3:-firmware-preset}"

if [[ ! -d "$BUILD_DIR" ]]; then
  echo "Build directory not found: $BUILD_DIR" >&2
  exit 1
fi

if [[ -z "${WAN2_USERNAME:-}" || -z "${WAN2_PASSWORD:-}" ]]; then
  echo "WAN2_USERNAME and WAN2_PASSWORD secrets are required for preset firmware." >&2
  exit 1
fi

WAN1_USERNAME="${WAN1_USERNAME:-059205648239}"
WAN1_PASSWORD="${WAN1_PASSWORD:-123456}"

mkdir -p "$PLAIN_DIR" "$PRESET_DIR"
cp -av firmware/* "$PLAIN_DIR/" 2>/dev/null || true

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cp -a codex/preset-files/. "$tmpdir/"

python3 - "$tmpdir/etc/uci-defaults/98-codex-dualwan-mwan3" <<'PY'
import os
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()
for key in ("WAN1_USERNAME", "WAN1_PASSWORD", "WAN2_USERNAME", "WAN2_PASSWORD"):
    text = text.replace(f"__{key}__", os.environ.get(key, ""))
path.write_text(text)
PY

install -Dm755 "$tmpdir/etc/uci-defaults/98-codex-dualwan-mwan3" \
  "$BUILD_DIR/package/base-files/files/etc/uci-defaults/98-codex-dualwan-mwan3"
install -Dm755 "$tmpdir/etc/hotplug.d/iface/99-codex-mwan3-quality" \
  "$BUILD_DIR/package/base-files/files/etc/hotplug.d/iface/99-codex-mwan3-quality"
install -Dm755 "$tmpdir/usr/bin/codex-mwan3-quality" \
  "$BUILD_DIR/package/base-files/files/usr/bin/codex-mwan3-quality"

pushd "$BUILD_DIR" >/dev/null
find bin/targets -type f \( -name "*.bin" -o -name "*.manifest" -o -name "*efi.img.gz" -o -name "*.itb" -o -name "*.fip" -o -name "*.ubi" -o -name "*rootfs.tar.gz" \) -delete
make target/install -j"$(($(nproc) + 1))" || make target/install -j1 V=s
find bin/targets -type f \( -name "*.bin" -o -name "*.manifest" -o -name "*efi.img.gz" -o -name "*.itb" -o -name "*.fip" -o -name "*.ubi" -o -name "*rootfs.tar.gz" \) -exec cp -f {} "../$PRESET_DIR/" \;
popd >/dev/null

find "$PLAIN_DIR" "$PRESET_DIR" -maxdepth 1 -type f -printf '%p %s\n'
