#!/usr/bin/env bash
set -euo pipefail

# Build a reproducible, isolated iOS Blink content_shell prototype using the
# Blinker Fluid overlay. This does NOT yet embed content_shell into Reynard.
# Overlay source is GPL-3.0; see the upstream LICENSE and preserve notices.

ROOT="${BLINK_BUILD_ROOT:-$HOME/reynard-blink-build}"
OVERLAY_REV="1924b4d67c994c26b4d52505f24f0ee4e9a50e89"
CHROMIUM_REV="4d790f9eb4c8abe65b8aaa3feba664e7c734ba56"
OVERLAY_URL="https://github.com/Nodesclock/Blinker-fluid/archive/${OVERLAY_REV}.tar.gz"
OUT_NAME="${BLINK_OUT:-blink15}"
JOBS="${BLINK_JOBS:-2}"
BUNDLE_ID="${BLINK_BUNDLE_ID:-com.reynard.blinkexperiment}"

for tool in git curl tar rsync gclient gn autoninja; do
  command -v "$tool" >/dev/null || { echo "Missing required tool: $tool (Chromium depot_tools required)" >&2; exit 1; }
done
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This build script requires macOS." >&2; exit 1
fi
available_kb=$(df -Pk "$HOME" | awk 'NR==2 {print $4}')
if (( available_kb < 110000000 )); then
  echo "At least ~110 GB free disk space is recommended. Available: $((available_kb/1024/1024)) GB" >&2
  exit 1
fi

mkdir -p "$ROOT"
cd "$ROOT"
if [[ ! -d overlay ]]; then
  mkdir overlay
  curl -fL "$OVERLAY_URL" | tar -xz --strip-components=1 -C overlay
fi
if [[ ! -d chromium/src/.git ]]; then
  mkdir -p chromium
  cd chromium
  gclient config --spec='solutions = [{"name": "src", "url": "https://chromium.googlesource.com/chromium/src.git", "managed": False, "custom_deps": {}, "custom_vars": {}}]; target_os = ["ios"]; target_os_only = True'
  gclient sync --nohooks --revision "src@$CHROMIUM_REV"
else
  cd chromium
  gclient sync --nohooks --revision "src@$CHROMIUM_REV"
fi

rsync -a --exclude='.git' "$ROOT/overlay/src/" "$ROOT/chromium/src/"
cd "$ROOT/chromium/src"
gclient runhooks
mkdir -p "out/$OUT_NAME"
cp "$ROOT/overlay/build_args.gn" "out/$OUT_NAME/args.gn"
python3 - "$BUNDLE_ID" "$OUT_NAME" <<'PY'
import sys
from pathlib import Path
bundle=sys.argv[1]
out_name=sys.argv[2]
args=Path("out") / out_name / "args.gn"
text=args.read_text()
text=text.replace('ios_content_shell_bundle_identifier = "com.nodesclock.blinkerfluid"',f'ios_content_shell_bundle_identifier = "{bundle}"')
args.write_text(text)
PY
gn gen "out/$OUT_NAME"
autoninja -C "out/$OUT_NAME" -j "$JOBS" content_shell
echo
echo "Build completed. App bundle: $ROOT/chromium/src/out/$OUT_NAME/content_shell.app"
echo "This standalone shell build is NOT yet a Reynard-embedded browser."
