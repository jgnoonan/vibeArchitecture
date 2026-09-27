# Fixtures for auth.yaml.
import hashlib
import hmac
import random
import secrets

import jwt
from django.views.decorators.csrf import csrf_exempt
from fastapi.middleware.cors import CORSMiddleware
from flask_cors import CORS


def jwts(token, key):
    # ruleid: va-jwt-unverified-py
    jwt.decode(token, options={"verify_signature": False})
    # ruleid: va-jwt-unverified-py
    jwt.decode(token, key, algorithms=["HS256", "none"])
    # ok: va-jwt-unverified-py
    jwt.decode(token, key, algorithms=["RS256"], audience="api")


def compare(signature, expected_signature, token, stored_token, api_key, body):
    # ruleid: va-timing-unsafe-compare-py
    if signature == expected_signature:
        pass
    # ruleid: va-timing-unsafe-compare-py
    if hmac.new(key, body, hashlib.sha256).hexdigest() == signature:
        pass
    # ruleid: va-timing-unsafe-compare-py
    if token != stored_token:
        pass
    # ok: va-timing-unsafe-compare-py
    if api_key == None:
        pass
    # ok: va-timing-unsafe-compare-py
    if hmac.compare_digest(signature, expected_signature):
        pass


def hashing(password, user, data):
    # ruleid: va-password-fast-hash-py
    h = hashlib.sha256(password.encode()).hexdigest()
    # ruleid: va-password-fast-hash-py
    h2 = hashlib.md5(user.password.encode("utf-8")).hexdigest()
    # ok: va-password-fast-hash-py
    etag = hashlib.sha256(data).hexdigest()


def randomness():
    # ruleid: va-insecure-random-secret-py
    reset_token = "".join(random.choice("abcdef0123456789") for _ in range(32))
    # ruleid: va-insecure-random-secret-py
    otp = random.randint(100000, 999999)
    # ok: va-insecure-random-secret-py
    jitter = random.uniform(0, 1)
    # ok: va-insecure-random-secret-py
    reset_token2 = secrets.token_urlsafe(32)


def make_session_id():
    # ruleid: va-insecure-random-secret-py
    return str(random.getrandbits(64))


def cookies(resp, app):
    # ruleid: va-cookie-flags-disabled-py
    resp.set_cookie("sid", "x", httponly=False)
    # ok: va-cookie-flags-disabled-py
    resp.set_cookie("sid", "x", httponly=True, secure=True, samesite="Lax")
    # ruleid: va-cookie-flags-disabled-py
    app.config["SESSION_COOKIE_SECURE"] = False


# ruleid: va-cookie-flags-disabled-py
SESSION_COOKIE_SECURE = False


# ruleid: va-csrf-disabled-py
@csrf_exempt
def update_profile(request):
    pass


def cors_setup(app):
    # ruleid: va-cors-reflect-origin-py
    app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True)
    # ok: va-cors-reflect-origin-py
    app.add_middleware(CORSMiddleware, allow_origins=["https://app.example.com"], allow_credentials=True)
    # ruleid: va-cors-reflect-origin-py
    CORS(app, supports_credentials=True)
    # ok: va-cors-reflect-origin-py
    CORS(app, origins=["https://app.example.com"], supports_credentials=True)


# ok: va-csrf-disabled-py
@require_POST
def update_email(request):
    pass


def enum_compare(tok, TokenType, token_count):
    # ok: va-timing-unsafe-compare-py
    if tok.type == TokenType.STRING:
        pass
    # ok: va-timing-unsafe-compare-py
    if token_count == 3:
        pass
