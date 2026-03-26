# Data Lifecycle — Why and How

> This guide covers what happens to data over its lifetime: backups, retention, privacy obligations, and encryption. Read it when planning your data strategy or dealing with compliance requirements.

## Backups — Your Safety Net

### Why Backups Are Non-Negotiable

Data loss happens. Servers fail, disks corrupt, humans run the wrong command, attackers encrypt your database for ransom. The only question is whether you can recover.

A real scenario: a developer runs `DELETE FROM users` in production instead of the test database. Without a backup, those users and all their data are gone. With a backup, you're annoyed but fine.

### The 3-2-1 Rule

A proven backup strategy:
- **3** copies of your data (the original plus two backups)
- **2** different storage types (database server plus cloud storage, for example)
- **1** copy off-site (in a different location than your servers)

For most cloud-hosted applications, this translates to:
- Your production database (copy 1)
- Automated daily snapshots stored by your cloud provider (copy 2)
- Regular exports stored in a different cloud region or service (copy 3)

### Automated Backups

Manual backups will eventually be forgotten. Automate them:
- **Managed databases** (RDS, Cloud SQL, etc.) have automated backups built in. Enable them and configure retention.
- **Self-hosted databases** need a cron job or scheduled task running a backup tool (`pg_dump` for PostgreSQL, `mysqldump` for MySQL).
- **Verify backups run on schedule.** A backup job that silently fails is worse than no backup — you think you're protected when you're not.

### Test Your Restores

The most important backup practice that almost everyone skips:

**A backup you've never restored from is a backup you can't trust.**

- Schedule a test restore at least once. Ideally quarterly.
- Restore to a separate environment (never to production).
- Verify the data is complete and usable.
- Measure how long the restore takes — this is your actual recovery time.

### Point-in-Time Recovery

Most managed databases support PITR (Point-in-Time Recovery). It lets you restore the database to any specific moment — not just the last backup.

This is invaluable when the problem isn't a total loss but a specific mistake: "We need the database as it was at 2:47 PM, before that bad migration ran." Enable PITR if your database supports it.

## Data Retention

### Define Retention Before You Collect

Before you start storing data, decide:
- **How long do you keep it?** User accounts: as long as they're active plus some grace period. Log data: 30–90 days. Financial records: 7 years (tax requirements). Session data: hours to days.
- **What happens when the retention period ends?** Automatically deleted? Archived to cheaper storage? Anonymized?
- **Who is responsible for enforcing retention?** Automated jobs, or does someone have to remember?

### Automated Cleanup

Write automated jobs that enforce your retention policies:
- Delete expired session records nightly
- Archive or delete old log entries monthly
- Anonymize or purge accounts that have been inactive beyond your retention period
- Clean up temporary files, expired tokens, and orphaned records

Without automation, old data accumulates forever, increasing storage costs, slowing queries, and expanding the impact of a potential data breach.

## Privacy and Compliance

### Know What You're Collecting

Maintain a data inventory — a list of what personal data you store, where it lives, and why you need it. This sounds bureaucratic, but it's required by GDPR and practically necessary for handling data requests.

At minimum, track:
- What personal data you collect (names, emails, addresses, etc.)
- Where it's stored (which database, which tables)
- Why you collect it (what feature requires it)
- How long you keep it
- Who has access

### GDPR (If You Have Users in the EU)

Key architectural implications:
- **Right to access:** Users can request all data you hold about them. You need to be able to export it.
- **Right to erasure ("right to be forgotten"):** Users can request deletion of their data. You need to be able to find and delete all of it — including backups (or have a process to handle backup retention).
- **Data portability:** Users can request their data in a standard format.
- **Consent:** You need clear, affirmative consent for data collection beyond what's necessary for the service.
- **Breach notification:** You must notify authorities within 72 hours of a data breach.

### CCPA (If You Have Users in California)

Similar to GDPR but with different specifics. Key requirement: users can opt out of the "sale" of their personal information and request deletion.

### HIPAA (If You Handle Health Data)

This is not something you can figure out as you go. HIPAA affects everything:
- Where data can be stored (BAA-covered services only)
- Who can access it (minimum necessary principle)
- How it's transmitted (encryption required)
- How access is logged (audit trails required)
- How breaches are handled (strict notification requirements)

If your project handles health data, consult a HIPAA compliance specialist before building. Architectural decisions made early are much cheaper to change than decisions baked into a running system.

## Data Encryption

### At Rest (Data Stored on Disk)

"Encryption at rest" means the data on disk is encrypted. If someone steals the hard drive or accesses the raw storage, they can't read the data without the encryption key.

- **Database-level encryption** — most managed databases offer this as a checkbox. Enable it.
- **Volume/disk encryption** — encrypts the entire disk the database sits on. Often the default on cloud providers.
- **Application-level encryption** — your application encrypts specific fields before storing them. Use this for the most sensitive data (SSNs, credit card numbers) where you want protection even from database administrators.

### In Transit (Data Moving Between Systems)

"Encryption in transit" means data is encrypted while traveling over a network. This prevents eavesdropping.

- **TLS (HTTPS)** — all web traffic should use HTTPS. This encrypts the data between the user's browser and your server.
- **Database connections** — use SSL/TLS for database connections, especially if the database is on a different server. Most managed databases support or require this.
- **Internal service communication** — if your application talks to other services, those connections should also be encrypted.

### Encryption Key Management

Encryption is only as secure as the keys:
- Don't store encryption keys in your code or alongside the encrypted data. Use a key management service (AWS KMS, Azure Key Vault, GCP KMS).
- If you lose the encryption key, the data is permanently unreadable. Ensure key backup and recovery procedures exist.
- Rotate keys periodically. Design your system so that re-encrypting data with a new key is possible without downtime.
