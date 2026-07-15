#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 4 ]]; then
    printf 'Usage: %s VERSION SHA256 REPOSITORY OUTPUT_PATH\n' "$0" >&2
    exit 1
fi

version="$1"
sha256="$2"
repository="$3"
output_path="$4"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf 'Invalid version: %s\n' "$version" >&2
    exit 1
fi

if [[ ! "$sha256" =~ ^[a-fA-F0-9]{64}$ ]]; then
    printf 'Invalid SHA-256: %s\n' "$sha256" >&2
    exit 1
fi

if [[ ! "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    printf 'Invalid GitHub repository: %s\n' "$repository" >&2
    exit 1
fi

sed \
    -e "s|{{VERSION}}|$version|g" \
    -e "s|{{SHA256}}|$sha256|g" \
    -e "s|{{REPOSITORY}}|$repository|g" \
    "$(dirname "$0")/cc-monitor.rb.tmpl" > "$output_path"
