#!/usr/bin/env bash
# openemr-doctor.php on a patched older release: the official OpenEMR 7.0.3 image, which is
# 7.0.3 patch 4 (MariaDB 10.6). Patch 4 deleted files 7.0.3 had, so the doctor must compare
# with the patch's file list; 7.0.3's composer.json lists no extensions, so it must fall back
# to setup's own; and up to 8.0 the error-display setting is user_debug.
# Containers are deleted at the end. Needs Docker and the facts in ../site/preflight.
set -euo pipefail
cd "$(dirname "$0")"
. ./test_lib.sh
serial
P=doctor-patch-test
docker compose -p $P -f test-docker-compose.yml up -d >/dev/null
trap 'docker compose -p $P -f test-docker-compose.yml down -v >/dev/null 2>&1' EXIT
C=$P-openemr-1; D=$P-mysql-1; OE=/var/www/localhost/htdocs/openemr
echo "waiting for OpenEMR 7.0.3 to install itself (several minutes)..."
wait_ready $C $OE
docker cp openemr-doctor.php $C:/tmp/doctor.php
docker exec $C mkdir -p /tmp/facts
for f in ../site/preflight/releases.json ../site/preflight/7.0.3.json ../site/preflight/7.0.3-files.json ../site/preflight/7.0.3-p4-files.json; do docker cp "$f" $C:/tmp/facts/; done
q() { docker exec $D mariadb -uroot -proot openemr -N -e "$1"; }
run() { docker exec -u apache $C php /tmp/doctor.php --openemr=$OE --facts=/tmp/facts || true; }
fails=0
expect() { if echo "$out" | grep -q -- "$1"; then echo "ok   $2"; else echo "FAIL $2"; echo "$out" | grep -E "^(PASS|WARN|FAIL|NOTE) " | sed 's/^/       | /'; fails=$((fails+1)); fi; }
refute() { if echo "$out" | grep -q -- "$1"; then echo "FAIL $2"; fails=$((fails+1)); else echo "ok   $2"; fi; }

out=$(run); echo "$out"; echo
expect "OpenEMR 7.0.3 patch 4" "1: the patch level is read"
expect "^PASS  Files: all .* files of the OpenEMR 7.0.3 patch 4 package" "1: compared with patch 4's files, not 7.0.3's"
expect "^PASS  PHP extensions: 5 required (7.0.3's composer.json lists none" "1: extensions fall back to setup's list"
expect "^PASS  Database version: .* patch 4" "1: database at patch 4"
# The 7.0.3 image's PHP is too old for the php2shell fixes, and its Alpine gets no update: the
# doctor must say so, and that is the install's only failure.
expect "^\(FAIL\|WARN\)  PHP security: " "1: the image's PHP is reported as lacking the php2shell fix"
if echo "$out" | grep "^FAIL" | grep -qv "^FAIL  PHP security"; then echo "FAIL 1: no other failures"; fails=$((fails+1)); else echo "ok   1: no other failures"; fi
q "UPDATE globals SET gl_value='2' WHERE gl_name='user_debug'"; out=$(run)
expect "^WARN  Error display: OpenEMR's user_debug setting is on.*User Debugging Options" "2: user_debug above 1 warns, with where to change it"
q "UPDATE globals SET gl_value='0' WHERE gl_name='user_debug'"
# The image deletes the setup scripts on a later start, so set both cases up explicitly.
q "UPDATE version SET v_realpatch = 3"
docker exec $C sh -c "cp $OE/sql_patch.php /tmp/sql_patch.php 2>/dev/null || touch $OE/sql_patch.php"; out=$(run)
expect "^FAIL  Database version: patch 4's files are in place but the database is at patch 3" "3: a patch whose sql_patch.php didn't run fails (t/26790)"
expect "Open sql_patch.php in the browser to finish the patch\.$" "3: and says to open sql_patch.php"
docker exec $C rm -f $OE/sql_patch.php; out=$(run)
expect "copy it from the patch first; it was removed" "3: or, once removed, to copy it back first"
q "UPDATE version SET v_realpatch = 4"
docker exec $C rm /tmp/facts/7.0.3-p4-files.json; out=$(run)
expect "^NOTE  Files: the file list for OpenEMR 7.0.3 patch 4 (7.0.3-p4-files.json) isn't in the facts" "4: a missing file list is said, not skipped"

echo; [ $fails -eq 0 ] && echo "PASSED" || { echo "FAILED: $fails"; exit 1; }
