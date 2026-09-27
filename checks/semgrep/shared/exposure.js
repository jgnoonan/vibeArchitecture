// Fixtures for exposure.yaml.
function env() {
  // ruleid: va-secret-in-public-env
  const k = process.env.NEXT_PUBLIC_STRIPE_SECRET_KEY;
  // ruleid: va-secret-in-public-env
  const s = import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY;
  // ok: va-secret-in-public-env
  const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  // ok: va-secret-in-public-env
  const server = process.env.STRIPE_SECRET_KEY;
}

function logging(user, password, req, logger) {
  // ruleid: va-sensitive-value-logged-js
  console.log("login attempt", user.email, password);
  // ruleid: va-sensitive-value-logged-js
  logger.info(`issued token ${req.body.token}`);
  // ruleid: va-sensitive-value-logged-js
  logger.debug({ userId: user.id, apiKey: user.apiKey });
  // ok: va-sensitive-value-logged-js
  logger.info({ userId: user.id, event: "password_changed" });
  // ok: va-sensitive-value-logged-js
  console.log("token refreshed for", user.id);
}
