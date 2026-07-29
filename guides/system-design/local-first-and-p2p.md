# Local-First and Peer-to-Peer: When the Server Doesn't Own the Data

> The framework's rules mostly assume a client-server shape: your server, your database, your backups. Local-first apps (data lives on the user's device, sync is optional), end-to-end encrypted products (the server stores bytes it cannot read), and peer-to-peer designs (devices talk to each other, servers only relay) invert several of those rules. This guide translates them — the same way `guides/infrastructure/serverless-and-edge.md` translates the long-running-server rules for serverless.

## What Changes and What Doesn't

**Unchanged:** input validation, authorization, fail-closed guards, dependency hygiene, testing, accessibility — everything about code quality survives the architecture change. A relay server still needs rate limiting; a sync endpoint still needs authentication.

**Inverted:** the operator can no longer see, repair, back up, or delete user data. Every rule that quietly relied on "you can fix it in the database" needs a replacement mechanism that runs on the user's device or not at all.

## Key Loss Is Account Loss — Build Recovery Before Launch

In a client-server app, "I forgot my password" is a reset email. In an encrypted local-first app, losing the device encryption key **bricks the user's data with no recovery path** — there is no admin who can help. This is the single most important product decision in the architecture:

- Ship a deliberate recovery mechanism from day one: a passphrase-derived escrow of the data key, a recovery code the user stores, or multi-device redundancy where another linked device can restore. "We'll add recovery later" means early users who lose a phone lose everything.
- Decide platform-backup behavior explicitly (iOS/Android backup inclusion or exclusion). Default settings can silently exclude your data from device backups — or silently include secrets you meant to keep device-bound. Both are wrong by accident; choose on purpose.
- Test the actual loss scenarios on real devices: app deleted and reinstalled, phone replaced from backup, phone lost entirely. Each has a different keychain/keystore survival behavior per platform.

## Backups Are the User's Problem Now — Which Makes Them Your Design Problem

`rules/data.md` says "automate backups, test restores." For E2EE content the *operator* can't do that — you can only back up ciphertext, and only the user can hold the key. Translate the rule:

- Encrypted server-side backup of ciphertext is still worth it (device loss ≠ data loss), but the recovery key custody must be designed (see above).
- The durability review question changes from "can the ops team restore?" to "can user data silently vanish?" — audit every path where the client deletes, overwrites, or fails to persist.

## Deletion and Privacy Get Easier and Harder

- **Easier:** deletion can be cryptographic. Destroying the key that decrypts content *is* erasure — and for content cached on peers' devices, it's the only erasure you can enforce. Design key custody so this works (per-item or per-scope keys, not one key for everything forever).
- **Harder:** your privacy claim now covers metadata, not content. The server can't read messages — but can it see who talks to whom, when, from where? Logs, push payloads, invitation records, and the social graph in your relay database are the attack surface. Review against a curious-or-subpoenaed operator; see `rules/privacy.md`.

## Multi-Device Is an Authorization Plane of Its Own

The moment an account spans devices (a phone plus a laptop, a linked "mirror" client), every server check needs to ask not just "is this the right account?" but "**is this the right device for this action?**":

- Give devices distinct identities and roles (primary vs. linked; which device may publish, which may only read). Enforce it server-side on *every* plane — the failure mode found repeatedly in real audits is device gating added to the identity plane (login, contacts) but never extended to the content/sync plane, letting a linked device do things only the primary should.
- Device linking is a cryptographic ceremony, not a row insert: the new device proves possession to the existing one (QR/short code), the primary signs what the new device may do, and root secrets never leave the primary if the design says they don't.
- Recovery and change-number-style flows are the classic account-takeover surface: never mint credentials for a caller-supplied device ID without verifying that device belongs to the authenticated account.

## Mobile Devices Are Bad Servers

If devices serve content to peers, mobile OS reality applies:

- A backgrounded or killed app cannot reliably serve. iOS and Android both suspend background execution aggressively; push wakes are best-effort and rate-limited. Design honestly around it — decide what happens when the serving device is offline (queue? degrade? explicitly unavailable?) rather than assuming wakes will paper over it.
- One slow peer must not stall the rest: per-peer timeouts and isolation, no head-of-line blocking on a shared tunnel or queue.
- Battery and data budgets are product constraints. Sync schedules, retry backoff with jitter, and payload sizes need the same discipline server-to-server systems apply — the user notices when you get it wrong.

## Sync Conflicts Are Normal Operation

Two offline devices both edited the same thing; both are "right." Conflict handling is a design decision, not an error path: last-writer-wins with a defined clock, CRDTs for mergeable structures, or surfacing the conflict to the user. Whatever you choose, make sync **idempotent** (replaying a message twice changes nothing) and **resumable** (a half-finished sync leaves consistent state) — reviews of real systems find most durability bugs in the "sync was interrupted" path.

## Tier Guidance

Local-first/P2P is orthogonal to the tier system: a Personal-tier local-first notes app needs only the key-loss section; a Public-tier E2EE messenger needs all of it plus `guides/security/cryptography.md`. The privacy overlay (`rules/privacy.md`) almost always applies, because these architectures are usually *chosen* for privacy — which makes the metadata section binding, not optional.
