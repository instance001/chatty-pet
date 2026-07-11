# Release Readiness

## What Is Already In Place

- Android package ID is set
- branding assets are present
- Android App Bundle generation works
- in-app `Help`, `Privacy`, and `About` surfaces exist
- deterministic gameplay loop is implemented
- automated analysis and tests pass

## What Still Needs Review Before Public Release

- real upload keystore configured locally
- intentional versioning and release numbering
- manual Android usability sweep as a first-time player
- confirmation that privacy wording matches the intended public policy page
- final review of text polish, accessibility, and support clarity

## Release Decision Rule

The app should not be treated as store-ready just because the `.aab` builds. It should only be treated as release-ready once a first-time player can understand the app, use the controls, and find support/privacy information without developer context.
