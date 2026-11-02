# OpenEMR reference, generated from the source

Facts about each OpenEMR release (7.0.0 on), read from its source at the release tag:

- **[Upgrade notes](site/index.md):** what changes between each release and the next. PHP and extension requirements, the databases CI tested, the upgrade scripts `sql_upgrade.php` runs, schema changes, modules moved, files removed, settings added, removed or changed.
- **[Database schema](site/schema/index.md):** every table and column as a fresh install creates it, with each table's changes by release.
- **[Settings](site/settings/index.md):** everything under Administration > Config, with defaults, choices and the release each setting appeared in.

- **[Upgrade pre-flight check](preflight/openemr-preflight.php):** run it on a server before upgrading, and it lists what to fix first.
- **[Upgrade rehearsal](preflight/openemr-rehearse.sh):** run the upgrade on a copy of the whole site (database and `sites/`) in Docker first: it compares receipts of the copy before and after, runs the doctor on it, and has OpenEMR read every patient and document back.
- **[Receipt](preflight/openemr-receipt.php):** what a site holds, as counts, money totals and checksums, with no patient data; two receipts compared say MATCH or name each difference.
- **[Upgrade](preflight/openemr-upgrade.sh):** for an install from the release tarball: takes a receipt, backs up, unpacks the new release beside the old, upgrades the databases, takes a second receipt and puts everything back by itself if the two disagree, checks with the doctor, switches, and rolls back on request.

**Upgrading a site?** [The step-by-step guide](UPGRADE-GUIDE.md) puts these in order for someone who isn't a programmer: copy the site, rehearse with receipts, the doctor and the access check, and only then upgrade the live system with receipts.
- **[Install doctor](preflight/openemr-doctor.php):** run it when an install shows a blank page, an error 500, a broken login or missing documents, and it names the cause.

Nothing in `site/` is written by hand. It complements the OpenEMR wiki, which has the upgrade *procedure* and the release features; these pages have the version-specific facts the procedure doesn't. A daily job adds each new OpenEMR release.

## Download

The two PHP tools and the upgrade script run on the server; the rehearsal runs on any machine with Docker:

- [openemr-doctor.php](https://github.com/anun333/openemr-reference/releases/latest/download/openemr-doctor.php)
- [openemr-doctor-docker.sh](https://github.com/anun333/openemr-reference/releases/latest/download/openemr-doctor-docker.sh), to run the doctor on an install from OpenEMR's Docker images
- [openemr-preflight.php](https://github.com/anun333/openemr-reference/releases/latest/download/openemr-preflight.php)
- [openemr-rehearse.sh](https://github.com/anun333/openemr-reference/releases/latest/download/openemr-rehearse.sh) and [openemr-utf8mb4.sql](https://github.com/anun333/openemr-reference/releases/latest/download/openemr-utf8mb4.sql)
- [openemr-receipt.php](https://github.com/anun333/openemr-reference/releases/latest/download/openemr-receipt.php), which the rehearsal and the upgrade run (and anyone can, on the server)
- [openemr-upgrade.sh](https://github.com/anun333/openemr-reference/releases/latest/download/openemr-upgrade.sh), for installs from the release tarball
- [scan.php](https://github.com/anun333/openemr-reference/releases/latest/download/scan.php), put beside the doctor and the pre-flight check: it reads a site's own code for what PHP removed (see [PHP changes in a site's own code](#php-changes-in-a-sites-own-code))
- [SHA256SUMS](https://github.com/anun333/openemr-reference/releases/latest/download/SHA256SUMS), to check them (`sha256sum -c SHA256SUMS --ignore-missing`; with BusyBox's `sha256sum`, as in OpenEMR's Docker image, check each file you downloaded: `grep ' openemr-receipt.php$' SHA256SUMS | sha256sum -c`)

**What they do and don't do.** The doctor and the pre-flight check only read: nothing in the install or its database is changed. They print no passwords, keys or setting values. The only network access is downloading this repository's facts for your release (about 300 KB) from `raw.githubusercontent.com`, and one request to `github.com` asking which release of these tools is newest, so a tool can say when a newer one is out. It never updates itself; `OPENEMR_REFERENCE_NO_UPDATE_CHECK=1` turns the question off, and the doctor doesn't ask when its facts come from a local folder. Nothing about your server is sent anywhere. On a server without internet, copy `site/preflight/` across and pass `--facts=` that folder. The rehearsal never touches the live site: it works on a copy of a database dump and of `sites/` (which it only reads), in containers it caps and deletes afterwards. It downloads the official OpenEMR and database images, Playwright's browser image and the pinned Playwright package from PyPI, and the same facts; its browser talks to the copy and nowhere else. The receipt only reads, and holds no patient data: counts, money totals and checksums. `openemr-utf8mb4.sql` only prints statements; nothing changes until you run them. `openemr-upgrade.sh` does change the server, in the order described below, after backing up, and keeps a way back. Each is a single readable file: read it before you run it.

Every push runs ShellCheck on the scripts, parses the PHP tools with each PHP they support (5.5 to 8.5 for the doctor and `scan.php`, 7.4 on for the pre-flight check), and runs `gen/check.py` (`.github/workflows/lint.yml`). The end-to-end suites below need Docker and several minutes each, so they run before each release: `release.sh` runs the same fast checks and then every suite, one at a time, and tags and publishes nothing unless all of them pass. It then downloads what it published and checks it against `SHA256SUMS`. (It exists because v0.3.8 went out with the doctor's suites run but not the upgrade suite, which also runs the doctor.)

Wrong answers are bugs: please [open an issue](https://github.com/anun333/openemr-reference/issues) with the output (it contains no patient data).

## Upgrade pre-flight check

```
php openemr-preflight.php --openemr=/var/www/html/openemr [--target=8.4.1] [--facts=DIR] [--skip=NAME,...]
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
| Site code on the new PHP | when the target needs a newer PHP: the files this site added and the modules the target doesn't ship use something PHP removes on the way (fail, naming file and line); uses it only deprecates, as one line (note). Needs `scan.php` beside the check; without it, it says the scan was skipped |
| Memory | under 1 GB available, on Linux (warn) |

Any of these can be left out by name, such as `--skip=room` on a large install: see [Leaving checks out](#leaving-checks-out).

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
preflight/openemr-rehearse.sh --dump=site.sql --sites=sites.tar.gz --from=7.0.3 [--to=8.5.0] [--site=default] [--db=mariadb:11.8]
                              [--cpus=3] [--memory=6g] [--sample=10] [--out=DIR] [--no-access-check] [--convert-utf8mb4] [--keep]
```

The pre-flight check reads the server; the rehearsal runs the upgrade itself, on a copy of the whole site, before the real one. Give it a `mysqldump` of the site's database (the backup the upgrade needs anyway) and its `sites/` folder (a `.tar.gz` of it, or the folder, which is only read), on any machine with Docker. The live site is never touched, and the copy never leaves that machine. It:

1. checks there is room, and says how much the copy needs (the database four times over, `sites/` twice, and any images not yet downloaded);
2. starts the target release's official image on a database server that release is tested on (by default the newest MariaDB in its CI), which also installs a fresh database of the target to compare with;
3. restores the dump twice, one copy to upgrade and one to keep as it was, and copies `sites/` in: documents, the encryption keys they need, the site's own files;
4. takes a [receipt](#receipt) of the untouched copy, runs the target's own `sql_upgrade.php --from=<from>` on the other, timed, and takes a receipt of the upgraded copy. The two must match, as they must on the live upgrade, which stops and puts everything back when they don't;
5. compares the upgraded copy with the fresh install (tables, columns, indexes), and asks for the login page served from it;
6. runs the [install doctor](#install-doctor) on the upgraded copy, as the live upgrade does;
7. has OpenEMR read the upgraded copy back (the access check), as a temporary administrator it removes afterwards:
   - every patient through OpenEMR's API, with each patient's encounters, appointments, prescriptions and lab orders counted and matched with the receipt;
   - every document through OpenEMR's own document route, decrypted with the site's keys, against the hash OpenEMR stored when it was saved;
   - Reports › Financial › Receipts by Payment Method for each year, and every patient's balance by OpenEMR's own `get_patient_balance` (the Billing card's Total Balance Due), against the receipt;
   - a sample of charts in a browser (Playwright, in Docker, allowed to talk to the copy only): random patients, the first and last registered, the oldest, the one with the most encounters, two with documents, two with a balance, one with lab results and one with prescriptions. For each it opens the dashboard (and reads the balance on its Billing card), demographics, the encounter list, documents, prescriptions, lab results, the latest lab order and the latest encounter with every form in it. Then one of each kind of encounter form on the site, in its own encounter. Every page must load without a PHP error: a status of 500, PHP's own message on the page, or a fatal error, uncaught exception or parse error in the log while it loaded. Warnings and JavaScript errors are listed as notes;
8. prints a report and writes it, with both receipts, their comparison, the doctor's output and the access check's, to `--out` (by default `openemr-rehearsal-<from>-to-<to>-<time>/`). Then it deletes everything; `--keep` leaves the copy running to look around.

The verdict is **ready** only when `sql_upgrade.php` finished cleanly, the schema differs from a fresh install only in known ways, the receipts match, the doctor fails nothing (other than PHP's own security update), and the access check passes.

**Capped.** Its containers share `--cpus` (3 unless given) and `--memory` (6 GB) equally: the database, OpenEMR and the browser each get a third. So it can run on the server beside the live site without starving it.

A rehearsal of the synthetic Pohnpei-shaped 7.0.3 (patch 4) site (`preflight/test_site.py`: 420 patients, 1,309 encounters, 811 appointments, 287 prescriptions, 213 lab orders with 401 results, 122 documents stored encrypted by OpenEMR itself, insurance and patient payments) to 8.5.0, on MariaDB 12.3 (abridged: "..." marks lines left out; the access check is from `test_rehearse.sh`'s clean run on the same data):

```
Rehearsing OpenEMR 7.0.3 -> 8.5.0 on mariadb:12.3 with site-703.sql (16 MB) and sites/ from sites-703.tar.gz (0 MB)
  the copy needs about 68 MB under /var/lib/docker (the database four times over, sites/ twice); 73738 MB free
  capped at 3 CPUs and 6g of memory in all (1.00 CPUs and 2048m each for the database, OpenEMR and the browser)
  ...
  check: sites/default copied whole into the copy (167 files)
  ...
sql_upgrade.php: exit 0 in 60s; database now 8.5.0 (database 555); size 37 MB -> 48 MB; login page from the upgraded copy: HTTP 200
Upgrade: 0 statements failed and were skipped; 0 PHP fatal errors

Schema against a fresh 8.5.0 install: 11 differences, 0 of them not known
  ok      5  timestamp columns with the old server's defaults: ...
  ...

Data: receipts of the copy before and after the upgrade (no patient data; in .../openemr-rehearsal-7.0.3-to-8.5.0-...)
  What the clinic has, and the money
    same Patients                                       420
    same Encounters (visits)                            1,309
    same Appointments (with a patient)                  811
    same Prescriptions                                  287
    same Lab orders                                     213
    same Lab results                                    401
    same Documents (database rows)                      122
    same Document files on disk                         122
    same Document files: bytes                          112,070
    same Document files missing                         0
    same Document files: checksum of every file         dbe6a73554da36b3
    same Charges (fee sheet)                            33,425.00
    same Co-pays (fee sheet)                            0.00
    same Drug sales                                     360.00
    same Payments                                       11,667.00
    same Adjustments                                    2,604.00
    same Balance (charges and drug sales, less co-pays, payments and adjustments) 19,514.00
    same Receipts / adjustments, 2024                   151.00 / 28.00
    same Receipts / adjustments, 2025                   11,516.00 / 2,576.00
    every figure the same, and each patient's counts and balance too

  Every table: 264 compared (82 of them a patient's, with 11,312 rows of patients), 22 created by the upgrade, 1 gone
    ok   drugs.uuid (1 row), form_encounter.uuid (1309 rows), ... patient_data.uuid (420 rows), ...: the upgrade gave each row that had no FHIR id (uuid) one; checked: every id that was there is still there, on as many rows.
    ok   form_encounter.last_update, form_vitals.last_updated, ...: updates itself whenever its row is written (ON UPDATE CURRENT_TIMESTAMP), ...
    ok   openemr_postcalendar_events.pc_endDate: 8.1.0 and 8.1.1 store a single appointment's empty end date as NULL instead of 0000-00-00 (...) (checked: exactly that rename, nothing else).
    ok   patient_data.ethnicity: 8.1.0 corrects the misspelled code 'declne_to_specfy' to 'decline_to_specify' (checked: exactly that rename, nothing else).
    ok   patient_data.last_updated: the 7.0.4 script updates every patient ...
    ok   settings, lists and other tables that aren't a patient's: 13 gained rows, 6 changed in place, 22 created (the upgrade scripts' own work)

  RESULT: MATCH. Every patient record, document and money figure is the same; the changes marked ok are the upgrade's own, each explained.

Install doctor on the upgraded copy (exit 0; full output: .../doctor.txt)
  14 checks pass, 0 fail, 0 warn

Access check: OpenEMR reads the upgraded copy back (sample seed 67178; 420 patients through the API, 122 documents, 24 chart visits (19 patients sampled), 2 report years)
  ok   logged in to the upgraded copy (a temporary administrator, removed afterwards)
  ok   every patient read through OpenEMR's API: 420 of 420
  ok   encounters per patient: the API's counts match the receipt for all 420 patients who have any
  ok   appointments per patient: the API's counts match the receipt for all 365 patients who have any
  ok   prescriptions per patient: the API's counts match the receipt for all 220 patients who have any
  ok   lab orders per patient: the API's counts match the receipt for all 178 patients who have any
  ok   every document fetched through OpenEMR's document route matches the hash OpenEMR stored: 122 of 122
  ok   Reports > Financial > Receipts by Payment Method, 2024 (payment date): receipts 151.00, adjustments 28.00, as the receipt
  ok   Reports > Financial > Receipts by Payment Method, 2025 (payment date): receipts 11,516.00, adjustments 2,576.00, as the receipt
  ok   every patient's balance by OpenEMR's own get_patient_balance (the Billing card's Total Balance Due) matches the receipt: 380 with a balance, 19,514.00 in all
  ok   the dashboard's Billing card shows each sampled patient's balance as the receipt has it (19 patients)
  ok   176 pages of 21 patients' charts opened in a browser without a PHP error
       opened: first registered (1); last registered (420); random (420, 176, ...); oldest (341); most encounters (7); has documents (321, 244); ...; a form of the kind 'procedure_order' (1); ...
  note OpenEMR logged 8 kinds of PHP warning or deprecation while the pages loaded (not errors; the pages loaded):
         patient 1: form 'procedure_order': PHP Warning:  Undefined array key 0 in .../interface/forms/procedure_order/templates/procedure_specimen_row.php on line 21
         ...
ACCESS: PASS
...
VERDICT: ready
```

`preflight/test_rehearse.sh` (55 checks) checks it both ways: the clean rehearsal above passes, with each container capped, and a rehearsal of the same site with faults planted in the source (one document's file missing, another's stored hash wrong, an encounter form whose code isn't in 8.5.0, and billing-line co-pays (as the old Charges screen writes them)) fails and names each one. The receipts of that copy still match: the faults were there before the upgrade, which is why the access check reads the data back through OpenEMR and doesn't stop at counting it.

**Two findings about OpenEMR 8.5.0 itself, from these rehearsals** (both reported here, not upstream yet):
- Reports › Financial › Receipts by Payment Method stops with a TypeError when the dates include a co-pay stored as a `billing` line (code type COPAY): its co-pay query doesn't select `code_text`, and OpenEMR 7.0.4 (#8794) made the function's `$memo` a `string`, so 7.0.4 through 8.5.0 and master stop on it. Those rows come from a visit's old Charges screen (with "Use Charges Panel" on, off by default) or from imports; the Fee Sheet's co-pay is stored as a payment (`ar_activity`) and doesn't trigger it. Fix offered as openemr/openemr#15001 (2026-11-02). (Corrected 2026-11-02: an earlier version of this line said Fee Sheet co-pays and 8.5.0.)
- A lab order made before 8.x has no rows in 8.5.0's new `procedure_specimen` table, and opening it logs PHP warnings (`procedure_specimen_row.php`, an undefined array key and a `foreach` over null). The page still loads.

A column whose type the upgrade changed (`date` to `datetime`, `float(5,2)` to `decimal(12,6)`) is compared through a form both types share, so a conversion that keeps every value isn't reported. Rehearsed on real installs of 5.0.2 (with `--convert-utf8mb4`), 6.1.0 and 7.0.3, all to 8.4.1, before the receipts and the access check were added.

What it finds that a site should know about, from rehearsals of real installs of 5.0.2, 6.1.0 and 7.0.3:
- **Sites installed before 6.0.0 still have `utf8mb3` tables**, which no upgrade converts. OpenEMR connects as `utf8mb4`, so an emoji or other 4-byte character typed into them is saved as `?` with no error. [`preflight/openemr-utf8mb4.sql`](preflight/openemr-utf8mb4.sql) prints the statements that convert them while keeping every column's type (`ALTER TABLE … CONVERT TO` would widen `text` to `mediumtext` and so on, and the schema would no longer match a fresh install). `--convert-utf8mb4` rehearses it on the upgraded copy. MariaDB only; back up first.
- **Restoring into a database created with the new server's default collation** (`utf8mb4_uca1400_ai_ci` on the official MariaDB images from 11.4 on) leaves the tables the upgrade creates in another collation than the restored ones. From 6.1.0 one upgrade statement then fails (openemr/openemr#7784), and afterwards queries joining old and new tables fail too, such as the patient dashboard's Care Team. Create the database `CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci` before restoring.

Needs Docker with compose, and the target must be 8.2.0 or later (`sql_upgrade.php` runs from the command line from 8.2.0). The dump is restored into MariaDB, not the site's own server, so it rehearses a move to a current server too.

**Using the upgraded copy.** With `--keep` the copy stays up, logged in to with the site's own accounts, so a site can try what needs the newer release before upgrading: the UDS Report module's guide, [Run your UDS report on a rehearsal copy of an older OpenEMR](https://github.com/anun333/oe-module-uds-report/blob/main/docs/rehearsal-copy.md), does that from 7.0.3 to 8.5.0. The copy holds the site's patient records and answers only on 127.0.0.1. Its port changes if the container restarts; ask again with the `port` command the rehearsal prints.

## Receipt

```
php openemr-receipt.php --openemr=/var/www/html/openemr [--site=default] [--out=FILE.json] [--label=TEXT] [--against=FIRST.json]
php openemr-receipt.php --compare FIRST.json SECOND.json
```

What a site holds, so that two moments (before and after an upgrade, a copy and its source, a backup restored) can be shown to hold the same data. It only reads, and it holds **no patient data**: counts, money totals and checksums, from which nothing about a patient can be read back. It runs on PHP 7.4 and later, with the PHP the site runs on. It has three parts:

- **A header:** the site, the OpenEMR release the files and the database say, the database server, when.
- **What the clinic has, in plain words:** patients, encounters, appointments, prescriptions, lab orders and lab results, documents (database rows, and the files on disk they point to, found the way OpenEMR's document route finds them: their count, bytes, a checksum of every file, and how many are missing), charges, co-pays and drug sales, payments and adjustments (voided ones left out), the total balance, and receipts and adjustments by year.
- **Every table:** its rows, the rows of a patient (tables with a `pid`, `patient_id` or `pc_pid`), a checksum of its rows, and one of each column.

The money figures are OpenEMR's own: the balance is what `get_patient_balance($pid, true)` (each patient's Billing card, Total Balance Due) gives, added up, and "receipts by year" is what Reports › Financial › Receipts by Payment Method shows by payment date for January 1 to December 31, from the report's own query (the same in 7.0.3 and 8.5.0). The rehearsal's access check checks both against OpenEMR on the upgraded copy: the report for each year, and `get_patient_balance` for every patient, whose checksum must equal the receipt's.

`--compare` prints **MATCH** when nothing differs but what an upgrade is known to change, each with its reason. A figure in "what the clinic has", or a patient's own counts or balance, is never explained away. The known changes are measured, and each is checked rather than assumed:

| Change | How it is checked |
|---|---|
| FHIR ids (`uuid`) given to rows that had none | fewer rows without one, and every id that was there still there (ids `uuid_registry` says were created after the first receipt are set aside) |
| a timestamp that updates itself when its row is written (`ON UPDATE CURRENT_TIMESTAMP`) | left out of the row checksums; every other column of the table is still compared |
| 8.1.0's renames: `declne_to_specfy` to `decline_to_specify` in race, language and ethnicity; a single appointment's end date `0000-00-00` to NULL | the first receipt also checksums the column with the rename applied, and that must equal the second's |
| 7.0.4 and 8.1.0 setting `patient_data.last_updated` and `document_templates` dates to the upgrade time | named columns; nothing else in those rows may change |
| rows removed from `uuid_registry` and `uuid_mapping` (7.0.4's retired vital-sign ids) | named tables, not a patient's |
| settings, lists and other tables that aren't a patient's gaining or changing rows, and the tables an upgrade creates | not a patient's; a created table with rows of a patient is a difference |

Everything else is a difference: a table losing or gaining rows of a patient, a patient table changing in place (by column, or values moved between rows, which the row checksum sees), a table gone, a money figure. A known cause is named beside a difference without excusing it: 8.1.0 deletes calendar events with no date (`pc_eventDate` 0000-00-00), and the comparison says so.

`--strict` allows no difference at all, not even what an upgrade is known to change (and each column's type and collation must be the same too): for a database restored from a backup, which the rollback checks this way.

`--against=FIRST.json` takes the second receipt the way the first was taken, so the two compare even where the upgrade changed a column's type; the rehearsal and the upgrade take it that way. Exit code 0 for MATCH, 1 otherwise.

## Upgrade

```
sudo preflight/openemr-upgrade.sh --openemr=/var/www/html/openemr --to=8.5.0 [--service=apache2] [--backup-dir=DIR] [--tarball=FILE] [--customizations=apply|leave] [--skip=NAME,...] [--debug]
sudo preflight/openemr-upgrade.sh --rollback --openemr=/var/www/html/openemr [--debug]
```

For an OpenEMR installed from the release tarball (with the official Docker image, upgrading means changing the image tag). After the pre-flight check and a rehearsal, it does the manual upgrade in order and stops at the first thing that goes wrong:

1. runs the pre-flight check, and stops on a FAIL unless `--force`;
2. gets the target release: downloaded from GitHub with its published sha256 checked, or `--tarball`;
3. unpacks it beside the old folder;
4. finds OpenEMR's own files that were changed here, each shipped file's git hash compared with the release or patch as published, and the files added outside `sites/`, `vendor/` and modules. A file the target's package also has counts as built by the release, such as compiled CSS. It saves them all and writes each change as a patch against the original. Then it tries each change on the target's copy: a file the target left as it was takes yours as is, and otherwise `patch` decides. If there are any changes, it stops unless `--customizations=apply` (carry the changes that apply and the added files, list the rest) or `--customizations=leave`. It then reads what will go in for what the PHP running it has removed: the lines each change writes, on the copy it goes into, and the added files and modules whole. It stops on any that won't load or stop with an error, unless `--force`. Until here nothing on the server has changed, and a stop removes the unpacked folder;
5. stops the web server (`--service`), or asks you to keep users out, takes a [receipt](#receipt) of each site, and backs up each site's database (`mysqldump`) and the whole `sites/` folder, which holds documents and encryption keys;
6. carries over `sites/`, the modules this install added (module folders and Composer packages not in its release's own lists) and, with `apply`, the changes from step 4;
7. runs the target's own `sql_upgrade.php --from=<current>` for each site, as the web server's user, from inside the new folder. It stops on any failed statement;
8. takes a second receipt of each site, from the new folder, and compares it with the first. On any difference the upgrade isn't known to make, or any change to a patient count or a money figure, it stops before switching and **puts everything back by itself**: the old folder stays live, each database is restored from the backup taken minutes before and checked against the first receipt, and the web server is started again. It says why in plain words and where the comparison is (stopping to ask would leave the clinic closed until someone answered; putting back loses nothing, since the database as the upgrade left it is saved first);
9. checks the new folder with the install doctor, and stops on a FAIL unless `--force`. A PHP that needs its own security update (the doctor's PHP security check) is reported and doesn't stop the switch: updating PHP is a separate job, and holding back the upgrade would only hold back OpenEMR's own security fixes;
10. swaps the folders, keeping the old one as `<folder>.old-<version>`, and starts the web server.

**It checks its own work.** After each step it verifies the result and prints a `check:` line, or stops:
- the unpacked release is the version asked for;
- each receipt finished, and read as many tables as the database has;
- each database dump ends with mysqldump's "Dump completed" line and has every table, so a dump cut short by a full disk is caught before anything changes;
- `sites.tar.gz` reads back whole: `gzip -t` reads every byte against the archive's own checksum, and it holds as many files, and as many bytes of them, as `sites/`;
- the copied `sites/` is whole;
- each database is at the target's version after `sql_upgrade.php`;
- the receipts before and after the database upgrade match;
- the folder is the target after the switch.

The rollback checks each restored database and the folder the same way, and then takes a receipt of each restored database, with the old folder's documents, and compares it strictly with the receipt taken before the upgrade (`--compare --strict`): every table, settings included, must have the same rows and the same checksum of every row and column, and every document file the same bytes. That is what shows the backup brought back everything: the dump's own checks show it is whole and has every table, not that every row came back. A restore that doesn't match is reported loudly (the folders are still switched back, since the old folder is the safer one to run). The receipt doesn't cover a table's next AUTO_INCREMENT number; the upgrade suite checks that too, with a full dump of the database byte for byte the one before.

**If it stops**, it says how far it got. Before the backup that means nothing changed: it removes the unpacked folder and starts the web server again if it stopped it. After the backup it says where the backup is, whether the folders were switched, and the exact `--rollback` command to run.

**Everything it prints also goes to a log** in the backup folder (`openemr-upgrade.log`, and `openemr-rollback-<time>.log`), so a request for help can include it, and so do the receipts and their comparisons (`receipt-<site>-before`, `receipt-<site>-after-upgrade`, `receipts-<site>-compared.txt`, and after a rollback `receipt-<site>-after-rollback-<time>` and `receipts-<site>-rollback-compared-<time>.txt`). `--debug` adds every command it runs; the database password stays out of all of them.

**Only one run at a time** per install: a second refuses to start while the first holds `.<folder>-upgrade.lock`. The web server it starts doesn't inherit the lock, so a later run, or the rollback, isn't refused because of it.

**The pre-flight check, the doctor and the receipt** it runs are the copies beside it, else they're downloaded from this script's own release and checked against that release's `SHA256SUMS`. One that doesn't match isn't run.

`preflight/test_upgrade.sh` (7.0.3 patch 4 to 8.5.0, on MariaDB 10.11 or the server `DB_IMAGE` names), 107 checks, on the synthetic Pohnpei-shaped site (`preflight/test_site.py`, its documents stored by OpenEMR's own code), covers:
- the receipt's floors on that site (patients, visits, appointments, prescriptions, labs, documents on disk, charges, payments, adjustments, a balance), and its comparison both ways: a receipt matches itself, and three planted differences are each named;
- local changes found, applied, kept as patches;
- the upgrade and the rollback, with work done in between kept; the receipts match after the database upgrade, having compared what's there; the rollback's receipt matches the first, strictly; a receipt the test takes itself at the end matches the one it took at the start;
- a change to the data during the upgrade, both ways: a payment deleted, and a charge and a date of birth edited, each right after `sql_upgrade.php`. The receipts disagree and name the change, the script stops before the doctor and the switch and puts everything back by itself (its strict check of the restored database passes), the web server runs again, a full dump of the database is byte for byte the one before, and a receipt the test takes itself matches the first. The dump is taken before anything loads a page: OpenEMR's audit log writes a row (`log`, `http-request-select`) for every request, the login page included, which the suite shows each time;
- a helper that doesn't match `SHA256SUMS` refused, and one that does used (the receipt among them);
- a second run refused while the first holds the lock;
- a stop before the backup, which changes nothing;
- a stop after it, which names the rollback, and that rollback;
- a failure partway through `sql_upgrade.php`: a planted duplicate makes one statement fail while the others run, and after the rollback a full dump of the database is byte-for-byte the one taken before;
- `--service`, with a stand-in SysV service whose child process keeps the descriptors it's given, as a web server does: the rollback after it still gets the lock;
- each self-check;
- a `--debug` log that traces every command, with the database password in no line of it nor in the receipts.

Run on 2026-11-01 on each database server a site is likely to have: MariaDB 10.11 with the whole suite, and MariaDB 10.6 and 11.8 and MySQL 8.0 and 8.4 with `RECEIPTS_ONLY=1` (64 checks each: the receipt's floors and comparison, both changes made during the upgrade, the clean upgrade, and the rollback with its strict check). All pass. On MySQL, the first restore makes `SHOW CREATE TABLE` write each text column's character set out (`CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci` where it wrote `COLLATE utf8mb4_general_ci`): the same character set and collation, which the rollback's strict receipt compares column by column. The suite's byte-for-byte check reads that wording as one, and only where the collation belongs to that character set.

Nothing is deleted. A rollback brings back the databases as they were before the upgrade, so anything entered since would be lost; `--rollback` therefore first saves each database as it is (`<site>.before-rollback-<time>.sql`) and, in a file of their own, the tables the upgrade created (`<site>.created-tables-<time>.sql`). Then it restores the backup, drops those tables, and swaps the folders back. The upgraded folder, with any documents uploaded since, is kept as `<folder>.failed-<version>-<time>`. The target must be 8.2.0 or later. A change the target conflicts with needs merging by hand: its patch is in the backup's `customizations/patches/`. Not covered yet: multisite setups with more than one database server.

## Install doctor

```
php openemr-doctor.php --openemr=/var/www/html/openemr [--site=default] [--facts=DIR] [--skip=NAME,...] [--debug]
```

`--debug` (or `?debug=1` in the browser) adds `DEBUG` lines: where each facts file came from and its size, the version it compared with and why, the counts behind each file check, timings, and a tally. On a build that isn't a release, such as the development branch (`8.5.0-dev`) or a release newer than the facts, it compares with the closest earlier release and says so. Files, packages and assets that release has and this build doesn't are then notes, not failures. A facts file that looks cut short (a file list under 1,000 entries, a Composer list under 20) is a warning, so a check against almost nothing can't pass quietly.

For an install that doesn't work: a blank page, an error 500, setup stopping part-way, a login page without styling, documents or encrypted data that won't open after a move. Each check comes from failures reported on the forum, and from OpenEMR's own code for what it needs to start. It only reads, and never prints a password or a key.

**On Docker**, run `openemr-doctor-docker.sh` in the directory with your `docker-compose.yml`. It finds the OpenEMR container by the image it was started from, so it still works after the tag has been pulled again (`docker compose ps` then shows `sha256:…`), and runs the doctor with that exact image's PHP. With `sites/` on a volume, as in OpenEMR's compose files, it runs from a throwaway container sharing the OpenEMR container's volumes and network, so it works even when that container won't stay up. Without the volume it runs inside the running container instead. It works with `docker compose` and the older `docker-compose`. It can be piped straight from curl, since the script runs only from its last line, so a download cut short does nothing:

```
curl -fsSL https://github.com/anun333/openemr-reference/releases/latest/download/openemr-doctor-docker.sh | bash
```

It says on stderr which container and image it checks and how it runs the doctor; the report is on stdout. The doctor is `openemr-doctor.php` in the current directory if there is one, else it downloads the doctor from its own release and runs it only if it matches that release's `SHA256SUMS`, leaving nothing behind.
- When the project has more than one OpenEMR container it names them and checks the first; set `CONTAINER=name` to pick another, or to check an image of your own built on `openemr/openemr`.
- `--debug` (`curl … | bash -s -- --debug`) traces the script and runs the doctor with `--debug`.

To check the script itself before running it, download it with `SHA256SUMS` and run `sha256sum -c SHA256SUMS --ignore-missing` (or `grep ' openemr-upgrade.sh$' SHA256SUMS | sha256sum -c`, which BusyBox's `sha256sum` accepts too).

The idea came from Asher Densmore-Lynn ([t/27118](https://community.open-emr.org/t/27118/8)).

The web server can run a different PHP from the command line's, with different settings. To check that one, copy the file into the OpenEMR folder and open `http://localhost/<folder>/openemr-doctor.php` in a browser on the server. It answers only requests from the server itself, refuses anything that came through a proxy, and asks to be deleted afterwards.

| Check | Fails or warns when | Forum reports |
|---|---|---|
| PHP | older than the release needs (fail), newer than CI tested it with (warn) | t/24361, t/24048, t/24282, t/26133 |
| PHP security | older than PHP's fix for php2shell (2026-10-21: 8.5.12, 8.4.27, 8.3.36, 8.2.35): fail for Alpine's packages (OpenEMR's images, with the in-place `apk upgrade`) and for PHP built from source; warn for a Debian, Ubuntu or RHEL package, which gets fixes without a new number (it names the package version to check against the distribution's notice); warn for 8.1 and older, which PHP no longer fixes | t/27152 |
| PHP extensions | one the release's `composer.json` requires isn't loaded; `intl` is named as the cause of a calendar showing "Unknown" (fail). Releases whose `composer.json` lists none get setup's own four, plus `intl` from 7.0.0 on, or before that only if the install's code uses it (5.0.2's image ships without it) | t/25453, t/25214, t/26800 |
| php.ini | errors shown on pages, or below the limits OpenEMR's setup recommends (warn in the browser, note on the command line) | t/24048, t/25023 |
| PHP libraries | `vendor/` missing (a git checkout), or a Composer package missing from it (fail) | t/23699 |
| Page assets | a built file every page loads is missing: the npm build didn't run (fail) | t/26790 |
| Files | a file the release package ships is missing from a folder OpenEMR runs from (fail; a note on a build that isn't the release the facts describe); documentation and tooling are optional | t/25717, t/23699 |
| Local changes | a file the release package ships was edited here, compared by git hash with the release or patch as published (note, naming the files); an edited PHP file that no longer parses with this PHP, with its line (fail; PHP 7.0 and later) | |
| Local changes on this PHP | an edited PHP file that parses but uses something this PHP removed, which fails only when its line runs, such as `each()` on PHP 8 (fail, with the line); deprecated uses as one line (note). Needs `scan.php` beside the doctor | |
| Site, setup | the site's `sqlconf.php` is missing (the real sites are listed), or setup hasn't finished | t/26989 |
| Documents folder | the web server can't write it (browser), or it belongs to root (command line) | t/24855 |
| Database SSL | `documents/certificates/mysql-ca`, `mysql-cert` or `mysql-key` can't be read or isn't PEM (fail); a client certificate without its key, or the reverse (fail from 8.1, which refuses to connect; warn before, which ignores it); a client certificate without `mysql-ca`, which turns SSL on (warn) | t/27148 |
| Database | can't connect, with what the error number means (1045, 1049, 2002…). It connects as OpenEMR does, over SSL when `mysql-ca` is there. A server that only accepts encrypted connections without `mysql-ca` is error 3159. Over SSL, PHP reports a refused server certificate only as error 2002, so the doctor reads the server's certificate and says why: `mysql-ca` didn't sign it, or the host in `sqlconf.php` isn't a name in it (for example Google Cloud SQL by internal IP) | t/23921, t/26432, t/25245, t/27148 |
| Database version | the database is behind the code (`sql_upgrade.php` or `sql_patch.php` didn't run), or ahead of it (fail) | t/26790, t/26133, t/24492 |
| Theme | the chosen theme's stylesheet is missing (fail) | t/26790 |
| Error display | OpenEMR's own setting shows PHP errors on pages (`user_debug` to 8.0, `user_php_debug` from 8.2) (warn) | t/27005 |
| Modules | a switched-on module has no files (fail before 7.0.4, which started switching them off; warn after) | t/25702 |
| Encryption keys | the keys folder and the `keys` table don't match: one is empty, or a key can't be verified with the other's HMAC key. OpenEMR silently makes a new key when one is missing, after which encrypted data can't be read (fail) | t/25795, t/27005 |
| Documents | a stored document has no file where OpenEMR looks for it (warn) | t/26815 |
| API keys | an API is on but its key pair is missing (warn) | t/24855 |

Any of these can be left out by name, such as `--skip=documents`: see [Leaving checks out](#leaving-checks-out).

It runs on PHP 5.4 and later, so it can explain a PHP that is too old instead of failing to parse (checked with PHPCompatibility, and run on PHP 5.6, 7.0, 7.4 and 8.3–8.5).

A patched install is compared with its patch's files (`site/preflight/<release>-p<N>-files.json`, from the `vX_Y_Z_N` tags): patches delete files, and 7.0.3 patch 4 dropped the old login templates. The setup scripts the Docker image deletes after setup (`setup.php`, `admin.php`, `sql_upgrade.php`…) are noted, not failed.

Two end-to-end tests build throwaway installs from the official images, break one thing at a time and check the doctor names it. Like the other suites, they run one at a time, and wait until OpenEMR's login page answers and its files stop changing, not only for "Setup Complete":
- `preflight/test_doctor.sh` (8.4.1, MariaDB 11.8): lost templates, a lost vendor package, missing built assets, optional documentation, an edited file and one that no longer parses, a missing theme, PHP errors shown, a module without files, an emptied keys folder, a key from another install, a document without its file and one moved from another root, a half-finished upgrade, a wrong password, a missing site, unfinished setup, the browser mode and its refusals (from outside, through a proxy), PHP 7.4, when `intl` is required before 7.0.0, and `openemr-doctor-docker.sh` on the same stack. It also covers:
  - a development build (`-dev`) and a release newer than the facts, whose missing files are notes;
  - a `version.php` the web server can't read;
  - `--debug`, and a facts file cut short;
  - `openemr-doctor-docker.sh` naming what it checks, downloading the doctor and checking it against `SHA256SUMS` (and refusing a changed one), and `--debug`;
  - MySQL over SSL, against a second MariaDB that only accepts encrypted connections, with a test CA: no `mysql-ca` (error 3159), the right CA (connected over SSL), a connection by IP (the certificate names the host, not the IP), the wrong CA, a client certificate without its key, and a `mysql-ca` that isn't PEM.

  87 checks in all.
- `preflight/test_doctor_patch.sh` (7.0.3 patch 4, MariaDB 10.6), 11 checks: the patch's file list, the extension fallback, `user_debug`, a patch whose `sql_patch.php` didn't run, a missing file list, and the image's PHP, which no Alpine update fixes for php2shell.
- `preflight/test_update_notice.sh`, 22 checks: the doctor (on PHP 5.6 and 8.5, with no warning or deprecation), `openemr-upgrade.sh` and `openemr-doctor-docker.sh` say when a newer release is out, stay quiet on the newest, compare versions as numbers, and are silenced by `OPENEMR_REFERENCE_NO_UPDATE_CHECK=1`, a local `--facts` folder or another `OPENEMR_REFERENCE_BASE`. It fails offline, since without the live latest release every case would pass vacuously.
- `preflight/test_php_security.sh`, 10 checks, no install needed: the PHP security check under OpenEMR's image before and after the in-place update, PHP built from source, Ubuntu's and Debian's own PHP, and PHP 8.1 and 5.6. Each expectation follows the PHP the container runs, so a rebuilt image moves a case from fail to pass instead of breaking the test.

`test_doctor.sh` applies the php2shell update to its 8.4.1 install before checking it, as a site would; the published image ships the affected PHP until it is rebuilt.

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
- **The names `--skip` takes**: the README's table for the pre-flight check and for the doctor lists each tool's own names, in its order.
- **php-upgrade-catalogue, pinned** (`gen/catalogue.json`): `preflight/scan.php` and `site/preflight/php-changes.json` are the pinned release's files byte for byte, the facts are the shape the scanner reads, and they still hold what every PHP since 7.4 must (PHP 8.0 removed `each` and `create_function`; 8.4 the imap and pspell extensions). A copy one byte off fails the build. `gen/fetch_catalogue.py` fetches them when the pin changes.
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

## Leaving checks out

Every check can be left out by name, with `--skip=NAME,NAME` (or `--skip` given more than once). A check left out prints a `SKIP` line in place of its result, does none of its work (the slow ones, room and local changes and the scan, are the usual reasons), and the summary at the end names what wasn't checked, so a skipped check never reads as a pass. A name that isn't a check stops the tool before it does anything, with the list of names; `--list-checks` prints them too. What every check needs (the install's version, the release facts, the site and the database connection) can't be left out.

**Pre-flight check** (`php openemr-preflight.php --openemr=... --skip=room,local-changes`):

<!-- skip-names: openemr-preflight.php -->
| Name | Leaves out |
|---|---|
| `xampp` | the XAMPP check |
| `php` | the PHP version against the target's |
| `php-extensions` | the extensions the target requires (and the plan's step to install them) |
| `database-server` | the database server against those CI tested (and the plan's step to upgrade it) |
| `previous-upgrade` | the database version against the code's |
| `settings` | settings the target removes that this install changed |
| `modules` | the module report (the list is still worked out, for `site-code`) |
| `custom-menus` | menus in use that link to removed files |
| `local-changes` | OpenEMR's own files changed here (it hashes every shipped file) |
| `site-code` | the site's own code read for what the new PHP removes |
| `room` | free space for the backup and the new release (it measures the code and documents) |
| `room-in-database` | free space for the tables the upgrade alters |
| `memory` | available memory |

**Install doctor** (`--skip=...` on the command line, `?skip=...` in the browser, or `--skip=` / `SKIP=` with `openemr-doctor-docker.sh`):

<!-- skip-names: openemr-doctor.php -->
| Name | Leaves out |
|---|---|
| `php` | the PHP version against the release's |
| `php-security` | the php2shell check |
| `php-extensions` | the extensions the release requires |
| `php-ini` | display_errors, the php.ini limits and the session folder |
| `php-libraries` | the Composer packages in vendor/ (and the Composer modules) |
| `page-assets` | the built files every page loads |
| `files` | every file the release package ships (and the setup scripts note) |
| `local-changes` | OpenEMR's own files edited here (it hashes every shipped file), and so the scan of them |
| `local-changes-php` | only the scan of edited files for what this PHP removed |
| `documents-folder` | who can write sites/<site>/documents |
| `database-server` | the database server against those CI tested |
| `database-version` | the database version against the code's |
| `theme` | the chosen theme's stylesheet |
| `error-display` | OpenEMR's own "show PHP errors" setting |
| `modules` | modules switched on whose files are missing |
| `encryption-keys` | the keys folder against the database's keys |
| `documents` | each stored document's file (it checks for up to 20 seconds) |
| `api-keys` | the API's key pair, when an API is on |

**Upgrade script** (`openemr-upgrade.sh ... --skip=scan,room`): one name of its own, `scan`, which leaves step 4's reading of what goes in for what PHP removed out, so it can't stop there. Any other name goes on to the pre-flight check (step 1) or the doctor (step 8), whichever knows it. The steps themselves (backup, upgrade, switch) can't be skipped; `--force` goes on past a failed check, which is a different thing: the check still runs and its failure is shown.

**Without scan.php.** The scanner is a file of its own, so the tools work without it: the pre-flight check and the doctor say the scan was skipped, and the upgrade script goes on if it can't fetch it. To leave it out on purpose, use `--skip=site-code` (pre-flight check), `--skip=local-changes-php` (doctor) or `--skip=scan` (upgrade script, which also passes the other two on if given).

**The other optional parts.** `--facts=DIR` reads the facts from a folder instead of downloading them, for a server without internet. `OPENEMR_REFERENCE_NO_UPDATE_CHECK=1` stops the doctor, the upgrade script and the Docker wrapper asking GitHub whether a newer release of these tools is out. The upgrade script's `--customizations=apply|leave` chooses whether this install's own changes go into the new release.

## PHP changes in a site's own code

A PHP upgrade breaks code that uses what PHP removed: `each()` and `create_function()` in PHP 8.0, string offsets written `$s{0}`, the imap extension in 8.4. OpenEMR's own code is tested on the PHP each release supports, but a site's own changes, added files and modules aren't. The scanner is [php-upgrade-catalogue](https://github.com/anun333/php-upgrade-catalogue)'s `scan.php` with its facts, measured on real PHP builds and checked against php-src, pinned here at a release (`gen/catalogue.json`) and shipped with these tools. It reads files and never runs them. A use behind `function_exists()`, `is_callable()`, `defined()`, `class_exists()`, `extension_loaded()` or a polyfill elsewhere in the install isn't counted; a guard covers its whole file, so it errs toward not failing.

- **The pre-flight check**, when the target needs a newer PHP: the files this site added and the modules the target doesn't ship, for what changes from this PHP to the one the target needs. Changed copies of OpenEMR's own files aren't read here, since the new release's copies replace them.
- **`openemr-upgrade.sh`, step 4:** what will go in, for the PHP running it: the lines each change writes on the new release's copy, and the added files and modules whole. It stops before the backup on any use that won't load or stops with an error, unless `--force`.
- **The doctor:** edited files of OpenEMR's own that parse, for what the PHP it runs on has removed, so a leftover `each()` explains a blank page after a PHP upgrade.
- **The upgrade notes:** each step that raises OpenEMR's PHP minimum lists what that PHP removed.

To read any folder yourself: `php scan.php --facts=php-changes.json --php=7.4:8.3 PATH` (add `--json` for one record per finding). The facts cover PHP 7.4 to 8.5; a newer PHP is said to be beyond them rather than passed.

## Limits

- Patches between releases (`vX_Y_Z_N` tags) and test builds aren't covered, except for the doctor's file lists.
- The upgrade notes (`site/`) cover the schema the upgrade scripts leave, not what they do to existing data; the receipts compare the data itself, on a rehearsal copy and on the live upgrade.
- A receipt's checksums are sums of CRC32 values, per column and per row: they show a change, not which row changed, and two changes that cancel out exactly would go unseen. The counts and money totals beside them are exact.
- For FHIR ids (`uuid`), which an upgrade fills in where they're empty, the receipts prove every id that was there is still in its table, on as many rows; not that each is still on the same row (row checksums leave ids out, since the upgrade changes them).
- Files removed under `interface/` and `portal/` include helper files as well as pages.
- CI-tested databases are what CI ran, not a support statement.
- The PHP changes are what the scanner can see without running code: a removed function, class, constant or setting, and syntax that no longer loads. A change in behaviour, such as how strings compare with numbers in PHP 8, needs the code run. A guard covers its whole file, so a use outside its `if` isn't counted.

### Not covered yet, and what comes next

These are the gaps that matter, most first. What isn't listed here is polish.

1. **PHP behaviour that depends on data.** The commonest PHP 8 breakage in old code isn't a removed function the scan can find: `count()` on null, a wrong type passed to a built-in function (now an error that stops the page), strings compared with numbers. Only running the code shows these. The rehearsal's access check now runs it on a sample: a sample of charts, one form of each kind, every document, the receipts report, every patient through the API, all on the upgraded copy with every PHP error logged (it found the 8.5.0 report crash above). **Next:** more of a site's pages (every report, the billing screens), and the site's own pages and modules.
2. **Servers other than Alpine.** The end-to-end suites run on OpenEMR's official Docker images, which are Alpine. The upgrade script is for tarball installs, and most of those run on Ubuntu or Debian with Apache, which the suites don't yet cover. **Next:** an Ubuntu tarball install with Apache in the upgrade suite.
3. **Real installs.** The tools have run on official images and synthetic data only. A real install has customizations and history the tests don't model, so the first runs on real servers are likely to find cases the suites don't have. Report them as issues on this repository.
4. **PHP 8.6.** It ships on 2026-11-19. php-upgrade-catalogue measures it then, and a release here pins the new facts. Until then a target on PHP 8.6 is reported as beyond the facts, not passed.
5. **Removed class methods and changed function signatures.** The catalogue covers removed functions, classes, constants and settings, and syntax that no longer loads; a method removed from a class, or a parameter a function no longer takes, isn't read yet.
6. **A site's own SQL and JavaScript.** Custom SQL can break on a newer MySQL or MariaDB, and custom JavaScript when OpenEMR moves to a newer jQuery or Bootstrap. These would be the same kind of check as the PHP scan, for the other layers, and are worth building only if real sites turn out to have much of either.
