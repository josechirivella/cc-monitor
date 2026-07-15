#!/usr/bin/env bash

set -euo pipefail

revision="${1:-HEAD}"
valid_tag='^v[0-9]+\.[0-9]+\.[0-9]+$'

tag_at_revision="$(git tag --points-at "$revision" --list 'v*' --sort=-v:refname | perl -ne 'chomp; if (/^v[0-9]+\.[0-9]+\.[0-9]+$/) { print; exit }')"
if [[ -n "$tag_at_revision" ]]; then
    printf '%s\n' "${tag_at_revision#v}"
    exit 0
fi

latest_tag="$(git tag --merged "$revision" --list 'v*' --sort=-v:refname | perl -ne 'chomp; if (/^v[0-9]+\.[0-9]+\.[0-9]+$/) { print; exit }')"
if [[ -z "$latest_tag" ]]; then
    latest_tag="v1.0.0"
fi

if [[ ! "$latest_tag" =~ $valid_tag ]]; then
    printf 'Invalid release tag: %s\n' "$latest_tag" >&2
    exit 1
fi

IFS=. read -r major minor patch <<< "${latest_tag#v}"
printf '%s.%s.%s\n' "$major" "$minor" "$((patch + 1))"
