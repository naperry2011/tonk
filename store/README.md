# Tonk store kit

Everything needed to ship the Android app to Google Play (and later iOS from the Mac).

## Files here

| File | What it's for |
|---|---|
| `icon-512.png` | Play Console app icon (512x512) |
| `feature-graphic.png` | Play Console feature graphic (1024x500, no alpha) |
| `screenshots/*.png` | Phone screenshots (1080x1920, no alpha). `raw/` holds the original captures |
| `privacy-policy.html` | Privacy policy page to host on your website. Replace `[CONTACT EMAIL]` first |

Regenerate the icon, store art, and screenshot conversions from `app/`:

```bash
flutter test tool/icon/render_icon_test.dart && dart run flutter_launcher_icons
flutter test tool/store/render_store_assets_test.dart
dart run flutter_native_splash:create
```

## 1. Create the upload key (one time, you do this)

The key signs every release. Keep the `.jks` file and both passwords somewhere safe (a password manager); losing them means you can't update the app without going through Google's key reset.

From `app/android/`:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `app/android/key.properties` (already gitignored, never commit it):

```
storePassword=<the keystore password>
keyPassword=<the key password>
keyAlias=upload
storeFile=../upload-keystore.jks
```

Without `key.properties`, release builds fall back to the debug key: they run, but Play rejects them.

## 2. Build the release bundle

From `app/`:

```bash
flutter build appbundle --release
```

Output: `app/build/app/outputs/bundle/release/app-release.aab`. Bump `version:` in `app/pubspec.yaml` (e.g. `1.0.1+2`) for every upload; the number after `+` must always increase.

## 3. Play Console setup

- **App ID:** `com.tonk.tonk` (permanent after the first upload).
- **Testing before production:** per several third-party guides, personal developer accounts created after November 13, 2023 must run a closed test with at least 12 opted-in testers for 14 continuous days before production unlocks. Organization accounts are exempt. Confirm the current rule in Play Console.
- **Privacy policy URL:** the hosted `privacy-policy.html`.
- **Data safety:** the app collects and shares no user data. It has no network access (the release manifest requests no internet permission). Answer "No" to data collection and sharing.
- **Ads:** No ads.
- **Content rating (IARC questionnaire):** answer honestly that the app contains simulated gambling (betting play chips with no real-world value, no real-money gambling, no cash-out). Also mild language: none (talk is kept clean).
- **Target audience:** 18+. Do not opt into Designed for Families.
- **Category:** Games > Card.

## 4. App Store (on the Mac, later)

- Needs an Apple Developer account and Xcode. Open `app/ios/Runner.xcworkspace`, set the team, and archive.
- **Age rating:** Apple's questionnaire maps frequent simulated gambling to **18+** (and R18+ in Australia even when infrequent). Tonk bets every round, so expect 18+.
- Korea: apps with frequent simulated gambling need a Rating Classification Number to be listed there.
- Icons and launch screen are already generated in `app/ios/Runner/Assets.xcassets`.
- Untested on iOS so far: check portrait lock, `UIRequiresFullScreen`, sounds, and haptics on a device.

## Listing copy (draft)

**App name:** Tonk

**Short description (80 characters max):**
Knock, spread, and talk trash in the classic card game Tonk. Play vs AI.

**Full description:**

Pull up a chair. Tonk is the fast, five-card rummy game from cookouts, kitchens, and card nights, now in your pocket.

Lay spreads, hit your opponents' spreads, and drop when you think you're holding the lowest hand. Guess wrong and you get caught. Go out with an empty hand and it's a TONK.

- Play 1 to 3 opponents with real personality: Uncle Ray never stops talking, Aunt Dot never folds, and Lil Tre knocks on anything.
- Table talk that reacts to every knock, catch, and tonk.
- Ante up, raise, call, or fold with a chip bankroll that carries between matches.
- Daily challenge: the same deal for everyone, every day. Keep your streak alive.
- Level up to unlock new tables, card backs, and tougher opponents.
- Earn achievements and track your stats.
- Plays offline. No ads, no accounts, no data collected.

Chips are play money with no real-world value. Tonk does not offer real-money gambling.
