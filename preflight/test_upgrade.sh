#!/usr/bin/env bash
# End-to-end test of openemr-upgrade.sh: a throwaway OpenEMR 7.0.3 (official image) on MariaDB 10.11,
# or the server DB_IMAGE names (mariadb:10.6, mariadb:11.8, mysql:8.0, mysql:8.4), loaded with the
# synthetic Pohnpei-shaped site (test_site.py: patients, visits, appointments, prescriptions, lab
# results, payments and adjustments, and documents stored by OpenEMR's own code), or with the dump
# given as the argument; upgraded to 8.5.0 (TO=) with the script (release downloaded from GitHub,
# sha256 checked), then rolled back. Checks the version, the login page, the patients and the tables
# after each, and the receipts both ways: on a clean upgrade they match; a change made during the
# upgrade (a payment deleted; a charge and a date of birth edited) makes them disagree, the script
# puts everything back by itself, and a receipt taken afterwards matches the first.
# Everything runs in containers deleted at the end.
#   preflight/test_upgrade.sh [7.0.3-dump.sql]        (DB_IMAGE=mysql:8.0 TO=8.5.0 RECEIPTS_ONLY=1 KEEP=1)
set -euo pipefail
cd "$(dirname "$0")"
. ./test_lib.sh
serial
LOG="$(mktemp -d)"; P=upgrade-test; C=$P-openemr-1; D=$P-mysql-1; OE=/var/www/localhost/htdocs/openemr; TO=${TO:-8.5.0}
export DB_IMAGE="${DB_IMAGE:-mariadb:10.11}"
echo "database server: $DB_IMAGE; upgrading OpenEMR 7.0.3 to $TO; logs in $LOG"
docker compose -p $P -f test-upgrade-compose.yml up -d >/dev/null
# KEEP=1 leaves the containers running to look around (delete with: docker compose -p upgrade-test -f test-upgrade-compose.yml down -v).
[[ "${KEEP:-0}" == 1 ]] || trap 'docker compose -p $P -f test-upgrade-compose.yml down -v >/dev/null 2>&1' EXIT
echo "waiting for OpenEMR 7.0.3 to install itself (about 6 minutes)..."
wait_ready $C $OE
DBC=$(docker exec $D sh -c 'command -v mariadb >/dev/null && echo mariadb || echo mysql')
DUMPER=$(docker exec $D sh -c 'command -v mariadb-dump >/dev/null && echo mariadb-dump || echo mysqldump')
q() { docker exec $D $DBC -uroot -proot -N openemr -e "$1" 2>/dev/null; }
SYNTHETIC=1
if [[ -n "${1:-}" ]]; then
    SYNTHETIC=0
    docker exec -i $D $DBC -uroot -proot openemr < "$1"
else
    python3 -I test_site.py 2>/dev/null | docker exec -i $D $DBC -uroot -proot openemr
    python3 -I test_site.py --documents 2>/dev/null > "$LOG/documents.php"
    docker cp "$LOG/documents.php" $C:$OE/synthetic-documents.php
    docker exec -u apache -w $OE $C php synthetic-documents.php 2>/dev/null | sed 's/^/  /'
    docker exec $C rm -f $OE/synthetic-documents.php
fi
echo "loaded: $(q 'SELECT COUNT(*) FROM patient_data') patients, $(q 'SELECT COUNT(*) FROM form_encounter') encounters, $(q 'SELECT COUNT(*) FROM documents') documents"
# The 7.0.3 image lacks two extensions the target needs (the pre-flight check says so); add them as an
# admin would, and bash and patch, which servers usually have and this Alpine image doesn't.
docker exec $C apk add --no-cache bash patch php83-bcmath php83-pecl-imagick >/dev/null
docker exec $C mkdir -p /root/tools /root/backups /root/cache
for f in openemr-upgrade.sh openemr-preflight.php openemr-doctor.php openemr-receipt.php scan.php; do docker cp $f $C:/root/tools/; done
# This checkout's facts beside the tools (/root/site/preflight), as when run from a clone, so the test
# uses the facts it was built with, not the published ones.
docker exec $C mkdir -p /root/site && docker cp ../site/preflight $C:/root/site/preflight
# The release, downloaded once with its published sha256, for the runs that aren't about downloading
# (--tarball checks it against the .sha256 beside it). The clean upgrade below downloads it itself.
url="https://github.com/openemr/openemr/releases/download/v${TO//./_}/openemr-$TO.tar.gz"
docker exec $C sh -c "cd /root/cache && curl -fsSL -o openemr-$TO.tar.gz '$url' && curl -fsSL -o openemr-$TO.tar.gz.sha256 '$url.sha256'"
TARBALL=/root/cache/openemr-$TO.tar.gz
state() {
    echo "$(q "SELECT CONCAT(v_major,'.',v_minor,'.',v_patch,' db ',v_database) FROM version")|$(q 'SELECT COUNT(*) FROM patient_data')|$(q "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'openemr'")|$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8372/interface/login/login.php?site=default)"
}
fails=0
check() { if [[ "$1" == "$2" ]]; then echo "ok   $3"; else echo "FAIL $3: got '$1', expected '$2'"; fails=$((fails + 1)); fi; }
IFS='|' read -r v0 p0 t0 l0 <<<"$(state)"
echo "before: OpenEMR $v0, $p0 patients, $t0 tables, login page HTTP $l0"

# The receipt of the site as loaded, taken by the test itself: what every later receipt is compared with.
receipt() {  # receipt FILE LABEL [options]: the test's own receipt of the live site
    local f="$1" l="$2"; shift 2
    docker exec $C php /root/tools/openemr-receipt.php --openemr=$OE --label="$l" --out="$f" "$@"
}
FLOORS=patients,encounters,appointments,prescriptions,lab_orders,lab_results,documents,document_files,charges,payments,adjustments,balance
floors=(); (( ! SYNTHETIC )) || floors=("--require=$FLOORS")
set +e; receipt /root/receipt-start.json "the test's own, at the start" ${floors[@]+"${floors[@]}"} > "$LOG/receipt-start.txt" 2>&1; rc=$?; set -e
sed -n '/^What the clinic has/,/^  Balance /p' "$LOG/receipt-start.txt" | sed 's/^/    /' || true
check "$rc" 0 "receipt: the site has patients, visits, appointments, prescriptions, labs, documents on disk, charges, payments, adjustments and a balance (floors)"
# The comparison itself, both ways, before any upgrade: a receipt matches itself, and a planted
# difference in a money figure, a count and a table's checksum each make it say DIFFERENT.
set +e; docker exec $C php /root/tools/openemr-receipt.php --compare /root/receipt-start.json /root/receipt-start.json > "$LOG/self.txt"; rc=$?; set -e
check "$rc|$(grep -c '^RESULT: MATCH' "$LOG/self.txt")" "0|1" "receipt: a receipt compared with itself is a MATCH"
docker exec $C php -r '$r = json_decode(file_get_contents("/root/receipt-start.json"), true);
    $r["figures"]["payments"] = number_format($r["figures"]["payments"] - 7, 2, ".", ""); $r["figures"]["patients"] = (string)($r["figures"]["patients"] - 1);
    $r["tables"]["prescriptions"]["columns"]["dosage"]["sum"] .= "9"; file_put_contents("/root/receipt-planted.json", json_encode($r));'
set +e; docker exec $C php /root/tools/openemr-receipt.php --compare /root/receipt-start.json /root/receipt-planted.json > "$LOG/planted.txt"; rc=$?; set -e
check "$rc|$(grep -c '^RESULT: DIFFERENT. 3 differences' "$LOG/planted.txt")" "1|1" "receipt: three planted differences make it DIFFERENT, with exit 1"
check "$(grep -cE '^  DIFF (Payments: .* before, .* after|Patients: .* before|prescriptions, a patient table, changed in place: dosage)' "$LOG/planted.txt")" 3 "receipt: and it names each (payments, patients, prescriptions.dosage)"

# Local changes to OpenEMR's own files, as a clinic makes them (synthetic):
#   a template edit in a file the target didn't change (applies cleanly),
#   an edit to a line the target rewrote (conflicts; the @link line went from http to https),
#   a report file of its own (added); and, apart, an added file calling each(), which PHP 8.0 removed.
TWIG=interface/forms/newpatient/templates/newpatient/partials/common/_form-heading.html.twig
REPORT=interface/reports/appointments_report.php
ADDED=interface/reports/synthetic_custom_report.php
docker exec $C sh -c "echo '{# synthetic local change #}' >> $OE/$TWIG && sed -i '12s|.*| * @link      http://www.open-emr.org (synthetic local change)|' $OE/$REPORT && echo '<?php // synthetic custom report' > $OE/$ADDED && chown apache $OE/$ADDED"
# up [-e VAR=VALUE]... [SCRIPT OPTIONS]: the upgrade, from the downloaded release.
up() {
    local envs=()
    while [[ "${1:-}" == -e ]]; do envs+=(-e "$2"); shift 2; done
    docker exec ${envs[@]+"${envs[@]}"} $C bash /root/tools/openemr-upgrade.sh --openemr=$OE --to=$TO --tarball=$TARBALL --yes --backup-dir=/root/backups "$@"
}
# A full dump of the database, and its checksum. One difference in wording is read as none: MySQL 8.0,
# after a dump is restored, writes each text column's character set out (CHARACTER SET utf8mb4
# COLLATE utf8mb4_general_ci) where it wrote only the collation before (COLLATE utf8mb4_general_ci).
# Same character set, same collation (the rollback's strict receipt compares each column's), and
# only where the collation belongs to that character set. MariaDB writes it the same either way.
dumpdb() { docker exec $D sh -c "$DUMPER -uroot -proot --skip-dump-date --skip-comments openemr 2>/dev/null" | sed -E 's/ CHARACTER SET ([a-z0-9]+) COLLATE (\1_[a-z0-9_]+)/ COLLATE \2/g'; }
sig() { dumpdb | md5sum | cut -d' ' -f1; }
# RECEIPTS_ONLY=1 (the other database servers) leaves out what doesn't touch the database server:
# local changes, the PHP scan, --skip, downloads, the lock, and the stops before and after the backup.
FULL=1; [[ "${RECEIPTS_ONLY:-0}" != 1 ]] || FULL=0
if (( FULL )); then

# Without --customizations it must stop before changing anything, and say what it found.
set +e; up > "$LOG/upgrade-stop.log" 2>&1; rc=$?; set -e
grep -E "^== 2|changed  |added    .*synthetic|^STOP" "$LOG/upgrade-stop.log" | sed 's/^/    /' | cut -c1-160 || true
check "$([[ $rc -ne 0 ]] && echo stopped)" stopped "local changes: without --customizations the script stops"
IFS='|' read -r vs _ _ _ <<<"$(state)"
check "$vs" "$v0" "local changes: nothing changed (still $v0)"
report() { docker exec $C sh -c "cat /root/backups/*/customizations/report.json"; }
check "$(report | python3 -c 'import json, sys; print(json.load(sys.stdin).get("changed", {}).get(sys.argv[1], {}).get("status", "missing"))' "$TWIG")" applies "local changes: the template edit is found, and applies to $TO"
check "$(report | python3 -c 'import json, sys; print(json.load(sys.stdin).get("changed", {}).get(sys.argv[1], {}).get("status", "missing"))' "$REPORT")" conflicts "local changes: the edit to a line $TO rewrote is found, as a conflict"
check "$(report | python3 -c 'import json, sys; print("found" if sys.argv[1] in json.load(sys.stdin).get("added", []) else "missing")' "$ADDED")" found "local changes: the added report is found"
check "$(grep -c 'before the backup was finished: nothing on the server was changed' "$LOG/upgrade-stop.log")" 1 "local changes: the stop says nothing on the server changed"
docker exec $C sh -c 'rm -rf /root/backups/*'

# What goes in is read for what this PHP removed (scan.php): an added file calling each(), which PHP
# 8.0 removed, stops step 4 before the backup; with --force it goes on (stopped before step 5 here).
EACH=interface/reports/synthetic_each_report.php
docker exec $C sh -c "printf '%s\n' '<?php' '\$synthetic = [1];' 'while (list(, \$value) = each(\$synthetic)) {' '}' > $OE/$EACH && chown apache $OE/$EACH"
set +e; up -e OPENEMR_UPGRADE_TEST_FAIL_BEFORE_STEP=5 --customizations=apply > "$LOG/scan-stop.log" 2>&1; rc=$?; set -e
grep -E "STOP|deprecated in|On PHP" "$LOG/scan-stop.log" | sed 's/^/    /' | cut -c1-160 || true
check "$(grep -cE "STOP in added files +$EACH line 3 each \(error when it runs\)" "$LOG/scan-stop.log")" 1 "PHP changes: an added file calling each() is named, with its line"
check "$(grep -c "won't load or stops with an error on PHP 8.3 (1 of the STOP lines above). Nothing on the server has changed." "$LOG/scan-stop.log")" 1 "PHP changes: step 4 stops before anything changes"
check "$(grep -c '^== 5' "$LOG/scan-stop.log" || true)" 0 "PHP changes: and goes no further"
docker exec $C sh -c 'rm -rf /root/backups/*'
set +e; up -e OPENEMR_UPGRADE_TEST_FAIL_BEFORE_STEP=5 --customizations=apply --force > "$LOG/scan-force.log" 2>&1; rc=$?; set -e
check "$(grep -c -- '--force: going on, though code that goes in' "$LOG/scan-force.log")" 1 "PHP changes: with --force it goes on, and says so"
docker exec $C sh -c 'rm -rf /root/backups/*'
# --skip: scan is this script's own (step 4 then reads nothing, so the each() above doesn't stop it);
# room goes on to the pre-flight check; a name none of them knows stops it before anything changes.
set +e; up -e OPENEMR_UPGRADE_TEST_FAIL_BEFORE_STEP=5 --customizations=apply --skip=scan,room > "$LOG/skip.log" 2>&1; set -e
check "$(grep -c '^SKIP  Room: left out (--skip=room)' "$LOG/skip.log")" 1 "skip: room goes on to the pre-flight check"
check "$(grep -c 'SKIP  what goes in, read for what PHP removed: left out (--skip=scan)' "$LOG/skip.log")" 1 "skip: scan leaves step 4's reading out"
check "$(grep -c 'stopped before step 5 for a test' "$LOG/skip.log")" 1 "skip: so step 4 doesn't stop on the each() it would have read"
docker exec $C sh -c 'rm -rf /root/backups/*'
set +e; up --customizations=apply --skip=bogus > "$LOG/skip-bad.log" 2>&1; rc=$?; set -e
check "$(grep -c "^STOP: --skip: no check named 'bogus'" "$LOG/skip-bad.log")" 1 "skip: a name none of the tools knows is refused"
check "$(grep -c '^== 2' "$LOG/skip-bad.log" || true)" 0 "skip: before it gets the release"
docker exec $C sh -c "rm -rf /root/backups/* $OE/$EACH"

# The helpers, when they aren't beside the script, come from the script's own release and must match
# its SHA256SUMS: a release folder of our own (file://), first with a changed pre-flight check.
docker exec $C sh -c "mkdir -p /root/alone /root/rel && cp /root/tools/openemr-upgrade.sh /root/alone/ && cp /root/tools/openemr-preflight.php /root/tools/openemr-doctor.php /root/tools/openemr-receipt.php /root/tools/scan.php /root/rel/ && cd /root/rel && echo '// changed' >> openemr-preflight.php && sha256sum openemr-doctor.php openemr-receipt.php scan.php > SHA256SUMS && cp /root/tools/openemr-preflight.php /tmp/pf && sha256sum /tmp/pf | sed 's| /tmp/pf| openemr-preflight.php|' >> SHA256SUMS"
alone() { set +e; docker exec -e OPENEMR_REFERENCE_BASE=file:///root/rel "$@" $C bash /root/alone/openemr-upgrade.sh --openemr=$OE --to=$TO --tarball=$TARBALL --yes --backup-dir=/root/backups --customizations=apply > "$LOG/alone.log" 2>&1; rc=$?; set -e; }
alone
check "$(grep -c "openemr-preflight.php from file:///root/rel doesn't match that release's SHA256SUMS" "$LOG/alone.log")" 1 "downloads: a pre-flight check that doesn't match SHA256SUMS is refused"
check "$(grep -c '^== 2' "$LOG/alone.log" || true)" 0 "downloads: and the upgrade goes no further"
docker exec $C sh -c "cp /root/tools/openemr-preflight.php /root/rel/ && rm -rf /root/backups/*"
alone -e OPENEMR_UPGRADE_TEST_FAIL_BEFORE_STEP=2
version="$(sed -n 's/^SCRIPT_VERSION=//p' openemr-upgrade.sh)"
check "$(grep -c "openemr-preflight.php downloaded from release v$version matches its SHA256SUMS" "$LOG/alone.log")" 1 "downloads: one that matches is used"
check "$(grep -c "openemr-receipt.php downloaded from release v$version matches its SHA256SUMS" "$LOG/alone.log")" 1 "downloads: the receipt too"
docker exec $C sh -c 'rm -rf /root/backups/* /root/alone /root/rel /tmp/pf'

# One run at a time: while another holds the lock, a second refuses to start.
docker exec -d $C flock "$(dirname "$OE")/.openemr-upgrade.lock" sleep 120
sleep 2
set +e; up --customizations=apply > "$LOG/locked.log" 2>&1; rc=$?; set -e
check "$(grep -c 'another openemr-upgrade.sh is already running' "$LOG/locked.log")" 1 "lock: a second run refuses to start"
docker exec $C pkill -f 'sleep 120' || true
docker exec $C sh -c 'rm -rf /root/backups/*'

# A stop before the backup takes the unpacked folder away again and changes nothing.
set +e; up -e OPENEMR_UPGRADE_TEST_FAIL_BEFORE_STEP=5 --customizations=apply > "$LOG/stop5.log" 2>&1; rc=$?; set -e
check "$(grep -c 'Stopped during step 5. Stopping the web server, taking a receipt and backing up (exit 1), before the backup was finished' "$LOG/stop5.log")" 1 "stop before the backup: says so"
check "$(docker exec $C sh -c "test -e $OE.new-$TO && echo left || echo gone")" gone "stop before the backup: the unpacked folder is removed"
IFS='|' read -r vs _ _ _ <<<"$(state)"
check "$vs" "$v0" "stop before the backup: nothing changed (still $v0)"
docker exec $C sh -c 'rm -rf /root/backups/*'

# A stop after the backup says how far it got and how to get back, and the rollback it names works.
set +e; up -e OPENEMR_UPGRADE_TEST_FAIL_BEFORE_STEP=7 --customizations=apply > "$LOG/stop7.log" 2>&1; rc=$?; set -e
grep -E "check:|receipt before|^Stopped|To put everything back|log of this run" "$LOG/stop7.log" | sed 's/^/    /' | cut -c1-200 || true
check "$(grep -c 'Stopped during step 7.* after the backup' "$LOG/stop7.log")" 1 "stop after the backup: says how far it got"
check "$(grep -c -- "To put everything back as it was before the upgrade:  /root/tools/openemr-upgrade.sh --rollback --openemr=$OE" "$LOG/stop7.log")" 1 "stop after the backup: gives the rollback command"
check "$(grep -c "check: default: the dump is complete ('Dump completed') and has all [0-9]* tables, as the receipt" "$LOG/stop7.log")" 1 "self-check: the dump is verified complete, with as many tables as the receipt read"
check "$(grep -c 'check: sites.tar.gz reads back whole: [0-9]* files and [0-9]* bytes' "$LOG/stop7.log")" 1 "self-check: sites.tar.gz is read back, every byte"
check "$(grep -c 'check: sites/ copied whole into the new folder' "$LOG/stop7.log")" 1 "self-check: the copied sites/ is counted"
check "$(grep -c 'default: receipt before the upgrade: ' "$LOG/stop7.log")" 1 "receipt: taken at step 5, before the backup, and summed up in plain words"
check "$(docker exec $C sh -c 'ls /root/backups/*/receipt-default-before.json /root/backups/*/receipt-default-before.txt | wc -l')" 2 "receipt: kept in the backup folder (.json and .txt)"
set +e; docker exec $C bash /root/tools/openemr-upgrade.sh --rollback --openemr=$OE > "$LOG/rollback7.log" 2>&1; rc=$?; set -e
check "$rc" 0 "stop after the backup: the rollback finishes"
IFS='|' read -r vr pr tr lr <<<"$(state)"
check "$vr|$pr|$tr|$lr" "$v0|$p0|$t0|200" "stop after the backup: the rollback puts back the same version, patients, tables and login page"
check "$(grep -c "check: default: openemr is ${v0%% db *} again" "$LOG/rollback7.log")" 1 "self-check: the rollback verifies the database version"
check "$(grep -c 'check: default: the restored database and documents match the receipt taken before the upgrade, every table' "$LOG/rollback7.log")" 1 "self-check: the rollback checks the restored database against the receipt"
docker exec $C sh -c "rm -rf /root/backups/* $OE.failed-*"

# A failure partway through the database upgrade, the case the rollback is for. Two identical
# synthetic telemetry rows make the upgrade's unique key on track_events fail (7.0.3 to 7.0.4),
# while the statements before and after it run. The rollback must then put the database back
# exactly: a full dump of it must be byte-for-byte the one taken before.
docker exec $D sh -c "$DUMPER -uroot -proot openemr > /tmp/clean.sql 2>/dev/null"
clean=$(sig)
q "CREATE TABLE IF NOT EXISTS track_events (id INT(11) UNSIGNED NOT NULL AUTO_INCREMENT, event_type TEXT, event_label VARCHAR(255) DEFAULT NULL, event_url TEXT, event_target TEXT, first_event DATETIME NULL, last_event DATETIME NULL, label_count INT UNSIGNED NOT NULL DEFAULT 1, PRIMARY KEY (id)) ENGINE=InnoDB"
for idx in $(q "SELECT DISTINCT index_name FROM information_schema.statistics WHERE table_schema = 'openemr' AND table_name = 'track_events' AND non_unique = 0 AND index_name <> 'PRIMARY'"); do q "ALTER TABLE track_events DROP INDEX \`$idx\`"; done
q "INSERT INTO track_events (event_type, event_label, event_url, event_target) VALUES ('synthetic', 'duplicate', 'u', 't'), ('synthetic', 'duplicate', 'u', 't')"
before=$(sig); tables_before=$(q "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'openemr'")
set +e; up --customizations=apply > "$LOG/half.log" 2>&1; rc=$?; set -e
grep -E "statement\(s\) failed|^STOP|^Stopped|To put everything back" "$LOG/half.log" | sed 's/^/    /' || true
check "$([[ $rc -ne 0 ]] && echo stopped)" stopped "half-upgraded: the script stops"
check "$(grep -c "the database upgrade didn't finish cleanly" "$LOG/half.log")" 1 "half-upgraded: it says the database upgrade didn't finish"
check "$(docker exec $C sh -c "grep -c 'Duplicate entry' /root/backups/*/upgrade-default.log" | awk '{print ($1 > 0) ? "found" : $1}')" found "half-upgraded: the failed statement is the duplicate key, as planted"
tables_mid=$(q "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'openemr'")
check "$([[ $tables_mid -gt $tables_before ]] && echo changed)" changed "half-upgraded: control: the other statements ran ($tables_before tables before, $tables_mid now)"
check "$([[ "$(sig)" != "$before" ]] && echo differs)" differs "half-upgraded: control: the database differs from before"
set +e; docker exec $C bash /root/tools/openemr-upgrade.sh --rollback --openemr=$OE > "$LOG/half-rollback.log" 2>&1; rc=$?; set -e
check "$rc" 0 "half-upgraded: the rollback finishes"
check "$(sig)" "$before" "half-upgraded: after the rollback a full dump of the database is byte-for-byte the one before (MySQL's column character-set wording aside)"
check "$(grep -c 'check: default: the restored database and documents match the receipt taken before the upgrade, every table' "$LOG/half-rollback.log")" 1 "half-upgraded: and the rollback's receipt matches the one before"
docker exec -i $D sh -c "$DBC -uroot -proot openemr < /tmp/clean.sql 2>/dev/null && rm -f /tmp/clean.sql"
docker exec $C sh -c "rm -rf /root/backups/* $OE.failed-*"
check "$(sig)" "$clean" "half-upgraded: the planted rows are gone again"

fi   # FULL

# A web server started with a SysV "service" script keeps the descriptors it was given. The
# stand-in below does too (its child keeps everything but stdin, stdout and stderr), so if the
# upgrade's lock were passed on, the rollback after the upgrade would be refused.
check "$(docker exec $C sh -c 'command -v systemctl || echo none')" none "service: no systemctl here, so the script uses the service command"
docker exec $C sh -c 'printf "%s\n" "#!/bin/sh" "# Test stand-in for a SysV service script." "case \"\$2\" in" "  start) (sleep 900 </dev/null >/dev/null 2>&1 &) ;;" "  stop) pkill -f \"sleep 900\" || true ;;" "esac" > /usr/local/bin/service && chmod 755 /usr/local/bin/service'
docker exec $C service fakeweb start

# A change to the data during the upgrade, as if the upgrade had made it (OPENEMR_UPGRADE_TEST_CHANGE_SQL
# runs right after sql_upgrade.php). The receipts must disagree and name it, the script must stop
# before switching and put everything back by itself, and afterwards the database must be byte for
# byte what it was, and a receipt the test takes itself must match the first.
inject() {  # inject NAME SQL EXPECTED-DIFF-PATTERN...
    local name="$1" sql="$2"; shift 2
    local sig0 sig1 sig2 rc v p t l pat
    sig0=$(sig); dumpdb > "$LOG/inject-$name-before.sql"
    set +e; up -e OPENEMR_UPGRADE_TEST_CHANGE_SQL="$sql" --customizations=apply --service=fakeweb > "$LOG/inject-$name.log" 2>&1; rc=$?; set -e
    # The dump straight after the run, before anything (the test's own login-page request) touches the site.
    sig1=$(sig); dumpdb > "$LOG/inject-$name-after.sql"
    grep -E "TEST:|check: default: the receipts|DON'T match|^    |^STOPPED|^  - |restored database|Nothing was switched|^A receipt|running again" "$LOG/inject-$name.log" | sed 's/^/    /' | cut -c1-190 || true
    check "$([[ $rc -ne 0 ]] && echo stopped)" stopped "changed during the upgrade ($name): the upgrade stops"
    check "$(grep -c "default: the receipts DON'T match" "$LOG/inject-$name.log")" 1 "changed during the upgrade ($name): the receipts disagree"
    for pat in "$@"; do
        check "$(grep -cE "^  - $pat" "$LOG/inject-$name.log")" 1 "changed during the upgrade ($name): it says what changed, in plain words: $pat"
    done
    check "$(grep -c '^STOPPED AND PUT BACK' "$LOG/inject-$name.log")" 1 "changed during the upgrade ($name): it puts everything back by itself, and says so"
    check "$(grep -c '^== 9\|^== 10' "$LOG/inject-$name.log" || true)" 0 "changed during the upgrade ($name): before the doctor and the switch"
    check "$(grep -c 'check: default: the restored database and documents match the receipt taken before the upgrade, every table' "$LOG/inject-$name.log")" 1 "changed during the upgrade ($name): the restored database matches the first receipt (the script's check)"
    check "$sig1" "$sig0" "changed during the upgrade ($name): a full dump of the database is byte for byte the one before (MySQL's column character-set wording aside)"
    [[ "$sig1" == "$sig0" ]] || { diff "$LOG/inject-$name-before.sql" "$LOG/inject-$name-after.sql" | cut -c1-200 | head -16 | sed 's/^/       | /'; } || true
    IFS='|' read -r v p t l <<<"$(state)"
    check "$v|$p|$t|$l" "$v0|$p0|$t0|200" "changed during the upgrade ($name): the same version, patients, tables and login page as before"
    # What the login page itself writes, for the record (a site's users would do the same once it's back).
    sig2=$(sig)
    if [[ "$sig2" != "$sig1" ]]; then
        echo "    note: loading the login page changed the database:"
        dumpdb | diff "$LOG/inject-$name-after.sql" - | grep '^[<>]' | cut -c1-160 | head -6 | sed 's/^/       | /' || true
    fi
    [[ "$sig1" != "$sig0" ]] || rm -f "$LOG/inject-$name-before.sql" "$LOG/inject-$name-after.sql"   # kept when they differ
    check "$(docker exec $C sh -c "php -r 'include \"$OE/version.php\"; echo \"\$v_major.\$v_minor.\$v_patch\n\";'; ls -d $OE.failed-$TO-* >/dev/null 2>&1 && echo kept; ls -d $OE.new-$TO 2>/dev/null; ls $(dirname $OE)/.openemr-upgrade-state 2>/dev/null" | tr '\n' ' ')" "${v0%% db *} kept " "changed during the upgrade ($name): the old folder is live; the $TO folder is kept aside; no upgrade is left half done"
    check "$(docker exec $C sh -c "pgrep -f 'sleep 900' >/dev/null && echo running || echo stopped")" running "changed during the upgrade ($name): the web server is running again"
    set +e; receipt /root/receipt-after-$name.json "the test's own, after the automatic rollback" > /dev/null 2>&1
    docker exec $C sh -c "php /root/tools/openemr-receipt.php --compare /root/backups/*/receipt-default-before.json /root/receipt-after-$name.json" > "$LOG/inject-$name-own.txt"; rc=$?; set -e
    check "$rc|$(grep -c '^RESULT: MATCH' "$LOG/inject-$name-own.txt")" "0|1" "changed during the upgrade ($name): a receipt the test takes itself afterwards matches the first"
    check "$(docker exec $C sh -c 'cd /root/backups/* && ls receipt-default-before.json receipt-default-after-upgrade.json receipts-default-compared.txt receipt-default-after-rollback-*.json receipts-default-rollback-compared-*.txt 2>/dev/null | wc -l')" 5 "changed during the upgrade ($name): both receipts, the one after the rollback and the comparisons are kept in the backup folder"
    docker exec $C sh -c "rm -rf /root/backups/* $OE.failed-*"
}
if (( SYNTHETIC )); then
    inject payment "DELETE FROM ar_activity WHERE deleted IS NULL AND pay_amount > 0 ORDER BY pid, encounter, sequence_no LIMIT 1" \
        "Payments: [0-9,.]+ before, [0-9,.]+ after" "ar_activity lost rows of a patient"
    inject charge-and-birth-date "UPDATE billing SET fee = fee + 10 WHERE activity = 1 AND code_type = 'CPT4' ORDER BY id LIMIT 1; UPDATE patient_data SET DOB = '1950-01-01' WHERE pid = 17" \
        "Charges \(fee sheet\): [0-9,.]+ before, [0-9,.]+ after" "patient_data, a patient table, changed in place: DOB"
fi

set +e; docker exec $C bash /root/tools/openemr-upgrade.sh --openemr=$OE --to=$TO --yes --backup-dir=/root/backups --customizations=apply --service=fakeweb --debug > "$LOG/upgrade.log" 2>&1; rc=$?; set -e
grep -E "^== |sha256|statement\(s\) failed|receipt|^Done|^STOP|carried over|applied your|NOT carried|NOTE" "$LOG/upgrade.log" | grep -v '^+' | sed 's/^/    /' | cut -c1-200 || true
docker exec $C sh -c "cat /root/backups/*/upgrade-*.log 2>/dev/null" > "$LOG/sql_upgrade.log" || true
check "$rc" 0 "upgrade: the script finished"
# The 7.0.3 image's PHP (8.3.15, Alpine 3.20) gets no php2shell update: the doctor fails that check,
# and the upgrade must report it and go ahead, since updating PHP is a separate job.
php_state="$(docker exec $C php -r '$f = ["8.5" => "8.5.12", "8.4" => "8.4.27", "8.3" => "8.3.36", "8.2" => "8.2.35"]; $b = PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION; echo isset($f[$b]) && version_compare(PHP_VERSION, $f[$b], "<") ? "old" : "fixed";')"
if [[ "$php_state" == old ]]; then
    check "$(grep -c "NOTE: the doctor's only failure is PHP security" "$LOG/upgrade.log")" 1 "upgrade: a PHP without its own security update is reported, not a stop"
fi
IFS='|' read -r v1 p1 t1 l1 <<<"$(state)"
echo "after the upgrade: OpenEMR $v1, $p1 patients, $t1 tables, login page HTTP $l1"
check "${v1%% db *}" "$TO" "upgrade: the database is $TO"
check "$p1" "$p0" "upgrade: every patient is still there"
check "$l1" 200 "upgrade: the login page answers from the new folder"
check "$(docker exec $C sh -c "test -d $OE.old-${v0%% db *} && echo kept")" kept "upgrade: the old folder is kept"
check "$(docker exec $C sh -c "ls /root/backups/*/*.sql /root/backups/*/sites.tar.gz | wc -l")" 2 "upgrade: the database dump and sites/ are backed up"
check "$(grep -c '^  check: default: the receipts match: every patient record, document and money figure is the same' "$LOG/upgrade.log")" 1 "upgrade (receipts): the receipt after the database upgrade matches the one before"
check "$(docker exec $C sh -c 'grep -c "^RESULT: MATCH" /root/backups/*/receipts-default-compared.txt')" 1 "upgrade (receipts): the comparison, kept in the backup folder, says MATCH"
if (( SYNTHETIC )); then
    docker exec $C sh -c 'cat /root/backups/*/receipts-default-compared.txt' > "$LOG/receipts-compared.txt"
    check "$(grep -cE '^  same (Patients +420|Document files on disk +122|Payments +[1-9][0-9,]*\.[0-9]{2})$' "$LOG/receipts-compared.txt")" 3 "upgrade (receipts): and it compared what's there (420 patients, 122 document files, the payments), not nothing"
fi
check "$(docker exec $C grep -c 'synthetic local change' $OE/$TWIG)" 1 "upgrade (apply): the template edit is in $TO"
check "$(docker exec $C grep -c 'synthetic local change' $OE/$REPORT || true)" 0 "upgrade (apply): the conflicting edit is not; $TO's file is"
check "$(docker exec $C sh -c "test -f $OE/$ADDED && echo there")" there "upgrade (apply): the added report is carried over"
check "$(docker exec $C sh -c "ls /root/backups/*/customizations/patches/$REPORT.patch >/dev/null && echo kept")" kept "upgrade (apply): the conflicting change is kept as a patch"
ulog() { docker exec $C sh -c "cat /root/backups/*/openemr-upgrade.log"; }
check "$(ulog | grep -c '^+ openemr-upgrade.sh:' | awk '{print ($1 > 100) ? "traced" : $1}')" traced "upgrade (--debug): the log traces the commands"
check "$(ulog | grep -c '^  check: ')" 7 "upgrade: the log has its seven self-checks (unpacked release, dump, sites.tar.gz, copied sites/, database version, receipts, switch)"
check "$(docker exec $C grep -c 'Synth-Pw-4417' $OE/sites/default/sqlconf.php)" 1 "upgrade (--debug): control: the site's password is in its sqlconf.php"
check "$(ulog | grep -c 'Synth-Pw-4417' || true)" 0 "upgrade (--debug): and never in the log"
check "$(docker exec $C sh -c "grep -c 'Synth-Pw-4417' /root/backups/*/receipt-* /root/backups/*/receipts-* | awk -F: '{n += \$2} END {print n + 0}'")" 0 "upgrade: nor in the receipts"
check "$(docker exec $C sh -c "pgrep -f 'sleep 900' >/dev/null && echo running || echo stopped")" running "upgrade (--service): the web server is started again at the end"

# Work done after the upgrade, which a rollback must not throw away: a row in a table the upgrade
# created (care_teams) and a note in one that was already there (pnotes). Synthetic.
q "INSERT INTO care_teams (uuid, pid, team_name, status) VALUES (NULL, 1, 'Synthetic team added after the upgrade', 'active')"
q "INSERT INTO pnotes (date, body, pid, user, groupname, activity, authorized, title, assigned_to, deleted, message_status) VALUES (NOW(), 'Synthetic note added after the upgrade', 1, 'synthetic', 'Default', 1, 0, 'Synthetic', 'synthetic', 0, 'New')"
set +e; docker exec $C bash /root/tools/openemr-upgrade.sh --rollback --openemr=$OE > "$LOG/rollback.log" 2>&1; rc=$?; set -e
grep -E "dropping|restoring|receipt|^Rolled back|^STOP" "$LOG/rollback.log" | sed 's/^/    /' | head -20 || true
check "$rc" 0 "rollback: the script finished"
check "$(grep -c 'already running' "$LOG/rollback.log" || true)" 0 "lock: the web server the upgrade started doesn't hold its lock, so the rollback runs"
IFS='|' read -r v2 p2 t2 l2 <<<"$(state)"
check "$v2" "$v0" "rollback: the database is back to $v0"
check "$t2" "$t0" "rollback: the same tables as before"
check "$p2" "$p0" "rollback: every patient is still there"
check "$l2" 200 "rollback: the login page answers from the old folder"
check "$(q "SELECT COUNT(*) FROM pnotes WHERE body = 'Synthetic note added after the upgrade'")" 0 "rollback: the database is as before the upgrade (the later note is gone from it)"
saved() { docker exec $C sh -c "grep -c \"$1\" /root/backups/*/default.$2-*.sql 2>/dev/null || true"; }
check "$(saved 'Synthetic note added after the upgrade' before-rollback)" 1 "rollback: the later note is kept in the database saved before the rollback"
check "$(saved 'Synthetic team added after the upgrade' before-rollback)" 1 "rollback: so is the row in the new table"
check "$(saved 'Synthetic team added after the upgrade' created-tables)" 1 "rollback: the new tables are saved on their own, with their rows"
check "$(saved 'CREATE TABLE \`pnotes\`' created-tables)" 0 "rollback: and only the new tables are in that file"
check "$(grep -c 'check: default: the restored database and documents match the receipt taken before the upgrade, every table' "$LOG/rollback.log")" 1 "rollback: the restored database matches the receipt taken before the upgrade"
set +e; receipt /root/receipt-end.json "the test's own, at the end" > /dev/null 2>&1
docker exec $C php /root/tools/openemr-receipt.php --compare /root/receipt-start.json /root/receipt-end.json > "$LOG/start-end.txt"; rc=$?; set -e
check "$rc" 0 "rollback: a receipt the test takes itself at the end matches the one it took at the start"
echo "full output: $LOG/upgrade-stop.log, $LOG/upgrade.log, $LOG/sql_upgrade.log, $LOG/rollback.log, $LOG/inject-*.log"
echo; [ $fails -eq 0 ] && echo "PASSED" || { echo "FAILED: $fails"; exit 1; }
