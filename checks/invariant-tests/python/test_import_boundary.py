"""Invariant: only one package may import crypto primitives (VA SYS-005, SEC-069).

Copy into your tests, then adjust SRC, ALLOWED and SENSITIVE.
"""
import pathlib
import re

SRC = pathlib.Path("src")
ALLOWED = ("src/app/crypto/",)
SENSITIVE = re.compile(r"^\s*(from|import)\s+(cryptography|nacl|Crypto|hashlib|hmac|secrets)\b", re.M)


def violations(files, read=lambda p: pathlib.Path(p).read_text()):
    return [f for f in files if not str(f).startswith(ALLOWED) and SENSITIVE.search(read(f))]


def test_crypto_imports_stay_in_one_package():
    files = [p.as_posix() for p in SRC.rglob("*.py")]
    assert files, f"scanned no files under {SRC}: the invariant would pass vacuously"
    assert violations(files) == []


def test_negative_control_flags_known_bad_file():
    bad = {"src/app/routes/login.py": "import hashlib\n"}
    assert violations(bad, read=bad.__getitem__) == ["src/app/routes/login.py"]
