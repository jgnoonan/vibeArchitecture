# Mobile Rules

> Applies to: Shared tier and above, when building native or cross-platform mobile apps (iOS, Android, React Native, Flutter).
> For detailed explanations: see `guides/security/mobile-security.md`

## Secure Storage

- Never store secrets, API keys, or long-lived auth tokens in UserDefaults, SharedPreferences, plain files, or app bundles. Use Keychain (iOS) or EncryptedSharedPreferences / Keystore (Android).
- Treat anything stored on the device as recoverable by a determined attacker with physical access. Don't store data on-device that you wouldn't want extracted from a lost phone.

## Network Security

- Use HTTPS for every API call. No exceptions, including development — use a local TLS proxy or staging certs instead of disabling TLS.
- Pin certificates or public keys only when you have an operational plan to rotate them. Misconfigured pinning breaks the app for all users until an update ships.
- Assume spotty connectivity. Queue writes, show offline state, and retry with backoff. Mobile users lose signal constantly.

## Authentication

- Prefer platform auth (Sign in with Apple, Google Sign-In) or short-lived tokens with secure refresh storage. Avoid embedding long-lived JWTs in the app binary or local storage.
- Support biometric unlock as a convenience layer on top of existing auth — not as a replacement for server-side session validation.
- Invalidate sessions server-side on logout. Clearing local storage alone is not enough.

## App Store and Privacy

- Declare data collection accurately in App Store Connect and Google Play Data Safety forms. Mismatch between what the app collects and what you declare is a rejection or compliance risk.
- Request permissions (camera, location, contacts) only when needed, in context, with a plain-language explanation before the system prompt.
- Use App Transport Security (iOS) and network security config (Android) defaults. Don't add broad exceptions for convenience.

## Updates and Compatibility

- Mobile clients you can't force-update linger in the wild for months. Version your API and support at least one previous app version.
- Test on real devices, not just simulators — background behavior, push notifications, and storage limits differ.

## Accessibility

- Support Dynamic Type / font scaling and TalkBack / VoiceOver. Mobile accessibility rules in `rules/accessibility.md` apply here too.

## Common AI-Generated Mistakes

- Hardcoded API keys in Swift/Kotlin source or React Native JavaScript bundles
- Storing auth tokens in AsyncStorage or UserDefaults without encryption
- No offline/error state — app shows a blank screen when the train goes through a tunnel
- Requesting all permissions at first launch "just in case"
