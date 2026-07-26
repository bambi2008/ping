# Ping

Ping is a private, offline-first subscription tracker built with Flutter.

## What works

- Add, edit, pause, resume, cancel, and remove subscriptions
- Weekly, monthly, and yearly renewal dates with calendar-safe roll-forward
- Local persistence across app restarts
- Monthly and yearly totals with multi-currency display
- Category spending breakdown
- Optional renewal reminders
- CSV export and one-tap local data deletion
- Light and dark appearance based on the device setting

Ping 1.0 does not connect to a bank, create an online account, sync to a
cloud service, or sell premium features. Those capabilities must not be
advertised until their backend, consent, billing, and deletion flows are
implemented and reviewed.

## Run locally

```sh
flutter pub get
flutter run
```

## Quality checks

```sh
flutter analyze
flutter test
flutter build apk --debug
```

## Android release signing

Copy `android/key.properties.example` to `android/key.properties`, set the
upload-keystore values, and keep the real file and keystore out of Git. Release
builds no longer fall back to the debug signing key.

## Data and privacy

Subscription records and preferences are stored locally with
`SharedPreferences`. Notification permission is requested only when reminders
are enabled. CSV data leaves the app only after the user chooses a share
destination.

See [docs/privacy.md](docs/privacy.md) for the current privacy disclosure.

## Scope notes

Static exchange rates are used only for display estimates. They are not
financial advice and are not presented as live market rates.

## License

No license has been declared yet. Add one before inviting external
contributions or redistributing the project.
