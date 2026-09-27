# Fixtures for reliability.yaml.
import httpx
import requests


def calls(url, kwargs):
    # ruleid: va-http-call-without-timeout-py
    requests.get(url)
    # ruleid: va-http-call-without-timeout-py
    requests.post(url, json={"a": 1})
    # ok: va-http-call-without-timeout-py
    requests.get(url, timeout=(3.05, 10))
    # ok: va-http-call-without-timeout-py
    requests.get(url, **kwargs)
    # ruleid: va-http-client-timeout-disabled
    httpx.Client(timeout=None)
    # ok: va-http-client-timeout-disabled
    httpx.Client(timeout=10.0)
