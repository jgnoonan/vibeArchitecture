# Mobile Rules

> Applies to: Shared tier and above, when building native or cross-platform mobile apps (iOS, Android, React Native, Flutter).
> For detailed explanations: see `guides/security/mobile-security.md`
> Standards baseline: **OWASP MASVS v2** is the mobile analog of ASVS — self-assess against it, and use the companion **MASTG** test guide to verify. See `appendices/standards-mapping.md`.

## Secure Storage

- Never store secrets, API keys, or long-lived auth tokens in UserDefaults, SharedPreferences, plain files, or app bundles. Use Keychain (iOS) or an Android Keystore-backed key with Tink AES-GCM (Android) — `EncryptedSharedPreferences` / `androidx.security:security-crypto` is deprecated. Better still: don't store it.
- Bind high-value Keychain/Keystore items to biometrics (`kSecAccessControlBiometryCurrentSet`, `setUserAuthenticationRequired`) so a stolen unlocked device still can't export them.
- On screens showing sensitive data, block screenshots/recording (`FLAG_SECURE`, iOS screen-capture detection), blank the app-switcher snapshot, and clear or expire clipboard contents you copy (one-time codes, keys).
- Treat anything stored on the device as recoverable by a determined attacker with physical access. Don't store data on-device that you wouldn't want extracted from a lost phone.

## Network Security

- Use HTTPS for every API call. No exceptions, including development — use a local TLS proxy or staging certs instead of disabling TLS.
- Pin certificates or public keys only when you have an operational plan to rotate them. Misconfigured pinning breaks the app for all users until an update ships.
- Assume spotty connectivity. Queue writes, show offline state, and retry with backoff. Mobile users lose signal constantly.

## Authentication

- Prefer platform auth (Sign in with Apple, Google Sign-In) or short-lived tokens with secure refresh storage. Avoid embedding long-lived JWTs in the app binary or local storage.
- Native OAuth uses the authorization code flow with PKCE through the system browser (`ASWebAuthenticationSession` / Custom Tabs), never an embedded WebView, and never a custom-scheme redirect alone: another app can register the same scheme and capture the code. Use verified Universal Links (iOS) / App Links (Android) for redirects.
- Harden every WebView: no `file://` access, JavaScript off unless required, no JavaScript bridges exposed to arbitrary URLs, and load only allowlisted hosts. A WebView is a browser with your app's identity.
- Attest the app when the API is worth abusing (Play Integrity / App Attest + DeviceCheck) — it raises the cost of scripted clients but is not a substitute for server-side authorization.
- Support biometric unlock as a convenience layer on top of existing auth — not as a replacement for server-side session validation.
- Invalidate sessions server-side on logout. Clearing local storage alone is not enough.

## App Store and Privacy

- Declare data collection accurately in App Store Connect and Google Play Data Safety forms. Mismatch between what the app collects and what you declare is a rejection or compliance risk.
- Request permissions (camera, location, contacts) only when needed, in context, with a plain-language explanation before the system prompt.
- Use App Transport Security (iOS) and network security config (Android) defaults. Don't add broad exceptions for convenience.
- Know the store-review triggers before you submit: iOS requires **in-app account deletion** if you support signup, plus a **Privacy Manifest** and justification for "required reason" APIs; Play enforces a recent **target SDK** and an accurate Data Safety form. See `guides/security/mobile-security.md`.

## Push Notifications

- Push payloads transit Apple's (APNs) and Google's (FCM) servers. Treat them as data shared with a third party: never put message content, names, or other personal data in the payload if your app claims any privacy posture. Send an opaque wake signal and fetch the real content on-device.
- Push delivery is best-effort, not guaranteed. Anything critical must also be reachable by an in-app poll or sync on next open.

## Updates and Compatibility

- Mobile clients you can't force-update linger in the wild for months. Version your API and support at least one previous app version.
- Test on real devices, not just simulators — background behavior, push notifications, and storage limits differ.

## Accessibility

- Support Dynamic Type / font scaling and TalkBack / VoiceOver. Mobile accessibility rules in `rules/accessibility.md` apply here too.

## Common AI-Generated Mistakes

- Hardcoded API keys in Swift/Kotlin source or React Native JavaScript bundles
- Storing auth tokens in AsyncStorage or UserDefaults without encryption
- OAuth redirect on a custom URL scheme (`myapp://callback`) that any other app can claim
- No offline/error state — app shows a blank screen when the train goes through a tunnel
- Requesting all permissions at first launch "just in case"
