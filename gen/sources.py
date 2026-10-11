"""Reads OpenEMR's source at its release tags straight from git, with no checkout.

Every fact the generators record names the tag and file it came from, so a page
can say where each statement was read.
"""

from __future__ import annotations

import os
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path

REPO = Path(os.environ.get("OPENEMR_REPO", Path.home() / "dev" / "openemr"))
ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
SITE = ROOT / "site"
FIRST = (7, 0, 0)
RELEASE_TAG = re.compile(r"^v(\d+)_(\d+)_(\d+)$")


@dataclass(frozen=True)
class Release:
    tag: str
    version: tuple[int, int, int]
    commit: str
    date: str

    @property
    def name(self) -> str:
        return ".".join(map(str, self.version))


def git(*args: str, binary: bool = False) -> str | bytes:
    out = subprocess.run(["git", "-C", str(REPO), *args], capture_output=True, check=True)
    return out.stdout if binary else out.stdout.decode("utf-8", "replace")


def releases() -> list[Release]:
    """The release tags (vX_Y_Z, not patches or test builds) from FIRST on, oldest first."""
    found = []
    for tag in str(git("tag", "-l", "v*")).split():
        m = RELEASE_TAG.match(tag)
        if not m:
            continue
        version = tuple(int(x) for x in m.groups())
        if version < FIRST:
            continue
        commit, date = str(git("log", "-1", "--format=%H %cs", tag)).split()
        found.append(Release(tag, version, commit, date))  # type: ignore[arg-type]
    return sorted(found, key=lambda r: r.version)


def show(release: Release, path: str) -> str | None:
    try:
        return str(git("show", f"{release.tag}:{path}"))
    except subprocess.CalledProcessError:
        return None


def files(release: Release, path: str = "") -> list[str]:
    out = str(git("ls-tree", "-r", "--name-only", release.tag, "--", path)) if path else str(git("ls-tree", "-r", "--name-only", release.tag))
    return out.split("\n") if out.strip() else []


def dirs(release: Release, path: str) -> list[str]:
    out = str(git("ls-tree", "-d", "--name-only", release.tag, "--", path.rstrip("/") + "/"))
    return [p.rsplit("/", 1)[-1] for p in out.split("\n") if p.strip()]


def source(release: Release, path: str) -> dict:
    """Provenance for a fact: the tag, its commit and the file."""
    return {"tag": release.tag, "commit": release.commit[:10], "file": path}
