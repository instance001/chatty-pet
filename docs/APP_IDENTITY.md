# App Identity

## Current Product Identity

- Product name: `Chatty Pet`
- Public source repo name: `chatty-pet`
- Internal Flutter package name: `chatty_pet_mobile`
- License: `AGPLv3`
- Current app description: reducer-owned pet terrarium built with Flutter
- Release steward: `Fractal Media Infrastructure (FMI)`
- Engine doctrine attribution: `RD Engine`
- Planned store format: `Android App Bundle (.aab)`

The public repository name and the internal Flutter package name do not need to match. In this project:

- `chatty-pet` is the public source release name
- `chatty_pet_mobile` is the internal Flutter package identifier
- `io.instance001.chattypet` is the Android application ID used for Play Store release

## Safe Defaults Already Applied

- Android launcher label uses `Chatty Pet`
- Windows window title uses `Chatty Pet`
- Windows file metadata no longer uses `com.example`
- In-app splash and About surface now display FMI and RD Engine attribution
- Android launch screen now shows FMI branding before Flutter paints

## Android Package ID

The Android application ID is now set to:

- `io.instance001.chattypet`

This ID should be treated as stable for Play Store purposes unless there is a strong reason to change it before first release.

## Release Notes

- Android package namespace and application ID are aligned to the org-owned `instance001` lane.
- FMI is the publishing/steward identity for the Play release.
- RD Engine should be credited as the reducer doctrine and deterministic runtime design spine behind Chatty-Pet.
