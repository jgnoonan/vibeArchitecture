# Fixtures for injection.yaml. `ruleid:` lines must match; `ok:` lines must not.
import os
import subprocess

import requests
from flask import Flask, Markup, redirect, render_template_string, request, send_file
from sqlalchemy import text
from werkzeug.utils import secure_filename

app = Flask(__name__)


def sql(cursor, session, user_id, email):
    # ruleid: va-sql-string-building-py
    cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
    # ruleid: va-sql-string-building-py
    cursor.execute("SELECT * FROM users WHERE email = '%s'" % email)
    # ruleid: va-sql-string-building-py
    cursor.execute("SELECT * FROM users WHERE email = '{}'".format(email))
    # ruleid: va-sql-string-building-py
    session.execute(text(f"DELETE FROM t WHERE id = {user_id}"))
    # ok: va-sql-string-building-py
    cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
    # ok: va-sql-string-building-py
    session.execute(text("SELECT * FROM users WHERE id = :id"), {"id": user_id})


def html(bio):
    # ruleid: va-raw-html-sink-py
    safe = Markup(bio)
    # ruleid: va-raw-html-sink-py
    page = render_template_string(bio)
    # ok: va-raw-html-sink-py
    ok = Markup("<br>")
    # ok: va-raw-html-sink-py
    ok2 = render_template_string("<p>{{ bio }}</p>", bio=bio)


def shell(name):
    # ruleid: va-shell-command-building-py
    os.system("convert " + name + " out.png")
    # ruleid: va-shell-command-building-py
    subprocess.run(f"ls {name}", shell=True)
    # ok: va-shell-command-building-py
    subprocess.run(["convert", name, "out.png"], check=True)
    # ok: va-shell-command-building-py
    os.system("sync")


def dyn(expr):
    # ruleid: va-dynamic-code-execution-py
    eval(expr)
    # ruleid: va-dynamic-code-execution-py
    exec(expr)
    # ok: va-dynamic-code-execution-py
    eval("1 + 1")


@app.route("/file")
def get_file():
    name = request.args.get("name")
    # ruleid: va-path-from-request-py
    return send_file(os.path.join("/srv/uploads", name))


@app.route("/file2")
def get_file_ok():
    name = request.args.get("name")
    # ok: va-path-from-request-py
    return send_file(os.path.join("/srv/uploads", secure_filename(name)))


@app.route("/preview", methods=["POST"])
def preview():
    url = request.json["url"]
    # ruleid: va-ssrf-request-url-py
    r = requests.get(url, timeout=5)
    # ok: va-ssrf-request-url-py
    r2 = requests.get(validate_url(url), timeout=5)
    # ok: va-ssrf-request-url-py
    r3 = requests.get("https://api.example.com/status", timeout=5)
    return r.text


@app.route("/done")
def done():
    # ruleid: va-open-redirect-py
    return redirect(request.args.get("next"))


@app.route("/done2")
def done_ok():
    # ok: va-open-redirect-py
    return redirect(safe_relative(request.args.get("next")))


@app.route("/users", methods=["POST"])
def create_user():
    # ruleid: va-mass-assignment-py
    user = User(**request.json)
    # ruleid: va-mass-assignment-py
    User.objects.create(**request.POST.dict())
    # ok: va-mass-assignment-py
    user2 = User(name=request.json["name"], email=request.json["email"])
    data = request.json
    # ruleid: va-mass-assignment-setattr
    for key, value in data.items():
        setattr(user, key, value)
    return "ok"


def copy_allowed(user, data):
    # ok: va-mass-assignment-setattr
    for key in ("name", "email"):
        setattr(user, key, data[key])
