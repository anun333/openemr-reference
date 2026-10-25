"""Fetches the pinned php-upgrade-catalogue files (gen/catalogue.json) into place: scan.php beside
the tools, php-changes.json with the pre-flight facts. A copy that already matches its pinned
sha256 is left alone, so this needs the network only when the pin changes.

    python3 gen/fetch_catalogue.py
"""

from __future__ import annotations

import hashlib
import json
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PIN = json.loads((ROOT / "gen" / "catalogue.json").read_text())


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    for name, f in PIN["files"].items():
        target = ROOT / f["to"]
        if target.is_file() and sha256(target.read_bytes()) == f["sha256"]:
            print(f"ok   {f['to']}: php-upgrade-catalogue {PIN['version']}'s {name}")
            continue
        with urllib.request.urlopen(f"{PIN['base']}/{name}", timeout=60) as r:
            data = r.read()
        if sha256(data) != f["sha256"]:
            print(f"FAIL {name} from {PIN['base']} doesn't match its pinned sha256; nothing written", file=sys.stderr)
            return 1
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        print(f"ok   {f['to']}: fetched php-upgrade-catalogue {PIN['version']}'s {name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
