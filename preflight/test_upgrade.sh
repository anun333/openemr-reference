#!/usr/bin/env bash
# End-to-end test of openemr-upgrade.sh: a throwaway OpenEMR 7.0.3 (official image, MariaDB 10.11),
# optionally loaded with a dump of a 7.0.3 site with synthetic patients, upgraded to 8.4.1 with the
# script (release downloaded from GitHub, sha256 checked), then rolled back. Checks the version, the
# login page, the patients and the tables after each. Everything runs in containers deleted at the end.
#   preflight/test_upgrade.sh [7.0.3-dump.sql]
set -euo pipefail
cd "$(dirname "$0")"
LOG="$(mktemp -d)"; P=upgrade-test; C=$P-openemr-1; D=$P-mysql-1; OE=/var/www/localhost/htdocs/openemr; TO=8.4.1
docker compose -p $P -f test-upgrade-compose.yml up -d >/dev/null
# KEEP=1 leaves the containers running to look around (delete with: docker compose -p upgrade-test -f test-upgrade-compose.yml down -v).
[[ "${KEEP:-0}" == 1 ]] || trap 'docker compose -p $P -f test-upgrade-compose.yml down -v >/dev/null 2>&1' EXIT
echo "waiting for OpenEMR 7.0.3 to install itself (about 6 minutes)..."
until docker logs $C 2>&1 | grep -q "Setup Complete"; do sleep 6; done
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
docker exec $C sh -c 'rm -rf /root/backups/*'

set +e; docker exec $C bash /root/tools/openemr-upgrade.sh --openemr=$OE --to=$TO --yes --backup-dir=/root/backups --customizations=apply > "$LOG/upgrade.log" 2>&1; rc=$?; set -e
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

# Work done after the upgrade, which a rollback must not throw away: a row in a table the upgrade
# created (care_teams) and a note in one that was already there (pnotes). Synthetic.
q "INSERT INTO care_teams (uuid, pid, team_name, status) VALUES (NULL, 1, 'Synthetic team added after the upgrade', 'active')"
q "INSERT INTO pnotes (date, body, pid, user, groupname, activity, authorized, title, assigned_to, deleted, message_status) VALUES (NOW(), 'Synthetic note added after the upgrade', 1, 'synthetic', 'Default', 1, 0, 'Synthetic', 'synthetic', 0, 'New')"
set +e; docker exec $C bash /root/tools/openemr-upgrade.sh --rollback --openemr=$OE > "$LOG/rollback.log" 2>&1; rc=$?; set -e
grep -E "dropping|restoring|^Rolled back|^STOP" "$LOG/rollback.log" | sed 's/^/    /' | head -20
check "$rc" 0 "rollback: the script finished"
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
