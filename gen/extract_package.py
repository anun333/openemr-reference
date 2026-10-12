"""What a release package should contain: the files it ships from git, and where Composer
puts each package. The install doctor compares an install with this to find files that
never arrived (an interrupted upload or copy, a patch unpacked in the wrong place).

The package is `git archive` of the tag, which honours the tag's export-ignore rules, plus
`composer install --no-dev` and the npm build (tools/release/src/PackageAssembler.php at
8.4.1). The prune step afterwards deletes only vendor and asset clutter (build.xml), so
every file git archive lists is in the package: checked against the 8.4.1 tarball. Before
8.1.0, .gitattributes didn't export-ignore tests/, ci/ and .github/, so those releases'
lists include them; the doctor treats such folders as optional anyway.

Also the built assets every page loads (from config/config.yaml).

Writes data/<tag>/package.json, and data/<tag>/package-p<N>.json for each patch tag
(vX_Y_Z_N). Needs PyYAML.
"""

from __future__ import annotations

import json
import subprocess
import sys
import tarfile

import yaml

from sources import DATA, REPO, Release, patches, releases, show, source


def archived_files(release: Release) -> list[str]:
    proc = subprocess.Popen(["git", "-C", str(REPO), "archive", "--format=tar", release.tag], stdout=subprocess.PIPE)
    names = []
    with tarfile.open(fileobj=proc.stdout, mode="r|") as tar:
        for member in tar:
            if member.isfile() or member.issym():
                names.append(member.name)
    if proc.wait() != 0:
        raise SystemExit(f"{release.tag}: git archive failed")
    return sorted(names)


def composer_packages(release: Release) -> list[dict]:
    """Non-dev packages from composer.lock, with the directory each is installed to."""
    lock = json.loads(show(release, "composer.lock") or "{}")
    out = []
    for pkg in lock.get("packages", []):
        kind = pkg.get("type", "library")
        if kind == "metapackage":
            continue
        if kind == "openemr-module":
            path = "interface/modules/custom_modules/" + pkg["name"].split("/", 1)[1]
        else:
            path = "vendor/" + pkg["name"]
        out.append({"name": pkg["name"], "version": pkg.get("version"), "type": kind, "path": path})
    return sorted(out, key=lambda p: p["name"])


def page_assets(release: Release) -> list[str]:
    """Built files every page loads (config/config.yaml entries with autoload: true under
    public/assets). They come from the npm build, not git, so a tree that skipped the
    build has none of them. The theme stylesheet is chosen at run time, so the doctor
    checks it separately."""
    config = yaml.safe_load(show(release, "config/config.yaml") or "{}") or {}
    out = []
    for asset in (config.get("assets") or {}).values():
        base = str(asset.get("basePath") or "")
        if not asset.get("autoload") or not base.startswith("%assets_static_relative%/"):
            continue
        base = "public/assets/" + base.split("/", 1)[1]
        for key in ("script", "link"):
            names = asset.get(key)
            for name in names if isinstance(names, list) else [names]:
                if isinstance(name, dict):
                    name = name.get("src")
                if name:
                    out.append(base + str(name))
    return sorted(set(out))


def write(release: Release, target) -> str:
    files = archived_files(release)
    packages = composer_packages(release)
    assets = page_assets(release)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps({
        "release": release.name,
        "tag": release.tag,
        "files": files,
        "composer": packages,
        "assets": assets,
        "source": source(release, "git archive (export-ignore applied) and composer.lock"),
    }, indent=0) + "\n")
    return f"{len(files):5} files from git, {len(packages):3} Composer packages, {len(assets)} page assets"


def main() -> None:
    """The release, and each of its patches: a patched install has the patch tag's files
    (Docker images are built from it; a patch zip adds and overwrites, and never deletes)."""
    for release in releases():
        target = DATA / release.tag / "package.json"
        if "--all" in sys.argv or not target.exists():
            print(f"{release.name:7} {write(release, target)}")
        for n, patch in patches(release):
            target = DATA / release.tag / f"package-p{n}.json"
            if "--all" in sys.argv or not target.exists():
                print(f"{release.name:7} patch {n}: {write(patch, target)}")


if __name__ == "__main__":
    main()
