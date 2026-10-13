"""Each shipped file's git blob hash at every release and patch tag (the first 10 hex digits), so
a tool on a server can tell which of OpenEMR's own files were changed there.

A file whose git blob hash (sha1 of "blob <size>\\0<content>") matches is byte for byte what the
release shipped. Checked 2026-10-13 on the official 8.4.1 image: all 9,060 files git tracks at
v8_4_1 that the image has match; none differs. So a file that doesn't match was changed locally.

The files are the ones the package ships (data/<tag>/package.json and package-p<N>.json, from
extract_package.py), read with `git ls-tree -r -z`. Writes data/<tag>/hashes.json and
data/<tag>/hashes-p<N>.json.
"""

from __future__ import annotations

import json
import sys

from sources import DATA, git, patches, releases

PREFIX = 10


def blob_hashes(tag: str) -> dict[str, str]:
    out = {}
    for entry in bytes(git("ls-tree", "-r", "-z", tag, binary=True)).split(b"\0"):
        if not entry:
            continue
        meta, path = entry.split(b"\t", 1)
        _mode, kind, sha = meta.split()
        if kind == b"blob":
            out[path.decode("utf-8", "surrogateescape")] = sha.decode()[:PREFIX]
    return out


def write(tag: str, package: str, target: str) -> tuple[int, int]:
    files = json.loads((DATA / tag / package).read_text())["files"]
    pk_tag = json.loads((DATA / tag / package).read_text()).get("tag", tag)
    hashes = blob_hashes(pk_tag)
    found = {f: hashes[f] for f in files if f in hashes}
    (DATA / tag / target).write_text(json.dumps({"tag": pk_tag, "hashes": found}, separators=(",", ":")) + "\n")
    return len(found), len(files)


def main() -> None:
    for release in releases():
        if not (DATA / release.tag / "package.json").exists():
            continue
        if "--all" not in sys.argv and (DATA / release.tag / "hashes.json").exists():
            continue
        n, of = write(release.tag, "package.json", "hashes.json")
        line = f"{release.name:7} {n} of {of} shipped files hashed"
        for number, patch in patches(release):
            if (DATA / release.tag / f"package-p{number}.json").exists():
                pn, pof = write(release.tag, f"package-p{number}.json", f"hashes-p{number}.json")
                line += f"; patch {number}: {pn} of {pof}"
        print(line)


if __name__ == "__main__":
    main()
