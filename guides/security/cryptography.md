# Cryptography: When the Product Is the Crypto

> Referenced from `rules/security.md` (Cryptography). For password hashing, TLS, and encryption at rest, the rules file is enough — this guide is for when you're building something where encryption is the *feature*: end-to-end encrypted messaging, encrypted sync or backup, encrypted document sharing.

## The First Rule Still Applies

"Don't roll your own crypto" doesn't end when you build an encrypted product. It changes meaning: you still never implement primitives (AES, elliptic curves, hashes) yourself, and you *also* don't invent protocols. Protocol design — how keys are exchanged, ratcheted, bound to identities, and retired — is where secure primitives get combined insecurely. Nearly every broken E2EE product used correct primitives in a broken arrangement.

**Build on analyzed patterns:**

- **Key agreement / session setup:** X3DH or PQXDH (the Signal pattern) for asynchronous first contact; Noise protocol patterns for interactive sessions; HPKE (RFC 9180) for one-shot sealed messages.
- **Ongoing message encryption:** the Double Ratchet — per-message forward secrecy plus healing after a key compromise.
- **Simple sealing:** libsodium sealed boxes or `age` when you just need "encrypt to this recipient's public key."

These have published security analyses. Your novel arrangement does not.

## Post-Quantum: Harvest-Now, Decrypt-Later Is a Today Problem

An adversary who records your encrypted traffic today can decrypt it in the future, when quantum computers can break today's elliptic-curve key exchange (Shor's algorithm breaks X25519 and Ed25519; it does not practically break ML-KEM or 256-bit symmetric crypto). If the data you protect must stay confidential for years — private messages, health records, journalism sources — the recording is happening *now*, so the defense has to ship now.

**The pattern: hybrid key agreement.** Combine a classical exchange (X25519) with a post-quantum KEM (ML-KEM-768, the NIST-standardized scheme formerly called Kyber) and derive the session key from both, so an attacker must break *both*. Never pure-PQ (the PQ schemes are newer and less battle-tested) and never classical-only for new designs with long-lived secrets.

- TLS already does this for you at the transport layer — browsers and modern TLS stacks default to hybrid groups (X25519MLKEM768). Don't disable it.
- Application-layer E2EE needs it explicitly: PQXDH is the published pattern for adding ML-KEM to an X3DH-style handshake.
- **Signatures can wait; confidentiality can't.** A quantum-forged signature matters only once quantum computers exist; recorded ciphertext is vulnerable retroactively. Prioritize hybrid *key agreement* now, plan signature migration (ML-DSA) later.

## Engineering Rules That Prevent Real Findings

Lessons from adversarial reviews of production encrypted systems — each of these was a real defect class:

- **Never verify against self-attested keys.** If the key that "authenticates" a record arrived with the record, verification proves nothing. Trust anchors come from an earlier, separate channel (registration-time keys, an out-of-band verification step).
- **Bind context into every encryption and signature.** Include the intended recipient, purpose, and protocol version in the AAD or signed transcript. Unbound ciphertext can be replayed in a different context; an unbound handshake can be redirected to a different addressee.
- **Persist your anti-replay state.** An in-memory replay floor resets on app restart, letting captured older messages force nonce or keystream reuse. Replay counters and ratchet state belong in durable storage.
- **Key lifecycle is part of the protocol.** Rotation cadence, what happens when one-time prekeys run out, zeroization on delete, and what a compromise recovers to — decide these explicitly. After-a-compromise security ("healing") comes from your rekey cadence, so it's a product decision, not a footnote.
- **State the security argument in a comment.** Every cryptographic function gets a sentence saying what property it provides against which attacker — not just what it does. This is what makes review possible; "encrypts the payload" is unreviewable.
- **Metadata is part of the promise.** Encrypting content while logging who-talks-to-whom, or copying names into push payloads, contradicts the E2EE claim. See `rules/privacy.md` (If You Claim Privacy, Audit the Metadata).
- **Deletion can be cryptographic.** Destroying the only key that can decrypt data *is* deletion — and for data cached on other people's devices, it's the only deletion you can enforce. Design key custody so this is possible.
- **Offer users out-of-band verification.** Safety numbers / QR fingerprint comparison is the practical defense against a compromised server substituting keys. It's cheap to build and it's what makes "the server can't MITM us" honest.

## Verifying It

- **Adversarial crypto review** (see `guides/testing/adversarial-review.md`): a dedicated pass hunting protocol misuse — KDF/AEAD misuse, replay, rollback, key lifecycle — separate from general security review.
- **Formal verification is more reachable than you think.** Tools like ProVerif (symbolic) and CryptoVerif (computational) have published, adaptable models for the Signal-family protocols. Adapting a published model to your variant, pinning the upstream baseline you adapted from, and committing the tool outputs verbatim gives you machine-checked evidence — a different *kind* of assurance than review. A review's silence means "nobody spotted an attack"; a proof's silence means "no attack of this class exists, given these assumptions." For a small team building on a standard pattern, this is weeks, not years.
- Record both in your assurance register (`appendices/assurance-register-template.md`).

## What Not to Do

- Don't design a novel handshake because the standard one "seems heavyweight." The heavyweight parts are the attacks it survived.
- Don't ship pure ML-KEM (or any pure-PQ design) to look modern — hybrid exists because the PQ schemes are young.
- Don't let "we use AES-256" stand in for a threat model. Name the attacker: network observer, compromised server, seized device, future quantum adversary. Each is defeated (or not) by a different mechanism.
- Don't confuse FIPS-*validated* with secure-by-design. FIPS 140-3 validation is a paid certification of specific modules; it matters when a government buyer requires it, not before (see `rules/universal.md` on self-assessable vs. certification-grade standards).
