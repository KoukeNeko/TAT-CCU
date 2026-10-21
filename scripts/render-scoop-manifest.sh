#!/usr/bin/env bash
# Renders the Scoop manifest for a published release.
#
#   scripts/render-scoop-manifest.sh v0.2.0 SHA256SUMS-windows > tat-ccu.json
#
# The Windows build is a folder (the app and its DLLs), released as a zip that
# Scoop unpacks into the app's directory; the shortcut opens tat_ccu.exe.
set -euo pipefail

tag="$1"
sums="$2"
version="${tag#v}"
asset="TAT-CCU-$version-windows-x64.zip"
sha="$(awk -v f="$asset" '$2 == f || $2 == "*" f { print $1 }' "$sums")"
[[ ${#sha} -eq 64 ]] || { echo "no SHA-256 for $asset in $sums" >&2; exit 1; }

template="$(cat <<'JSON'
{
    "version": "@VERSION@",
    "description": "Timetable, eCourse2 and campus services of National Chung Cheng University",
    "homepage": "https://github.com/KoukeNeko/TAT-CCU",
    "architecture": {
        "64bit": {
            "url": "https://github.com/KoukeNeko/TAT-CCU/releases/download/v@VERSION@/TAT-CCU-@VERSION@-windows-x64.zip",
            "hash": "@SHA@"
        }
    },
    "shortcuts": [
        [
            "tat_ccu.exe",
            "TAT CCU"
        ]
    ],
    "checkver": {
        "github": "https://github.com/KoukeNeko/TAT-CCU"
    },
    "autoupdate": {
        "architecture": {
            "64bit": {
                "url": "https://github.com/KoukeNeko/TAT-CCU/releases/download/v$version/TAT-CCU-$version-windows-x64.zip"
            }
        },
        "hash": {
            "url": "https://github.com/KoukeNeko/TAT-CCU/releases/download/v$version/SHA256SUMS-windows"
        }
    }
}
JSON
)"
template="${template//@VERSION@/$version}"
printf '%s\n' "${template//@SHA@/$sha}"
