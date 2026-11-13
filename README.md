# Segmented Date Picker Plus

A beautifully animated, compact, and fully customizable segmented date picker for Flutter.

Designed as a direct, drop-in replacement for Flutter's built-in `showDatePicker`, this package features independent Year, Month, and Day selection views while maintaining a tight vertical footprint to prevent keyboard overflow issues.

## ✨ Features

* **Drop-in Replacement:** Uses the exact same parameters and `Future<DateTime?>` return type as Flutter's native `showDatePicker`.
* **Segmented Views:** Independent, smoothly animated panels for Year, Month, and Day.
* **Compact Footprint:** Specifically engineered to look great on modern mobile screens without overflowing when the keyboard opens in text-input mode.
* **Highly Customizable:** Override specific colors using `SegmentedPickerColors` while falling back to your app's native theme.
* **Zero Dependencies:** Built entirely with pure Dart and Flutter. No native platform code or heavy third-party packages.

## 🚀 Getting Started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  segmented_date_picker_plus: ^1.0.0