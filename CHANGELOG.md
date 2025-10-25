## 2.0.0

### Breaking Changes
* **BREAKING:** Renamed `clearHistory()` to `clearLogs()` - Update your code to use the new method name

### New Features
* Added extension system for custom functionality via `InAppConsoleExtension`
* Added `registerExtension()` and `unregisterExtension()` methods
* Added `InAppConsoleExtensionContext` for extension data access

### Improvements
* UI improvements and bug fixes

## 1.1.0
* Added `InAppConsole.kEnableConsole` flag
* Changed `error` property data type:
```
void logError({
    required String message,
    Error? error,
    StackTrace? stackTrace,
  });
```

to 

```
void logError({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  });
```

## 1.0.1
* Refactor logging method names in README and implementation files to use 'logWarning' for consistency across the codebase.

## 1.0.0
* Add meta data.
  
## 0.0.1

* Initial release.
