Release notes, read by the release workflow.

- `release-notes/vX.Y.Z.md`: the GitHub release's notes for tag `vX.Y.Z`.
  Without one, the release falls back to notes generated from the commits.
- `whatsnew/whatsnew-<locale>`: Google Play's "What's New" for the next
  release, one file per Play locale (`zh-TW`, `en-US`, `ja-JP`), uploaded
  with the bundle. Plain text, at most 500 characters; overwritten each
  release.
