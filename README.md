# OpenEMR reference, generated from the source

Facts about each OpenEMR release (7.0.0 on), read from its source at the release tag:

- **[Upgrade notes](site/index.md):** what changes between each release and the next. PHP and extension requirements, the databases CI tested, the upgrade scripts `sql_upgrade.php` runs, schema changes, modules moved, files removed, settings added, removed or changed.
- **[Database schema](site/schema/index.md):** every table and column as a fresh install creates it, with each table's changes by release.
- **[Settings](site/settings/index.md):** everything under Administration > Config, with defaults, choices and the release each setting appeared in.

- **[Upgrade pre-flight check](preflight/openemr-preflight.php):** run it on a server before upgrading, and it lists what to fix first.
- **[Install doctor](preflight/openemr-doctor.php):** run it when an install shows a blank page, an error 500, a broken login or missing documents, and it names the cause.

Nothing in `site/` is written by hand. It complements the OpenEMR wiki, which has the upgrade *procedure* and the release features; these pages have the version-specific facts the procedure doesn't. A daily job adds each new OpenEMR release.

## Download

Each tool is one PHP file. Download it to the server:

- [openemr-doctor.php](https://github.com/anun333/openemr-reference/releases/latest/download/openemr-doctor.php)
- [openemr-preflight.php](https://github.com/anun333/openemr-reference/releases/latest/download/openemr-preflight.php)
- [SHA256SUMS](https://github.com/anun333/openemr-reference/releases/latest/download/SHA256SUMS), to check them (`sha256sum -c SHA256SUMS --ignore-missing`)

**What they do and don't do.** They only read: nothing in the install or its database is changed. They print no passwords, keys or setting values. The only network access is downloading this repository's facts for your release (about 300 KB) from `raw.githubusercontent.com`; nothing about your server is sent anywhere. On a server without internet, copy `site/preflight/` across and pass `--facts=` that folder. Each is a single readable file: read it before you run it.

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
| Disk space | less free than twice the code's size (warn) |

It then lists the upgrade scripts `sql_upgrade.php` will run and the upgrade notes for each step. It runs on PHP 7.4 and later, since it runs on the current install's PHP. Exit code 1 if any check fails.

`preflight/test_preflight.sh` builds a throwaway OpenEMR 7.0.3 (official image, MariaDB 10.6) and checks four cases against the newest release:
- as installed: missing `bcmath` and `imagick`, MariaDB 10.6 no longer tested, ClaimRev moved to Composer;
- a user assigned a menu that links to the removed Backup page;
- a removed setting turned on;
- a half-finished earlier upgrade.

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
- `preflight/test_doctor.sh` (8.4.1, MariaDB 11.8), 39 checks: lost templates, a lost vendor package, missing built assets, optional documentation, a missing theme, PHP errors shown, a module without files, an emptied keys folder, a key from another install, a document without its file and one moved from another root, a half-finished upgrade, a wrong password, a missing site, unfinished setup, the browser mode and its refusals (from outside, through a proxy), and PHP 7.4.
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
