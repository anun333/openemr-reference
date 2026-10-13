#!/usr/bin/env bash
# End-to-end test of openemr-preflight.php against a throwaway OpenEMR 7.0.3 (official image,
# MariaDB 10.6), targeting the newest release with facts. Four scenarios, each adding one problem:
#   1 as installed: expects a FAIL for missing PHP extensions, WARNs for the database and ClaimRev
#   2 a user assigned the stock Custom.json menu, which links to removed files: Custom menus WARN
#   3 a removed setting changed from its default: Settings WARN
#   4 the database one version behind the code (a half-finished upgrade): Previous upgrade FAIL
#   5 the same install reached through an xampp/ path: XAMPP FAIL with the migration guide
#   6 a backup directory on a 1 MB disk: Room FAIL
# Everything runs in containers that are deleted at the end. Needs Docker and the facts in ../site/preflight.
set -euo pipefail
cd "$(dirname "$0")"
P=preflight-test
docker compose -p $P -f test-docker-compose.yml up -d >/dev/null
trap 'docker compose -p $P -f test-docker-compose.yml down -v >/dev/null 2>&1' EXIT
C=$P-openemr-1; D=$P-mysql-1
echo "waiting for OpenEMR 7.0.3 to install itself (about 6 minutes)..."
until docker logs $C 2>&1 | grep -q "Setup Complete"; do sleep 6; done
docker cp openemr-preflight.php $C:/tmp/preflight.php
docker exec $C mkdir -p /tmp/pf-facts
for f in ../site/preflight/*.json; do docker cp "$f" $C:/tmp/pf-facts/; done
q() { docker exec $D mariadb -uroot -proot openemr -e "$1"; }
run() { docker exec $C php /tmp/preflight.php --openemr=/var/www/localhost/htdocs/openemr --facts=/tmp/pf-facts || true; }
fails=0
expect() { if echo "$out" | grep -q "$1"; then echo "ok   $2"; else echo "FAIL $2"; fails=$((fails+1)); fi; }
out=$(run); echo "$out" | head -20
expect "^FAIL  PHP extensions: missing: bcmath, imagick" "1: missing PHP extensions fail"
expect "^WARN  Database server: MariaDB 10.6 is older" "1: MariaDB 10.6 warns"
expect "^WARN  Modules: oe-module-claimrev-connect is installed by Composer" "1: ClaimRev moved to Composer"
expect "^PASS  Custom menus: .*no user is assigned it" "1: an unassigned stock menu doesn't warn"
expect "^PASS  Previous upgrade" "1: database matches code"
expect "^PASS  Room: .* has .* free; need about .*backup: database .*new release 8.4.1" "1: room for the backup and the new release is reported"
expect "^NOTE  Room in the database: [0-9]* tables altered from 7.0.3 to 8.4.1, the largest here" "1: the tables the upgrade alters are measured; the database's folder is in another container"
q "UPDATE users SET main_menu_role='Custom.json' WHERE username='admin'"; out=$(run)
expect "^WARN  Custom menus: menus in use point to files removed .*interface/main/backup.php" "2: an assigned menu linking a removed file warns"
q "REPLACE INTO globals (gl_name, gl_index, gl_value) VALUES ('configuration_import_export', 0, '1')"; out=$(run)
expect "^WARN  Settings: .* removes settings this install has changed: configuration_import_export" "3: a changed removed setting warns"
q "UPDATE version SET v_database = v_database - 2"; out=$(run)
expect "^FAIL  Previous upgrade: the code is" "4: a half-finished upgrade fails"
docker exec $C sh -c 'mkdir -p /opt/xampp/htdocs && ln -sfn /var/www/localhost/htdocs/openemr /opt/xampp/htdocs/openemr'
out=$(docker exec $C php /tmp/preflight.php --openemr=/opt/xampp/htdocs/openemr --facts=/tmp/pf-facts || true)
expect "^FAIL  XAMPP: this install runs on XAMPP" "5: an install under an xampp directory is told why, with the migration guide"
expect "XAMPP_to_Docker_Migration" "5: the migration guide is linked"
out=$(docker exec $C php /tmp/preflight.php --openemr=/var/www/localhost/htdocs/openemr --facts=/tmp/pf-facts --backup-dir=/tinybackup || true)
expect "^FAIL  Room: /tinybackup has .* free" "6: a backup disk too small for the backup fails"
expect "put the backup on another disk with --backup-dir" "6: and says what to do"
echo; [ $fails -eq 0 ] && echo "PASSED" || { echo "FAILED: $fails"; exit 1; }
