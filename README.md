# Sift

Sift automatically organizes and tags your screenshots using on-device OCR
(Google ML Kit) and AI-powered classification (Gemini). Package:
`com.neurodevlabs.sift`.

## Getting started

```
flutter pub get
```

### Secrets

Sift takes no secrets from source control or a bundled `.env` — everything
is supplied at build time via `--dart-define-from-file`, so nothing ships
inside the compiled app as a readable file.

```
cp dart_define.example.json dart_define.json   # fill in real values, gitignored
flutter run --dart-define-from-file=dart_define.json
```

See `dart_define.example.json` for the full list of keys (Gemini API key,
RevenueCat API keys, AdMob rewarded ad unit ID).

### Release signing

```
cp android/key.properties.example android/key.properties   # gitignored
```

Fill in the real keystore path/passwords (see `android/key.properties.example`
for the format). Without this file, release builds silently fall back to
debug signing so local `flutter run --release` still works.

### Building for Play Store

```
flutter build appbundle --release --dart-define-from-file=dart_define.json
```

For the full process — Play Console app setup, RevenueCat/Play Billing
integration, and everything that can go wrong along the way (signing
mismatches, Firebase Studio disk limits, keystore pitfalls) — see
[`docs/GOOGLE_PLAY_PLAYBOOK.md`](docs/GOOGLE_PLAY_PLAYBOOK.md).
