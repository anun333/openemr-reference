"""Extracts facts for any release not yet in data/, checks them, and rebuilds the site.

    python3 gen/run.py            # new releases only
    python3 gen/run.py --all      # every release again

Needs git (OPENEMR_REPO pointing at an openemr/openemr clone with its tags) and Docker.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent

for step in ("extract_release.py", "extract_package.py", "extract_hashes.py", "extract_upgrades.py", "extract_settings.py", "extract_schema.py", "check.py", "build_pages.py", "build_preflight.py"):
    print(f"== {step}", flush=True)
    args = sys.argv[1:] if step.startswith("extract") else []
    if subprocess.run([sys.executable, str(HERE / step), *args]).returncode != 0:
        sys.exit(f"{step} failed; the site was not rebuilt")
