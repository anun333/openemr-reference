# Upgrading OpenEMR without losing anything: the details

The step-by-step checklist is [UPGRADE-GUIDE.md](UPGRADE-GUIDE.md). This page explains each step, what a receipt counts, and what to do when something stops.

For whoever looks after an OpenEMR installed from the release tarball (on Ubuntu or a similar Linux), moving from 7.0.x to 8.5.0. No programming is needed: you copy and paste the commands below, in order, and read what they print.

The order is the point. Steps 1 to 3 only read your live system: they work on a copy. Step 4 changes the live system, and only after the copy has shown the upgrade works. Step 4 then checks itself: if anything in your data changed that shouldn't have, it puts everything back by itself.

You need:
- root (sudo) on the OpenEMR server;
- a machine with Docker for the rehearsal. It can be the server itself: the rehearsal is capped (3 CPUs and 6 GB of memory unless you say otherwise) so it can't slow your OpenEMR down;
- room on that machine. The rehearsal says how much before it starts.

Your release and patch are in OpenEMR under **Administration › About**. The commands below use `7.0.3`, the folder `/var/www/html/openemr` and the database `openemr`: put in your own. The database's name is the `$dbase` line in `sites/default/sqlconf.php`.

## 1. Copy your site

On the server:

```
sudo mysqldump --single-transaction --routines --triggers openemr > site.sql
sudo tar -czf sites.tar.gz -C /var/www/html/openemr sites
```

If `mysqldump` asks for a password or says access is denied, add the user and password from `sites/default/sqlconf.php` (the `$login` and `$pass` lines): `mysqldump -u LOGIN -p --single-transaction ...`, and type the password when asked.

`site.sql` is the database; `sites.tar.gz` is the `sites/` folder, with your documents and the keys that unlock them. Together they are your whole site. **They hold every patient's record:** keep them on your own machines, never email them, and delete them when you're done.

## 2. Get the tools

On the machine with Docker, in an empty folder:

```
FILES="openemr-rehearse.sh openemr-receipt.php openemr-doctor.php openemr-upgrade.sh openemr-preflight.php scan.php"
for f in $FILES SHA256SUMS; do
  curl -fsSLO https://github.com/anun333/openemr-reference/releases/latest/download/$f
done
for f in $FILES; do grep " $f\$" SHA256SUMS; done | sha256sum -c
```

(This checks only the files you downloaded, and works with GNU's `sha256sum` and with BusyBox's, as in OpenEMR's Docker image, which has no `--ignore-missing`.)

Every line must end in `OK`. If one doesn't, stop: the file isn't the one published. Copy the same folder to the server for step 4.

## 3. Rehearse on the copy

```
bash openemr-rehearse.sh --dump=site.sql --sites=sites.tar.gz --from=7.0.3 --to=8.5.0
```

It takes from 10 minutes to an hour, depending on the size of your site. It upgrades a copy in Docker, never your live system, and checks the copy three ways:

1. **Receipts.** A receipt is a count of what your clinic has: patients, visits, appointments, prescriptions, lab orders and results, documents, and the money. It is taken of the copy before the upgrade and again after, and the two must say `RESULT: MATCH`.
2. **The install doctor** checks the upgraded copy the way it will check your server. It must show `0 fail`.
3. **The access check** has OpenEMR itself read your data back: it logs in, reads every patient, opens every document, runs the money reports, and opens a sample of charts in a browser. It must end `ACCESS: PASS`.

The last line is the verdict. **Go on to step 4 only if it says `VERDICT: ready`.** If it says `not ready`, the lines marked `FAIL` or `DIFF` above say why. Send the folder it names at the end (`openemr-rehearsal-...`) to whoever helps you: the report and the receipts in it hold no patient data. One file there, `php-errors.log`, may quote part of a record in an error message: read it before you send it.

A known problem in OpenEMR itself, from 7.0.4 through 8.5.0: if your clinic recorded co-pays from a visit's Charges screen (shown only with "Use Charges Panel" on, which is off by default; imports can write the same rows), the report **Receipts by Payment Method** stops with an error for any dates that include one of those co-pays, and the access check says so. Co-pays added on the Fee Sheet are stored as payments and don't cause it. That is OpenEMR's bug, not your data; the fix is offered as openemr/openemr#15001. Decide with whoever helps you whether you can do without that report until it is fixed.

## Reading a receipt

Each line of "What the clinic has" and "Money" counts one thing, for the whole site:

| Line | What it counts | Where to see it in OpenEMR |
|---|---|---|
| Patients | every patient record | Patient › Finder, all |
| Encounters (visits) | every visit | a patient's encounter list |
| Appointments (with a patient) | every calendar appointment for a patient | the calendar |
| Prescriptions | every prescription | a patient's prescriptions |
| Lab orders, Lab results | every order, every result line | Procedures › Lab results |
| Documents (database rows) | every document OpenEMR knows | a patient's Documents |
| Document files on disk | the files those documents are, with their total size and a checksum (a fingerprint of every byte) | |
| Document files missing | documents whose file isn't on disk | |
| Charges (fee sheet) | everything charged on fee sheets, removed lines left out | |
| Co-pays (billing lines) | co-pays kept as billing lines: the Charges screen's Copay, old data and imports (the Fee Sheet's Add Copay is a payment, counted under Payments) | |
| Drug sales | drugs dispensed and charged | |
| Payments, Adjustments | every payment and adjustment posted, voided ones left out | |
| Balance | charges and drug sales, less co-pays, payments and adjustments | each patient's dashboard, Billing card, **Total Balance Due**, added up over all patients |
| Receipts by year | payments by the date they were paid | **Reports › Financial › Receipts by Payment Method**, Report by: Payment Method, Payment Date, January 1 to December 31: the **Grand Total** line |

The last part, "Every table", gives each table of the database a checksum, so that a change anywhere is seen, not only in the lines above.

When two receipts are compared, each line says `same` or `DIFF`. Lines marked `ok` under "Every table" are changes the upgrade always makes, each with its reason: it gives records that lacked one an ID for OpenEMR's FHIR interface, it fixes a misspelled code, it records an empty appointment end date in a new way. A figure in "What the clinic has" or "Money" is never allowed to change.

## 4. Upgrade the live system

Choose a quiet time and tell everyone to stay out of OpenEMR until you say. On the server, in the folder with the tools:

```
sudo bash openemr-upgrade.sh --openemr=/var/www/html/openemr --to=8.5.0 --service=apache2 --backup-dir=/root/openemr-backups
```

(`apache2` is the web server's name on Ubuntu; `httpd` on Red Hat and its relatives.) It checks the server first and asks `Continue?` Answer `y`. Then, in order, it:

1. stops the web server, so nobody can change anything;
2. takes a receipt of your site;
3. backs up the database and the `sites/` folder, and checks that the backup is whole;
4. upgrades a copy of the program beside the old one, and the database;
5. takes a second receipt and compares it with the first;
6. runs the install doctor;
7. switches to the new release and starts the web server.

It prints `Done` at the end. Log in, open a few patients, and run Receipts by Payment Method for last year: it shows the same totals as the receipt. The receipts and their comparison are in the backup folder it named.

## If it stops

- **Before the backup** (it says "nothing on the server was changed"): your OpenEMR is as it was, and running. Fix what the message says, and run the command again.
- **"STOPPED AND PUT BACK"**: the second receipt didn't match the first. It has already put everything back: your OpenEMR is the old release, its database is restored from the backup made minutes before, and a third receipt shows it matches the first. Users can work again. Don't run the upgrade again until someone has read why: send them `receipts-default-compared.txt` from the backup folder. It holds no patient data.
- **Any other stop after the backup**: it prints the exact command that puts everything back. Run it.

## Rolling back later

If something is wrong after the upgrade, within days:

```
sudo bash openemr-upgrade.sh --rollback --openemr=/var/www/html/openemr
```

It first saves the database as it is (with everything entered since the upgrade), then restores the backup, checks the restored database against the receipt taken before the upgrade, and switches the folders back. Nothing is deleted.

When you're sure all is well, after a week or two: delete the file `/var/www/html/.openemr-upgrade-state` (the rollback needs it until then), and later the old folder (`openemr.old-7.0.3`) and the backup folder. The backup holds patient records: delete it the way you delete any.

## More

- What each tool checks, and how it was tested: [README](README.md).
- Trying the UDS Report module on the rehearsal copy before you upgrade: [Run your UDS report on a rehearsal copy](https://github.com/anun333/oe-module-uds-report/blob/main/docs/rehearsal-copy.md).
