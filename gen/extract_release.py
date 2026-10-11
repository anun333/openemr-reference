"""Per-release facts: requirements, database version, upgrade scripts, the PHP and
database versions CI tested, bundled modules, and user-facing pages.

Writes data/<tag>/release.json.
"""

from __future__ import annotations

import json
import re
import sys

from sources import DATA, Release, dirs, files, releases, show, source

DB_IMAGE = re.compile(r"image:\s*['\"]?(mariadb|mysql):([0-9][0-9.]*)")
PHP_IN_IMAGE = re.compile(r"image:\s*['\"]?[^\s'\"]*?(?:php-|php-fpm:|php:)(\d+\.\d+)")
FOLDER = re.compile(r"^(apache|nginx)_(\d)(\d)_(\d+)")


def version_php(text: str) -> dict:
    out = {}
    for name in ("v_major", "v_minor", "v_patch", "v_realpatch", "v_tag", "v_database", "v_acl", "v_js_includes"):
        m = re.search(r"^\$" + name + r"\s*=\s*'?([^';]*)'?\s*;", text, re.M)
        if m:
            out[name] = int(m.group(1)) if m.group(1).isdigit() else m.group(1)
    return out


def ci_matrix(release: Release) -> list[dict]:
    """What CI ran: one entry per ci/<folder> with a database image."""
    rows = []
    for folder in dirs(release, "ci"):
        compose = show(release, f"ci/{folder}/docker-compose.yml")
        if compose is None:
            continue
        db = DB_IMAGE.search(compose)
        if db is None:
            continue
        php = PHP_IN_IMAGE.search(compose)
        php_from = "image"
        if php is None:
            m = FOLDER.match(folder)
            php_version = f"{m.group(2)}.{m.group(3)}" if m else None
            php_from = "folder name" if m else None
        else:
            php_version = php.group(1)
        rows.append({
            "folder": folder,
            "web": "nginx" if folder.startswith("nginx") else "apache",
            "php": php_version,
            "php_from": php_from,
            "database": db.group(1),
            "database_version": db.group(2),
            "variant": "upgrade" if folder.endswith("_upgrade") else ("redis" if "redis" in folder else None),
        })
    return rows


def extract(release: Release) -> dict:
    composer = json.loads(show(release, "composer.json") or "{}")
    require = composer.get("require", {})
    package = json.loads(show(release, "package.json") or "{}")
    version = version_php(show(release, "version.php") or "")
    sql = sorted(f.split("/", 1)[1] for f in files(release, "sql") if f.endswith("_upgrade.sql") and "/" not in f.split("/", 1)[1])
    pages = sorted(f for f in files(release, "interface") + files(release, "portal") if f.endswith(".php"))
    return {
        "release": release.name,
        "tag": release.tag,
        "commit": release.commit,
        "date": release.date,
        "php": {"requires": require.get("php"), "platform": composer.get("config", {}).get("platform", {}).get("php"),
                "source": source(release, "composer.json")},
        "extensions": {"requires": sorted(k[4:] for k in require if k.startswith("ext-")), "source": source(release, "composer.json")},
        "node": {"requires": (package.get("engines") or {}).get("node"), "source": source(release, "package.json")},
        "version": {**version, "source": source(release, "version.php")},
        "upgrade_scripts": {"files": sql, "source": source(release, "sql/")},
        "ci": {"rows": ci_matrix(release), "source": source(release, "ci/")},
        "modules": {
            "bundled": sorted(dirs(release, "interface/modules/custom_modules")),
            "composer": sorted(k for k in require if "/" in k and k.split("/", 1)[1].startswith("oe-module") and not k.endswith("installer-plugin")),
            "source": source(release, "interface/modules/custom_modules/ and composer.json"),
        },
        "pages": {"files": pages, "source": source(release, "interface/ and portal/")},
    }


def main() -> None:
    for release in releases():
        if "--all" not in sys.argv and (DATA / release.tag / "release.json").exists():
            continue
        out = DATA / release.tag
        out.mkdir(parents=True, exist_ok=True)
        facts = extract(release)
        (out / "release.json").write_text(json.dumps(facts, indent=1, sort_keys=False) + "\n")
        ci = facts["ci"]["rows"]
        print(f"{release.name:7} {release.date} php {facts['php']['requires']:8} db v{facts['version'].get('v_database')} "
              f"upgrade scripts {len(facts['upgrade_scripts']['files'])} ci {len(ci)} pages {len(facts['pages']['files'])} "
              f"modules {len(facts['modules']['bundled'])}+{len(facts['modules']['composer'])}")


if __name__ == "__main__":
    main()
