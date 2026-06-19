# Before and After: What vibeArchitecture Changes

Same user request. Same AI tool. Different outcome.

**User prompt:** *"Build me a login API for my recipe sharing app. Users sign up with email and password."*

---

## Without vibeArchitecture

The AI optimizes for speed. The code often *looks* fine.

```javascript
// routes/auth.js
const express = require('express');
const router = express.Router();

router.post('/signup', async (req, res) => {
  const { email, password } = req.body;
  const user = await db.query(
    `INSERT INTO users (email, password) VALUES ('${email}', '${password}') RETURNING *`
  );
  res.json({ user: user.rows[0] });
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  const user = await db.query(
    `SELECT * FROM users WHERE email = '${email}' AND password = '${password}'`
  );
  if (user.rows.length) {
    res.json({ token: jwt.sign({ id: user.rows[0].id }, 'my-secret-key-123') });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});

module.exports = router;
```

**What's wrong (even if it "works"):**

| Problem | Real-world consequence |
|---------|------------------------|
| SQL built from user input | SQL injection — attacker can read or wipe the database |
| Password stored in plain text | One breach exposes every user's password |
| JWT secret hardcoded in source | Anyone with repo access can forge login tokens |
| No input validation | Garbage input crashes the route or corrupts data |
| Full user row returned on signup | May leak internal fields later |
| Generic error on login | Fine here, but often becomes "user not found" vs "wrong password" (email enumeration) |

This is not a caricature. These patterns show up constantly in AI-generated auth code.

---

## With vibeArchitecture (Shared tier)

The AI runs intake first, sees **Shared tier** (family accounts, real emails), and loads `security.md` + `data.md` before writing code.

```javascript
// routes/auth.js
const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { z } = require('zod');
const router = express.Router();

const signupSchema = z.object({
  email: z.string().email().max(255),
  password: z.string().min(12).max(128),
});

router.post('/signup', async (req, res) => {
  const parsed = signupSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid email or password format' });
  }

  const { email, password } = parsed.data;
  const passwordHash = await bcrypt.hash(password, 12);

  try {
    const result = await db.query(
      'INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id, email, created_at',
      [email, passwordHash]
    );
    return res.status(201).json({ user: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'An account with this email already exists' });
    }
    console.error('Signup failed', { err });
    return res.status(500).json({ error: 'Something went wrong. Please try again.' });
  }
});

router.post('/login', async (req, res) => {
  const parsed = signupSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid email or password format' });
  }

  const { email, password } = parsed.data;
  const result = await db.query(
    'SELECT id, email, password_hash FROM users WHERE email = $1',
    [email]
  );

  const user = result.rows[0];
  const valid = user && (await bcrypt.compare(password, user.password_hash));

  if (!valid) {
    // Same message whether email or password was wrong
    return res.status(401).json({ error: 'Invalid email or password' });
  }

  const token = jwt.sign(
    { sub: user.id },
    process.env.JWT_SECRET,
    { expiresIn: '1h' }
  );

  return res.json({ token });
});

module.exports = router;
```

**What changed:**

| vibeArchitecture rule | What the AI did |
|----------------------|-----------------|
| Parameterized queries | `$1, $2` placeholders — no string concatenation |
| Hash passwords | bcrypt with cost factor 12 |
| Secrets in environment | `process.env.JWT_SECRET`, not in source |
| Validate input | Zod schema with length and format checks |
| Handle errors gracefully | try/catch, generic 500 message, structured logging |
| Don't leak data | Returns `id, email, created_at` only — not password hash |

The user didn't ask for any of this. The framework made it default behavior for a Shared-tier project.

---

## The difference in one sentence

**Without vibeArchitecture:** the AI ships the happy path.

**With vibeArchitecture:** the AI still ships fast, but assumes strangers might abuse the app and secrets might leak — because at Shared tier and above, that's the realistic threat model.

See [first-success-walkthrough.md](first-success-walkthrough.md) for the full intake → profile → build flow.
