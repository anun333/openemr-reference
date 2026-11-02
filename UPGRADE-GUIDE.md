# Upgrade OpenEMR 7.0 to 8.5 without losing anything

A checklist for whoever looks after the clinic's OpenEMR server. You don't need to be a programmer: copy each command, paste it into the terminal, press Enter, and check that you see what the step says you should see.

**How it keeps you safe:**
- Steps 1 to 5 never change your OpenEMR. They check your server and test the upgrade on a **copy** first.
- Step 6 changes your OpenEMR, only after the copy passed. If anything in your data doesn't match afterwards, step 6 **puts everything back by itself**.

**Time:** about 2 to 3 hours in all, mostly waiting. Nobody can use OpenEMR during step 6, which usually takes 15 to 45 minutes.

This is for an OpenEMR installed from the release download (a `.tar.gz`) on Ubuntu or a similar Linux. If yours runs in Docker, ask for help first.

---

## Before you start

Tick each box:

- [ ] I can log in to the OpenEMR server and use `sudo`.
- [ ] I have a computer with Docker. It can be the server itself. To check, type `docker compose version`: it must print a version number.
- [ ] I know my OpenEMR version. It's in OpenEMR under **Administration > About**, for example `7.0.3 (4)`.
- [ ] The server and the Docker computer can reach the internet (github.com).
- [ ] I have picked a quiet time for step 6, when nobody needs OpenEMR for an hour.
- [ ] I know who I will ask for help if a step says **STOP**.

---

## Step 0. Fill in your four values

Change these four lines to match your server, then paste them into the terminal:

```
OE=/var/www/html/openemr
FROM=7.0.3
DB=openemr
WEB=apache2
```

| Line | What to put |
|---|---|
| `OE` | the folder OpenEMR is in. `/var/www/html/openemr` is the usual one. |
| `FROM` | your version from **Administration > About**, without the part in brackets: `7.0.3 (4)` is `7.0.3`. |
| `DB` | your database's name. To see it, run `sudo grep dbase $OE/sites/default/sqlconf.php` and use the name between the quotes. |
| `WEB` | `apache2` on Ubuntu or Debian; `httpd` on Red Hat, Rocky or Alma. |

> If you close the terminal window, paste these four lines again before you go on.

---

## Step 1. Get the tools (on the server, 1 minute)

On the server, make a new empty folder, go into it, and paste:

```
FILES="openemr-rehearse.sh openemr-receipt.php openemr-doctor.php openemr-upgrade.sh openemr-preflight.php scan.php"
for f in $FILES SHA256SUMS; do
  curl -fsSLO https://github.com/anun333/openemr-reference/releases/latest/download/$f
done
for f in $FILES; do grep " $f\$" SHA256SUMS; done | sha256sum -c
```

**You should see:** six lines, each ending in `OK`.

**If any line says** `FAILED`: **STOP.** The download isn't the published file. Delete the folder and try again later.

If your Docker computer isn't the server, copy this folder to it too (a USB drive or `scp`).

---

## Step 2. Check the server is ready (on the server, 1 minute)

In the tools folder, paste:

```
sudo php openemr-preflight.php --openemr="$OE" --target=8.5.0
```

It only reads; it changes nothing.

**You should see, on the last line:** `No blocking problems found.` ("warning(s) to read" after it is fine; read them.)

**If it says** `Fix the ... failed check(s) before upgrading.`: **STOP.** The lines marked `FAIL` say what. The usual ones are PHP itself (OpenEMR 8.5 needs PHP 8.2 or later) and missing PHP extensions, such as `bcmath` or `imagick`. Updating PHP is a separate job, so ask whoever helps you, and come back to this guide once this step passes.

---

## Step 3. Copy your site (on the server, about 5 minutes)

In the tools folder, paste:

```
sudo mysqldump --single-transaction --routines --triggers "$DB" > site.sql
sudo tar -czf sites.tar.gz -C "$OE" sites
ls -lh site.sql sites.tar.gz
```

**You should see:** two files with sizes bigger than 0, such as `site.sql 812M`.

**If you see** `Access denied`: open `$OE/sites/default/sqlconf.php` and find the `$login` and `$pass` lines. Run the first command again as `sudo mysqldump -u LOGIN -p --single-transaction --routines --triggers "$DB" > site.sql`, with LOGIN replaced by the `$login` value, and type the `$pass` value when it asks for a password.

If your Docker computer isn't the server, copy these two files into the tools folder there.

> ⚠️ These two files hold **every patient's record**. Keep them on clinic computers only. Never email them or upload them anywhere.

---

## Step 4. Test the upgrade on the copy (on the Docker computer, 10 minutes to an hour)

In the tools folder, paste the four lines from step 0, then this, and **leave the window open** until it finishes:

```
bash openemr-rehearse.sh --dump=site.sql --sites=sites.tar.gz --from=$FROM --to=8.5.0
```

- The first time, it downloads OpenEMR's Docker images and says how much first. It also checks there's enough disk space.
- If it says `permission denied` about Docker, run the same command with `sudo` in front.
- It never touches your real OpenEMR.

---

## Step 5. Read the result

Scroll up through the end of what it printed and find these four lines:

| Look for | It means |
|---|---|
| `RESULT: MATCH` | Nothing was lost: every patient, visit, document and dollar counts the same after the upgrade as before. |
| `... checks pass, 0 fail, ...` | The install check found no problems. |
| `ACCESS: PASS` | OpenEMR could open every patient and every document on the upgraded copy. |
| `VERDICT: ready` | All good. `ready, with notes` is good too: read the notes above it. |

**If it says** `VERDICT: ready`: go on to step 6.

**If it says** `VERDICT: not ready`: **STOP.** Don't upgrade. Send the folder it names at the very end, `openemr-rehearsal-...`, to whoever helps you.
- That folder holds no patient data, except perhaps one file, `php-errors.log`, which can quote part of a record. Open it and check before you send it.
- Never send `site.sql` or `sites.tar.gz`.

**One known problem in OpenEMR itself (7.0.4 through 8.5.0):** if your clinic ever recorded co-pays from a visit's **Charges** screen (an option that's off unless "Use Charges Panel" was turned on), the report **Receipts by Payment Method** shows an error for dates that include one of those co-pays, and step 5's result will mention it. Co-pays added on the Fee Sheet don't cause it. That is a bug in OpenEMR, not a problem with your data; a fix has been offered to OpenEMR (pull request 15001). Ask whoever helps you whether you can manage without that report until it's fixed.

---

## Step 6. Upgrade the real OpenEMR (on the server, 15 to 45 minutes)

1. At your quiet time, tell everyone to log out of OpenEMR and stay out until you say.
2. Go into the tools folder from step 1, paste the four lines from step 0 again, then:

```
sudo bash openemr-upgrade.sh --openemr="$OE" --to=8.5.0 --service="$WEB" --backup-dir=/root/openemr-backups
```

3. It checks the server and asks `Continue?`. Type `y` and press Enter.
4. Wait. It stops the website, makes a backup, upgrades, and checks your data before and after.

**You should see, at the end:** `Done: ... is OpenEMR 8.5.0`.

**If you see** `STOPPED AND PUT BACK`:
- Your data didn't match, so it **already put everything back**. OpenEMR is the old version again, with all your data, and running. People can work again.
- Don't try again yet. Send `receipts-default-compared.txt` from the backup folder (inside `/root/openemr-backups`) to whoever helps you. It has no patient data.

**If it stops and says** `nothing on the server was changed`: your OpenEMR is untouched and running. Fix what the message says, or ask for help, then try step 6 again.

**If it stops any other way:** it prints a command that puts everything back. Copy that command, paste it, and press Enter. Then ask for help.

---

## Step 7. Check it yourself (10 minutes)

1. Log in to OpenEMR. **Administration > About** should say `8.5.0`.
2. Open three patients you know, including one with documents. Open one document.
3. Open **Reports > Financial > Receipts by Payment Method**. Choose Report by **Payment Method**, **Payment Date**, and last year from January 1 to December 31.
4. Compare its **Grand Total** with the line for last year under "Receipts by year" in `receipt-default-before.txt`, in the backup folder. They should be the same.
5. Tell everyone they can use OpenEMR again.

---

## If something is wrong in the days after

Paste the four lines from step 0, then:

```
sudo bash openemr-upgrade.sh --rollback --openemr="$OE"
```

This goes back to your old version, with the database as it was before the upgrade. It first saves a copy of everything entered since the upgrade, so nothing is thrown away. Ask for help with getting that newer work back in.

---

## After two weeks with no problems: tidy up

- Delete the file `.openemr-upgrade-state` next to your OpenEMR folder, for example `sudo rm /var/www/html/.openemr-upgrade-state`. Undoing the upgrade isn't possible after this.
- Later, delete the old folder (for example `/var/www/html/openemr.old-7.0.3`) and the backup folder in `/root/openemr-backups`.
- Delete `site.sql` and `sites.tar.gz` from step 3.

> ⚠️ The backup and the step 3 files hold patient records. Delete them the way your clinic deletes any patient data.

---

## Words used here

- **Copy / rehearsal:** a test run of the upgrade on a copy of your site, in Docker, away from your real OpenEMR.
- **Receipt:** a count of what your clinic has: patients, visits, appointments, prescriptions, lab results, documents and money totals. It holds no patient names or details. Before and after must match.
- **Install check (doctor):** a check that OpenEMR's files, settings and server are all right.
- **Rollback / put back:** returning to the old version and the backup.

What each receipt line counts, and more about each step: [the details](UPGRADE-GUIDE-DETAILS.md). How the tools were tested: [README](README.md).
