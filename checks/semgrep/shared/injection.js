// Fixtures for injection.yaml. `ruleid:` lines must match; `ok:` lines must not.
const express = require("express");
const fs = require("fs");
const path = require("path");
const { exec, execFile, spawn } = require("child_process");
const app = express();

// --- va-sql-string-building ---
async function sql(db, req, prisma, sqlTag) {
  // ruleid: va-sql-string-building-js
  await db.query(`SELECT * FROM users WHERE id = ${req.params.id}`);
  // ruleid: va-sql-string-building-js
  await db.query("SELECT * FROM users WHERE email = '" + req.body.email + "'");
  // ruleid: va-sql-string-building-js
  await prisma.$queryRawUnsafe(`SELECT * FROM t WHERE name = '${name}'`);
  // ok: va-sql-string-building-js
  await db.query("SELECT * FROM users WHERE id = $1", [req.params.id]);
  // ok: va-sql-string-building-js
  await db.query(`SELECT * FROM users`);
  // ok: va-sql-string-building-js
  await prisma.$queryRaw`SELECT * FROM users WHERE id = ${req.params.id}`;
}

// --- va-raw-html-sink ---
function html(el, userBio, DOMPurify) {
  // ruleid: va-raw-html-sink-js
  el.innerHTML = userBio;
  // ruleid: va-raw-html-sink-js
  el.insertAdjacentHTML("beforeend", userBio);
  // ruleid: va-raw-html-sink-js
  document.write(userBio);
  // ok: va-raw-html-sink-js
  el.innerHTML = "";
  // ok: va-raw-html-sink-js
  el.innerHTML = DOMPurify.sanitize(userBio);
  // ok: va-raw-html-sink-js
  el.textContent = userBio;
}

// --- va-shell-command-building ---
function shell(req, file) {
  // ruleid: va-shell-command-building-js
  exec(`convert ${req.query.file} out.png`);
  // ruleid: va-shell-command-building-js
  exec("ls " + req.query.dir);
  // ruleid: va-shell-command-building-js
  spawn("sh", ["-c", file], { shell: true });
  // ok: va-shell-command-building-js
  exec("ls -la");
  // ok: va-shell-command-building-js
  execFile("convert", [file, "out.png"]);
  // ok: va-shell-command-building-js
  /abc/.exec(file);
}

// --- va-dynamic-code-execution ---
function dyn(expr, handler) {
  // ruleid: va-dynamic-code-execution-js
  eval(expr);
  // ruleid: va-dynamic-code-execution-js
  const f = new Function("a", expr);
  // ok: va-dynamic-code-execution-js
  eval("1 + 1");
  // ok: va-dynamic-code-execution-js
  setTimeout(handler, 100);
  // ok: va-dynamic-code-execution-js
  setTimeout(() => handler(), 100);
  // ruleid: va-dynamic-code-execution-string
  setTimeout("run(" + expr + ")", 100);
}

// --- va-path-from-request ---
app.get("/file", (req, res) => {
  // ruleid: va-path-from-request-js
  res.sendFile(path.join(__dirname, "uploads", req.query.name));
  // ruleid: va-path-from-request-js
  fs.readFileSync("/data/" + req.params.file);
  // ok: va-path-from-request-js
  res.sendFile(path.join(__dirname, "uploads", path.basename(req.query.name)));
  // ok: va-path-from-request-js
  fs.readFileSync("/data/static.txt");
});

// --- va-ssrf-request-url ---
app.post("/preview", async (req, res) => {
  // ruleid: va-ssrf-request-url-js
  const r = await fetch(req.body.url);
  // ok: va-ssrf-request-url-js
  const safe = await fetch(assertSafeUrl(req.body.url));
  // ok: va-ssrf-request-url-js
  const fixed = await fetch("https://api.example.com/v1/status");
});

// --- va-open-redirect ---
app.get("/login/done", (req, res) => {
  // ruleid: va-open-redirect-js
  res.redirect(req.query.next);
  // ok: va-open-redirect-js
  res.redirect(safeRelativePath(req.query.next));
  // ok: va-open-redirect-js
  res.redirect("/dashboard");
});

// --- va-mass-assignment ---
app.post("/users", async (req, res) => {
  // ruleid: va-mass-assignment-js
  await User.create(req.body);
  // ruleid: va-mass-assignment-js
  await User.findByIdAndUpdate(req.params.id, req.body);
  // ruleid: va-mass-assignment-js
  Object.assign(user, req.body);
  // ruleid: va-mass-assignment-js
  await prisma.user.create({ data: req.body });
  // ruleid: va-mass-assignment-js
  await prisma.user.update({ where: { id }, data: { ...req.body } });
  // ok: va-mass-assignment-js
  await User.create({ name: req.body.name, email: req.body.email });
  // ok: va-mass-assignment-js
  await prisma.user.create({ data: { name: req.body.name } });
});

function timerControls(handler) {
  // ok: va-dynamic-code-execution-string
  setTimeout(() => handler("x" + 1), 100);
}

app.get("/users/:id/go", (req, res) => {
  // ok: va-open-redirect-js
  res.redirect("/user/" + req.params.id);
});
