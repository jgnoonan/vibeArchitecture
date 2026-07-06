# Mobile Security Basics

> This guide explains mobile-specific security for native and cross-platform apps. Read it when building iOS, Android, React Native, or Flutter projects, or when the user asks why tokens can't live in UserDefaults.

For the compact rules, see `rules/mobile.md`.

---

## Why Mobile Is Different

A web app runs in a browser with some built-in protections. A mobile app runs on a device the user controls — and that can be lost, jailbroken, or running a modified build. Anything in your app binary or local storage is more exposed than server-side secrets.

---

## Where to Store Sensitive Data

| Storage | Safe for secrets? | Notes |
|---------|-------------------|-------|
| iOS Keychain | Yes | Encrypted, OS-managed |
| Android Keystore / EncryptedSharedPreferences | Yes | Use AndroidX Security library |
| UserDefaults / SharedPreferences (plain) | No | Readable on rooted/jailbroken devices |
| AsyncStorage (React Native) | No | Not encrypted by default |
| App bundle / source code | Never | Extractable from the APK/IPA |

**Rule of thumb:** If losing the phone would expose it, don't store it on the phone unencrypted.

---

## API Keys in Mobile Apps

Backend API keys with billing or write access must never ship in the mobile app. Anyone can decompile an APK or inspect a JavaScript bundle.

**Do this instead:** Route sensitive calls through your backend. The app authenticates the user; your server holds the secret key.

If you must call a third-party SDK that needs a client key, use a restricted key (read-only, domain-bound, rate-limited) and accept that it is not truly secret.

---

## Certificate Pinning

Pinning prevents man-in-the-middle attacks by verifying the server's certificate matches a known good one. It also means when your certificate expires or you change CDNs, the app stops working until users update.

Pin only if you have a documented rotation process and a fallback (e.g., pin backup keys, remote config to disable pinning in emergencies).

---

## Push Notifications and Background

Push tokens identify a device. Treat them as sensitive — don't log them in plain text or send them to analytics without need.

Background fetch and silent push can wake your app with stale credentials. Re-validate sessions when handling background work.

---

## Platform Privacy Requirements

**iOS:** Privacy Nutrition Labels, App Tracking Transparency for cross-app tracking, Sign in with Apple if you offer other social logins for account creation.

**Android:** Data Safety section, runtime permissions, scoped storage for file access.

Both platforms reject or penalize apps that over-collect or misdeclare data use.

---

## App Store Review: Rejections That Actually Bite

Getting your code working is only half the battle. Apple and Google review every app, and they reject or pull apps for privacy and policy reasons an AI assistant won't warn you about until it's too late. These are the high-frequency 2026 triggers. Check every one before you submit.

**In-app account deletion (iOS, required).** If your app lets users create an account, Apple requires a way to delete that account *from inside the app* — not "email us to close your account." A settings screen link that starts the deletion is enough. This is one of the most common rejections for apps with sign-up. (Android has similar expectations and a required "delete account" link in your Play listing.)

**iOS Privacy Manifest (`PrivacyInfo.xcprivacy`).** Your app — and every third-party SDK you bundle — must ship a privacy manifest declaring what data it collects and *why*. On top of that, certain common APIs are now "required reason" APIs (things like reading file timestamps, disk space, or user defaults): you must declare an approved reason code for using them. Missing or incomplete manifests now cause rejections at submission. Ask your AI to check whether your SDKs already provide their own manifests — most popular ones do, but you still need yours.

**Privacy labels must match reality.** Apple's App Privacy "nutrition label" and Google Play's Data Safety section are forms *you* fill out describing what you collect. Reviewers (and automated tooling) compare your declarations against what the app actually does. If you say "no data collected" but your analytics SDK phones home with device IDs, that mismatch gets flagged. Fill these out honestly, and re-check them every time you add an SDK. See `rules/mobile.md` ("App Store and Privacy").

**Tracking requires the ATT prompt (iOS).** If your app tracks users across other companies' apps and websites — anything using the IDFA advertising identifier, most ad and attribution SDKs — you must show Apple's App Tracking Transparency prompt and get permission first. Undisclosed tracking SDKs are a rejection and post-launch removal risk. If you don't need cross-app tracking, don't add the SDK, and you can skip the prompt entirely.

**Permissions need purpose strings, requested in context.** Every sensitive permission (camera, location, contacts, microphone) needs a plain-language usage description — on iOS these are the `NSCameraUsageDescription`-style strings in `Info.plist`; a missing one is an automatic rejection. Request the permission *when the feature is first used*, not at launch. This ties directly to the existing rule: request permissions in context, with an explanation before the system prompt (`rules/mobile.md`).

**Android specifics.** Google Play enforces a *recent target API level* — apps that target an old Android version can't be updated or shown to new users until you bump the target SDK. You also need an accurate Data Safety section (as above) and, if you use a foreground service (background location, media playback, data sync), you must declare its type and justify it; unjustified foreground services get rejected.

**The pre-submission checklist:** account deletion in-app, privacy manifest present, privacy labels match the SDKs you actually ship, ATT prompt if you track, purpose strings for every permission, current Android target SDK. Walking through these first saves a rejection round-trip that can add a week to your launch.

## Testing on Real Devices

Simulators don't replicate: low memory kills, background suspension, biometric failures, OS-level permission revokes, or network handoffs (Wi-Fi → cellular). Test auth flows and offline behavior on physical hardware before launch.
