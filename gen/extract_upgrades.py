"""What each upgrade script touches, for the pre-flight check's room check: the tables it
alters (which MariaDB or MySQL may rebuild, needing free space in its data directory as large
as the table) and the tables it only writes rows to. Read from sql/*_upgrade.sql at each
release tag, so the facts for a target release are that release's own scripts.

Also the unpacked size of the release package, where the release has a tarball on GitHub
(8.2.0 on), by listing it as it downloads; nothing is kept.

Writes data/<tag>/upgrades.json.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import tarfile
import urllib.request

from sources import DATA, Release, files, releases, show, source

SCRIPT = re.compile(r"^sql/(\d+)_(\d+)_(\d+)-to-(\d+)_(\d+)_(\d+)_upgrade\.sql$")
NAME = r"`?([A-Za-z0-9_]+)`?"
ALTERS = [
    re.compile(r"\bALTER\s+TABLE\s+" + NAME, re.I),
    re.compile(r"^#(?:IfMissingColumn|IfColumn|IfNotColumnType|IfNotColumnTypeDefault|IfIndex|IfNotIndex|IfTableEngine|IfInnoDBMigrationNeeded)\s+" + NAME, re.I | re.M),
    re.compile(r"\bCREATE\s+(?:UNIQUE\s+)?INDEX\s+\S+\s+ON\s+" + NAME, re.I),
]
WRITES = [
    re.compile(r"\bINSERT\s+(?:IGNORE\s+)?INTO\s+" + NAME, re.I),
    re.compile(r"\bREPLACE\s+INTO\s+" + NAME, re.I),
    re.compile(r"\bUPDATE\s+" + NAME + r"\s+SET\b", re.I),
    re.compile(r"\bDELETE\s+FROM\s+" + NAME, re.I),
]
CREATES = re.compile(r"\bCREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?" + NAME, re.I)


def tables(text: str, patterns: list[re.Pattern]) -> list[str]:
    found = set()
    for p in patterns:
        found.update(m.group(1) for m in p.finditer(text))
    return sorted(found)


def scripts(release: Release) -> dict:
    out = {}
    for path in files(release, "sql"):
        m = SCRIPT.match(path)
        if not m:
            continue
        text = show(release, path) or ""
        body = "\n".join(l for l in text.splitlines() if not l.lstrip().startswith("--"))
        created = set(tables(body, [CREATES]))
        out[path.split("/", 1)[1]] = {
            "from": ".".join(m.group(1, 2, 3)),
            "to": ".".join(m.group(4, 5, 6)),
            # A table the script creates is new and empty; altering it needs no room.
            "alters": [t for t in tables(body, ALTERS) if t not in created],
            "creates": sorted(created),
            "writes": tables(body, WRITES),
        }
    return out


def unpacked_bytes(release: Release) -> int | None:
    url = f"https://github.com/openemr/openemr/releases/download/{release.tag}/openemr-{release.name}.tar.gz"
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "openemr-reference"}), timeout=60) as r:
            with tarfile.open(fileobj=r, mode="r|gz") as tar:
                return sum(m.size for m in tar if m.isfile())
    except Exception:
        return None


def main() -> None:
    for release in releases():
        target = DATA / release.tag / "upgrades.json"
        if "--all" not in sys.argv and target.exists():
            continue
        found = scripts(release)
        size = unpacked_bytes(release)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps({"release": release.name, "scripts": found, "package_unpacked_bytes": size,
                                      "source": source(release, "sql/*_upgrade.sql; the GitHub release tarball")}, indent=1) + "\n")
        altered = sum(len(s["alters"]) for s in found.values())
        print(f"{release.name:7} {len(found):2} upgrade scripts, {altered:4} table alterations, package "
              + (f"{size / 1048576:.0f} MB unpacked" if size else "size unknown (no GitHub tarball)"))


if __name__ == "__main__":
    main()
