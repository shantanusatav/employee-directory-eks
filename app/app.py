"""Employee Directory - a small Flask web app for the EKS CI/CD assignment.

Features:
  1. Add an employee (name, department, email)
  2. List and search employees by name or department
  3. Delete an employee
  4. /health endpoint (used by Kubernetes probes) and /api/employees JSON API
"""
import os
import sqlite3

from flask import Flask, g, jsonify, redirect, render_template, request, url_for

APP_VERSION = os.environ.get("APP_VERSION", "v1")
DB_PATH = os.environ.get("DB_PATH", "/tmp/employees.db")

app = Flask(__name__)


def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(app.config.get("DB_PATH", DB_PATH))
        g.db.row_factory = sqlite3.Row
        g.db.execute(
            """CREATE TABLE IF NOT EXISTS employees (
                   id INTEGER PRIMARY KEY AUTOINCREMENT,
                   name TEXT NOT NULL,
                   department TEXT NOT NULL,
                   email TEXT NOT NULL
               )"""
        )
    return g.db


@app.teardown_appcontext
def close_db(_exc):
    db = g.pop("db", None)
    if db is not None:
        db.close()


@app.route("/")
def index():
    q = request.args.get("q", "").strip()
    db = get_db()
    if q:
        like = f"%{q}%"
        rows = db.execute(
            "SELECT * FROM employees WHERE name LIKE ? OR department LIKE ? ORDER BY name",
            (like, like),
        ).fetchall()
    else:
        rows = db.execute("SELECT * FROM employees ORDER BY name").fetchall()
    return render_template("index.html", employees=rows, q=q, version=APP_VERSION)


@app.route("/add", methods=["POST"])
def add():
    name = request.form.get("name", "").strip()
    dept = request.form.get("department", "").strip()
    email = request.form.get("email", "").strip()
    if name and dept and email:
        db = get_db()
        db.execute(
            "INSERT INTO employees (name, department, email) VALUES (?, ?, ?)",
            (name, dept, email),
        )
        db.commit()
    return redirect(url_for("index"))


@app.route("/delete/<int:emp_id>", methods=["POST"])
def delete(emp_id):
    db = get_db()
    db.execute("DELETE FROM employees WHERE id = ?", (emp_id,))
    db.commit()
    return redirect(url_for("index"))


@app.route("/api/employees")
def api_employees():
    rows = get_db().execute("SELECT * FROM employees ORDER BY name").fetchall()
    return jsonify([dict(r) for r in rows])


@app.route("/health")
def health():
    return jsonify(status="ok", version=APP_VERSION)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
