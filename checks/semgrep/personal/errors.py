# Fixtures for errors.yaml.
import os
import traceback

from flask import Flask, jsonify

app = Flask(__name__)


def main():
    # ruleid: va-debug-mode-enabled-py
    app.run(host="0.0.0.0", debug=True)
    # ok: va-debug-mode-enabled-py
    app.run(debug=os.environ.get("FLASK_DEBUG") == "1")


@app.route("/x")
def handler():
    try:
        work()
    except Exception:
        # ruleid: va-error-details-in-response-py
        return traceback.format_exc(), 500
    try:
        work()
    except Exception:
        app.logger.exception("work failed")
        # ok: va-error-details-in-response-py
        return jsonify(error="Something went wrong"), 500
