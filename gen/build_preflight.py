"""Writes the compact per-release facts the pre-flight check reads (site/preflight/<release>.json):
requirements, CI-tested databases, modules, settings (key, section, label, default),
PHP files, and upgrade scripts. Built from data/, like the pages.
"""

from __future__ import annotations

import json

from build_pages import load
from sources import SITE


def facts(r: dict) -> dict:
    settings = {}
    for section, keys in (r["settings"] or {}).items():
        for key, f in keys.items():
            default = f.get("default")
            settings[key] = {"section": section, "label": f.get("label") if isinstance(f.get("label"), str) else None,
                             "default": default if not isinstance(default, dict) else None, "default_at_run_time": isinstance(default, dict)}
    return {
        "release": r["release"], "tag": r["tag"], "commit": r["commit"], "date": r["date"],
        "php": (r["php"]["requires"] or "").lstrip(">="),
        "extensions": r["extensions"]["requires"],
        "node": r["node"]["requires"],
        "v_database": r["version"].get("v_database"),
        "ci_databases": sorted({(row["database"], ".".join(row["database_version"].split(".")[:2])) for row in r["ci"]["rows"]}),
        "modules": {"bundled": r["modules"]["bundled"], "composer": r["modules"]["composer"]},
        "settings": settings,
        "pages": r["pages"]["files"],
        "upgrade_scripts": r["upgrade_scripts"]["files"],
    }


def main() -> None:
    releases = load()
    out = SITE / "preflight"
    out.mkdir(parents=True, exist_ok=True)
    for r in releases:
        (out / f"{r['release']}.json").write_text(json.dumps(facts(r), separators=(",", ":"), ensure_ascii=False) + "\n")
    (out / "releases.json").write_text(json.dumps([r["release"] for r in releases]) + "\n")
    print(f"{len(releases)} release fact files in {out}")


if __name__ == "__main__":
    main()
