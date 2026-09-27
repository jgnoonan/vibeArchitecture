#!/usr/bin/env bash
# vibeArchitecture post-deploy smoke test for transport and security headers.
#   smoke-headers.sh https://app.example.com [/path/that/requires/login]
# Run it from your deploy pipeline after each deploy (and on a schedule). Exits 1 on any miss.
# Covers rules SEC-063..SEC-065, API-035/API-037, PERF-018.
set -u
url="${1:?usage: smoke-headers.sh https://host [authenticated-path]}"
auth_path="${2:-}"
host="${url#https://}"; host="${host%%/*}"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

headers=$(curl -sS -o /dev/null -D - --max-time 15 "$url") || { echo "could not reach $url"; exit 1; }
has() { printf '%s' "$headers" | grep -iq "^$1:"; }
val() { printf '%s' "$headers" | grep -i "^$1:" | head -1 | cut -d: -f2- | tr -d '\r' | sed 's/^ *//'; }

echo "== $url"
code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "http://$host/") || code=000
case "$code" in 301|302|307|308) ok "http:// redirects ($code)";; *) bad "http:// does not redirect to https (got $code)";; esac
has strict-transport-security && ok "Strict-Transport-Security" || bad "Strict-Transport-Security missing"
if has content-security-policy; then
  csp=$(val content-security-policy)
  printf '%s' "$csp" | grep -q "frame-ancestors" && ok "CSP with frame-ancestors" || bad "CSP lacks frame-ancestors"
  printf '%s' "$csp" | grep -q "unsafe-inline" && ! printf '%s' "$csp" | grep -Eq "nonce-|strict-dynamic" && bad "CSP allows unsafe-inline without nonces"
else
  bad "Content-Security-Policy missing"
fi
[ "$(val x-content-type-options | tr 'A-Z' 'a-z')" = "nosniff" ] && ok "X-Content-Type-Options: nosniff" || bad "X-Content-Type-Options: nosniff missing"
has referrer-policy && ok "Referrer-Policy" || bad "Referrer-Policy missing"
has permissions-policy && ok "Permissions-Policy" || bad "Permissions-Policy missing"
has cross-origin-opener-policy && ok "Cross-Origin-Opener-Policy" || bad "Cross-Origin-Opener-Policy missing"
printf '%s' "$headers" | grep -i '^set-cookie:' | while read -r c; do
  printf '%s' "$c" | grep -iq 'secure' && printf '%s' "$c" | grep -iq 'httponly' && printf '%s' "$c" | grep -iq 'samesite' \
    || echo "  FAIL  cookie without Secure/HttpOnly/SameSite: $(printf '%s' "$c" | cut -d= -f1 | cut -d: -f2)"
done | grep -q FAIL && { bad "cookie flags (see above)"; }

if [ -n "$auth_path" ]; then
  echo "== $url$auth_path (authenticated route)"
  h2=$(curl -sS -o /dev/null -D - --max-time 15 "${url%/}$auth_path")
  printf '%s' "$h2" | grep -i '^cache-control:' | grep -Eiq 'no-store|private' && ok "Cache-Control private/no-store" \
    || bad "authenticated route is cacheable (send Cache-Control: private, no-store)"
fi
exit $fail
