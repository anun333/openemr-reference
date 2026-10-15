#!/usr/bin/env bash
# End-to-end test of openemr-upgrade.sh: a throwaway OpenEMR 7.0.3 (official image, MariaDB 10.11),
# optionally loaded with a dump of a 7.0.3 site with synthetic patients, upgraded to 8.4.1 with the
# script (release downloaded from GitHub, sha256 checked), then rolled back. Checks the version, the
# login page, the patients and the tables after each. Everything runs in containers deleted at the end.
#   preflight/test_upgrade.sh [7.0.3-dump.sql]
set -euo pipefail
cd "$(dirname "$0")"
. ./test_lib.sh
serial
LOG="$(mktemp -d)"; P=upgrade-test; C=$P-openemr-1; D=$P-mysql-1; OE=/var/www/localhost/htdocs/openemr; TO=8.4.1
docker compose -p $P -f test-upgrade-compose.yml up -d >/dev/null
# KEEP=1 leaves the containers running to look around (delete with: docker compose -p upgrade-test -f test-upgrade-compose.yml down -v).
[[ "${KEEP:-0}" == 1 ]] || trap 'docker compose -p $P -f test-upgrade-compose.yml down -v >/dev/null 2>&1' EXIT
echo "waiting for OpenEMR 7.0.3 to install itself (about 6 minutes)..."
wait_ready $C $OE
q() { docker exec $D mariadb -uroot -proot -N openemr -e "$1"; }
if [[ -n "${1:-}" ]]; then
    docker exec -i $D mariadb -uroot -proot openemr < "$1"
    echo "loaded $1: $(q 'SELECT COUNT(*) FROM patient_data') patients"
fi
# The 7.0.3 image lacks two extensions 8.4.1 needs (the pre-flight check says so); add them as an admin would,
# and bash and patch, which servers usually have and this Alpine image doesn't.
docker exec $C apk add --no-cache bash patch php83-bcmath php83-pecl-imagick >/dev/null
docker exec $C mkdir -p /root/tools /root/backups
docker cp openemr-upgrade.sh $C:/root/tools/ && docker cp openemr-preflight.php $C:/root/tools/ && docker cp openemr-doctor.php $C:/root/tools/
# This checkout's facts beside the tools (/root/site/preflight), as when run from a clone, so the test
# uses the facts it was built with, not the published ones.
docker exec $C mkdir -p /root/site && docker cp ../site/preflight $C:/root/site/preflight
state() {
    echo "$(q "SELECT CONCAT(v_major,'.',v_minor,'.',v_patch,' db ',v_database) FROM version")|$(q 'SELECT COUNT(*) FROM patient_data')|$(q "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'openemr'")|$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8372/interface/login/login.php?site=default)"
}
fails=0
check() { if [[ "$1" == "$2" ]]; then echo "ok   $3"; else echo "FAIL $3: got '$1', expected '$2'"; fails=$((fails + 1)); fi; }
IFS='|' read -r v0 p0 t0 l0 <<<"$(state)"
echo "before: OpenEMR $v0, $p0 patients, $t0 tables, login page HTTP $l0"

# Local changes to OpenEMR's own files, as a clinic makes them (synthetic):
#   a template edit in a file 8.4.1 didn't change (applies cleanly),
#   an edit to a line 8.4.1 rewrote (conflicts; the @link line went from http to https),
#   a report file of its own (added).
TWIG=interface/forms/newpatient/templates/newpatient/partials/common/_form-heading.html.twig
REPORT=interface/reports/appointments_report.php
ADDED=interface/reports/synthetic_custom_report.php
docker exec $C sh -c "echo '{# synthetic local change #}' >> $OE/$TWIG && sed -i '12s|.*| * @link      http://www.open-emr.org (synthetic local change)|' $OE/$REPORT && echo '<?php // synthetic custom report' > $OE/$ADDED && chown apache $OE/$ADDED"

# Without --customizations it must stop before changing anything, and say what it found.
set +e; docker exec $C bash /root/tools/openemr-upgrade.sh --openemr=$OE --to=$TO --yes --backup-dir=/root/backups > "$LOG/upgrade-stop.log" 2>&1; rc=$?; set -e
grep -E "^== 2|changed  |added    .*synthetic|^STOP" "$LOG/upgrade-stop.log" | sed 's/^/    /' | cut -c1-160
check "$([[ $rc -ne 0 ]] && echo stopped)" stopped "local changes: without --customizations the script stops"
IFS='|' read -r vs _ _ _ <<<"$(state)"
check "$vs" "$v0" "local changes: nothing changed (still $v0)"
report() { docker exec $C sh -c "cat /root/backups/*/customizations/report.json"; }
check "$(report | python3 -c 'import json, sys; print(json.load(sys.stdin).get("changed", {}).get(sys.argv[1], {}).get("status", "missing"))' "$TWIG")" applies "local changes: the template edit is found, and applies to $TO"
check "$(report | python3 -c 'import json, sys; print(json.load(sys.stdin).get("changed", {}).get(sys.argv[1], {}).get("status", "missing"))' "$REPORT")" conflicts "local changes: the edit to a line $TO rewrote is found, as a conflict"
check "$(report | python3 -c 'import json, sys; print("found" if sys.argv[1] in json.load(sys.stdin).get("added", []) else "missing")' "$ADDED")" found "local changes: the added report is found"
check "$(grep -c 'before the backup was finished: nothing on the server was changed' "$LOG/upgrade-stop.log")" 1 "local changes: the stop says nothing on the server changed"
docker exec $C sh -c 'rm -rf /root/backups/*'

# The helpers, when they aren't beside the script, come from the script's own release and must match
# its SHA256SUMS: a release folder of our own (file://), first with a changed pre-flight check.
docker exec $C sh -c "mkdir -p /root/alone /root/rel && cp /root/tools/openemr-upgrade.sh /root/alone/ && cp /root/tools/openemr-preflight.php /root/tools/openemr-doctor.php /root/rel/ && cd /root/rel && echo '// changed' >> openemr-preflight.php && sha256sum openemr-doctor.php > SHA256SUMS && cp /root/tools/openemr-preflight.php /tmp/pf && sha256sum /tmp/pf | sed 's| /tmp/pf| openemr-preflight.php|' >> SHA256SUMS"
alone() { set +e; docker exec -e OPENEMR_REFERENCE_BASE=file:///root/rel "$@" $C bash /root/alone/openemr-upgrade.sh --openemr=$OE --to=$TO --yes --backup-dir=/root/backups --customizations=apply > "$LOG/alone.log" 2>&1; rc=$?; set -e; }
alone
check "$(grep -c "openemr-preflight.php from file:///root/rel doesn't match that release's SHA256SUMS" "$LOG/alone.log")" 1 "downloads: a pre-flight check that doesn't match SHA256SUMS is refused"
check "$(grep -c '^== 2' "$LOG/alone.log" || true)" 0 "downloads: and the upgrade goes no further"
docker exec $C sh -c "cp /root/tools/openemr-preflight.php /root/rel/ && rm -rf /root/backups/*"
alone -e OPENEMR_UPGRADE_TEST_FAIL_BEFORE_STEP=2
check "$(grep -c "openemr-preflight.php downloaded from release v$(sed -n 's/^SCRIPT_VERSION=//p' openemr-upgrade.sh) matches its SHA256SUMS" "$LOG/alone.log")" 1 "downloads: one that matches is used"
docker exec $C sh -c 'rm -rf /root/backups/* /root/alone /root/rel /tmp/pf'

# One run at a time: while another holds the lock, a second refuses to start.
docker exec -d $C flock "$(dirname "$OE")/.openemr-upgrade.lock" sleep 120
sleep 2
set +e; docker exec $C bash /root/tools/openemr-upgrade.sh --openemr=$OE --to=$TO --yes --backup-dir=/root/backups --customizations=apply > "$LOG/locked.log" 2>&1; rc=$?; set -e
check "$(grep -c 'another openemr-upgrade.sh is already running' "$LOG/locked.log")" 1 "lock: a second run refuses to start"
docker exec $C pkill -f 'sleep 120' || true
docker exec $C sh -c 'rm -rf /root/backups/*'

# A stop before the backup takes the unpacked folder away again and changes nothing.
set +e; docker exec -e OPENEMR_UPGRADE_TEST_FAIL_BEFORE_STEP=5 $C bash /root/tools/openemr-upgrade.sh --openemr=$OE --to=$TO --yes --backup-dir=/root/backups --customizations=apply > "$LOG/stop5.log" 2>&1; rc=$?; set -e
check "$(grep -c 'Stopped during step 5. Stopping the web server and backing up (exit 1), before the backup was finished' "$LOG/stop5.log")" 1 "stop before the backup: says so"
check "$(docker exec $C sh -c "test -e $OE.new-$TO && echo left || echo gone")" gone "stop before the backup: the unpacked folder is removed"
IFS='|' read -r vs _ _ _ <<<"$(state)"
check "$vs" "$v0" "stop before the backup: nothing changed (still $v0)"
docker exec $C sh -c 'rm -rf /root/backups/*'

# A stop after the backup says how far it got and how to get back, and the rollback it names works.
set +e; docker exec -e OPENEMR_UPGRADE_TEST_FAIL_BEFORE_STEP=7 $C bash /root/tools/openemr-upgrade.sh --openemr=$OE --to=$TO --yes --backup-dir=/root/backups --customizations=apply > "$LOG/stop7.log" 2>&1; rc=$?; set -e
grep -E "check:|^Stopped|To put everything back|log of this run" "$LOG/stop7.log" | sed 's/^/    /'
check "$(grep -c 'Stopped during step 7.* after the backup' "$LOG/stop7.log")" 1 "stop after the backup: says how far it got"
check "$(grep -c -- "To put everything back as it was before the upgrade:  /root/tools/openemr-upgrade.sh --rollback --openemr=$OE" "$LOG/stop7.log")" 1 "stop after the backup: gives the rollback command"
check "$(grep -c "check: default: the dump is complete ('Dump completed') and has all [0-9]* tables" "$LOG/stop7.log")" 1 "self-check: the dump is verified complete"
check "$(grep -c 'check: sites.tar.gz reads back whole' "$LOG/stop7.log")" 1 "self-check: sites.tar.gz is read back"
check "$(grep -c 'check: sites/ copied whole into the new folder' "$LOG/stop7.log")" 1 "self-check: the copied sites/ is counted"
set +e; docker exec $C bash /root/tools/openemr-upgrade.sh --rollback --openemr=$OE > "$LOG/rollback7.log" 2>&1; rc=$?; set -e
check "$rc" 0 "stop after the backup: the rollback finishes"
IFS='|' read -r vr pr tr lr <<<"$(state)"
check "$vr|$pr|$tr|$lr" "$v0|$p0|$t0|200" "stop after the backup: the rollback puts back the same version, patients, tables and login page"
check "$(grep -c "check: default: openemr is ${v0%% db *} again" "$LOG/rollback7.log")" 1 "self-check: the rollback verifies the database version"
docker exec $C sh -c "rm -rf /root/backups/* $OE.failed-*"

# A failure partway through the database upgrade, the case the rollback is for. Two identical
# synthetic telemetry rows make the upgrade's unique key on track_events fail (7.0.3 to 7.0.4),
# while the statements before and after it run. The rollback must then put the database back
# exactly: a full dump of it must be byte-for-byte the one taken before.
sig() { docker exec $D sh -c "mariadb-dump -uroot -proot --skip-dump-date --skip-comments openemr | md5sum | cut -d' ' -f1"; }
docker exec $D sh -c "mariadb-dump -uroot -proot openemr > /tmp/clean.sql"
clean=$(sig)
q "CREATE TABLE IF NOT EXISTS track_events (id INT(11) UNSIGNED NOT NULL AUTO_INCREMENT, event_type TEXT, event_label VARCHAR(255) DEFAULT NULL, event_url TEXT, event_target TEXT, first_event DATETIME NULL, last_event DATETIME NULL, label_count INT UNSIGNED NOT NULL DEFAULT 1, PRIMARY KEY (id)) ENGINE=InnoDB"
for idx in $(q "SELECT DISTINCT index_name FROM information_schema.statistics WHERE table_schema = 'openemr' AND table_name = 'track_events' AND non_unique = 0 AND index_name <> 'PRIMARY'"); do q "ALTER TABLE track_events DROP INDEX \`$idx\`"; done
q "INSERT INTO track_events (event_type, event_label, event_url, event_target) VALUES ('synthetic', 'duplicate', 'u', 't'), ('synthetic', 'duplicate', 'u', 't')"
before=$(sig); tables_before=$(q "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'openemr'")
set +e; docker exec $C bash /root/tools/openemr-upgrade.sh --openemr=$OE --to=$TO --yes --backup-dir=/root/backups --customizations=apply > "$LOG/half.log" 2>&1; rc=$?; set -e
grep -E "statement\(s\) failed|^STOP|^Stopped|To put everything back" "$LOG/half.log" | sed 's/^/    /'
check "$([[ $rc -ne 0 ]] && echo stopped)" stopped "half-upgraded: the script stops"
check "$(grep -c "the database upgrade didn't finish cleanly" "$LOG/half.log")" 1 "half-upgraded: it says the database upgrade didn't finish"
check "$(docker exec $C sh -c "grep -c 'Duplicate entry' /root/backups/*/upgrade-default.log" | awk '{print ($1 > 0) ? "found" : $1}')" found "half-upgraded: the failed statement is the duplicate key, as planted"
tables_mid=$(q "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'openemr'")
check "$([[ $tables_mid -gt $tables_before ]] && echo changed)" changed "half-upgraded: control: the other statements ran ($tables_before tables before, $tables_mid now)"
check "$([[ "$(sig)" != "$before" ]] && echo differs)" differs "half-upgraded: control: the database differs from before"
set +e; docker exec $C bash /root/tools/openemr-upgrade.sh --rollback --openemr=$OE > "$LOG/half-rollback.log" 2>&1; rc=$?; set -e
check "$rc" 0 "half-upgraded: the rollback finishes"
check "$(sig)" "$before" "half-upgraded: after the rollback a full dump of the database is byte-for-byte the one before"
docker exec -i $D sh -c "mariadb -uroot -proot openemr < /tmp/clean.sql && rm -f /tmp/clean.sql"
docker exec $C sh -c "rm -rf /root/backups/* $OE.failed-*"
check "$(sig)" "$clean" "half-upgraded: the planted rows are gone again"

# A web server started with a SysV "service" script keeps the descriptors it was given. The
# stand-in below does too (its child keeps everything but stdin, stdout and stderr), so if the
# upgrade's lock were passed on, the rollback after the upgrade would be refused.
check "$(docker exec $C sh -c 'command -v systemctl || echo none')" none "service: no systemctl here, so the script uses the service command"
docker exec $C sh -c 'printf "%s\n" "#!/bin/sh" "# Test stand-in for a SysV service script." "case \"\$2\" in" "  start) (sleep 900 </dev/null >/dev/null 2>&1 &) ;;" "  stop) pkill -f \"sleep 900\" || true ;;" "esac" > /usr/local/bin/service && chmod 755 /usr/local/bin/service'

set +e; docker exec $C bash /root/tools/openemr-upgrade.sh --openemr=$OE --to=$TO --yes --backup-dir=/root/backups --customizations=apply --service=fakeweb --debug > "$LOG/upgrade.log" 2>&1; rc=$?; set -e
grep -E "^== |sha256|statement\(s\) failed|^Done|^STOP|carried over|applied your|NOT carried|NOTE" "$LOG/upgrade.log" | sed 's/^/    /'
docker exec $C sh -c "cat /root/backups/*/upgrade-*.log 2>/dev/null" > "$LOG/sql_upgrade.log" || true
check "$rc" 0 "upgrade: the script finished"
IFS='|' read -r v1 p1 t1 l1 <<<"$(state)"
echo "after the upgrade: OpenEMR $v1, $p1 patients, $t1 tables, login page HTTP $l1"
check "${v1%% db *}" "$TO" "upgrade: the database is $TO"
check "$p1" "$p0" "upgrade: every patient is still there"
check "$l1" 200 "upgrade: the login page answers from the new folder"
check "$(docker exec $C sh -c "test -d $OE.old-${v0%% db *} && echo kept")" kept "upgrade: the old folder is kept"
check "$(docker exec $C sh -c "ls /root/backups/*/*.sql /root/backups/*/sites.tar.gz | wc -l")" 2 "upgrade: the database dump and sites/ are backed up"
check "$(docker exec $C grep -c 'synthetic local change' $OE/$TWIG)" 1 "upgrade (apply): the template edit is in $TO"
check "$(docker exec $C grep -c 'synthetic local change' $OE/$REPORT || true)" 0 "upgrade (apply): the conflicting edit is not; $TO's file is"
check "$(docker exec $C sh -c "test -f $OE/$ADDED && echo there")" there "upgrade (apply): the added report is carried over"
check "$(docker exec $C sh -c "ls /root/backups/*/customizations/patches/$REPORT.patch >/dev/null && echo kept")" kept "upgrade (apply): the conflicting change is kept as a patch"
ulog() { docker exec $C sh -c "cat /root/backups/*/openemr-upgrade.log"; }
check "$(ulog | grep -c '^+ openemr-upgrade.sh:' | awk '{print ($1 > 100) ? "traced" : $1}')" traced "upgrade (--debug): the log traces the commands"
check "$(ulog | grep -c '^  check: ')" 6 "upgrade: the log has its six self-checks (unpacked release, dump, sites.tar.gz, copied sites/, database version, switch)"
check "$(docker exec $C grep -c 'Synth-Pw-4417' $OE/sites/default/sqlconf.php)" 1 "upgrade (--debug): control: the site's password is in its sqlconf.php"
check "$(ulog | grep -c 'Synth-Pw-4417' || true)" 0 "upgrade (--debug): and never in the log"
check "$(docker exec $C sh -c "pgrep -f 'sleep 900' >/dev/null && echo running || echo stopped")" running "upgrade (--service): the web server is started again at the end"

# Work done after the upgrade, which a rollback must not throw away: a row in a table the upgrade
# created (care_teams) and a note in one that was already there (pnotes). Synthetic.
q "INSERT INTO care_teams (uuid, pid, team_name, status) VALUES (NULL, 1, 'Synthetic team added after the upgrade', 'active')"
q "INSERT INTO pnotes (date, body, pid, user, groupname, activity, authorized, title, assigned_to, deleted, message_status) VALUES (NOW(), 'Synthetic note added after the upgrade', 1, 'synthetic', 'Default', 1, 0, 'Synthetic', 'synthetic', 0, 'New')"
set +e; docker exec $C bash /root/tools/openemr-upgrade.sh --rollback --openemr=$OE > "$LOG/rollback.log" 2>&1; rc=$?; set -e
grep -E "dropping|restoring|^Rolled back|^STOP" "$LOG/rollback.log" | sed 's/^/    /' | head -20
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
echo "full output: $LOG/upgrade-stop.log, $LOG/upgrade.log, $LOG/sql_upgrade.log, $LOG/rollback.log"
echo; [ $fails -eq 0 ] && echo "PASSED" || { echo "FAILED: $fails"; exit 1; }
