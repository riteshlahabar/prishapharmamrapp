# mr_app — Prisha Pharma MR

Stack: Dart/Flutter · Riverpod · go_router · Dio · `com.prishapharma.mr`

## Commands
- `flutter pub get`
- `flutter analyze` — must report no issues
- `flutter test`
- `flutter run --dart-define=API_BASE_URL=<base>/api/v1`

## Layout
```
lib/core/      api (client, envelope, failures, tokens), location, theme, router
lib/features/  auth · attendance · visits · persons · messages · profile · shell
test/          unit, widget, and golden screenshots; fixtures/ are real API captures
design/        Medilab ProKit reference, excluded from analysis
```

## Conventions
- Material comes from `package:material_ui/material_ui.dart`. The SDK's
  `package:flutter/material.dart` is deprecated after Flutter 3.47 and its
  types are *not* interchangeable with material_ui's — mixing them gives
  "TextTheme can't be assigned to TextTheme".
- One feature = `domain/` + `data/` + `state/` + `ui/`. UI never touches Dio.
- Every API failure is an `ApiFailure` with a stable `reason`; never branch
  on an HTTP status or a message string.
- Backend contract: `docs/api/v1-common.md` and `v1-mr.md` in the CRM repo.
