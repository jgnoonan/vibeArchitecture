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

## Testing on Real Devices

Simulators don't replicate: low memory kills, background suspension, biometric failures, OS-level permission revokes, or network handoffs (Wi-Fi → cellular). Test auth flows and offline behavior on physical hardware before launch.
