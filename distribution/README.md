Release notes, read by the release workflow.

- `release-notes/vX.Y.Z.md`: the GitHub release's notes for tag `vX.Y.Z`.
  Without one, the release falls back to notes generated from the commits.
- `whatsnew/whatsnew-<locale>`: the store's "What's New" for the next
  release, one file per App Store Connect locale (`zh-Hant`, `en-US`,
  `ja`). Plain text; overwritten each release.
