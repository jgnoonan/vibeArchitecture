"""Invariant: data sent to third parties uses an allowlist of keys (VA MOB-018, PRIV-023).

Build each outbound payload with the real builder and check its keys. Push
payloads transit Apple/Google; email, SMS, analytics and webhook payloads
transit their vendors. Replace the imports with your own builders.
"""
from app.notifications import build_push_payload  # your code

ALLOWED_PUSH_KEYS = {"aps", "type", "id"}  # an opaque wake-up: the app fetches content itself


def keys(obj, prefix=""):
    out = set()
    for k, v in obj.items():
        out.add(prefix + k)
        if isinstance(v, dict) and k != "aps":
            out |= keys(v, prefix + k + ".")
    return out


def test_push_payload_has_no_content_or_identity():
    payload = build_push_payload(message_id="m_1", sender_name="Alice", body="See you at 6")
    extra = keys(payload) - ALLOWED_PUSH_KEYS
    assert not extra, f"push payload carries {sorted(extra)} to a third party"
    assert "Alice" not in str(payload) and "See you" not in str(payload)


def test_negative_control_catches_a_leaky_payload():
    leaky = {"aps": {"alert": "Alice: See you at 6"}, "type": "msg", "sender": "Alice"}
    assert keys(leaky) - ALLOWED_PUSH_KEYS == {"sender"}
