"""Per-release database schema, as a fresh install creates it: each release's
sql/database.sql is loaded into a throwaway MariaDB, and the tables, columns and
indexes are read back from information_schema. Reading what the database built,
rather than parsing the SQL, means the schema is exactly what an install gets.

Writes data/<tag>/schema.json. Needs Docker.
"""

from __future__ import annotations

import json
import subprocess
import sys
import time

from sources import DATA, Release, releases, show, source

IMAGE = "mariadb:11.8"
CONTAINER = "openemr-reference-mariadb"


def sh(*args: str, input: str | None = None) -> str:
    run = subprocess.run(list(args), input=input, capture_output=True, text=True)
    if run.returncode != 0:
        raise RuntimeError(f"{' '.join(args[:6])}...: {run.stderr[-1500:]}")
    return run.stdout


def mariadb(sql: str, database: str = "", script: str | None = None) -> str:
    cmd = ["docker", "exec", "-i", CONTAINER, "mariadb", "-uroot", "-proot", "-N", "-B", "--default-character-set=utf8mb4"]
    if database:
        cmd.append(database)
    if script is None:
        cmd += ["-e", sql]
    return sh(*cmd, input=script)


def start() -> None:
    subprocess.run(["docker", "rm", "-f", CONTAINER], capture_output=True)
    sh("docker", "run", "-d", "--name", CONTAINER, "-e", "MARIADB_ROOT_PASSWORD=root", IMAGE)
    for _ in range(60):
        if subprocess.run(["docker", "exec", CONTAINER, "mariadb", "-uroot", "-proot", "-e", "SELECT 1"], capture_output=True).returncode == 0:
            return
        time.sleep(2)
    raise SystemExit("MariaDB did not start")


def stop() -> None:
    subprocess.run(["docker", "rm", "-f", CONTAINER], capture_output=True)


def query_json(sql: str) -> list:
    out = mariadb("SET SESSION group_concat_max_len = 1073741824; " + sql).strip()
    return json.loads(out) if out and out != "NULL" else []


def extract(release: Release) -> dict:
    text = show(release, "sql/database.sql")
    if text is None:
        raise SystemExit(f"{release.tag}: no sql/database.sql")
    db = "oe_" + release.tag
    mariadb(f"DROP DATABASE IF EXISTS `{db}`; CREATE DATABASE `{db}` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci")
    # As OpenEMR's installer does (Installer.class.php: SET sql_mode = ''); some releases' seed rows need it.
    mariadb("", db, script="SET SESSION sql_mode = '';\n" + text)
    where = f"TABLE_SCHEMA = '{db}'"
    tables = query_json(f"""SELECT JSON_ARRAYAGG(JSON_OBJECT('table', TABLE_NAME, 'engine', ENGINE, 'comment', TABLE_COMMENT,
        'rows', TABLE_ROWS)) FROM information_schema.TABLES WHERE {where} AND TABLE_TYPE = 'BASE TABLE'""")
    columns = query_json(f"""SELECT JSON_ARRAYAGG(JSON_OBJECT('table', TABLE_NAME, 'column', COLUMN_NAME, 'position', ORDINAL_POSITION,
        'type', COLUMN_TYPE, 'nullable', IS_NULLABLE = 'YES', 'default', COLUMN_DEFAULT, 'extra', EXTRA, 'comment', COLUMN_COMMENT))
        FROM information_schema.COLUMNS WHERE {where}""")
    indexes = query_json(f"""SELECT JSON_ARRAYAGG(JSON_OBJECT('table', TABLE_NAME, 'index', INDEX_NAME, 'unique', NON_UNIQUE = 0,
        'seq', SEQ_IN_INDEX, 'column', COLUMN_NAME, 'sub_part', SUB_PART)) FROM information_schema.STATISTICS WHERE {where}""")
    counts = query_json(f"""SELECT JSON_ARRAYAGG(JSON_OBJECT('table', TABLE_NAME, 'rows', TABLE_ROWS))
        FROM information_schema.TABLES WHERE {where} AND TABLE_TYPE = 'BASE TABLE'""")
    mariadb(f"DROP DATABASE `{db}`")

    schema: dict[str, dict] = {}
    for t in tables:
        schema[t["table"]] = {"engine": t["engine"], "comment": t["comment"], "columns": [], "indexes": {}}
    for c in sorted(columns, key=lambda c: (c["table"], c["position"])):
        if c["table"] in schema:
            schema[c["table"]]["columns"].append({k: c[k] for k in ("column", "type", "nullable", "default", "extra", "comment")})
    for i in sorted(indexes, key=lambda i: (i["table"], i["index"], i["seq"])):
        if i["table"] in schema:
            idx = schema[i["table"]]["indexes"].setdefault(i["index"], {"unique": bool(i["unique"]), "columns": []})
            idx["columns"].append(i["column"] + (f"({i['sub_part']})" if i["sub_part"] else ""))
    return {"release": release.name, "loaded_with": IMAGE, "tables": dict(sorted(schema.items())),
            "source": source(release, "sql/database.sql")}


def main() -> None:
    todo = [r for r in releases() if "--all" in sys.argv or not (DATA / r.tag / "schema.json").exists()]
    if not todo:
        return
    start()
    try:
        for release in todo:
            facts = extract(release)
            (DATA / release.tag).mkdir(parents=True, exist_ok=True)
            (DATA / release.tag / "schema.json").write_text(json.dumps(facts, indent=1, ensure_ascii=False) + "\n")
            tables = facts["tables"]
            print(f"{release.name:7} {len(tables):4} tables {sum(len(t['columns']) for t in tables.values()):5} columns")
    finally:
        stop()


if __name__ == "__main__":
    main()
