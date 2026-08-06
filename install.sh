#!/usr/bin/env bash
set -euo pipefail

# Managed-fork installer. This script only installs the binary bundled beside
# it in a reviewed release archive. It intentionally contains no network
# client, release URL, floating version lookup, or download override.

main() {
    local script_dir install_dir bundled_binary skip_config candidate_version installed installed_version
    local -a install_args
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    install_dir="${HOME:?HOME must be set}/.local/bin"
    bundled_binary="$script_dir/codebase-memory-mcp"
    skip_config=false

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --dir=*) install_dir="${1#--dir=}" ;;
            --dir)
                [ "$#" -ge 2 ] || { echo "error: --dir requires a path" >&2; exit 2; }
                install_dir="$2"
                shift
                ;;
            --skip-config) skip_config=true ;;
            --standard|--ui)
                # The archive already determines the bundled variant.
                ;;
            --help|-h)
                echo "Usage: install.sh [--dir PATH] [--skip-config]"
                echo "Installs only the codebase-memory-mcp binary bundled beside this script."
                exit 0
                ;;
            *) echo "error: unknown installer option: $1" >&2; exit 2 ;;
        esac
        shift
    done

    if [ ! -f "$bundled_binary" ] || [ -L "$bundled_binary" ]; then
        echo "error: reviewed release bundle is incomplete: $bundled_binary is missing or unsafe" >&2
        echo "This managed installer never downloads a replacement." >&2
        exit 1
    fi

    chmod 755 "$bundled_binary"
    if ! candidate_version=$("$bundled_binary" --version 2>&1); then
        echo "error: bundled binary failed to run" >&2
        exit 1
    fi
    echo "Verified bundled candidate: $candidate_version"

    install_args=(-y --force "--dir=$install_dir")
    if [ "$skip_config" = true ]; then
        install_args+=(--skip-config)
    fi
    "$bundled_binary" install "${install_args[@]}"

    installed="$install_dir/codebase-memory-mcp"
    if ! installed_version=$("$installed" --version 2>&1); then
        echo "error: installed binary failed to run" >&2
        exit 1
    fi
    echo "Installed: $installed_version"
    echo "Updates are managed centrally; this build cannot self-update or fetch upstream releases."
}

main "$@"
