# Shared by every script here: load config, fail early with a useful message.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
[ -f "$HERE/config.sh" ] || {
    echo "No config.sh. Run:  cp config.example.sh config.sh && \$EDITOR config.sh" >&2
    exit 1
}
# shellcheck disable=SC1091
. "$HERE/config.sh"
mkdir -p "$WORK_DIR"
need() { command -v "$1" >/dev/null || { echo "missing required tool: $1" >&2; exit 1; }; }
