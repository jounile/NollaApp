# NollaApp — App Store Publishing Plan

Target stores: **Google Play** and **Apple App Store**  
Package / Bundle ID: `net.nolla.app`  
Approach: manual first release, CI/CD automation added after first successful submission

---

## Assets to prepare before writing any code

Nothing can proceed without these. Gather them first.

| Asset | Spec | Notes |
|---|---|---|
| App icon | 1024×1024 PNG, no transparency, no rounded corners | Single source; all sizes generated from this |
| Phone screenshots | 2–5 per platform, 1080×1920 min (Android), 1290×2796 for 6.5" iPhone | Simulator screenshots are acceptable |
| Feature graphic | 1024×500 PNG | Android only |
| Short description | 80 chars max | Reusable across stores |
| Full description | Up to 4000 chars | Community spots map + media sharing |
| App subtitle (iOS) | 30 chars max | e.g. "Community spots & media" |
| Keywords (iOS) | 100 chars, comma-separated | community, spots, map, media, social |
| Privacy policy | Public URL | **Mandatory** — both stores block submission without it; required because app uses location, camera, microphone, and photos |

---

## Phase 1 — Code changes

Do these in order before creating any store accounts.

### 1.1 App icons

The iOS asset catalog (`ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`) lists 20 icon sizes but none of the PNG files exist — the iOS build will fail App Store validation without them. Android has a generic Flutter placeholder. Both need real icons.

Use `flutter_launcher_icons` to generate all required sizes from your single source image.

**`pubspec.yaml`** — add to `dev_dependencies` and add a top-level config block:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#2196F3"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

Place your 1024×1024 icon at `assets/icon/app_icon.png`, then run:

```bash
dart run flutter_launcher_icons
```

### 1.2 Android — change bundle ID

**File:** `android/app/build.gradle`

Change both values on the `namespace` and `applicationId` lines:

```
com.example.nolla_app  →  net.nolla.app
```

> **This is permanent.** Once you upload the first AAB to Play Store, the `applicationId` can never be changed.

### 1.3 Android — release signing

Create a release keystore (run once, back it up permanently — losing it means you can never update the app):

```bash
keytool -genkey -v \
  -keystore ~/nolla-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias nolla-key \
  -dname "CN=Nolla, OU=App, O=Nolla, L=Helsinki, S=Uusimaa, C=FI"
```

**Create `android/key.properties`** (already gitignored by Flutter's default `.gitignore`):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=nolla-key
storeFile=/absolute/path/to/nolla-release.jks
```

**Update `android/app/build.gradle`** — add a `signingConfigs` block and fix the `buildTypes.release` entry:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

// inside android { ... }
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release  // was: signingConfigs.debug
    }
}
```

### 1.4 iOS — change bundle identifier

**File:** `ios/Runner.xcodeproj/project.pbxproj`

Change all 3 occurrences of:
```
PRODUCT_BUNDLE_IDENTIFIER = com.example.nollaApp;
```
to:
```
PRODUCT_BUNDLE_IDENTIFIER = net.nolla.app;
```

### 1.5 iOS — fix Info.plist

**File:** `ios/Runner/Info.plist`

- Change `CFBundleName` value from `nolla_app` → `NollaApp`
- Review `NSLocationAlwaysUsageDescription` — the app uses location only while in use (SpotsScreen), so this key may be removable. Keeping an unused permission declaration is a common rejection reason.

### 1.6 iOS — Development Team (requires Apple Developer account)

After enrolling in the Apple Developer Program, open `ios/Runner.xcworkspace` in Xcode:

1. Select the **Runner** target → **Signing & Capabilities**
2. Set **Team** to your developer account
3. Enable **Automatically manage signing**

Xcode writes the `DEVELOPMENT_TEAM` value and provisioning profile references into the project — this cannot be done by hand-editing the `.pbxproj` file reliably.

### 1.7 Smoke test

```bash
# Android — produces build/app/outputs/bundle/release/app-release.aab
flutter build appbundle --release

# iOS — use Xcode: Product → Archive
```

Confirm the AAB is created and has the correct `applicationId` before proceeding to Phase 2.

---

## Phase 2 — Developer accounts

### Google Play Console

- URL: [play.google.com/console](https://play.google.com/console)
- Cost: **$25 USD one-time**
- Identity verification required; expect **1–3 business days**
- After verification: create developer profile (name, address, phone — visible on store listing)

### Apple Developer Program

- URL: [developer.apple.com/programs](https://developer.apple.com/programs)
- Cost: **$99 USD/year**
- Individual enrollment is straightforward
- Organization enrollment requires a D-U-N-S number; expect **1–5 business days**
- Unlocks App Store Connect and Xcode distribution signing

---

## Phase 3 — Android submission

### 3.1 Create the app in Play Console

- App name: NollaApp
- Package: `net.nolla.app` (set permanently on first upload — do not create the listing until Phase 1 code changes are complete and tested)
- Free or paid (can switch free→paid later, but not paid→free)

### 3.2 Store listing

In **Play Console → Store presence → Main store listing**:

| Field | Content |
|---|---|
| App name | NollaApp |
| Short description | 80 chars |
| Full description | 4000 chars max |
| Screenshots | 2–8 phone screenshots (1080×1920 min); optionally tablet sizes |
| App icon | 512×512 PNG |
| Feature graphic | 1024×500 PNG |
| Privacy policy | Public URL — mandatory |

### 3.3 Content rating

Complete the **IARC questionnaire** (Play Console → Policy → App content → Content ratings). Declare user-generated content (media uploads, community posts). Expect a **Teen** rating or higher.

### 3.4 Data safety section

Mandatory since 2022. Declare:
- **Precise location** (while in use)
- **Photos and videos** (user-uploaded)

Answers must match your Privacy Policy text.

### 3.5 Upload the release AAB

1. Go to **Release → Internal testing → Create new release**
2. Upload `app-release.aab`
3. Write release notes
4. Review and roll out

> Start with **Internal testing** (up to 100 testers by email), promote to Closed testing (alpha), Open testing (beta), then Production. This avoids a buggy v1.0 in permanent production history.

**Review timeline:** 3–7 days for a new app.

---

## Phase 4 — iOS submission

### 4.1 Create the app in App Store Connect

- Platform: iOS
- Name: NollaApp
- Bundle ID: `net.nolla.app` (appears in the dropdown only after Xcode has registered it via automatic signing)
- SKU: `nollaapp-ios` (internal only, never shown to users)

### 4.2 Store listing

In **App Store Connect → App Information and Version Information**:

| Field | Spec |
|---|---|
| App name | 30 chars max |
| Subtitle | 30 chars — e.g. "Community spots & media" |
| Description | 4000 chars |
| Keywords | 100 chars, comma-separated |
| Screenshots | Required: 6.5" iPhone (1290×2796 or 1284×2778); recommended: 5.5" iPhone, 12.9" iPad |
| Privacy policy URL | Mandatory |

### 4.3 App Privacy questionnaire

Feeds the **Privacy Nutrition Label** shown on the store page. Apple cross-checks this against your `Info.plist` permissions.

| Data type | Collection | Linked to user |
|---|---|---|
| Precise location | Yes, while in use | Depends on server-side storage |
| Photos / videos | Yes, user-uploaded | Yes |
| Camera | Capture only, not stored independently | No |
| Microphone | Video recording only | No |

### 4.4 Archive and upload from Xcode

1. Select **Any iOS Device (arm64)** as build target
2. **Product → Archive**
3. In Organizer: select archive → **Distribute App → App Store Connect → Upload**
4. Let Xcode handle signing automatically
5. The build appears in App Store Connect under **TestFlight** within ~30 minutes

### 4.5 Test via TestFlight

1. Add yourself as an internal tester
2. Install TestFlight on a real iPhone
3. Test on a real device — especially GPS and camera (not available in simulator)
4. Fix issues before submitting for App Review

### 4.6 Submit for App Review

In the Version page:

1. Select the uploaded build under **Build**
2. **App Review Information** — provide working login credentials for the reviewer. Use `testaaja1`/`testaaja1` (already used in CI) or create a dedicated reviewer account on nolla.net
3. **Export compliance** — app uses HTTPS only → answer "no" to proprietary encryption question
4. Submit for review

**Review timeline:** 24–48 hours typically; up to 7 days for new apps.

### 4.7 Common rejection reasons to address in advance

| Risk | Mitigation |
|---|---|
| No privacy policy URL | Publish a page before submitting |
| Login-only app | Provide reviewer credentials in App Review Information |
| `NSLocationAlwaysUsageDescription` declared but not used | Remove from Info.plist if not needed |
| Placeholder content or broken features | Test every screen with the demo account |

---

## Phase 5 — Future CI/CD automation

Do this after 2–3 successful manual releases. You need working certificates and provisioning profiles before you can automate signing.

### Current CI state

Both `build-android` and `build-ios` jobs in `.github/workflows/build.yml` are disabled with `if: false`.

**Known issue before re-enabling:** The `build-ios` job contains:
```yaml
run: flutter create --platforms=ios --org com.example --project-name nolla_app .
```
This would reset the bundle identifier back to `com.example.nollaApp`. Update `--org com.example` → `--org net.nolla` before re-enabling the iOS job.

### Android CI path

1. Store keystore as GitHub Actions secrets:
   - `KEYSTORE_BASE64` — `base64 -i nolla-release.jks`
   - `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`
2. Decode keystore and write `key.properties` at build time
3. Change build command: `flutter build apk --debug` → `flutter build appbundle --release`
4. Add `r0adkll/upload-google-play@v1` action with a Google Play service account JSON key
5. Remove `if: false` from the `build-android` job

### iOS CI path

1. Export distribution certificate as `.p12` and provisioning profile from Xcode
2. Store as GitHub Actions secrets
3. Use `apple-actions/import-codesign-certs` and `apple-actions/download-provisioning-profiles`
4. Build: `flutter build ipa --release --export-options-plist=ExportOptions.plist`
5. Upload via `fastlane pilot` or `apple-actions/upload-testflight-build`
6. Remove `if: false` from the `build-ios` job (and fix the `--org` flag first)

---

## Pre-submission checklist

**Assets:**
- [ ] 1024×1024 app icon PNG ready
- [ ] Store description text written (short + long)
- [ ] Privacy policy published at a public URL
- [ ] Screenshots captured (2–5, simulator is fine)
- [ ] Feature graphic 1024×500 (Android)

**Code changes:**
- [ ] `flutter_launcher_icons` added to `pubspec.yaml` and icons generated
- [ ] `applicationId` and `namespace` changed to `net.nolla.app` in `android/app/build.gradle`
- [ ] Release keystore created and backed up securely
- [ ] `android/key.properties` configured
- [ ] Release `signingConfig` wired in `android/app/build.gradle`
- [ ] All 3 `PRODUCT_BUNDLE_IDENTIFIER` occurrences changed to `net.nolla.app` in `ios/Runner.xcodeproj/project.pbxproj`
- [ ] `CFBundleName` fixed in `ios/Runner/Info.plist`
- [ ] `NSLocationAlwaysUsageDescription` reviewed / removed if not needed
- [ ] Development Team set in Xcode (after Apple Developer account)
- [ ] Release builds smoke-tested locally

**Accounts:**
- [ ] Google Play Console ($25 one-time, 1–3 days verification)
- [ ] Apple Developer Program ($99/year, 1–5 days for organizations)

**Submissions:**
- [ ] Android — Internal testing → Closed testing → Production
- [ ] iOS — TestFlight → App Review → Release
