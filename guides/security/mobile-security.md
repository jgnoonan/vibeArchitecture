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
| Android Keystore + Tink AES-GCM | Yes | Keystore holds the key; Tink encrypts the data. `EncryptedSharedPreferences` / `androidx.security:security-crypto` is deprecated — don't start new code on it |
| UserDefaults / SharedPreferences (plain) | No | Readable on rooted/jailbroken devices |
| AsyncStorage (React Native) | No | Not encrypted by default |
| App bundle / source code | Never | Extractable from the APK/IPA |

**Rule of thumb:** If losing the phone would expose it, don't store it on the phone unencrypted — and ask first whether you need to store it at all. A short-lived access token that's refreshed from the server is often the better answer than a long-lived secret in secure storage.

**Bind the most sensitive items to biometrics.** Keychain items created with `kSecAccessControlBiometryCurrentSet` and Keystore keys with `setUserAuthenticationRequired(true)` can only be read after a fresh Face ID / fingerprint check, and are invalidated if the enrolled biometrics change. Use this for refresh tokens and local encryption keys, not for everything — every read prompts the user.

**Protect what's on screen and on the clipboard.** Set `FLAG_SECURE` on Android activities that show sensitive data (blocks screenshots and appears black in the app switcher); on iOS, blank sensitive views when the app resigns active and watch `UIScreen.capturedDidChangeNotification`. When you copy a one-time code or key, use the platform's sensitive-clipboard flags (`UIPasteboard` expiration / `localOnly`, Android `EXTRA_IS_SENSITIVE`) and clear it after a short timeout.

---

## OAuth, Deep Links, and WebViews

**Use PKCE through the system browser.** Native OAuth means the authorization-code flow with PKCE (RFC 9700 / OAuth 2.1), opened in `ASWebAuthenticationSession` (iOS) or a Custom Tab (Android). Never load the provider's login page in an embedded WebView — the user can't verify the URL, and your app could read their password.

**Custom URL schemes can be hijacked.** Any app can register `myapp://`, so if your OAuth redirect is `myapp://callback`, a malicious app installed on the same phone can receive the authorization code. Use **Universal Links** (iOS, `apple-app-site-association`) and **verified App Links** (Android, `assetlinks.json`) for redirects and any deep link that carries a token or code — the OS verifies your domain ownership before routing. PKCE limits the damage from a stolen code, but don't rely on it alone.

**Treat every deep link as untrusted input.** Validate parameters, never execute an action (transfer, delete, link account) from a deep link without the user confirming in-app, and never let a deep link choose which URL a WebView loads.

**Harden WebViews.** Disable `file://` access and JavaScript unless the feature requires it, don't expose JavaScript bridges (`addJavascriptInterface`, `WKScriptMessageHandler`) to pages you don't control, restrict navigation to an allowlist of hosts, and don't inject auth tokens into pages that can navigate elsewhere.

**App attestation.** Play Integrity (Android) and App Attest + DeviceCheck (iOS) let your server check that a request came from your genuine app on an unmodified device. It raises the cost of scripted abuse of your API and is worth enabling when the API is valuable — but it is a bot-control measure, not authentication or authorization; the server still checks the user and the resource.

---

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

**iOS:** Privacy Nutrition Labels, App Tracking Transparency for cross-app tracking, and — if you offer third-party social login for account creation — App Store guideline 4.8 requires you to also offer a login option with equivalent privacy (limits data collection to name and email, lets users hide their email, no tracking). Sign in with Apple satisfies this, but it is no longer specifically required.

**Android:** Data Safety section, runtime permissions, scoped storage for file access.

Both platforms reject or penalize apps that over-collect or misdeclare data use.

---

## App Store Review: Rejections That Actually Bite

Getting your code working is only half the battle. Apple and Google review every app, and they reject or pull apps for privacy and policy reasons an AI assistant won't warn you about until it's too late. These are the current high-frequency triggers. Check every one before you submit, and re-check the store guidelines each release — they change.

**In-app account deletion (iOS, required).** If your app lets users create an account, Apple requires a way to delete that account *from inside the app* — not "email us to close your account." A settings screen link that starts the deletion is enough. This is one of the most common rejections for apps with sign-up. (Android has similar expectations and a required "delete account" link in your Play listing.)

**iOS Privacy Manifest (`PrivacyInfo.xcprivacy`).** Your app — and every third-party SDK you bundle — must ship a privacy manifest declaring what data it collects and *why*. On top of that, certain common APIs are now "required reason" APIs (things like reading file timestamps, disk space, or user defaults): you must declare an approved reason code for using them. Missing or incomplete manifests now cause rejections at submission. Ask your AI to check whether your SDKs already provide their own manifests — most popular ones do, but you still need yours.

**Privacy labels must match reality.** Apple's App Privacy "nutrition label" and Google Play's Data Safety section are forms *you* fill out describing what you collect. Reviewers (and automated tooling) compare your declarations against what the app actually does. If you say "no data collected" but your analytics SDK phones home with device IDs, that mismatch gets flagged. Fill these out honestly, and re-check them every time you add an SDK. See `rules/mobile.md` ("App Store and Privacy").

**Tracking requires the ATT prompt (iOS).** If your app tracks users across other companies' apps and websites — anything using the IDFA advertising identifier, most ad and attribution SDKs — you must show Apple's App Tracking Transparency prompt and get permission first. Undisclosed tracking SDKs are a rejection and post-launch removal risk. If you don't need cross-app tracking, don't add the SDK, and you can skip the prompt entirely.

**Permissions need purpose strings, requested in context.** Every sensitive permission (camera, location, contacts, microphone) needs a plain-language usage description — on iOS these are the `NSCameraUsageDescription`-style strings in `Info.plist`; a missing one is an automatic rejection. Request the permission *when the feature is first used*, not at launch. This ties directly to the existing rule: request permissions in context, with an explanation before the system prompt (`rules/mobile.md`).

**Android specifics.** Google Play enforces a *recent target API level* — apps that target an old Android version can't be updated or shown to new users until you bump the target SDK. You also need an accurate Data Safety section (as above) and, if you use a foreground service (background location, media playback, data sync), you must declare its type and justify it; unjustified foreground services get rejected.

**The pre-submission checklist:** account deletion in-app, privacy manifest present, privacy labels match the SDKs you actually ship, ATT prompt if you track, purpose strings for every permission, current Android target SDK. Walking through these first saves a rejection round-trip that can add a week to your launch.

## Testing on Real Devices

Simulators don't replicate: low memory kills, background suspension, biometric failures, OS-level permission revokes, or network handoffs (Wi-Fi → cellular). Test auth flows and offline behavior on physical hardware before launch.
