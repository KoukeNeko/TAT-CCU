#!/usr/bin/env bash
# Renders the Homebrew cask for a published release.
#
#   scripts/render-homebrew-cask.sh v0.2.0 SHA256SUMS > tat-ccu.rb
set -euo pipefail

tag="$1"
sums="$2"
version="${tag#v}"
asset="TAT-CCU-$version-macos.zip"
sha="$(awk -v f="$asset" '$2 == f || $2 == "*" f { print $1 }' "$sums")"
[[ ${#sha} -eq 64 ]] || { echo "no SHA-256 for $asset in $sums" >&2; exit 1; }

cat <<CASK
cask "tat-ccu" do
  version "$version"
  sha256 "$sha"

  url "https://github.com/KoukeNeko/TAT-CCU/releases/download/v#{version}/TAT-CCU-#{version}-macos.zip"
  name "TAT CCU"
  desc "Timetable, eCourse2 and campus services of National Chung Cheng University"
  homepage "https://github.com/KoukeNeko/TAT-CCU"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :monterey

  app "TAT CCU.app"

  uninstall quit: "io.github.koukeneko.tatCcu"

  zap trash: [
    "~/Library/Application Support/io.github.koukeneko.tatCcu",
    "~/Library/Containers/io.github.koukeneko.tatCcu",
  ]
end
CASK
