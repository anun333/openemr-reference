# OpenEMR reference, generated from the source

Facts about each OpenEMR release (7.0.0 on), read from its source at the release tag:

- **[Upgrade notes](site/index.md):** what changes between each release and the next. PHP and extension requirements, the databases CI tested, the upgrade scripts `sql_upgrade.php` runs, schema changes, modules moved, files removed, settings added, removed or changed.
- **[Database schema](site/schema/index.md):** every table and column as a fresh install creates it, with each table's changes by release.
- **[Settings](site/settings/index.md):** everything under Administration > Config, with defaults, choices and the release each setting appeared in.

Nothing in `site/` is written by hand. It complements the OpenEMR wiki, which has the upgrade *procedure* and the release features; these pages have the version-specific facts the procedure doesn't.

## How each fact is read

| Fact | Read from | How |
|---|---|---|
| PHP, extensions, Node | `composer.json`, `package.json` | at the tag, with `git show` |
| Database version, upgrade scripts | `version.php`, `sql/*_upgrade.sql` | at the tag |
| What CI tested | `ci/*/docker-compose.yml` | the database image; PHP from the OpenEMR image, or the folder name where the image doesn't say (each row says which) |
| Modules | `interface/modules/custom_modules/`, `composer.json` | at the tag |
| Schema | `sql/database.sql` | loaded into MariaDB 11.8 with `sql_mode = ''` (as OpenEMR's installer does) and read back from `information_schema` |
| Settings | `library/globals.inc.php` | parsed with nikic/php-parser, not run; enum-case keys resolved from `src/Services/Globals/*Enum.php` |

## Checks

`gen/check.py` runs before any page is built, and the build stops if it fails:

- **Floors** that a broken extraction would trip (no tables, no settings, no CI setups).
- **Known facts** from outside the pipeline: the Backup page and the Configuration Export/Import setting are in 8.2.0 and gone in 8.3.0 (openemr/openemr#13471), `patient_data.financial_review` is a datetime, the PHP floor never falls, and an enum-keyed setting resolves.
- **Runtime** (`--runtime <openemr-container> <db-container>`), against a running OpenEMR of the latest release. Every extracted setting is in what OpenEMR loads, and every extracted table and column is in its database with the same type.

On 2026-10-11, against a running 8.4.1:
- All 491 settings matched (the running system had 6 more, added by the Care Coordination module).
- All 283 tables matched, with no column differing (the running database also had our own two modules' tables).
- Corrupting one setting and one column type made four checks fail.

## Running it

```
cd tools/settings-extract && composer install    # or with Docker: see .github/workflows/update.yml
OPENEMR_REPO=~/dev/openemr python3 gen/run.py    # new releases only; --all for every release
```

`.github/workflows/update.yml` runs this daily and commits when OpenEMR tags a release.

## Limits

- Patches between releases (`vX_Y_Z_N` tags) and test builds aren't covered.
- What the upgrade scripts do to existing data isn't covered, only the schema they leave.
- Files removed under `interface/` and `portal/` include helper files as well as pages.
- CI-tested databases are what CI ran, not a support statement.
