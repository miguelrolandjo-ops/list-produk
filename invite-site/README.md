# Invite site

The page behind invite links (`https://<host>/j/?kode=XXXXXXXX`) and the
`assetlinks.json` that lets Android open those links straight in the app.

Published as a GitHub Pages user site; steps in `docs/server-setup.md`,
"Invite links". Files:

- `j/index.html`: shows the code, "Buka aplikasi" and install steps.
  `PACKAGE` at the bottom must equal the app's `applicationId`.
- `.well-known/assetlinks.json`: package name plus the SHA-256 of every key
  that signs the app (debug for testing, Play App Signing for release).
- `.nojekyll`: without it GitHub Pages hides the `.well-known` folder.
