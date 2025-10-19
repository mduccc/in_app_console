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
