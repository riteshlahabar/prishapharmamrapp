# Prisha Pharma — MR app

The medical representative's app: presence and visits, both geo-stamped, plus
an inbox of notes from the telecaller team.

Flutter · Riverpod · go_router · Dio. Backend contract lives in the CRM repo
under `docs/api/` — **`v1-common.md` first**, then `v1-mr.md`.

## Run it

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

`10.0.2.2` is the host machine from the Android emulator; the default is that
same value, so a local CRM on `php artisan serve` works with no flag. For a
real device, pass your machine's LAN address or the deployed host.

```bash
flutter analyze                                   # must be clean
flutter test                                      # 40 checks
flutter test test/screenshot_test.dart --update-goldens   # re-render the PNGs
```

## Layout

```
lib/
  core/        api client, envelope, failures, token store, location, theme
  features/    auth · attendance · visits · persons · messages · profile · shell
```

Each feature is `domain/` (models), `data/` (repository), `state/` (Riverpod),
`ui/` (screens). A screen never sees Dio, an HTTP status, or an exception type.

## What matters here

- **One envelope.** Every response is `{success, message, data, meta}`, and
  every failure carries a stable `errors.reason`. `ApiClient` decodes it once
  and throws `ApiFailure`; screens switch on `reason`, never on prose.
- **The server owns the rules.** `can_check_in` / `can_check_out` come from
  the API, so the buttons cannot be talked into a double punch by a device
  with a wrong clock. Times are never sent — the server stamps them.
- **A token dies with its account.** `account_inactive` and `role_changed`
  clear the token and drop to login; a plain `forbidden` does not.
- **Geo travels with its timestamp.** `location_fetched_at` says when the
  device read the GPS, which the server keeps beside its own receive time, so
  a visit filed late is visibly late.

## Design

`design/medilab_prokit/` is the Medilab ProKit reference, kept for its look
only: palette (`#1157FA`), spacing, card shapes. It is built on nb_utils and
MobX and is excluded from analysis — we harvest the design, not the state
layer.

`test/golden/*.png` are rendered screens for human review. They substitute
Roboto for Poppins, because google_fonts cannot fetch a typeface offline in a
test; colour, spacing and layout are the app's own.

Package id: `com.prishapharma.mr`.

## Before release

- The bearer token sits in `SharedPreferences`; move it to the
  Keychain/Keystore (`flutter_secure_storage`).
- Fonts are fetched at runtime by google_fonts. Bundle Poppins so a rep on a
  poor connection does not get a fallback face on first launch.
