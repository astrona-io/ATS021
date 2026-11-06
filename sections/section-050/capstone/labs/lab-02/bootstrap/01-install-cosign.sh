#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_DIR=/usr/local/bin
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) TOOL_PLATFORM=darwin-arm64 ;;
  Darwin-x86_64) TOOL_PLATFORM=darwin-amd64 ;;
  Linux-aarch64|Linux-arm64) TOOL_PLATFORM=linux-arm64 ;;
  Linux-x86_64) TOOL_PLATFORM=linux-amd64 ;;
  *) echo 'Unsupported terminal platform' >&2; exit 1 ;;
esac
for asset in "cosign-$TOOL_PLATFORM" cosign_checksums.txt; do
  curl -fsSL --retry 3 -o "$WORK/$asset" "https://github.com/sigstore/cosign/releases/download/v3.1.4/$asset"
done
python3 - "$WORK/cosign-$TOOL_PLATFORM" "$WORK/cosign_checksums.txt" <<'PYHASH'
import hashlib, pathlib, sys
asset, manifest = map(pathlib.Path, sys.argv[1:])
expected = [line.split()[0] for line in manifest.read_text().splitlines()
            if len(line.split()) == 2 and line.split()[1].lstrip('*') == asset.name]
assert len(expected) == 1, 'Missing or ambiguous checksum'
assert hashlib.sha256(asset.read_bytes()).hexdigest() == expected[0], 'Checksum mismatch'
PYHASH
install -m 0755 "$WORK/cosign-$TOOL_PLATFORM" "$BIN_DIR/cosign"
mkdir -p /tmp/ats021-capstone-050-02-signatures
cp "$SCRIPT_DIR/../manifests/audit-signing.pub" /tmp/ats021-capstone-050-02-signatures/audit-signing.pub
"$BIN_DIR/cosign" version
