# Backend Configuration Guide

## Quick Setup

The Flutter app automatically uses the production backend URL by default. You don't need to rebuild the app when the backend URL changes!

## Current Configuration

**Production Backend:** `https://redstonebackend-qzyfnbktn-snaps-projects-656f28bb.vercel.app/api`

## How to Change Backend URL

### Method 1: Environment Variable (Recommended)
You can override the backend URL at build time without changing code:

```bash
# For production
flutter build apk --dart-define=API_BASE_URL=https://redstonebackend-qzyfnbktn-snaps-projects-656f28bb.vercel.app/api

# For local development
flutter build apk --dart-define=API_BASE_URL=http://localhost:3000/api

# For testing
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000/api
```

### Method 2: Update Default URL
Edit `lib/config/config.dart` and change the `defaultValue`:

```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'YOUR_NEW_BACKEND_URL_HERE/api',
);
```

## Building Different Versions

### Development Build (Local Backend)
```bash
flutter build apk --dart-define=API_BASE_URL=http://localhost:3000/api --target-platform android-arm64 --split-per-abi
```

### Production Build (Vercel Backend)
```bash
flutter build apk --dart-define=API_BASE_URL=https://redstonebackend-qzyfnbktn-snaps-projects-656f28bb.vercel.app/api --target-platform android-arm64 --split-per-abi
```

### Testing Build (Custom URL)
```bash
flutter build apk --dart-define=API_BASE_URL=https://your-custom-backend.com/api --target-platform android-arm64 --split-per-abi
```

## Quick Commands

### Check Current Backend URL
```bash
cd redstone_flutter_app/frontend
flutter run --dart-define=API_BASE_URL=CHECK
```

### Update to Latest Vercel Deployment
1. Get the latest deployment URL from Vercel dashboard
2. Update the default value in `lib/config/config.dart`
3. Rebuild: `flutter build apk`

## Network Configuration

### Local Development
- Backend: `http://localhost:3000/api`
- Make sure your local backend is running

### Production
- Backend: `https://redstonebackend-qzyfnbktn-snaps-projects-656f28bb.vercel.app/api`
- Automatically uses HTTPS and production database

### Android Network Security
If using HTTP (localhost), ensure your Android app allows cleartext traffic by checking `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:usesCleartextTraffic="true"
    ... >
```

## Troubleshooting

### Connection Issues
1. Check if backend URL is reachable
2. Verify network permissions in AndroidManifest.xml
3. Test API endpoints manually

### CORS Issues
- Production backend already configured for CORS
- Local development may need CORS setup

### Build Issues
1. Clean build: `flutter clean && flutter pub get`
2. Rebuild: `flutter build apk`
3. Check for any syntax errors in config.dart