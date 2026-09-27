// Fixtures for api.yaml.
app.post("/x", (req, res) => {
  // ruleid: va-error-with-200-status-js
  res.json({ error: "not found" });
  // ruleid: va-error-with-200-status-js
  res.status(200).json({ ok: false, error: "bad input" });
  // ok: va-error-with-200-status-js
  res.status(404).json({ type: "about:blank", title: "Not Found", error: "not found" });
});

// ruleid: va-in-memory-rate-limit-js
const limiter = rateLimit({ windowMs: 60000, limit: 100 });
// ok: va-in-memory-rate-limit-js
const limiter2 = rateLimit({ windowMs: 60000, limit: 100, store: new RedisStore({ sendCommand }) });

// ruleid: va-graphql-introspection-enabled
const server = new ApolloServer({ typeDefs, resolvers, introspection: true });
// ok: va-graphql-introspection-enabled
const server2 = new ApolloServer({ typeDefs, resolvers });

async function call(key) {
  // ruleid: va-secret-in-query-string
  await fetch(`https://api.example.com/v1/items?api_key=${key}`);
  // ok: va-secret-in-query-string
  await fetch("https://api.example.com/v1/items", { headers: { Authorization: `Bearer ${key}` } });
}

export async function GET() {
  // ok: va-error-with-200-status-js
  return Response.json({ error: "not found" }, { status: 404 });
}

app.use((req, res) => {
  res.status(404);
  // ok: va-error-with-200-status-js
  return res.json({ error: "Not found" });
});
