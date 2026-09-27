# Fixtures for api.yaml.
from flask import jsonify
from flask_limiter import Limiter


def view():
    # ruleid: va-error-with-200-status-py
    return jsonify(error="not found")


def view_ok():
    # ok: va-error-with-200-status-py
    return jsonify(error="not found"), 404


# ruleid: va-in-memory-rate-limit-py
limiter = Limiter(get_remote_address, app=app)
# ok: va-in-memory-rate-limit-py
limiter2 = Limiter(get_remote_address, app=app, storage_uri="redis://cache:6379")
