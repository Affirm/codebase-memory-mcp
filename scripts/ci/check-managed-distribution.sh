#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

for removed in scripts/setup.sh scripts/setup-windows.ps1 server.json glama.json; do
    [ ! -e "$removed" ] || fail "$removed reintroduces an unmanaged distribution path"
done
if [ -d pkg ] && find pkg -type f -print -quit | grep -q .; then
    fail "pkg contains an unmanaged package-distribution path"
fi

bash -n install.sh

for installer in install.sh install.ps1; do
    if rg -n -i 'https?://|curl|wget|invoke-webrequest|httpclient|download_url|releases/latest' \
        "$installer"; then
        fail "$installer contains a network download capability"
    fi
done

if rg -n 'raw\.githubusercontent\.com/.*/(install|scripts/setup)|releases/latest' \
    README.md docs/index.html; then
    fail "user-facing documentation advertises a floating/network installer"
fi

if rg -n 'DeusData/codebase-memory-mcp/releases|api\.github\.com/repos/DeusData|releases/latest/download' \
    src .github/workflows install.sh install.ps1; then
    fail "an executable source or workflow still selects an upstream/floating release"
fi

release_workflow=.github/workflows/release.yml
for forbidden in 'npm publish' 'twine upload' 'mcp-publisher' 'publish-registries' \
    'publish-mcp-registry'; do
    if rg -n -F "$forbidden" "$release_workflow"; then
        fail "release workflow retains public registry path: $forbidden"
    fi
done

python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
source = (root / "src/cli/cli.c").read_text(encoding="utf-8")
start = source.index("int cbm_cmd_update(int argc, char **argv) {")
production_end = source.index("#else", start)
production = source[start:production_end]
required = (
    "self-update is disabled in this managed build",
    "managed distribution channel",
    "return CLI_TRUE",
)
missing = [item for item in required if item not in production]
if missing:
    raise SystemExit("FAIL: production update path is not fail-closed: " + ", ".join(missing))
for forbidden in ("install.sh", "install.ps1", "releases/latest", "CBM_DOWNLOAD_URL"):
    if forbidden in production:
        raise SystemExit(f"FAIL: production update path retains {forbidden}")

test_api = source[source.index("static const char *cli_download_protocol"):start]
if 'return "=https"' in test_api:
    raise SystemExit("FAIL: test-only updater can still access HTTPS")
if 'return "=file"' not in test_api:
    raise SystemExit("FAIL: local file fixture seam unexpectedly disappeared")
PY

echo "PASS: managed distribution is local-only and upstream release paths are closed"
