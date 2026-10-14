"""Demo web service deployed by Ansible behind nginx + gunicorn."""

import os
import socket
from pathlib import Path

from flask import Flask, jsonify

app = Flask(__name__)
app.config["SECRET_KEY"] = os.environ["APP_SECRET_KEY"]

VERSION = Path(__file__).with_name("VERSION").read_text(encoding="utf-8").strip()
ENVIRONMENT = os.environ.get("APP_ENV", "dev")
HOSTNAME = socket.gethostname()


@app.get("/")
def index():
    return jsonify(
        service="ansible-aws-automation",
        version=VERSION,
        environment=ENVIRONMENT,
        host=HOSTNAME,
    )


@app.get("/health")
def health():
    return jsonify(status="ok", version=VERSION)


@app.after_request
def no_store(response):
    response.headers["Cache-Control"] = "no-store"
    return response
