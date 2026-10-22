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
sha_of() {
    local asset="TAT-CCU-$version-windows-$1.zip" sha
    sha="$(awk -v f="$asset" '$2 == f || $2 == "*" f { print $1 }' "$sums")"
    [[ ${#sha} -eq 64 ]] || { echo "no SHA-256 for $asset in $sums" >&2; exit 1; }
    echo "$sha"
}
sha_x64="$(sha_of x64)"
sha_arm64="$(sha_of arm64)"

template="$(cat <<'JSON'
{
    "version": "@VERSION@",
    "description": "Timetable, eCourse2 and campus services of National Chung Cheng University",
    "homepage": "https://github.com/KoukeNeko/TAT-CCU",
    "architecture": {
        "64bit": {
            "url": "https://github.com/KoukeNeko/TAT-CCU/releases/download/v@VERSION@/TAT-CCU-@VERSION@-windows-x64.zip",
            "hash": "@SHA_X64@"
        },
        "arm64": {
            "url": "https://github.com/KoukeNeko/TAT-CCU/releases/download/v@VERSION@/TAT-CCU-@VERSION@-windows-arm64.zip",
            "hash": "@SHA_ARM64@"
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
            },
            "arm64": {
                "url": "https://github.com/KoukeNeko/TAT-CCU/releases/download/v$version/TAT-CCU-$version-windows-arm64.zip"
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
template="${template//@SHA_X64@/$sha_x64}"
printf '%s\n' "${template//@SHA_ARM64@/$sha_arm64}"
