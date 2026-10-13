"""Writes the compact per-release facts the pre-flight check reads (site/preflight/<release>.json):
requirements, CI-tested PHP and databases, modules, settings (key, section, label, default),
PHP files, upgrade scripts, Composer install paths and page assets; and, for the install
doctor, the files each package ships from git (site/preflight/<release>-files.json).
Built from data/, like the pages.
"""

from __future__ import annotations

import json

from build_pages import load
from sources import DATA, SITE


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
        "ci_php": sorted({row["php"] for row in r["ci"]["rows"] if row["php"]}, key=lambda v: tuple(map(int, v.split(".")))),
        "ci_databases": sorted({(row["database"], ".".join(row["database_version"].split(".")[:2])) for row in r["ci"]["rows"]}),
        "modules": {"bundled": r["modules"]["bundled"], "composer": r["modules"]["composer"]},
        "settings": settings,
        "pages": r["pages"]["files"],
        "upgrade_scripts": r["upgrade_scripts"]["files"],
    }


def grouped(files: list[str]) -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    for f in files:
        d, _, name = f.rpartition("/")
        out.setdefault(d, []).append(name)
    return out


def grouped_hashes(hashes: dict[str, str]) -> dict[str, dict[str, str]]:
    """Each shipped file's git blob hash prefix, by directory (extract_hashes.py): for telling which of
    OpenEMR's own files were changed on a server. In <release>-hashes.json, apart from the release
    facts, so only the tools that compare contents download them."""
    out: dict[str, dict[str, str]] = {}
    for path, sha in sorted(hashes.items()):
        d, _, name = path.rpartition("/")
        out.setdefault(d, {})[name] = sha
    return out


def package(r: dict) -> tuple[dict, dict[str, dict]]:
    """The doctor's half: Composer install paths and page assets go in the release facts
    (each patch's under "patches"); the file lists go in <release>-files.json and
    <release>-p<N>-files.json, grouped by directory to keep them small."""
    pk = json.loads((DATA / r["tag"] / "package.json").read_text())
    up = json.loads((DATA / r["tag"] / "upgrades.json").read_text())
    extra = {"composer": [[c["path"], c["type"]] for c in pk["composer"]], "assets": pk["assets"], "patches": {},
             "upgrade_alters": {name: s["alters"] for name, s in up["scripts"].items()},
             "package_unpacked_bytes": up["package_unpacked_bytes"]}
    files = {f"{r['release']}-files": {"release": r["release"], "dirs": grouped(pk["files"])}}
    hashes = DATA / r["tag"] / "hashes.json"
    if hashes.exists():
        files[f"{r['release']}-hashes"] = {"release": r["release"], "tag": r["tag"], "dirs": grouped_hashes(json.loads(hashes.read_text())["hashes"])}
    for path in sorted((DATA / r["tag"]).glob("package-p*.json"), key=lambda p: int(p.stem.split("-p")[1])):
        n = path.stem.split("-p")[1]
        pp = json.loads(path.read_text())
        extra["patches"][n] = {"tag": pp["tag"], "composer": [[c["path"], c["type"]] for c in pp["composer"]], "assets": pp["assets"]}
        files[f"{r['release']}-p{n}-files"] = {"release": r["release"], "patch": int(n), "dirs": grouped(pp["files"])}
        ph = DATA / r["tag"] / f"hashes-p{n}.json"
        if ph.exists():
            files[f"{r['release']}-p{n}-hashes"] = {"release": r["release"], "patch": int(n), "tag": pp["tag"],
                                                    "dirs": grouped_hashes(json.loads(ph.read_text())["hashes"])}
    return extra, files


def main() -> None:
    releases = load()
    out = SITE / "preflight"
    out.mkdir(parents=True, exist_ok=True)
    for r in releases:
        extra, files = package(r)
        (out / f"{r['release']}.json").write_text(json.dumps({**facts(r), **extra}, separators=(",", ":"), ensure_ascii=False) + "\n")
        for name, data in files.items():
            (out / f"{name}.json").write_text(json.dumps(data, separators=(",", ":"), ensure_ascii=False) + "\n")
    (out / "releases.json").write_text(json.dumps([r["release"] for r in releases]) + "\n")
    print(f"{len(releases)} release fact files in {out}")


if __name__ == "__main__":
    main()
