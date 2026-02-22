Check that all package versions are consistent across the repository. Follow these steps:

## 1. Main package: `in_app_console`

- Read `pubspec.yaml` → extract the `version` field (call it `MAIN_VERSION`).
- Read `README.md` → find the line that shows the dependency, e.g. `in_app_console: ^X.Y.Z`. The `X.Y.Z` part must equal `MAIN_VERSION`.
- Report any mismatch.

## 2. Extension packages (every directory under `packages/`)

For each extension package, perform all three checks and compare against the `version` field in its own `pubspec.yaml` (call it `PKG_VERSION`):

### a) CHANGELOG.md — latest version entry

- Read `packages/<ext>/CHANGELOG.md`.
- The first heading in the file (e.g. `## 2.0.0`) is the latest released version.
- It must equal `PKG_VERSION`.

### b) Dart source — `String get version` override

- Find the `.dart` file inside `packages/<ext>/lib/` that contains `String get version`.
- Extract the string literal returned (e.g. `'1.0.1'`).
- It must equal `PKG_VERSION`.

### c) Report

For each extension, print a summary table:

| Source | Value | Status |
|---|---|---|
| pubspec.yaml | `PKG_VERSION` | — |
| CHANGELOG.md | `<first heading>` | ✅ / ❌ |
| `String get version` | `<dart value>` | ✅ / ❌ |

At the end, print an overall result:
- **All consistent** — if every check passed.
- **Inconsistencies found** — list every mismatch with file path and found value.
