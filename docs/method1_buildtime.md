# Method 1: Build-Time Configuration (Current)

## How it works:
1. You build APK with specific URL: `flutter build apk --dart-define=API_BASE_URL=https://backend.com/api`
2. URL gets compiled into the APK file
3. Phone app uses this hardcoded URL
4. App always connects to the same backend URL

## Pros:
✅ Simple and reliable
✅ Fast - no network calls needed
✅ Works offline
✅ Secure - URL is embedded in app

## Cons:
❌ Need to rebuild APK when backend URL changes
❌ Users need to download new APK
❌ Cannot update URL remotely

## Example:
```dart
// This URL is compiled into the app at build time
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://fixed-backend-url.com/api',
);
```

## When to use:
- Small teams
- Infrequent backend URL changes
- Simple deployment process
- High security requirements