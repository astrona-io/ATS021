#!/usr/bin/env bash
# Install pinned command-line tools on the terminal, as sibling labs do.
set -euo pipefail
BIN_DIR=/usr/local/bin
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) TRIVY_ASSET=macOS-ARM64; TOOL_PLATFORM=darwin-arm64; JQ_PLATFORM=macos-arm64 ;;
  Darwin-x86_64) TRIVY_ASSET=macOS-64bit; TOOL_PLATFORM=darwin-amd64; JQ_PLATFORM=macos-amd64 ;;
  Linux-aarch64|Linux-arm64) TRIVY_ASSET=Linux-ARM64; TOOL_PLATFORM=linux-arm64; JQ_PLATFORM=linux-arm64 ;;
  Linux-x86_64) TRIVY_ASSET=Linux-64bit; TOOL_PLATFORM=linux-amd64; JQ_PLATFORM=linux-amd64 ;;
  *) echo 'Unsupported terminal platform' >&2; exit 1 ;;
esac
verify_checksum() {
  local asset="$1" manifest="$2"
  python3 - "$WORK/$asset" "$WORK/$manifest" <<'PYHASH'
import hashlib, pathlib, sys
asset, manifest = map(pathlib.Path, sys.argv[1:])
expected = [line.split()[0] for line in manifest.read_text().splitlines()
            if len(line.split()) == 2 and line.split()[1].lstrip('*') == asset.name]
assert len(expected) == 1, 'Missing or ambiguous checksum'
assert hashlib.sha256(asset.read_bytes()).hexdigest() == expected[0], 'Checksum mismatch'
PYHASH
}
TRIVY_VERSION=0.76.2
TRIVY_ARCHIVE="trivy_${TRIVY_VERSION}_${TRIVY_ASSET}.tar.gz"
for asset in "$TRIVY_ARCHIVE" "trivy_${TRIVY_VERSION}_checksums.txt"; do
  curl -fsSL --retry 3 -o "$WORK/$asset" "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/$asset"
done
verify_checksum "$TRIVY_ARCHIVE" "trivy_${TRIVY_VERSION}_checksums.txt"
tar -xzf "$WORK/$TRIVY_ARCHIVE" -C "$WORK" trivy
install -m 0755 "$WORK/trivy" "$BIN_DIR/trivy"
for asset in "jq-$JQ_PLATFORM" sha256sum.txt; do
  curl -fsSL --retry 3 -o "$WORK/$asset" "https://github.com/jqlang/jq/releases/download/jq-1.8.2/$asset"
done
verify_checksum "jq-$JQ_PLATFORM" sha256sum.txt
install -m 0755 "$WORK/jq-$JQ_PLATFORM" "$BIN_DIR/jq"
trivy --version
jq --version
