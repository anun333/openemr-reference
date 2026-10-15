#!/usr/bin/env bash
# End-to-end test of openemr-doctor.php against a throwaway OpenEMR 8.4.1 (official image,
# MariaDB 11.8). It first runs on the install as it is, then breaks one thing at a time the
# way the forum reports describe, checks the doctor names it, and puts it back:
#   files lost from templates/, a vendor package, the built assets, the theme stylesheet;
#   OpenEMR's PHP-error display on; a switched-on module with no files; the keys folder
#   emptied, and a key from another install; a document without its file, and one moved
#   from another root; a half-finished upgrade; a wrong password, a missing site, setup not
#   finished; an edited file, and one that no longer parses; then the browser mode (local
#   only), PHP 7.4, too old for 8.4.1, when intl is required before 7.0.0, and
#   openemr-doctor-docker.sh.
# Everything runs in containers that are deleted at the end. Synthetic data only.
# Needs Docker and the facts in ../site/preflight (python3 gen/build_preflight.py).
set -euo pipefail
cd "$(dirname "$0")"
. ./test_lib.sh
serial
P=doctor-test
docker compose -p $P -f test-doctor-compose.yml up -d >/dev/null
trap 'docker compose -p $P -f test-doctor-compose.yml down -v >/dev/null 2>&1' EXIT
C=$P-openemr-1; D=$P-mysql-1; OE=/var/www/localhost/htdocs/openemr; S=$OE/sites/default
echo "waiting for OpenEMR 8.4.1 to install itself (several minutes)..."
wait_ready $C $OE
docker cp openemr-doctor.php $C:/tmp/doctor.php
docker exec $C mkdir -p /tmp/facts
for f in ../site/preflight/releases.json ../site/preflight/8.4.1.json ../site/preflight/8.4.1-files.json ../site/preflight/8.4.1-hashes.json; do docker cp "$f" $C:/tmp/facts/; done
q() { docker exec $D mariadb -uroot -proot openemr -N -e "SET SESSION sql_mode=''; $1"; }
x() { docker exec $C sh -c "$1"; }
run() { docker exec -u apache $C php /tmp/doctor.php --openemr=$OE --facts=/tmp/facts "$@" || true; }
fails=0
expect() { if echo "$out" | grep -q -- "$1"; then echo "ok   $2"; else echo "FAIL $2"; echo "$out" | grep -E "^(PASS|WARN|FAIL|NOTE) " | sed 's/^/       | /'; fails=$((fails+1)); fi; }
refute() { if echo "$out" | grep -q -- "$1"; then echo "FAIL $2"; fails=$((fails+1)); else echo "ok   $2"; fi; }

# A fresh install has no keys until something is encrypted: encrypt a value the way OpenEMR does.
docker exec -u apache -e HTTP_HOST=localhost $C php -r '$ignoreAuth = true; $_GET["site"] = "default"; $sessionAllowWrite = true;
  require "/var/www/localhost/htdocs/openemr/interface/globals.php"; \OpenEMR\BC\ServiceContainer::getCrypto()->encryptStandard("doctor-test");' >/dev/null
out=$(run); echo "$out"; echo
expect "^PASS  PHP: 8" "1: PHP in range"
expect "^PASS  PHP extensions" "1: extensions loaded"
expect "^PASS  PHP libraries: all" "1: every Composer library present"
expect "^PASS  Page assets" "1: built assets present"
expect "^PASS  Files: all" "1: every package file present"
expect "^PASS  Local changes: all [0-9]* files of the OpenEMR 8.4.1 package that are here are as released" "1: no shipped file edited"
expect "^PASS  Database version" "1: database matches code"
expect "^PASS  Theme" "1: theme present"
expect "^PASS  Encryption keys: 2 in the keys folder, and they match" "1: keys verified against the database"
expect "^WARN  Modules: Composer installs oe-module-claimrev-connect" "1: the image's missing ClaimRev is reported"
expect "^NOTE  Setup scripts: removed after setup, as the Docker image does" "1: the image's removed setup scripts are a note"
refute "^FAIL" "1: no failures on a healthy install"

x "mv $OE/templates/interface/main/tabs /tmp/tabs"; out=$(run)
expect "^FAIL  Files: .* missing, in templates/interface" "2: lost template files fail (t/25717)"
x "mv /tmp/tabs $OE/templates/interface/main/tabs"
x "mv $OE/vendor/adodb /tmp/adodb"; out=$(run)
expect "^FAIL  PHP libraries: 1 of the .* adodb/adodb-php" "3: a lost vendor package fails"
x "mv /tmp/adodb $OE/vendor/adodb"
x "mv $OE/public/assets/jquery /tmp/jquery"; out=$(run)
expect "^FAIL  Page assets: 1 of the 3 .*assets/jquery/" "4: a missing built asset fails (t/26790)"
x "mv /tmp/jquery $OE/public/assets/jquery"
x "mv $OE/Documentation /tmp/Documentation"; out=$(run)
expect "^PASS  Files: all .* optional ones" "5: missing documentation is optional"
x "mv /tmp/Documentation $OE/Documentation"
# An edited file is named; an edit that doesn't parse fails with its line.
x "cp -p $OE/interface/main/about_page.php /tmp/about_page.php && printf '\n' >> $OE/interface/main/about_page.php"; out=$(run)
expect "^NOTE  Local changes: 1 of OpenEMR's own files differ from OpenEMR 8.4.1 as released: interface/main/about_page.php" "5b: an edited file is named"
refute "^FAIL  Local changes" "5b: and an edit that parses isn't a failure"
x "cp -p $OE/interface/main/main_screen.php /tmp/main_screen.php && sed -i '2i this is not php;' $OE/interface/main/main_screen.php"; out=$(run)
expect "^FAIL  Local changes: 1 edited file of OpenEMR's own doesn't parse with this PHP: interface/main/main_screen.php line 2" "5b: an edit that doesn't parse fails, with its line"
expect "^NOTE  Local changes: 2 of OpenEMR's own files differ" "5b: both edited files are named"
x "cp -p /tmp/about_page.php $OE/interface/main/about_page.php && cp -p /tmp/main_screen.php $OE/interface/main/main_screen.php"
out=$(run); expect "^PASS  Local changes: all" "5b: restored files pass again"

q "UPDATE globals SET gl_value='style_gone.css' WHERE gl_name='css_header'"; out=$(run)
expect "^FAIL  Theme: the chosen theme public/themes/style_gone.css is missing" "6: a missing theme fails"
q "UPDATE globals SET gl_value='style_light.css' WHERE gl_name='css_header'"
q "UPDATE globals SET gl_value='1' WHERE gl_name='user_php_debug'"; out=$(run)
expect "^WARN  Error display: OpenEMR's user_php_debug setting is on" "7: OpenEMR showing PHP errors warns (t/27005)"
q "UPDATE globals SET gl_value='0' WHERE gl_name='user_php_debug'"
q "INSERT INTO modules (mod_name, mod_directory, mod_active, type) VALUES ('Gone', 'oe-module-gone', 1, 0)"; out=$(run)
expect "^WARN  Modules: switched on, but their files are missing: oe-module-gone" "8: a switched-on module without files warns (t/25702)"
q "DELETE FROM modules WHERE mod_directory='oe-module-gone'"

x "mkdir -p /tmp/keys && mv $S/documents/logs_and_misc/methods/seven? /tmp/keys/"; out=$(run)
expect "^FAIL  Encryption keys: the database has encryption keys" "9: an emptied keys folder fails (t/25795)"
x "cp -p /tmp/keys/seven? $S/documents/logs_and_misc/methods/"
# A key from another install: same format, different HMAC key.
x "php -r '\$k=random_bytes(32); \$iv=random_bytes(16); \$c=openssl_encrypt(random_bytes(32),\"aes-256-cbc\",\$k,OPENSSL_RAW_DATA,\$iv); echo \"007\".base64_encode(hash_hmac(\"sha384\",\$iv.\$c,random_bytes(32),true).\$iv.\$c);' > $S/documents/logs_and_misc/methods/sevenb"; out=$(run)
expect "^FAIL  Encryption keys: the keys folder and the database don't belong together: sevenb" "10: a key from another install fails"
x "cp -p /tmp/keys/sevenb $S/documents/logs_and_misc/methods/sevenb"
out=$(run); expect "^PASS  Encryption keys: 2 .* match" "10: keys restored"

q "INSERT INTO documents (id, type, url, path_depth, storagemethod, deleted, foreign_id, date) VALUES (990001, 'file_url', 'file://$S/documents/1/doctor-test.pdf', 1, 0, 0, 1, NOW())"; out=$(run)
expect "^WARN  Documents: 1 of 1 documents checked have no file .*990001" "11: a document without its file warns (t/26815)"
x "mkdir -p $S/documents/1 && echo synthetic > $S/documents/1/doctor-test.pdf"
q "UPDATE documents SET url='file:///old/server/openemr/sites/default/documents/1/doctor-test.pdf' WHERE id=990001"; out=$(run)
expect "^PASS  Documents: all 1 documents checked have their file" "11: a document moved from another root is found where OpenEMR looks"
q "DELETE FROM documents WHERE id=990001"; x "rm -f $S/documents/1/doctor-test.pdf"

q "UPDATE version SET v_database = v_database - 1"; out=$(run)
expect "^FAIL  Database version: the code is 8.4.1" "12: a half-finished upgrade fails"
q "UPDATE version SET v_database = v_database + 1"

x "cp -a $S $OE/sites/wrongpass && sed -i \"s/^\\\$pass.*/\\\$pass = 'nope';/\" $OE/sites/wrongpass/sqlconf.php"; out=$(run --site=wrongpass)
expect "^FAIL  Database: can't connect with sites/wrongpass/sqlconf.php (error 1045)" "13: a wrong password names error 1045"
expect "user name or password" "13: and says what it means"
x "rm -rf $OE/sites/wrongpass"
out=$(run --site=nosuch)
expect "^FAIL  Site: there is no sites/nosuch/sqlconf.php; sites here: default" "14: a missing site lists the real ones"
x "cp -a $S $OE/sites/unfinished && sed -i 's/^\$config = 1;/\$config = 0;/' $OE/sites/unfinished/sqlconf.php"; out=$(run --site=unfinished)
expect "^FAIL  Setup: sites/unfinished/sqlconf.php says setup hasn't finished, and setup.php is missing" "15: unfinished setup without setup.php (the image removed it) fails"
refute "^PASS  Database" "15: and the database isn't checked"
x "touch $OE/setup.php"; out=$(run --site=unfinished)
expect "^NOTE  Setup: sites/unfinished/sqlconf.php says setup hasn't finished" "15: with setup.php in place it says to open it"
x "rm -f $OE/setup.php"
x "rm -rf $OE/sites/unfinished"

# Browser mode: in the OpenEMR folder, facts beside it, local requests only.
docker cp openemr-doctor.php $C:$OE/openemr-doctor.php
x "mkdir -p $OE/openemr-doctor-facts && cp /tmp/facts/* $OE/openemr-doctor-facts/ && chown -R apache $OE/openemr-doctor.php $OE/openemr-doctor-facts"
out=$(docker exec $C curl -s http://localhost/openemr-doctor.php)
expect "Checked by the web server's PHP" "16: the browser mode runs as the web server"
expect "^PASS  Documents folder: the web server can write it" "16: and checks what the web server can write"
expect "^PASS  Encryption keys" "16: and the keys"
expect "Delete openemr-doctor.php" "16: and asks to be deleted"
out=$(docker exec $C curl -s -H 'X-Forwarded-For: 203.0.113.9' http://localhost/openemr-doctor.php)
expect "only answers a browser on this server" "17: refused through a proxy"
out=$(curl -s http://127.0.0.1:8372/openemr-doctor.php)
expect "only answers a browser on this server" "17: refused from outside the container"
refute "PASS" "17: and shows nothing"
x "rm -rf $OE/openemr-doctor.php $OE/openemr-doctor-facts"

# PHP 7.4 on a tree that says it is 8.4.1 (the image's tree isn't a volume to share).
out=$(docker run --rm -v "$PWD:/d:ro" -v "$PWD/../site/preflight:/facts:ro" php:7.4-cli sh -c \
  'mkdir -p /oe && printf "<?php\n\$v_major = 8;\n\$v_minor = 4;\n\$v_patch = 1;\n\$v_realpatch = 0;\n\$v_database = 543;\n" > /oe/version.php && php /d/openemr-doctor.php --openemr=/oe --facts=/facts' || true)
expect "^FAIL  PHP: 7.4.* is too old: OpenEMR 8.4.1 needs 8.3.0 or later" "18: PHP 7.4 is too old for 8.4.1, said plainly"
expect "^FAIL  PHP extensions: missing: .*intl" "18: and its missing extensions, intl among them (t/25453)"
expect "^NOTE  Local changes: 1 of OpenEMR's own files differ from OpenEMR 8.4.1 as released: version.php" "18: the hand-written version.php is named as edited"

# intl before 7.0.0: required only if the install's own code uses it (5.0.2's image ships without it).
# php:7.4-cli has no intl and no mysqli; fake trees with only version.php and one PHP file.
tree() { printf '<?php\n$v_major = %s;\n$v_minor = %s;\n$v_patch = %s;\n$v_realpatch = 0;\n$v_database = 1;\n' "$1" "$2" "$3"; }
intl_run() { docker run --rm -v "$PWD:/d:ro" -v "$PWD/../site/preflight:/facts:ro" php:7.4-cli sh -c \
  "mkdir -p /oe/library && printf '%s' '$1' > /oe/version.php && printf '%s' '$2' > /oe/library/x.php && php /d/openemr-doctor.php --openemr=/oe --facts=/facts" 2>&1 || true; }
out=$(intl_run "$(tree 6 1 0)" '<?php echo 1;')
expect "^FAIL  PHP extensions: missing: mysqli " "19: 6.1.0 without intl in its code: mysqli is missing"
refute "^FAIL  PHP extensions: .*intl" "19: and intl isn't required"
out=$(intl_run "$(tree 6 1 0)" '<?php echo Normalizer::normalize("a");')
expect "^FAIL  PHP extensions: missing: .*intl" "19: 6.1.0 whose code uses Normalizer: intl is required"
out=$(intl_run "$(tree 7 0 3)" '<?php echo 1;')
expect "^FAIL  PHP extensions: missing: .*intl" "19: 7.0.3 requires intl, as before"

# openemr-doctor-docker.sh on this compose project: sites/ isn't on a volume here, so it runs inside the container.
out=$(COMPOSE_FILE=test-doctor-compose.yml COMPOSE_PROJECT_NAME=$P DOCTOR=openemr-doctor.php bash openemr-doctor-docker.sh 2>&1 || true)
expect "OpenEMR install doctor: /var/www/localhost/htdocs/openemr (site default), OpenEMR 8.4.1" "20: openemr-doctor-docker.sh finds the OpenEMR container"
expect "^PASS  Database version" "20: and, without a sites/ volume, runs inside it with the database checks"
refute "^FAIL" "20: with no failures"
V=$(sed -n "s/^    VERSION=//p" openemr-doctor-docker.sh)   # the release the script fetches from
expect "openemr-doctor-docker.sh $V: container $C, image openemr/openemr:8.4.1, running" "20: it says which container and image it checks"
expect "sites/ is inside the container: running the doctor in it" "20: and how it runs the doctor"

# Compared with another release than the one installed, missing files are notes: a build from the
# development branch (a -dev tag), and a release newer than the facts. Scenario 2 is the control:
# the same missing templates fail on 8.4.1 as released.
# The image's files are apache's and read-only (0400): keep that when saving and restoring.
x "cp -p $OE/version.php /tmp/version.php.orig && sed -i \"s/^\\\$v_tag *=.*/\\\$v_tag   = '-dev';/\" $OE/version.php && chown apache:apache $OE/version.php"
x "mv $OE/templates/interface/main/tabs /tmp/tabs"; out=$(run)
expect "^NOTE  Release facts: 8.4.1-dev is an unreleased build; comparing it with 8.4.1" "21: a -dev build is named as unreleased"
expect "^NOTE  Files: .* missing, in templates/interface" "21: and its missing files are a note"
refute "^FAIL" "21: not a failure"
x "cp -p /tmp/version.php.orig $OE/version.php && sed -i \"s/^\\\$v_patch *=.*/\\\$v_patch = '9';/\" $OE/version.php && chown apache:apache $OE/version.php"; out=$(run)
expect "^NOTE  Release facts: 8.4.9 isn't a release with facts yet; using 8.4.1" "22: a release newer than the facts is named"
expect "^NOTE  Files: .* missing, in templates/interface" "22: and its missing files are a note"
refute "^FAIL" "22: not a failure"
x "cp -p /tmp/version.php.orig $OE/version.php && mv /tmp/tabs $OE/templates/interface/main/tabs"; out=$(run)
refute "^FAIL" "22b: version.php and the templates put back"

# A version.php the web server can't read (ownership lost in a copy) is said plainly, not compared
# with the facts as an empty version. Found by this test's own first run.
x "chown root:root $OE/version.php && chmod 600 $OE/version.php"; out=$(run)
expect "^FAIL  Version: .*can't read version.php (0600)" "22c: an unreadable version.php fails, saying who can't read it"
expect "OpenEMR (version unknown)" "22c: and the version is unknown, not empty"
refute "older than any release with facts" "22c: not compared with the facts"
x "cp -p /tmp/version.php.orig $OE/version.php"; out=$(run)
refute "^FAIL" "22c: put back"

# --debug says where each fact came from and how much there was.
out=$(run --debug)
expect "^DEBUG .* facts 8.4.1-files.json: [0-9]* bytes from /tmp/facts" "23: --debug names each facts file it read"
expect "^DEBUG .* Files: [0-9]* in the facts for OpenEMR 8.4.1, 0 missing" "23: and the counts behind the file check"
expect "^DEBUG .* results: [0-9]* pass, .* 0 fail" "23: and a tally"
expect "^PASS  Files: all" "23: the checks themselves are the same"

# Facts that look truncated are reported, instead of passing a check against almost nothing.
TMPDIR_SHORT=$(mktemp -d)
python3 -c 'import json, sys; d = json.load(open(sys.argv[1])); first = next(iter(d["dirs"])); d["dirs"] = {first: d["dirs"][first][:5]}; json.dump(d, open(sys.argv[2], "w"))' ../site/preflight/8.4.1-files.json "$TMPDIR_SHORT/8.4.1-files.json"
docker exec $C mkdir -p /tmp/facts-short
for f in ../site/preflight/releases.json ../site/preflight/8.4.1.json ../site/preflight/8.4.1-hashes.json "$TMPDIR_SHORT/8.4.1-files.json"; do docker cp "$f" $C:/tmp/facts-short/; done
docker exec $C chmod -R a+rX /tmp/facts-short
out=$(docker exec -u apache $C php /tmp/doctor.php --openemr=$OE --facts=/tmp/facts-short || true)
expect "^WARN  Release facts: the file list for OpenEMR 8.4.1 has only [0-9]* files, which looks incomplete" "24: a file list cut short is reported"

# openemr-doctor-docker.sh fetching the doctor itself: checked against SHA256SUMS, from a release
# folder of our own (file://), run from a directory with no openemr-doctor.php in it.
here=$(pwd); rel=$(mktemp -d); empty=$(mktemp -d)
cp openemr-doctor.php "$rel/" && (cd "$rel" && sha256sum openemr-doctor.php > SHA256SUMS)
fetched_doctor() { (cd "$empty" && COMPOSE_FILE=$here/test-doctor-compose.yml COMPOSE_PROJECT_NAME=$P OPENEMR_REFERENCE_BASE=file://$rel bash "$here/openemr-doctor-docker.sh" 2>&1) || true; }
out=$(fetched_doctor)
expect "doctor: downloaded from release v$V, matches its SHA256SUMS" "25: a downloaded doctor is checked against SHA256SUMS"
expect "^PASS  Database version" "25: and then runs"
echo '// changed' >> "$rel/openemr-doctor.php"; out=$(fetched_doctor)
expect "doesn't match SHA256SUMS of release v$V" "26: a doctor that doesn't match is refused"
refute "OpenEMR install doctor:" "26: and never runs"
[ -z "$(ls -A "$empty")" ] && echo "ok   26: nothing left in the directory it ran from" || { echo "FAIL 26: files left in $empty"; fails=$((fails+1)); }
out=$(COMPOSE_FILE=test-doctor-compose.yml COMPOSE_PROJECT_NAME=$P DOCTOR=openemr-doctor.php bash openemr-doctor-docker.sh --debug 2>&1 || true)
expect "^+ openemr-doctor-docker.sh:" "27: --debug traces the script"
expect "^DEBUG " "27: and runs the doctor with --debug"
rm -rf "$rel" "$empty" "$TMPDIR_SHORT"

echo; [ $fails -eq 0 ] && echo "PASSED" || { echo "FAILED: $fails"; exit 1; }
