# Android Release Signing

## Current State

The project is wired for conditional release signing:

- if `android/key.properties` exists, release builds use that keystore
- if it does not exist, release builds fall back to debug signing for local testing only

This means local `appbundle` validation can work without baking secrets into the repo, but Play Store uploads should use a real upload keystore.

## Files

- template: [android/key.properties.example](../android/key.properties.example)
- real local file: `android/key.properties` (gitignored)
- keystore file location: referenced by `storeFile` in `android/key.properties`

## `key.properties` Format

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=upload
storeFile=upload-keystore.jks
```

`storeFile` is relative to the `android/` folder unless you use an absolute path.

## Recommended Layout

Keep the keystore inside the local `android/` folder and out of Git:

```text
android/
  key.properties
  upload-keystore.jks
```

Both are ignored by `.gitignore`.

## Create A Keystore

From the repo root, run:

```powershell
keytool -genkeypair -v `
  -keystore android\upload-keystore.jks `
  -alias upload `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000
```

Then create `android/key.properties` from the example file and fill in the real passwords.

## Build Commands

Debug APK:

```powershell
flutter build apk --debug
```

Release app bundle:

```powershell
flutter build appbundle
```

## Important Note

Do not lose the upload keystore or its passwords. For Play Store updates, continuity of the signing setup matters.
