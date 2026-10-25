#!/usr/bin/env bash
# End-to-end test of openemr-preflight.php against a throwaway OpenEMR 7.0.3 (official image,
# MariaDB 10.6), targeting the newest release with facts. Ten scenarios:
#   1 as installed: expects a FAIL for missing PHP extensions, WARNs for the database and ClaimRev
#   2 a user assigned the stock Custom.json menu, which links to removed files: Custom menus WARN
#   3 a removed setting changed from its default: Settings WARN
#   4 the database one version behind the code (a half-finished upgrade): Previous upgrade FAIL
#   5 the same install reached through an xampp/ path: XAMPP FAIL with the migration guide
#   6 a backup directory on a 1 MB disk: Room FAIL
#   7 (facts altered) a target needing a newer PHP than the old release was tested on: one-window warning
#   8 a local change to one of OpenEMR's own files (and one to sites/, which doesn't count): Local changes WARN
#   9 (facts altered: the target needs PHP 8.5) a file and a module this site added calling what PHP 8.4
#     removed: Site code FAIL, with a deprecation as a note, a guarded call left out; then no scan.php
#  10 checks left out with --skip: SKIP lines, not run, counted in the summary; an unknown name refused
# Everything runs in containers that are deleted at the end. Needs Docker and the facts in ../site/preflight.
set -euo pipefail
cd "$(dirname "$0")"
. ./test_lib.sh
serial
P=preflight-test
docker compose -p $P -f test-docker-compose.yml up -d >/dev/null
trap 'docker compose -p $P -f test-docker-compose.yml down -v >/dev/null 2>&1' EXIT
C=$P-openemr-1; D=$P-mysql-1
echo "waiting for OpenEMR 7.0.3 to install itself (about 6 minutes)..."
wait_ready $C /var/www/localhost/htdocs/openemr
docker cp openemr-preflight.php $C:/tmp/preflight.php
docker cp scan.php $C:/tmp/scan.php
docker exec $C mkdir -p /tmp/pf-facts
for f in ../site/preflight/*.json; do docker cp "$f" $C:/tmp/pf-facts/; done
q() { docker exec $D mariadb -uroot -proot openemr -e "$1"; }
run() { docker exec $C php /tmp/preflight.php --openemr=/var/www/localhost/htdocs/openemr --facts=/tmp/pf-facts || true; }
fails=0
expect() { if echo "$out" | grep -q "$1"; then echo "ok   $2"; else echo "FAIL $2"; fails=$((fails+1)); fi; }
refute() { if echo "$out" | grep -q "$1"; then echo "FAIL $2"; fails=$((fails+1)); else echo "ok   $2"; fi; }
out=$(run); echo "$out" | head -20
expect "^FAIL  PHP extensions: missing: bcmath, imagick" "1: missing PHP extensions fail"
expect "^WARN  Database server: MariaDB 10.6 is older" "1: MariaDB 10.6 warns"
expect "^WARN  Modules: oe-module-claimrev-connect is installed by Composer" "1: ClaimRev moved to Composer"
expect "^PASS  Custom menus: .*no user is assigned it" "1: an unassigned stock menu doesn't warn"
expect "^PASS  Previous upgrade" "1: database matches code"
expect "^PASS  Local changes: every file OpenEMR ships is as 7.0.3 patch 4 released it" "1: the image's shipped files match the patch's hashes"
expect "^PASS  Room: .* has .* free; need about .*backup: database .*new release 8.4.1" "1: room for the backup and the new release is reported"
expect "^NOTE  Room in the database: [0-9]* tables altered from 7.0.3 to 8.4.1, the largest here" "1: the tables the upgrade alters are measured; the database's folder is in another container"
expect "^The plan, from what was found:" "1: a plan is printed"
expect "with the extensions bcmath, imagick" "1: the plan installs the missing extensions"
expect "Upgrade the database server from MariaDB 10.6 to one CI tested 8.4.1 with" "1: the plan upgrades the database server first"
expect "run sql_upgrade.php from 7.0.3 (it runs [0-9]* upgrade scripts)" "1: the plan runs the upgrade from the right release"
expect "^NOTE  Site code on the new PHP: 8.4.1 runs on this PHP (8.3), so the code this site added meets no PHP change" "1: no PHP change, so the site's own code isn't scanned"
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
# A target needing a newer PHP than the old release was tested with: one maintenance window.
docker exec $C sh -c 'rm -rf /tmp/pf-facts2 && cp -r /tmp/pf-facts /tmp/pf-facts2'
docker exec $C php -r '$t = json_decode(file_get_contents("/tmp/pf-facts2/8.4.1.json"), true); $t["php"] = "8.9.0"; file_put_contents("/tmp/pf-facts2/8.4.1.json", json_encode($t));
  $f = json_decode(file_get_contents("/tmp/pf-facts2/7.0.3.json"), true); $f["ci_php"] = ["8.1", "8.2"]; file_put_contents("/tmp/pf-facts2/7.0.3.json", json_encode($f));'
out=$(docker exec $C php /tmp/preflight.php --openemr=/var/www/localhost/htdocs/openemr --facts=/tmp/pf-facts2 || true)
expect "Move to PHP 8.9 or later" "7: the plan moves PHP first when the target needs a newer one"
expect "was tested on PHP 8.1, 8.2 only, so it may not run on PHP 8.9: do this and the next step in one maintenance window" "7: and warns when the old release may not run on it"
expect "^PASS  Site code on the new PHP: the 0 files this site added use nothing PHP 8.3 to 8.9 removes" "7: with nothing added, the site's own code passes"
expect "^NOTE  Site code on the new PHP: the PHP changes known cover PHP up to 8.5, so what PHP 8.9 itself changes isn't checked yet" "7: and a PHP newer than the facts is said, not passed in silence"
# A local change to one of OpenEMR's own files (synthetic), and one to sites/, which isn't one.
docker exec $C sh -c 'echo "{# synthetic local change #}" >> /var/www/localhost/htdocs/openemr/interface/forms/newpatient/templates/newpatient/partials/common/_form-heading.html.twig && echo "// synthetic" >> /var/www/localhost/htdocs/openemr/sites/default/config.php'
out=$(run)
expect "^WARN  Local changes: 1 of OpenEMR's own files were changed here.*_form-heading.html.twig" "8: a changed shipped file warns, and sites/ doesn't count"
expect "openemr-upgrade.sh saves them" "8: and says what the upgrade script does with them"
# A file this site added and a module it added, read for what PHP 8.4 and 8.5 remove (facts altered
# so the target needs PHP 8.5): imap and pspell left PHP in 8.4, so their calls fail; an implicitly
# nullable parameter is only deprecated; a call behind function_exists() isn't counted.
docker exec $C sh -c 'rm -rf /tmp/pf-facts3 && cp -r /tmp/pf-facts /tmp/pf-facts3'
docker exec $C php -r '$t = json_decode(file_get_contents("/tmp/pf-facts3/8.4.1.json"), true); $t["php"] = "8.5.0"; file_put_contents("/tmp/pf-facts3/8.4.1.json", json_encode($t));'
docker exec $C sh -c 'OE=/var/www/localhost/htdocs/openemr; mkdir -p $OE/interface/modules/custom_modules/oe-module-pf-scan
printf "%s\n" "<?php" "\$pfBox = imap_open(\"{localhost}\", \"user\", \"secret\");" "function pf_scan_nullable(int \$x = null) { return \$x; }" "if (function_exists(\"imap_close\")) { imap_close(\$pfBox); }" > $OE/custom/pf_scan_test.php
printf "%s\n" "<?php" "\$pfSpell = pspell_new(\"en\");" > $OE/interface/modules/custom_modules/oe-module-pf-scan/index.php'
out=$(docker exec $C php /tmp/preflight.php --openemr=/var/www/localhost/htdocs/openemr --facts=/tmp/pf-facts3 || true)
expect "^FAIL  Site code on the new PHP: 2 uses in the 1 file this site added and its 1 module won't load or stop with an error on PHP 8.5: custom/pf_scan_test.php line 2 imap_open (error when it runs), interface/modules/custom_modules/oe-module-pf-scan/index.php line 2 pspell_new (error when it runs)" "9: an added file and an added module calling what PHP 8.4 removed fail, with their lines"
expect "^NOTE  Site code on the new PHP: 1 use deprecated between PHP 8.3 and 8.5 still works, with a warning" "9: an implicitly nullable parameter is one deprecation, not a failure"
refute "imap_close (error" "9: a call behind function_exists() isn't counted"
expect "Fix the 2 uses of what PHP 8.5 removes in the code this site added (listed above), before moving PHP." "9: the plan says to fix them before moving PHP"
docker exec $C sh -c 'mv /tmp/scan.php /tmp/scan.php.away'
out=$(docker exec $C php /tmp/preflight.php --openemr=/var/www/localhost/htdocs/openemr --facts=/tmp/pf-facts3 || true)
expect "^NOTE  Site code on the new PHP: scan skipped: put scan.php beside this file" "9: without scan.php beside it, the check says the scan was skipped"
docker exec $C sh -c 'mv /tmp/scan.php.away /tmp/scan.php; OE=/var/www/localhost/htdocs/openemr; rm -rf $OE/custom/pf_scan_test.php $OE/interface/modules/custom_modules/oe-module-pf-scan'
# Checks left out by name: each says so, doesn't run, and the summary counts it; a name that isn't one stops it.
out=$(docker exec $C php /tmp/preflight.php --openemr=/var/www/localhost/htdocs/openemr --facts=/tmp/pf-facts --skip=room,local-changes --skip=site-code || true)
expect "^SKIP  Room: left out (--skip=room)" "10: --skip=room says it was left out"
refute "^\(PASS\|WARN\|FAIL\)  Room:" "10: and the room check doesn't run"
expect "^SKIP  Local changes: left out (--skip=local-changes)" "10: so does local-changes, from a second --skip"
expect "3 check(s) left out with --skip, so not checked: local-changes, site-code, room" "10: the summary names what was left out"
expect "^\(PASS\|WARN\|FAIL\)  Previous upgrade" "10: the other checks still run (this one fails here: case 4 left the database behind)"
out=$(docker exec $C php /tmp/preflight.php --openemr=/var/www/localhost/htdocs/openemr --facts=/tmp/pf-facts --skip=rooms 2>&1; echo "exit $?")
expect "^--skip: no check named 'rooms'; the names are xampp, php, " "10: a name that isn't a check is refused, with the names"
expect "^exit 2$" "10: and nothing runs"
out=$(docker exec $C php /tmp/preflight.php --list-checks)
expect "^room-in-database$" "10: --list-checks prints the names"
echo; [ $fails -eq 0 ] && echo "PASSED" || { echo "FAILED: $fails"; exit 1; }
