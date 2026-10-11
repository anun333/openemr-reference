"""Per-release settings (Administration > Config): read from library/globals.inc.php
by tools/settings-extract, which parses the file without running it.

Writes data/<tag>/settings.json. Needs Docker (the composer:2 image, for PHP).
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from sources import DATA, ROOT, Release, files, releases, show, source

TOOL = ROOT / "tools" / "settings-extract"
ENUM_DIR = "src/Services/Globals"


def extract(release: Release) -> dict:
    text = show(release, "library/globals.inc.php")
    if text is None:
        raise SystemExit(f"{release.tag}: no library/globals.inc.php")
    enums = [f for f in files(release, ENUM_DIR) if f.endswith("Enum.php")]
    with tempfile.TemporaryDirectory() as tmp:
        Path(tmp, "globals.inc.php").write_text(text)
        for enum in enums:
            Path(tmp, Path(enum).name).write_text(show(release, enum) or "")
        run = subprocess.run(
            ["docker", "run", "--rm", "--user", f"{os.getuid()}:{os.getgid()}", "-v", f"{TOOL}:/t:ro", "-v", f"{tmp}:/in:ro",
             "--entrypoint", "php", "composer:2", "/t/extract.php", "/in/globals.inc.php", *[f"/in/{Path(e).name}" for e in enums]],
            capture_output=True, text=True,
        )
    if run.returncode != 0:
        raise SystemExit(f"{release.tag}: settings extraction failed\n{run.stderr[-2000:]}")
    return {"release": release.name, "sections": json.loads(run.stdout), "source": source(release, "library/globals.inc.php"),
            "enum_files": enums}


def main() -> None:
    for release in releases():
        if "--all" not in sys.argv and (DATA / release.tag / "settings.json").exists():
            continue
        facts = extract(release)
        (DATA / release.tag).mkdir(parents=True, exist_ok=True)
        (DATA / release.tag / "settings.json").write_text(json.dumps(facts, indent=1, ensure_ascii=False) + "\n")
        sections = facts["sections"]
        print(f"{release.name:7} {len(sections):3} sections {sum(len(v) for v in sections.values()):4} settings")


if __name__ == "__main__":
    main()
