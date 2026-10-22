Release notes, read by the release workflow.

- `release-notes/vX.Y.Z.md`: the GitHub release's notes for tag `vX.Y.Z`.
  Without one, the release falls back to notes generated from the commits.
- `whatsnew/whatsnew-<locale>`: the "What's New" for the next release, one
  file per Play locale (`zh-TW`, `en-US`, `ja-JP`), uploaded with the bundle
  to Google Play and used for the App Store version and TestFlight's "What
  to Test". Plain text, at most 500 characters; overwritten each release.

The App Store listing text is in `fastlane/metadata/ios`, set on each
release's version by `scripts/app-store-release.py`.
