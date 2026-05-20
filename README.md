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

### Useful commands

```bash
flutter devices                            # list connected devices
flutter emulators                          # list available emulators
flutter emulators --launch <emulator-id>   # launch a specific emulator
```
