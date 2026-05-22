# NollaApp
Nolla.net mobile application

## Testing

### Unit & widget tests (no device required)

```bash
flutter test
```

### On an Android Emulator

1. Start an emulator via Android Studio (Device Manager) or:
   ```bash
   flutter emulators --launch <emulator-id>
   ```
2. Run the app:
   ```bash
   flutter run
   ```

### On a physical Android device

1. Enable **Developer Options → USB Debugging** on the device
2. Connect via USB, then:
   ```bash
   flutter devices          # confirm device is listed
   flutter run -d <device-id>
   ```

You can also install the debug APK directly:
```bash
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### On the iOS Simulator (macOS only)

```bash
open -a Simulator          # launch the Simulator app
flutter run                # Flutter picks the booted simulator
```

### On a physical iPhone (macOS only)

1. Open Xcode → Devices and Simulators and trust the device
2. Run:
   ```bash
   flutter run -d <device-id>
   ```

### On a mobile browser (GitHub Pages)

Every push to `main` automatically builds the web version and deploys it to GitHub Pages. No installation needed — open the URL in any mobile browser:

```
https://jounile.github.io/NollaApp/
```

Works on both Android (Chrome, Firefox) and iPhone (Safari, Chrome). The page is the same Flutter app compiled to WebAssembly/JavaScript.

**First-time setup (repo owner only):**
Go to **Settings → Pages → Source** and select **GitHub Actions**.
After the first successful CI run the URL becomes live.

### Useful commands

```bash
flutter devices                            # list connected devices
flutter emulators                          # list available emulators
flutter emulators --launch <emulator-id>   # launch a specific emulator
```

### Build web locally

```bash
flutter build web --release --base-href /NollaApp/
# Output is in build/web/ — open build/web/index.html in a browser
```
