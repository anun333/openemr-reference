# OpenEMR reference, generated from the source

Facts about each OpenEMR release (7.0.0 on), read from its source at the release tag:

- **[Upgrade notes](site/index.md):** what changes between each release and the next. PHP and extension requirements, the databases CI tested, the upgrade scripts `sql_upgrade.php` runs, schema changes, modules moved, files removed, settings added, removed or changed.
- **[Database schema](site/schema/index.md):** every table and column as a fresh install creates it, with each table's changes by release.
- **[Settings](site/settings/index.md):** everything under Administration > Config, with defaults, choices and the release each setting appeared in.

- **[Upgrade pre-flight check](preflight/openemr-preflight.php):** run it on a server before upgrading, and it lists what to fix first.
- **[Upgrade rehearsal](preflight/openemr-rehearse.sh):** run the upgrade on a copy of the site's database in Docker first, and it reports what the upgrade did to the schema and to the data.
- **[Upgrade](preflight/openemr-upgrade.sh):** for an install from the release tarball: backs up, unpacks the new release beside the old, upgrades the databases, checks with the doctor, switches, and rolls back on request.
- **[Install doctor](preflight/openemr-doctor.php):** run it when an install shows a blank page, an error 500, a broken login or missing documents, and it names the cause.

Nothing in `site/` is written by hand. It complements the OpenEMR wiki, which has the upgrade *procedure* and the release features; these pages have the version-specific facts the procedure doesn't. A daily job adds each new OpenEMR release.

## Download

The two PHP tools and the upgrade script run on the server; the rehearsal runs on any machine with Docker:

- [openemr-doctor.php](https://github.com/anun333/openemr-reference/releases/latest/download/openemr-doctor.php)
- [openemr-preflight.php](https://github.com/anun333/openemr-reference/releases/latest/download/openemr-preflight.php)
- [openemr-rehearse.sh](https://github.com/anun333/openemr-reference/releases/latest/download/openemr-rehearse.sh) and [openemr-utf8mb4.sql](https://github.com/anun333/openemr-reference/releases/latest/download/openemr-utf8mb4.sql)
- [openemr-upgrade.sh](https://github.com/anun333/openemr-reference/releases/latest/download/openemr-upgrade.sh), for installs from the release tarball
- [SHA256SUMS](https://github.com/anun333/openemr-reference/releases/latest/download/SHA256SUMS), to check them (`sha256sum -c SHA256SUMS --ignore-missing`)

**What they do and don't do.** The doctor and the pre-flight check only read: nothing in the install or its database is changed. They print no passwords, keys or setting values. The only network access is downloading this repository's facts for your release (about 300 KB) from `raw.githubusercontent.com`; nothing about your server is sent anywhere. On a server without internet, copy `site/preflight/` across and pass `--facts=` that folder. The rehearsal never touches the live site: it works on a copy of a database dump, in containers it deletes afterwards, and downloads only the official OpenEMR and MariaDB images and the same facts. `openemr-utf8mb4.sql` only prints statements; nothing changes until you run them. `openemr-upgrade.sh` does change the server, in the order described below, after backing up, and keeps a way back. Each is a single readable file: read it before you run it.

Wrong answers are bugs: please [open an issue](https://github.com/anun333/openemr-reference/issues) with the output (it contains no patient data).

## Upgrade pre-flight check

```
php openemr-preflight.php --openemr=/var/www/html/openemr [--target=8.4.1] [--facts=DIR]
```

Run it with the PHP the web server uses. It only reads: nothing in the install or its database changes, and no password or setting value is printed. It checks:

| Check | Fails or warns when |
|---|---|
| PHP | older than the target needs (fail) |
| PHP extensions | one the target's `composer.json` requires isn't loaded (fail) |
| Database server | not a version CI tested the target with (warn) |
| Previous upgrade | the `version` table and `version.php` disagree: an earlier `sql_upgrade.php` didn't finish, or code was rolled back without the database (fail) |
| Settings | the target removes a setting this install changed from its default (warn) |
| Modules | a module moved to Composer, or isn't part of the target (warn) |
| Custom menus | a menu assigned to users links to a file the target removed (warn) |
| Room | for each disk involved, less free than the backup (database and documents) and the new release need, plus 20% (fail); the backup disk is chosen with `--backup-dir` |
| Room in the database | the database's data folder has less free space than the largest table the upgrade scripts alter, plus 20%, which a rebuild of it can take (fail); where the folder isn't visible, it says how much to check for |
| Local changes | files OpenEMR ships that were changed on this server, compared by git hash with the release or patch as published (warn) |
| Memory | under 1 GB available, on Linux (warn) |

It then prints **the plan, in order, from what it found**: the backup (including the encryption keys), the PHP and extension changes and the database server upgrade the target needs, the upgrade itself beside the old folder, the check with the install doctor, and the way back. When the current release was never tested on the PHP the target needs, it says to change PHP and upgrade in one maintenance window, since the old version may not run on the new PHP. Then it lists the upgrade scripts `sql_upgrade.php` will run and the upgrade notes for each step. It runs on PHP 7.4 and later, since it runs on the current install's PHP. Exit code 1 if any check fails.

`preflight/test_preflight.sh` builds a throwaway OpenEMR 7.0.3 (official image, MariaDB 10.6) and checks seven cases against the newest release:
- as installed: missing `bcmath` and `imagick`, MariaDB 10.6 no longer tested, ClaimRev moved to Composer;
- a user assigned a menu that links to the removed Backup page;
- a removed setting turned on;
- a half-finished earlier upgrade;
- the same install reached through an `xampp/` path;
- a backup folder on a 1 MB disk (room);
- a target that needs a newer PHP than the old release was tested on (one maintenance window).

## Upgrade rehearsal

```
preflight/openemr-rehearse.sh --dump=site.sql --from=7.0.3 [--to=8.4.1] [--db=mariadb:11.8] [--convert-utf8mb4] [--keep]
```

The pre-flight check reads the server; the rehearsal runs the upgrade itself, on a copy, before the real one. Give it a `mysqldump` of the site's database (the backup the upgrade needs anyway) on any machine with Docker. The live site is never touched, and the copy never leaves that machine. It:

1. starts the target release's official image on a database server that release is tested on (by default the newest MariaDB in its CI), which also installs a fresh database of the target to compare with;
2. restores the dump twice, one copy to upgrade and one to keep as it was;
3. runs the target's own `sql_upgrade.php --from=<from>` on the first copy, timed;
4. compares the upgraded copy with the fresh install (tables, columns, indexes) and with the untouched copy (row counts and the values of every column, per table), and asks for the login page served from the upgraded copy;
5. prints a report and deletes everything (`--keep` leaves it running to look around).

Each difference it already knows is named with its cause and effect, and the rest are listed as not known. Patient tables (those with a `pid`, `patient_id` or `pc_pid` column) that lose rows, a failed statement or a PHP fatal error make the verdict **not ready**. A rehearsal of 7.0.3 with 40 synthetic patients (Synthea, 1,716 encounters, 4,307 results, 553 immunizations) to 8.4.1 on MariaDB 12.3 took under 3 minutes for a 21 MB dump:

```
sql_upgrade.php: exit 0 in 50s; database now 8.4.1 (database 543); size 47 MB -> 54 MB; login page from the upgraded copy: HTTP 200
Upgrade: 0 statements failed and were skipped; 0 PHP fatal errors

Schema against a fresh 8.4.1 install: 11 differences, 0 of them not known
  ok      5  timestamp columns with the old server's defaults: ...
  ok      3  contact_address lacks created_by, updated_date, updated_by: ...
  ok      1  procedure_order lacks the index idx_specimen_type: ...
  ok      2  drug_sales: the uuid index is named uuid_unique: ...

Data against the copy before the upgrade: 82 patient tables, 15202 rows
  patient rows lost: none
  patient rows added by the upgrade: none
  tables dropped that held rows: none
  ok   patient_data (last_updated) changed: the 7.0.4 script updates every patient (sex_identified, interpreter_needed), so last_updated, and with it FHIR meta.lastUpdated and _lastUpdated searches, show the upgrade time.
  ok   document_templates (send_date, end_date) changed: 8.1.0 replaces zero dates: ...
  ok   rows removed from uuid_registry: 14267 -> 14147: 7.0.4 retires the FHIR ids of four vital-sign Observations ...
  ...
VERDICT: ready
```

A column whose type the upgrade changed (`date` to `datetime`, `float(5,2)` to `decimal(12,6)`) is compared through a form both types share, so a conversion that keeps every value isn't reported; 6.1.0 with the same patients has five such conversions, all value-preserving. Rehearsed on real installs of 5.0.2 (with `--convert-utf8mb4`), 6.1.0 and 7.0.3, all to 8.4.1.

What it finds that a site should know about, from rehearsals of real installs of 5.0.2, 6.1.0 and 7.0.3:
- **Sites installed before 6.0.0 still have `utf8mb3` tables**, which no upgrade converts. OpenEMR connects as `utf8mb4`, so an emoji or other 4-byte character typed into them is saved as `?` with no error. [`preflight/openemr-utf8mb4.sql`](preflight/openemr-utf8mb4.sql) prints the statements that convert them while keeping every column's type (`ALTER TABLE … CONVERT TO` would widen `text` to `mediumtext` and so on, and the schema would no longer match a fresh install). `--convert-utf8mb4` rehearses it on the upgraded copy. MariaDB only; back up first.
- **Restoring into a database created with the new server's default collation** (`utf8mb4_uca1400_ai_ci` on the official MariaDB images from 11.4 on) leaves the tables the upgrade creates in another collation than the restored ones. From 6.1.0 one upgrade statement then fails (openemr/openemr#7784), and afterwards queries joining old and new tables fail too, such as the patient dashboard's Care Team. Create the database `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci` before restoring.

Needs Docker with compose, and the target must be 8.2.0 or later (`sql_upgrade.php` runs from the command line from 8.2.0). The dump is restored into MariaDB, not the site's own server, so it rehearses a move to a current server too.

## Upgrade

```
sudo preflight/openemr-upgrade.sh --openemr=/var/www/html/openemr --to=8.4.1 [--service=apache2] [--backup-dir=DIR] [--tarball=FILE] [--customizations=apply|leave]
sudo preflight/openemr-upgrade.sh --rollback --openemr=/var/www/html/openemr
```

For an OpenEMR installed from the release tarball (with the official Docker image, upgrading means changing the image tag). After the pre-flight check and a rehearsal, it does the manual upgrade in order and stops at the first thing that goes wrong:

1. runs the pre-flight check, and stops on a FAIL unless `--force`;
2. gets the target release: downloaded from GitHub with its published sha256 checked, or `--tarball`;
3. unpacks it beside the old folder;
4. finds OpenEMR's own files that were changed here, each shipped file's git hash compared with the release or patch as published, and the files added outside `sites/`, `vendor/` and modules. A file the target's package also has counts as built by the release, such as compiled CSS. It saves them all and writes each change as a patch against the original. Then it tries each change on the target's copy: a file the target left as it was takes yours as is, and otherwise `patch` decides. If there are any changes, it stops unless `--customizations=apply` (carry the changes that apply and the added files, list the rest) or `--customizations=leave`. Until here nothing on the server has changed, and a stop removes the unpacked folder;
5. stops the web server (`--service`), or asks you to keep users out, and backs up each site's database (`mysqldump`) and the whole `sites/` folder, which holds documents and encryption keys;
6. carries over `sites/`, the modules this install added (module folders and Composer packages not in its release's own lists) and, with `apply`, the changes from step 4;
7. runs the target's own `sql_upgrade.php --from=<current>` for each site, as the web server's user, from inside the new folder. It stops on any failed statement;
8. checks the new folder with the install doctor, and stops on a FAIL unless `--force`;
9. swaps the folders, keeping the old one as `<folder>.old-<version>`, and starts the web server.

Nothing is deleted. A rollback brings back the databases as they were before the upgrade, so anything entered since would be lost; `--rollback` therefore first saves each database as it is (`<site>.before-rollback-<time>.sql`) and, in a file of their own, the tables the upgrade created (`<site>.created-tables-<time>.sql`). Then it restores the backup, drops those tables, and swaps the folders back. The upgraded folder, with any documents uploaded since, is kept as `<folder>.failed-<version>-<time>`. The target must be 8.2.0 or later. A change the target conflicts with needs merging by hand: its patch is in the backup's `customizations/patches/`. Not covered yet: multisite setups with more than one database server.

## Install doctor

```
php openemr-doctor.php --openemr=/var/www/html/openemr [--site=default] [--facts=DIR]
```

For an install that doesn't work: a blank page, an error 500, setup stopping part-way, a login page without styling, documents or encrypted data that won't open after a move. Each check comes from failures reported on the forum, and from OpenEMR's own code for what it needs to start. It only reads, and never prints a password or a key.

The web server can run a different PHP from the command line's, with different settings. To check that one, copy the file into the OpenEMR folder and open `http://localhost/<folder>/openemr-doctor.php` in a browser on the server. It answers only requests from the server itself, refuses anything that came through a proxy, and asks to be deleted afterwards.

| Check | Fails or warns when | Forum reports |
|---|---|---|
| PHP | older than the release needs (fail), newer than CI tested it with (warn) | t/24361, t/24048, t/24282, t/26133 |
| PHP extensions | one the release's `composer.json` requires isn't loaded; `intl` is named as the cause of a calendar showing "Unknown" (fail) | t/25453, t/25214, t/26800 |
| php.ini | errors shown on pages, or below the limits OpenEMR's setup recommends (warn in the browser, note on the command line) | t/24048, t/25023 |
| PHP libraries | `vendor/` missing (a git checkout), or a Composer package missing from it (fail) | t/23699 |
| Page assets | a built file every page loads is missing: the npm build didn't run (fail) | t/26790 |
| Files | a file the release package ships is missing from a folder OpenEMR runs from (fail); documentation and tooling are optional | t/25717, t/23699 |
| Local changes | a file the release package ships was edited here, compared by git hash with the release or patch as published (note, naming the files); an edited PHP file that no longer parses with this PHP, with its line (fail; PHP 7.0 and later) | |
| Site, setup | the site's `sqlconf.php` is missing (the real sites are listed), or setup hasn't finished | t/26989 |
| Documents folder | the web server can't write it (browser), or it belongs to root (command line) | t/24855 |
| Database | can't connect, with what the error number means (1045, 1049, 2002…) | t/23921, t/26432, t/25245 |
| Database version | the database is behind the code (`sql_upgrade.php` or `sql_patch.php` didn't run), or ahead of it (fail) | t/26790, t/26133, t/24492 |
| Theme | the chosen theme's stylesheet is missing (fail) | t/26790 |
| Error display | OpenEMR's own setting shows PHP errors on pages (`user_debug` to 8.0, `user_php_debug` from 8.2) (warn) | t/27005 |
| Modules | a switched-on module has no files (fail before 7.0.4, which started switching them off; warn after) | t/25702 |
| Encryption keys | the keys folder and the `keys` table don't match: one is empty, or a key can't be verified with the other's HMAC key. OpenEMR silently makes a new key when one is missing, after which encrypted data can't be read (fail) | t/25795, t/27005 |
| Documents | a stored document has no file where OpenEMR looks for it (warn) | t/26815 |
| API keys | an API is on but its key pair is missing (warn) | t/24855 |

It runs on PHP 5.4 and later, so it can explain a PHP that is too old instead of failing to parse (checked with PHPCompatibility, and run on PHP 5.6, 7.0, 7.4 and 8.3–8.5).

A patched install is compared with its patch's files (`site/preflight/<release>-p<N>-files.json`, from the `vX_Y_Z_N` tags): patches delete files, and 7.0.3 patch 4 dropped the old login templates. The setup scripts the Docker image deletes after setup (`setup.php`, `admin.php`, `sql_upgrade.php`…) are noted, not failed.

Two end-to-end tests build throwaway installs from the official images, break one thing at a time and check the doctor names it:
- `preflight/test_doctor.sh` (8.4.1, MariaDB 11.8), 46 checks: lost templates, a lost vendor package, missing built assets, optional documentation, an edited file and one that no longer parses, a missing theme, PHP errors shown, a module without files, an emptied keys folder, a key from another install, a document without its file and one moved from another root, a half-finished upgrade, a wrong password, a missing site, unfinished setup, the browser mode and its refusals (from outside, through a proxy), and PHP 7.4.
- `preflight/test_doctor_patch.sh` (7.0.3 patch 4, MariaDB 10.6), 10 checks: the patch's file list, the extension fallback, `user_debug`, a patch whose `sql_patch.php` didn't run, and a missing file list.

On the official 8.4.1 image as installed, it reports one real gap: the image has no ClaimRev module, which Composer installs outside `vendor/` and the image's Dockerfile doesn't copy.

## How each fact is read

| Fact | Read from | How |
|---|---|---|
| PHP, extensions, Node | `composer.json`, `package.json` | at the tag, with `git show` |
| Database version, upgrade scripts | `version.php`, `sql/*_upgrade.sql` | at the tag |
| What CI tested | `ci/*/docker-compose.yml` | the database image; PHP from the OpenEMR image, or the folder name where the image doesn't say (each row says which) |
| Modules | `interface/modules/custom_modules/`, `composer.json` | at the tag |
| Schema | `sql/database.sql` | loaded into MariaDB 11.8 with `sql_mode = ''` (as OpenEMR's installer does) and read back from `information_schema` |
| Settings | `library/globals.inc.php` | parsed with nikic/php-parser, not run; enum-case keys resolved from `src/Services/Globals/*Enum.php` |
| Package files | the tag | `git archive`, which applies the tag's `export-ignore`; every file it lists is in the 8.4.1 release tarball (checked 2026-10-11). Before 8.1.0 it also lists `tests/`, `ci/` and `.github/` |
| Patch file lists | each `vX_Y_Z_N` tag | as the package files |
| File hashes | each release and patch tag | `git ls-tree`: each shipped file's git blob hash (first 10 hex digits), in `site/preflight/<release>[-p<N>]-hashes.json`. A file whose hash matches is byte for byte what the release shipped: on the official 8.4.1 image all 9,060 files git tracks at the tag match (checked 2026-10-13), so a mismatch is a local change |
| Upgrade scripts' tables, package size | `sql/*_upgrade.sql` at each tag; the GitHub release tarball | the tables each script alters, creates and writes; the tarball's unpacked size, listed as it downloads (8.2.0 on) |
| Composer packages, page assets | `composer.lock`, `config/config.yaml` | each package's install directory (`openemr-module` packages go to `custom_modules/`); the built files with `autoload: true` |

## Checks

`gen/check.py` runs before any page is built, and the build stops if it fails:

- **Floors** that a broken extraction would trip (no tables, no settings, no CI setups).
- **Known facts** from outside the pipeline: the Backup page and the Configuration Export/Import setting are in 8.2.0 and gone in 8.3.0 (openemr/openemr#13471), `patient_data.financial_review` is a datetime, the PHP floor never falls, an enum-keyed setting resolves, ClaimRev is a Composer module from 8.2.0, and the tabs template whose loss blanked logins (t/25717) is in the 8.4.1 package.
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

- Patches between releases (`vX_Y_Z_N` tags) and test builds aren't covered, except for the doctor's file lists.
- What the upgrade scripts do to existing data isn't covered, only the schema they leave.
- Files removed under `interface/` and `portal/` include helper files as well as pages.
- CI-tested databases are what CI ran, not a support statement.
