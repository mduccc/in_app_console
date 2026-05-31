# iac_statistics_ext

Log analytics extension for [in_app_console](https://pub.dev/packages/in_app_console).

## Features

- **Overview** — compact total / info / warning / error counts
- **Log Timeline** — adaptive bar chart showing activity over time (auto-scales from seconds to days)
- **Top Repeated Issues** — groups duplicate errors and warnings by message similarity; counts across sessions
- **Module Health** — ranks modules by weighted error ratio, color-coded green / orange / red
- **Persistent history** — logs are saved to device storage and survive app restarts (capped at 500 entries)

## Screenshot

<img src="https://raw.githubusercontent.com/mduccc/in_app_console/fd305f4687f6ca2033e940e2359556061eaed384/packages/iac_statistics_ext/screenshots/screenshot.png" width=35%>

## Grouping algorithms

The "Top Repeated Issues" section supports two algorithms, switchable via the segmented control in the UI. **TF-IDF is the default.**

| | TF-IDF | Pattern |
|---|---|---|
| How it works | TF-IDF vectors + cosine similarity | Normalizes hex addresses and numeric IDs, then exact-matches |
| Best for | Natural-language variation | Structured / templated log messages |
| Speed | Slower on large histories | Fast |

## Usage

```dart
InAppConsole.instance.registerExtension(LogStatisticsExtension());
```

## Clear history

Tap the trash icon in the extension header to clear persisted log history.
