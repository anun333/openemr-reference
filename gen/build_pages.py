"""Builds the Markdown site (site/) from the extracted facts in data/.

Nothing on these pages is written by hand: every fact is read from OpenEMR's
source at a release tag, and each page names the tags and files it used.
"""

from __future__ import annotations

import json
import re
import shutil
from datetime import date
from pathlib import Path

from sources import DATA, SITE

WIKI_RELEASE_FEATURES = "https://www.open-emr.org/wiki/index.php/Release_Features"
PAGES_LISTED = 40


# ---------------------------------------------------------------- loading

def load() -> list[dict]:
    out = []
    for d in sorted(DATA.iterdir()):
        if not (d / "release.json").exists():
            continue
        r = json.loads((d / "release.json").read_text())
        r["schema"] = json.loads((d / "schema.json").read_text())["tables"] if (d / "schema.json").exists() else None
        r["settings"] = json.loads((d / "settings.json").read_text())["sections"] if (d / "settings.json").exists() else None
        out.append(r)
    return sorted(out, key=lambda r: tuple(int(x) for x in r["release"].split(".")))


def flat_settings(sections: dict) -> dict[str, dict]:
    return {key: {**field, "section": section} for section, keys in sections.items() for key, field in keys.items()}


# ---------------------------------------------------------------- formatting

def cell(value) -> str:
    if value is None:
        return ""
    if isinstance(value, dict) and "expr" in value:
        text = f"set at run time: `{value['expr']}`"
    elif isinstance(value, (dict, list)):
        text = json.dumps(value, ensure_ascii=False)
    elif isinstance(value, bool):
        text = "yes" if value else "no"
    else:
        text = str(value)
    return text.replace("\\", "\\\\").replace("|", "\\|").replace("\n", " ").replace("\r", " ")


def code(value) -> str:
    text = cell(value)
    return f"`{text}`" if text and not text.startswith("set at run time") else text


def table(headers: list[str], rows: list[list]) -> str:
    out = ["| " + " | ".join(headers) + " |", "|" + "---|" * len(headers)]
    out += ["| " + " | ".join(r) + " |" for r in rows]
    return "\n".join(out)


def stamp(*releases: dict) -> str:
    srcs = ", ".join(f"`{r['tag']}` ({r['commit'][:10]})" for r in releases)
    return (f"\n---\n\n*Generated {date.today().isoformat()} by [openemr-reference](README_LINK) from OpenEMR {srcs}. "
            "Every statement on this page was read from the source at those tags; nothing is written by hand.*\n")


def write(path: Path, text: str) -> None:
    depth = len(path.relative_to(SITE).parts)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.replace("README_LINK", "../" * depth + "README.md").rstrip() + "\n")


def version_key(name: str) -> tuple[int, ...]:
    return tuple(int(x) for x in re.findall(r"\d+", name))


def ci_summary(r: dict) -> str:
    dbs: dict[str, set] = {}
    for row in r["ci"]["rows"]:
        dbs.setdefault(row["database"], set()).add(".".join(row["database_version"].split(".")[:2]))
    php = sorted({row["php"] for row in r["ci"]["rows"] if row["php"]}, key=version_key)
    parts = [f"{'MySQL' if db == 'mysql' else 'MariaDB'} {', '.join(sorted(v, key=version_key))}" for db, v in sorted(dbs.items())]
    return "; ".join(parts) + (f" (PHP {', '.join(php)})" if php else "")


def ci_databases(r: dict) -> set[str]:
    return {f"{'MySQL' if row['database'] == 'mysql' else 'MariaDB'} {'.'.join(row['database_version'].split('.')[:2])}" for row in r["ci"]["rows"]}


def php_min(r: dict) -> str:
    return (r["php"]["requires"] or "").lstrip(">=") or "?"


# ---------------------------------------------------------------- upgrade scripts

def scripts_between(r_from: dict, r_to: dict) -> list[str]:
    """The upgrade scripts sql_upgrade.php runs from one release to the next: those
    starting at or after the old version and ending at or before the new one."""
    old, new = version_key(r_from["release"]), version_key(r_to["release"])
    out = []
    for f in r_to["upgrade_scripts"]["files"]:
        m = re.match(r"(\d+)_(\d+)_(\d+)-to-(\d+)_(\d+)_(\d+)_upgrade\.sql$", f)
        if not m:
            continue
        start, end = tuple(map(int, m.groups()[:3])), tuple(map(int, m.groups()[3:]))
        if start >= old and end <= new:
            out.append(f)
    return sorted(out, key=version_key)


# ---------------------------------------------------------------- pages

def release_page(r: dict, prev: dict | None, nxt: dict | None) -> str:
    v = r["version"]
    rows = sorted({(row["php"] or "?", f"{'MySQL' if row['database'] == 'mysql' else 'MariaDB'} {row['database_version']}",
                    row["web"], row["variant"] or "", row["php_from"] or "") for row in r["ci"]["rows"]},
                  key=lambda x: (version_key(x[0]), x[1], x[2], x[3], x[4]))
    lines = [
        f"# OpenEMR {r['release']}", "",
        f"Tagged `{r['tag']}` on {r['date']} (commit `{r['commit'][:10]}`).", "",
        "## Requirements", "",
        f"- **PHP:** {code(r['php']['requires'])} (from `composer.json`)",
        f"- **PHP extensions:** {', '.join(f'`{e}`' for e in r['extensions']['requires']) or 'none listed in composer.json'}",
        f"- **Node:** {code(r['node']['requires']) if r['node']['requires'] else 'no requirement in package.json'}",
        f"- **Database version** (`v_database` in `version.php`): {v.get('v_database')}", "",
        "## What CI tested this release with", "",
        "From the release's `ci/*/docker-compose.yml`: the database image, and the PHP version from the OpenEMR image (or, where the image doesn't say, from the folder name).", "",
        table(["PHP", "Database", "Web server", "Variant", "PHP read from"], [[*map(cell, row)] for row in rows]), "",
        "## Modules", "",
        f"- **Bundled** (`interface/modules/custom_modules/`): {', '.join(f'`{m}`' for m in r['modules']['bundled']) or 'none'}",
        f"- **Installed by Composer:** {', '.join(f'`{m}`' for m in r['modules']['composer']) or 'none'}", "",
        "## In numbers", "",
        f"- {len(r['schema'] or {})} database tables ([schema](../schema/index.md) for the latest release)",
        f"- {sum(len(s) for s in (r['settings'] or {}).values())} settings in {len(r['settings'] or {})} sections",
        f"- {len(r['pages']['files'])} PHP pages under `interface/` and `portal/`", "",
    ]
    if prev:
        lines.append(f"Upgrading from {prev['release']}: [{prev['release']} to {r['release']}](../upgrade/{prev['release']}-to-{r['release']}.md)")
    if nxt:
        lines.append(f"Upgrading to {nxt['release']}: [{r['release']} to {nxt['release']}](../upgrade/{r['release']}-to-{nxt['release']}.md)")
    return "\n".join(lines) + "\n" + stamp(r)


def schema_changes(a: dict, b: dict) -> tuple[list[str], list[str], dict[str, list[str]]]:
    added = sorted(set(b) - set(a))
    removed = sorted(set(a) - set(b))
    changed: dict[str, list[str]] = {}
    for t in sorted(set(a) & set(b)):
        ca = {c["column"]: c for c in a[t]["columns"]}
        cb = {c["column"]: c for c in b[t]["columns"]}
        notes = [f"added `{c}` {cb[c]['type']}" for c in cb if c not in ca]
        notes += [f"removed `{c}`" for c in ca if c not in cb]
        for c in cb:
            if c in ca:
                for k in ("type", "nullable", "default"):
                    if ca[c][k] != cb[c][k]:
                        notes.append(f"`{c}` {k} {cell(ca[c][k]) or 'none'} → {cell(cb[c][k]) or 'none'}")
        ia, ib = a[t]["indexes"], b[t]["indexes"]
        notes += [f"index `{i}` added ({', '.join(ib[i]['columns'])})" for i in ib if i not in ia]
        notes += [f"index `{i}` removed" for i in ia if i not in ib]
        if notes:
            changed[t] = notes
    return added, removed, changed


def setting_changes(a: dict, b: dict) -> tuple[list[str], list[str], list[tuple[str, str]]]:
    fa, fb = flat_settings(a), flat_settings(b)
    added = sorted(set(fb) - set(fa))
    removed = sorted(set(fa) - set(fb))
    changed = []
    for k in sorted(set(fa) & set(fb)):
        for field, label in (("default", "default"), ("type", "type"), ("section", "moved to section")):
            if fa[k].get(field) != fb[k].get(field):
                changed.append((k, f"{label} {code(fa[k].get(field)) or 'none'} → {code(fb[k].get(field)) or 'none'}"))
        if fa[k].get("options") != fb[k].get("options") and fa[k].get("type") == fb[k].get("type") == "select":
            oa, ob = fa[k].get("options") or {}, fb[k].get("options") or {}
            ka, kb = set(oa if isinstance(oa, dict) else range(len(oa))), set(ob if isinstance(ob, dict) else range(len(ob)))
            if ka != kb:
                changed.append((k, f"choices added {sorted(map(str, kb - ka)) or '[]'}, removed {sorted(map(str, ka - kb)) or '[]'}"))
    return added, removed, changed


def upgrade_page(a: dict, b: dict) -> str:
    out = [f"# Upgrading OpenEMR {a['release']} to {b['release']}", "",
           f"What changes between `{a['tag']}` ({a['date']}) and `{b['tag']}` ({b['date']}) that matters before and after an upgrade. "
           f"The upgrade steps themselves are on the OpenEMR wiki; new features are in the wiki's [Release Features]({WIKI_RELEASE_FEATURES}).", ""]
    checks = []
    if php_min(a) != php_min(b):
        checks.append(f"**PHP must be {php_min(b)} or later** (was {php_min(a)}). Upgrade PHP first.")
    ea, eb = set(a["extensions"]["requires"]), set(b["extensions"]["requires"])
    if eb - ea:
        checks.append(f"**New PHP extensions required:** {', '.join(f'`{e}`' for e in sorted(eb - ea))}.")
    if a["node"]["requires"] != b["node"]["requires"]:
        checks.append(f"**Node requirement:** {code(a['node']['requires']) or 'none'} → {code(b['node']['requires']) or 'none'}.")
    da, db = ci_summary(a), ci_summary(b)
    out += ["## Before you upgrade", ""] + ([f"- {c}" for c in checks] or ["- No change in the PHP version, PHP extensions or Node requirement."])
    dropped = sorted(ci_databases(a) - ci_databases(b), key=lambda d: (d.split()[0], version_key(d)))
    started = sorted(ci_databases(b) - ci_databases(a), key=lambda d: (d.split()[0], version_key(d)))
    if dropped:
        out.append(f"- **CI no longer tests:** {', '.join(dropped)}. If your database is one of these, check it is still supported before upgrading.")
    if started:
        out.append(f"- **CI now also tests:** {', '.join(started)}.")
    out += [f"- **Databases CI tested:** {a['release']}: {da or 'none found'}. {b['release']}: {db or 'none found'}.", ""]

    scripts = scripts_between(a, b)
    out += ["## Database", "",
            f"- Database version {a['version'].get('v_database')} → {b['version'].get('v_database')}.",
            f"- `sql_upgrade.php` runs, from {a['release']}: " + (", ".join(f"`sql/{s}`" for s in scripts) if scripts else "no version-to-version script (none matches these two releases)") + ".", ""]
    added, removed, changed = schema_changes(a["schema"] or {}, b["schema"] or {})
    if added or removed or changed:
        out += [f"Schema, as a fresh install of each creates it: {len(added)} tables added, {len(removed)} removed, {len(changed)} changed.", ""]
        if added:
            out.append("- **New tables:** " + ", ".join(f"[`{t}`](../schema/{t}.md)" for t in added))
        if removed:
            out.append("- **Removed tables:** " + ", ".join(f"`{t}`" for t in removed))
        for t, notes in changed.items():
            out.append(f"- [`{t}`](../schema/{t}.md): " + "; ".join(notes))
        out.append("")
    else:
        out += ["No schema change.", ""]

    ma, mb = a["modules"], b["modules"]
    moved = sorted(m for m in set(ma["bundled"]) - set(mb["bundled"]) if any(c.endswith("/" + m) or c.split("/")[-1].startswith(m) for c in mb["composer"]))
    mod = []
    for m in sorted(set(mb["bundled"]) - set(ma["bundled"])):
        mod.append(f"- Now bundled: `{m}`")
    for m in sorted(set(ma["bundled"]) - set(mb["bundled"])):
        mod.append(f"- No longer bundled: `{m}`" + (" (now installed by Composer)" if m in moved else ""))
    for m in sorted(set(mb["composer"]) - set(ma["composer"])):
        mod.append(f"- Now installed by Composer: `{m}`")
    out += ["## Modules", ""] + (mod or ["No change."]) + [""]

    pa, pb = set(a["pages"]["files"]), set(b["pages"]["files"])
    gone = sorted(pa - pb)
    out += ["## Pages removed", ""]
    if gone:
        out += [f"{len(gone)} PHP files under `interface/` and `portal/` are gone (some were pages; some were included by pages). Bookmarks or links to them will break.", ""]
        out += [f"- `{p}`" for p in gone[:PAGES_LISTED]]
        if len(gone) > PAGES_LISTED:
            out.append(f"- … and {len(gone) - PAGES_LISTED} more")
    else:
        out.append("None.")
    out.append("")

    sa, sr, sc = setting_changes(a["settings"] or {}, b["settings"] or {})
    fb, fa = flat_settings(b["settings"] or {}), flat_settings(a["settings"] or {})
    out += ["## Settings (Administration > Config)", ""]
    if sa or sr or sc:
        if sa:
            out += ["**New:**", ""] + [f"- `{k}` ({cell(fb[k]['section'])}): {cell(fb[k]['label'])}. Default {code(fb[k]['default']) or 'none'}." for k in sa] + [""]
        if sr:
            out += ["**Removed:**", ""] + [f"- `{k}` ({cell(fa[k]['section'])}): {cell(fa[k]['label'])}" for k in sr] + [""]
        if sc:
            out += ["**Changed:**", ""] + [f"- `{k}`: {note}" for k, note in sc] + [""]
    else:
        out += ["No change.", ""]
    out += ["## Not covered here", "",
            "- What the upgrade scripts do to existing data, beyond the schema they leave.",
            "- Changes to `sites/*/sqlconf.php` or `config.php`, and behaviour that changed without a schema or setting change.",
            "- Patches between releases (the wiki's OpenEMR Patches page)."]
    return "\n".join(out) + "\n" + stamp(a, b)


def schema_pages(releases: list[dict]) -> None:
    latest = releases[-1]
    first_seen: dict[str, str] = {}
    for r in releases:
        for t in r["schema"] or {}:
            first_seen.setdefault(t, r["release"])
    rows = []
    for t, info in (latest["schema"] or {}).items():
        since = first_seen[t] if first_seen[t] != releases[0]["release"] else f"{releases[0]['release']} or earlier"
        rows.append([f"[`{t}`]({t}.md)", str(len(info["columns"])), since, cell(info["comment"])])
        history = []
        for prev, cur in zip(releases, releases[1:]):
            pa, pb = prev["schema"] or {}, cur["schema"] or {}
            if t in pb and t not in pa:
                history.append(f"- **{cur['release']}:** table added")
            elif t in pa and t in pb:
                _, _, changed = schema_changes({t: pa[t]}, {t: pb[t]})
                if t in changed:
                    history.append(f"- **{cur['release']}:** " + "; ".join(changed[t]))
        cols = [[f"`{c['column']}`", f"`{c['type']}`", cell(c["nullable"]), code(c["default"]), cell(c["extra"]), cell(c["comment"])] for c in info["columns"]]
        idx = [[f"`{i}`", "yes" if x["unique"] else "", ", ".join(f"`{c}`" for c in x["columns"])] for i, x in info["indexes"].items()]
        write(SITE / "schema" / f"{t}.md", "\n".join([
            f"# `{t}`", "", f"As OpenEMR {latest['release']}'s `sql/database.sql` creates it. Engine {info['engine']}." + (f" {cell(info['comment'])}" if info["comment"] else ""), "",
            "## Columns", "", table(["Column", "Type", "Null", "Default", "Extra", "Comment"], cols), "",
            "## Indexes", "", table(["Index", "Unique", "Columns"], idx), "",
            f"## Changes since {releases[0]['release']}", "", *(history or ["None."]),
        ]) + "\n" + stamp(latest))
    gone = sorted({t for r in releases for t in (r["schema"] or {})} - set(latest["schema"] or {}))
    write(SITE / "schema" / "index.md", "\n".join([
        f"# Database schema, OpenEMR {latest['release']}", "",
        f"{len(rows)} tables, as a fresh install creates them (`sql/database.sql` loaded into MariaDB and read back). "
        "Modules add their own tables when installed; those aren't here.", "",
        table(["Table", "Columns", "Since", "Comment"], rows), "",
        f"## Removed since {releases[0]['release']}", "", *([f"- `{t}`" for t in gone] or ["None."]),
    ]) + "\n" + stamp(latest))


def settings_page(releases: list[dict]) -> None:
    latest = releases[-1]
    first_seen: dict[str, str] = {}
    for r in releases:
        for k in flat_settings(r["settings"] or {}):
            first_seen.setdefault(k, r["release"])
    out = [f"# Settings, OpenEMR {latest['release']}", "",
           "Every setting under Administration > Config, from `library/globals.inc.php`. "
           "A default shown as *set at run time* is computed when OpenEMR starts. Modules add their own settings when they're enabled "
           "(Care Coordination adds six in its own section, for example); those aren't here.", ""]
    for section, keys in (latest["settings"] or {}).items():
        out += [f"## {section}", ""]
        rows = []
        for k, f in keys.items():
            t = f["type"]
            if t == "select" and f.get("options"):
                opts = f["options"]
                pairs = opts.items() if isinstance(opts, dict) else enumerate(opts)
                t = "one of: " + "; ".join(f"`{key}` {cell(label)}" for key, label in pairs)
            since = first_seen[k] if first_seen[k] != releases[0]["release"] else ""
            rows.append([f"`{k}`", cell(f["label"]), cell(t), code(f["default"]), cell(f["description"]), since])
        out += [table(["Setting", "Label", "Type", "Default", "Description", "New in"], rows), ""]
    gone = []
    for prev, cur in zip(releases, releases[1:]):
        for k in sorted(set(flat_settings(prev["settings"] or {})) - set(flat_settings(cur["settings"] or {}))):
            gone.append(f"- `{k}`: removed in {cur['release']}")
    out += [f"## Removed since {releases[0]['release']}", "", *(gone or ["None."])]
    write(SITE / "settings" / "index.md", "\n".join(out) + "\n" + stamp(latest))


def index_page(releases: list[dict]) -> None:
    rows = []
    for prev, r in zip([None, *releases], releases):
        up = f"[from {prev['release']}](upgrade/{prev['release']}-to-{r['release']}.md)" if prev else ""
        rows.append([f"[{r['release']}](releases/{r['release']}.md)", r["date"], php_min(r), cell(ci_summary(r)),
                     str(r["version"].get("v_database")), str(len(r["schema"] or {})), str(sum(len(s) for s in (r["settings"] or {}).values())), up])
    write(SITE / "index.md", "\n".join([
        "# OpenEMR reference, generated from the source", "",
        "Facts about each OpenEMR release, read from its source at the release tag: what it needs, what CI tested it with, "
        "what changes when you upgrade, its database schema and its settings. It is regenerated when OpenEMR tags a release, "
        "so it doesn't go stale, and nothing on it is written by hand.", "",
        "- [Upgrade notes](#releases): what changes between each release and the next",
        "- [Database schema](schema/index.md)",
        "- [Settings](settings/index.md)", "",
        "## Releases", "",
        table(["Release", "Tagged", "PHP at least", "Databases CI tested", "DB version", "Tables", "Settings", "Upgrade notes"], rows),
    ]) + "\n" + stamp(releases[-1]))


def main() -> None:
    releases = load()
    # Only what this builder writes; site/preflight/ belongs to build_preflight.py.
    for part in ("releases", "upgrade", "schema", "settings"):
        shutil.rmtree(SITE / part, ignore_errors=True)
    (SITE / "index.md").unlink(missing_ok=True)
    index_page(releases)
    for i, r in enumerate(releases):
        write(SITE / "releases" / f"{r['release']}.md", release_page(r, releases[i - 1] if i else None, releases[i + 1] if i + 1 < len(releases) else None))
    for a, b in zip(releases, releases[1:]):
        write(SITE / "upgrade" / f"{a['release']}-to-{b['release']}.md", upgrade_page(a, b))
    schema_pages(releases)
    settings_page(releases)
    print(f"{sum(1 for _ in SITE.rglob('*.md'))} pages in {SITE}")


if __name__ == "__main__":
    main()
