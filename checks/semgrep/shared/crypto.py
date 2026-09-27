# Fixtures for crypto.yaml.
import pickle
import ssl
import tarfile

import requests
import yaml
from Crypto.Cipher import AES, DES
from cryptography.hazmat.primitives.ciphers import algorithms, modes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from lxml import etree


def ciphers(key, iv):
    # ruleid: va-weak-cipher-py
    c = DES.new(key, DES.MODE_CBC, iv)
    # ruleid: va-weak-cipher-py
    c2 = AES.new(key, AES.MODE_ECB)
    # ruleid: va-weak-cipher-py
    m = modes.ECB()
    # ok: va-weak-cipher-py
    c3 = AESGCM(key)
    # ok: va-weak-cipher-py
    c4 = AES.new(key, AES.MODE_GCM, nonce=iv)


def tls(url):
    # ruleid: va-tls-verification-disabled-py
    requests.get(url, verify=False, timeout=5)
    # ruleid: va-tls-verification-disabled-py
    ctx = ssl._create_unverified_context()
    # ok: va-tls-verification-disabled-py
    requests.get(url, timeout=5)


def deser(blob, text):
    # ruleid: va-unsafe-deserialization-py
    obj = pickle.loads(blob)
    # ruleid: va-unsafe-deserialization-py
    cfg = yaml.load(text)
    # ruleid: va-unsafe-deserialization-py
    cfg2 = yaml.load(text, Loader=yaml.FullLoader)
    # ok: va-unsafe-deserialization-py
    cfg3 = yaml.safe_load(text)
    # ok: va-unsafe-deserialization-py
    cfg4 = yaml.load(text, Loader=yaml.SafeLoader)


def xml(body):
    # ruleid: va-xxe-parser-py
    doc = etree.fromstring(body)
    # ok: va-xxe-parser-py
    doc2 = etree.fromstring(body, parser=etree.XMLParser(resolve_entities=False, no_network=True))
    # ruleid: va-xxe-parser-py
    p = etree.XMLParser(resolve_entities=True)


def extract(path, dest):
    # ruleid: va-archive-extract-unsafe-py
    tarfile.open(path).extractall(dest)
    with tarfile.open(path) as tf:
        # ruleid: va-archive-extract-unsafe-py
        tf.extractall(dest)
    with tarfile.open(path) as tf2:
        # ok: va-archive-extract-unsafe-py
        tf2.extractall(dest, filter="data")
