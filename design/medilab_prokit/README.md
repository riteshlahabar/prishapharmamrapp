# Medilab ProKit — design reference (not compiled)

Source design kit for the MR and Telecaller apps. **Reference only** — it is
not part of the build and is excluded from `pubspec.yaml` assets.

- `lib/` 123 Dart files (34 screens, 53 components), `images/` 68 assets
- Primary colour `#1157FA`; see `lib/utils/MLColors.dart`, `AppTheme.dart`
- Built on `nb_utils` + **MobX**. This project uses **Riverpod**: take the
  visual language (colour, type scale, card// button styling, spacing,
  imagery), not the state layer.
- Screens worth mining: MLLoginScreen, MLDashboardScreen, MLDoctorDetailScreen,
  MLHospitalDetailScreen, MLAppintmentDetailScreen, MLChatScreen.

Note: the current `lib/core/app_theme.dart` uses teal `#00897B` and claims
"Medilab ProKit" styling — it does not match this kit. Reconcile in Phase 9.
