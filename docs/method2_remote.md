# Method 2: Remote Configuration (Dynamic)

## How it works:
1. App starts up
2. App fetches configuration from a stable URL (GitHub, Firebase, etc.)
3. App gets latest backend URL from remote config
4. App caches URL locally for offline use
5. App connects to backend using dynamic URL

## Implementation:
```dart
// App fetches this from remote source
{
  "backend_url": "https://latest-backend.vercel.app/api",
  "updated_at": "2025-10-06T00:30:00Z"
}
```

## Pros:
✅ No need to rebuild APK when backend changes
✅ Can update URL remotely
✅ Users don't need to download new APK
✅ Supports A/B testing
✅ Can enable maintenance mode

## Cons:
❌ Requires internet connection on first launch
❌ More complex implementation
❌ Potential security concerns
❌ Remote config service dependency

## Flow:
1. App launches
2. App checks: "Do I have cached backend URL?"
3. If yes and recent (< 1 hour): Use cached URL
4. If no or old: Fetch from remote config
5. Cache new URL and use it
6. Fallback to hardcoded URL if remote fails

## When to use:
- Frequent backend URL changes
- Large user base
- Need remote control over app behavior
- A/B testing requirements