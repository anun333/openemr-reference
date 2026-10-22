"""Checks the extracted facts before pages are built. Exits non-zero on any failure.

Three kinds of check:
  floors       a broken extraction yields too little (no tables, no settings), which
               would otherwise look like "nothing changed"
  known facts  things known from outside this pipeline, each with its source
  runtime      (--runtime) the latest extracted release against a running OpenEMR of
               that release: its settings as OpenEMR loads them, and its database

    python3 gen/check.py [--runtime OPENEMR_CONTAINER DB_CONTAINER]
"""

from __future__ import annotations

import json
import subprocess
import sys

from sources import DATA

failures: list[str] = []


def check(ok: bool, msg: str) -> None:
    print(("ok   " if ok else "FAIL ") + msg)
    if not ok:
        failures.append(msg)


def load(tag: str, name: str) -> dict:
    return json.loads((DATA / tag / f"{name}.json").read_text())


def floors(tags: list[str]) -> None:
    check(len(tags) >= 11, f"{len(tags)} releases from 7.0.0 on (at least 11)")
    for tag in tags:
        r, s, st = load(tag, "release"), load(tag, "schema"), load(tag, "settings")
        n_settings = sum(len(v) for v in st["sections"].values())
        n_cols = sum(len(t["columns"]) for t in s["tables"].values())
        ok = (len(s["tables"]) >= 250 and n_cols >= 3000 and n_settings >= 400 and len(r["ci"]["rows"]) >= 5
              and str(r["php"]["requires"] or "").startswith(">=") and isinstance(r["version"].get("v_database"), int)
              and len(r["pages"]["files"]) >= 900)
        check(ok, f"{tag}: {len(s['tables'])} tables, {n_cols} columns, {n_settings} settings, {len(r['ci']['rows'])} CI setups, "
                  f"PHP {r['php']['requires']}, database version {r['version'].get('v_database')}, {len(r['pages']['files'])} PHP files")
        pk = load(tag, "package")
        # .gitattributes export-ignores tests/, ci/ and .github/ from 8.1.0 on; before that git archive lists them.
        leaked = [f for f in pk["files"] if f.startswith(("tests/", ".github/", "ci/"))]
        ignores = tuple(int(x) for x in tag[1:].split("_")) >= (8, 1, 0)
        check(len(pk["files"]) >= 5000 and len(pk["composer"]) >= 100 and len(pk["assets"]) >= 3 and bool(leaked) != ignores
              and "interface/login/login.php" in pk["files"] and "version.php" in pk["files"],
              f"{tag}: package lists {len(pk['files'])} files from git, {len(pk['composer'])} Composer packages, {len(pk['assets'])} page assets, "
              f"{len(leaked)} tests/ci/.github paths ({'none expected' if ignores else 'expected before 8.1.0'})")


def known_facts(tags: list[str]) -> None:
    def has_page(tag: str, page: str) -> bool:
        return page in load(tag, "release")["pages"]["files"]

    def has_setting(tag: str, key: str) -> bool:
        return any(key in keys for keys in load(tag, "settings")["sections"].values())

    # openemr/openemr#13471 deleted the Backup page on 2026-08-12; 8.2.0 was tagged 2026-07-08 and 8.3.0 2026-08-18.
    check("v8_2_0" in tags and has_page("v8_2_0", "interface/main/backup.php") and not has_page("v8_3_0", "interface/main/backup.php"),
          "the Backup page is in 8.2.0 and gone in 8.3.0 (#13471)")
    check(has_setting("v8_2_0", "configuration_import_export") and not has_setting("v8_3_0", "configuration_import_export"),
          "the Configuration Export/Import setting went with it")
    # #14494 is about the Financial Review Date being a text box over a datetime column.
    col = next(c for c in load("v8_4_1", "schema")["tables"]["patient_data"]["columns"] if c["column"] == "financial_review")
    check(col["type"] == "datetime", f"patient_data.financial_review is datetime in 8.4.1 ({col['type']})")
    # composer.json's PHP floor only ever rises across these releases.
    floors_seen = [tuple(map(int, load(t, "release")["php"]["requires"].lstrip(">=").split(".")[:2])) for t in tags]
    check(floors_seen == sorted(floors_seen), f"the PHP floor never falls ({' → '.join('.'.join(map(str, f)) for f in floors_seen)})")
    # The 8.4.1 release tarball (sha256 checked, 2026-10-11) contains every file git archive lists
    # and has ClaimRev, which Composer installs outside vendor/ (#11265, from 8.2.0).
    claimrev = {c["name"]: c["path"] for c in load("v8_4_1", "package")["composer"]}.get("claimrevolution/oe-module-claimrev-connect")
    check(claimrev == "interface/modules/custom_modules/oe-module-claimrev-connect"
          and "claimrevolution/oe-module-claimrev-connect" not in {c["name"] for c in load("v8_1_0", "package")["composer"]},
          f"ClaimRev is a Composer module installed to custom_modules from 8.2.0 ({claimrev})")
    check("templates/interface/main/tabs/tabs_template.html.twig" in load("v8_4_1", "package")["files"],
          "8.4.1's package has the tabs template whose absence blanked logins in t/25717")
    # Upgrade scripts: every release has them, and 8.3.0 to 8.4.0 alters api_log (read from the script).
    up = load("v8_4_1", "upgrades")
    check(len(up["scripts"]) >= 30 and "api_log" in up["scripts"]["8_3_0-to-8_4_0_upgrade.sql"]["alters"]
          and up["package_unpacked_bytes"] and up["package_unpacked_bytes"] > 400_000_000,
          f"8.4.1 has {len(up['scripts'])} upgrade scripts; 8.3.0 to 8.4.0 alters api_log; the package unpacks to {up['package_unpacked_bytes']} bytes")
    # Patches delete files: 7.0.3 patch 4 dropped the old login template (seen on the official 7.0.3 image).
    check("templates/login/login_core.html.twig" in load("v7_0_3", "package")["files"]
          and "templates/login/login_core.html.twig" not in load("v7_0_3", "package-p4")["files"],
          "7.0.3 has templates/login/login_core.html.twig and its patch 4 doesn't")
    # A setting key resolved from an enum, which the extractor must read from the enum file.
    check(has_setting("v8_4_1", "rest_fhir_api"), "8.4.1 has rest_fhir_api, whose key is an enum case (GlobalConnectorsEnum::REST_FHIR_API)")


def tools() -> None:
    """The scripts that fetch their helpers from their own release must agree on which release that is."""
    import re
    from pathlib import Path
    root = Path(__file__).resolve().parent.parent / "preflight"
    found = {}
    for name, pattern in (("openemr-upgrade.sh", r"^SCRIPT_VERSION=(\S+)$"), ("openemr-doctor-docker.sh", r"^\s*VERSION=(\S+)$"),
                          ("openemr-doctor.php", r"^define\('DOCTOR_VERSION', '([^']+)'\);$")):
        m = re.search(pattern, (root / name).read_text(), re.M)
        found[name] = m.group(1) if m else None
    versions = set(found.values())
    check(None not in versions and len(versions) == 1,
          f"the scripts name one release to fetch their helpers from ({', '.join(f'{k} {v}' for k, v in found.items())})")


def runtime(tag: str, app: str, db: str) -> None:
    php = r"""$ignoreAuth = true; $_GET['site'] = 'default'; $sessionAllowWrite = true;
require '/var/www/localhost/htdocs/openemr/interface/globals.php';
require '/var/www/localhost/htdocs/openemr/library/globals.inc.php';
echo json_encode(array_map(fn($s) => array_keys($s), $GLOBALS_METADATA));"""
    run = subprocess.run(["docker", "exec", "-u", "apache", "-e", "HTTP_HOST=localhost", app, "php", "-r", php], capture_output=True, text=True)
    live = json.loads(run.stdout) if run.returncode == 0 and run.stdout.strip().startswith("{") else {}
    extracted = load(tag, "settings")["sections"]
    lk = {(s, k) for s, keys in live.items() for k in keys}
    ek = {(s, k) for s, keys in extracted.items() for k in keys}
    check(bool(lk) and ek <= lk, f"every extracted {tag} setting is in the running OpenEMR ({len(ek)} of its {len(lk)})")
    extra_sections = sorted({s for s, _ in lk - ek})
    print(f"     settings only at run time are in sections {extra_sections} (added by modules when they start)")

    sql = ("SET SESSION group_concat_max_len=1073741824; SELECT JSON_ARRAYAGG(JSON_OBJECT('t',TABLE_NAME,'c',COLUMN_NAME,'type',COLUMN_TYPE)) "
           "FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='openemr'")
    run = subprocess.run(["docker", "exec", db, "mariadb", "-uroot", "-proot", "-N", "-B", "-e", sql], capture_output=True, text=True)
    rows = json.loads(run.stdout) if run.returncode == 0 and run.stdout.strip().startswith("[") else []
    live_cols: dict[str, dict] = {}
    for r in rows:
        live_cols.setdefault(r["t"], {})[r["c"]] = r["type"]
    ext = {t: {c["column"]: c["type"] for c in v["columns"]} for t, v in load(tag, "schema")["tables"].items()}
    missing = sorted(set(ext) - set(live_cols))
    differ = [(t, c) for t in set(ext) & set(live_cols) for c in ext[t] if ext[t][c] != live_cols[t].get(c)]
    check(bool(live_cols) and not missing and not differ,
          f"every extracted {tag} table and column is in the running database with the same type ({len(ext)} tables; missing {missing[:3]}, differing {differ[:3]})")
    print(f"     tables only in the running database: {sorted(set(live_cols) - set(ext))} (from installed modules)")


def main() -> int:
    tags = sorted((d.name for d in DATA.iterdir() if (d / "release.json").exists()),
                  key=lambda t: tuple(int(x) for x in t[1:].split("_")))
    floors(tags)
    tools()
    known_facts(tags)
    if "--runtime" in sys.argv:
        i = sys.argv.index("--runtime")
        runtime(tags[-1], sys.argv[i + 1], sys.argv[i + 2])
    print(f"\n{'FAILED' if failures else 'PASSED'}: {len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
