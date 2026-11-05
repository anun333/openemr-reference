#!/usr/bin/env bash
# End-to-end test of openemr-doctor.php against a throwaway OpenEMR 8.4.1 (official image,
# MariaDB 11.8). It first runs on the install as it is, then breaks one thing at a time the
# way the forum reports describe, checks the doctor names it, and puts it back:
#   files lost from templates/, a vendor package, the built assets, the theme stylesheet;
#   OpenEMR's PHP-error display on; a switched-on module with no files; the keys folder
#   emptied, and a key from another install; a document without its file, and one moved
#   from another root; a half-finished upgrade; a wrong password, a missing site, setup not
#   finished; an edited file, one that no longer parses, and one calling each() (scan.php); then the browser mode (local
#   only), PHP 7.4, too old for 8.4.1, when intl is required before 7.0.0, and
#   openemr-doctor-docker.sh (its exit code, sites/ on a volume of a container that never started,
#   facts beside the doctor, how it finds OpenEMR's folder); the install's own composer.json without
#   facts and with them; then MySQL over SSL: a database that only accepts it, its CA,
#   a connection by IP, the wrong CA, a client certificate without its key, a CA that isn't PEM.
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
# The published image ships the PHP that php2shell (2026-10-21) affects. A healthy install has
# the advisory's in-place update (OpenEMR's t/27152), so apply it as a site would, and restart.
if [ "$(docker exec $C php -r 'echo version_compare(PHP_VERSION, "8.5.12", "<") ? "old" : "fixed";')" = old ]; then
    docker exec $C sh -c "apk update >/dev/null && apk upgrade \$(apk info -q | grep '^php85') >/dev/null"
    docker restart $C >/dev/null
    wait_ready $C $OE
fi
docker cp openemr-doctor.php $C:/tmp/doctor.php
docker cp scan.php $C:/tmp/scan.php
docker exec $C mkdir -p /tmp/facts
for f in ../site/preflight/releases.json ../site/preflight/8.4.1.json ../site/preflight/8.4.1-files.json ../site/preflight/8.4.1-hashes.json ../site/preflight/php-changes.json; do docker cp "$f" $C:/tmp/facts/; done
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
expect "^PASS  PHP security: 8.5.1[2-9]" "1: PHP has the php2shell fix, updated in place"
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
# An edit that parses but calls what PHP 8.0 removed fails only when its line runs: scan.php finds it.
# A call behind function_exists() isn't counted, and without scan.php beside the doctor it says so.
x "cat > $OE/interface/main/about_page.php <<'PHPX'
<?php
\$pfList = [1];
while (list(, \$pfValue) = each(\$pfList)) {
}
if (function_exists('create_function')) {
    \$pfMade = create_function('', '');
}
PHPX"; out=$(run)
expect "^FAIL  Local changes on this PHP: 1 use in edited files of OpenEMR's own won't load or stop with an error on PHP 8.5: interface/main/about_page.php line 3 each (error when it runs)" "5c: an edit calling each() fails on PHP 8, with its line"
refute "create_function (error" "5c: and a call behind function_exists() isn't counted"
x "mv /tmp/scan.php /tmp/scan.php.away"; out=$(run)
expect "^NOTE  Local changes on this PHP: scan skipped: put scan.php beside this file" "5c: without scan.php beside it, the doctor says the scan was skipped"
x "mv /tmp/scan.php.away /tmp/scan.php && cp -p /tmp/about_page.php $OE/interface/main/about_page.php"
out=$(run); refute "Local changes on this PHP" "5c: with nothing edited, nothing is scanned"
# Checks left out by name: each says so and doesn't run, the summary counts them; an unknown name is refused.
out=$(run --skip=documents,encryption-keys)
expect "^SKIP  Documents: left out (--skip=documents)" "5d: --skip=documents says it was left out"
refute "^\(PASS\|WARN\|FAIL\)  Encryption keys:" "5d: and encryption-keys doesn't run"
expect "2 check(s) left out with --skip, so not checked: encryption-keys, documents" "5d: the summary names what was left out"
expect "^PASS  Database version" "5d: the other checks still run"
out=$(docker exec -u apache $C php /tmp/doctor.php --openemr=$OE --facts=/tmp/facts --skip=document 2>&1; echo "exit $?")
expect "^--skip: no check named 'document' to skip; the names are php, " "5d: a name that isn't a check is refused, with the names"
expect "^exit 2$" "5d: and nothing runs"

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
out=$(docker run --rm --cpus 1 --memory 512m --memory-swap 512m -v "$PWD:/d:ro" -v "$PWD/../site/preflight:/facts:ro" php:7.4-cli sh -c \
  'mkdir -p /oe && printf "<?php\n\$v_major = 8;\n\$v_minor = 4;\n\$v_patch = 1;\n\$v_realpatch = 0;\n\$v_database = 543;\n" > /oe/version.php && php /d/openemr-doctor.php --openemr=/oe --facts=/facts' || true)
expect "^FAIL  PHP: 7.4.* is too old: OpenEMR 8.4.1 needs 8.3.0 or later" "18: PHP 7.4 is too old for 8.4.1, said plainly"
expect "^FAIL  PHP extensions: missing: .*intl" "18: and its missing extensions, intl among them (t/25453)"
expect "^NOTE  Local changes: 1 of OpenEMR's own files differ from OpenEMR 8.4.1 as released: version.php" "18: the hand-written version.php is named as edited"

# intl before 7.0.0: required only if the install's own code uses it (5.0.2's image ships without it).
# php:7.4-cli has no intl and no mysqli; fake trees with only version.php and one PHP file.
tree() { printf '<?php\n$v_major = %s;\n$v_minor = %s;\n$v_patch = %s;\n$v_realpatch = 0;\n$v_database = 1;\n' "$1" "$2" "$3"; }
intl_run() { docker run --rm --cpus 1 --memory 512m --memory-swap 512m -v "$PWD:/d:ro" -v "$PWD/../site/preflight:/facts:ro" php:7.4-cli sh -c \
  "mkdir -p /oe/library && printf '%s' '$1' > /oe/version.php && printf '%s' '$2' > /oe/library/x.php && php /d/openemr-doctor.php --openemr=/oe --facts=/facts" 2>&1 || true; }
out=$(intl_run "$(tree 6 1 0)" '<?php echo 1;')
expect "^FAIL  PHP extensions: missing: mysqli " "19: 6.1.0 without intl in its code: mysqli is missing"
refute "^FAIL  PHP extensions: .*intl" "19: and intl isn't required"
out=$(intl_run "$(tree 6 1 0)" '<?php echo Normalizer::normalize("a");')
expect "^FAIL  PHP extensions: missing: .*intl" "19: 6.1.0 whose code uses Normalizer: intl is required"
out=$(intl_run "$(tree 7 0 3)" '<?php echo 1;')
expect "^FAIL  PHP extensions: missing: .*intl" "19: 7.0.3 requires intl, as before"

# 19b. The install's own composer.json: without facts it gives the PHP floor and the extensions; with
# facts, a higher floor in it counts (a release newer than the facts) and a lower one is said.
# php:7.4-cli (7.4.33) has no soap, which only composer.json names here.
own_run() {  # own_run COMPOSER_PHP [DOCTOR_ARGS...]: a tree that says 8.4.1, with this composer.json
    local c="{\"require\": {\"php\": \"$1\", \"ext-soap\": \"*\", \"ext-json\": \"*\"}}"; shift
    docker run --rm --cpus 1 --memory 512m --memory-swap 512m -v "$PWD:/d:ro" -v "$PWD/../site/preflight:/facts:ro" php:7.4-cli sh -c \
      "mkdir -p /oe && printf '%s' '$(tree 8 4 1)' > /oe/version.php && printf '%s' '$c' > /oe/composer.json && php /d/openemr-doctor.php --openemr=/oe $*" 2>&1 || true
}
out=$(own_run '>=8.3.0' --facts=/nonexistent)
expect "^FAIL  PHP: 7.4.* is too old: this install's composer.json asks for 8.3.0 or later" "19b: without facts, the PHP floor comes from composer.json"
expect "^FAIL  PHP extensions: missing: soap" "19b: and the extensions it requires (soap, which setup's own list hasn't)"
for c in '^7.3 || ^8.0:PASS.*asks for 7.3.0' '>= 7.4.0:PASS.*asks for 7.4.0' '~8.1.0:FAIL.*asks for 8.1.0' '>=7.2 <8.0:PASS.*asks for 7.2.0' 'dev-master:NOTE  PHP: 7.4.* (no release facts to compare with, and no composer.json that says)'; do
    out=$(own_run "${c%%:*}" --facts=/nonexistent)
    expect "^${c#*:}" "19b: composer.json's php '${c%%:*}' is read as ${c#*:}"
done
out=$(own_run '>=8.4.0' --facts=/facts)
expect "^FAIL  PHP: 7.4.* is too old: this install's composer.json asks for 8.4.0 or later" "19b: with facts, a higher floor in composer.json counts"
out=$(own_run '>=7.2.0' --facts=/facts)
expect "^NOTE  PHP: this install's composer.json asks for PHP >=7.2.0, lower than the 8.3.0 OpenEMR 8.4.1 needs" "19b: and a lower one is said"
expect "^FAIL  PHP: 7.4.* is too old: OpenEMR 8.4.1 needs 8.3.0 or later" "19b: while the release's floor still counts"

# openemr-doctor-docker.sh on this compose project: sites/ isn't on a volume here, so it runs inside the container.
out=$(COMPOSE_FILE=test-doctor-compose.yml COMPOSE_PROJECT_NAME=$P DOCTOR=openemr-doctor.php bash openemr-doctor-docker.sh 2>&1 || true)
expect "OpenEMR install doctor: /var/www/localhost/htdocs/openemr (site default), OpenEMR 8.4.1" "20: openemr-doctor-docker.sh finds the OpenEMR container"
expect "^PASS  Database version" "20: and, without a sites/ volume, runs inside it with the database checks"
refute "^FAIL" "20: with no failures"
V=$(sed -n "s/^    VERSION=//p" openemr-doctor-docker.sh)   # the release the script fetches from
expect "openemr-doctor-docker.sh $V: container $C, image openemr/openemr:8.4.1, running" "20: it says which container and image it checks"
expect "sites/ is inside the container: running the doctor in it" "20: and how it runs the doctor"
expect "OpenEMR is in /var/www/localhost/htdocs/openemr (its version.php)" "20: it finds OpenEMR's folder by its version.php"
expect "openemr-doctor-docker.sh $V: released [0-9-]*\$" "20: it says its version and date"
out=$(COMPOSE_FILE=test-doctor-compose.yml COMPOSE_PROJECT_NAME=$P DOCTOR=openemr-doctor.php bash openemr-doctor-docker.sh >/dev/null 2>&1; echo "exit $?")
expect "^exit 0$" "20: its exit code is the doctor's: 0 on a healthy install"
q "UPDATE version SET v_database = v_database - 1"
out=$(COMPOSE_FILE=test-doctor-compose.yml COMPOSE_PROJECT_NAME=$P DOCTOR=openemr-doctor.php bash openemr-doctor-docker.sh 2>&1; echo "exit $?")
q "UPDATE version SET v_database = v_database + 1"
expect "^FAIL  Database version" "20b: a failing check, run through openemr-doctor-docker.sh"
expect "^exit 1$" "20b: makes its exit code 1, as the doctor's"
out=$(COMPOSE_FILE=test-doctor-compose.yml COMPOSE_PROJECT_NAME=$P DOCTOR=openemr-doctor.php OE=/nowhere bash openemr-doctor-docker.sh 2>&1; echo "exit $?")
refute "OpenEMR is in " "20b: OE= names the folder, and it doesn't look"
expect "/nowhere doesn't look like an OpenEMR folder" "20b: so a wrong one is said by the doctor"
expect "^exit 2$" "20b: with exit code 2 (it couldn't check)"

# 20c. sites/ on a volume, as in OpenEMR's compose files, and the container never started: the
# doctor runs from a throwaway container of the same image with its volumes, on its network. The
# volume gets this install's sites/; the image's PHP may predate the php2shell fix, so that check is
# left out here (the in-place update is in the running container, not the image).
VC=$P-volume; VV=$P-sites
docker volume create $VV >/dev/null
docker cp $C:$OE/sites/. - | docker run --rm -i --memory 256m --memory-swap 256m -v $VV:/dst alpine:3 tar -xf - -C /dst
docker create --name $VC --memory 1g --memory-swap 1g --network ${P}_default -v $VV:$OE/sites openemr/openemr:8.4.1 >/dev/null
out=$(CONTAINER=$VC DOCTOR=openemr-doctor.php SKIP=php-security bash openemr-doctor-docker.sh 2>&1; echo "exit $?")
docker rm -f -v $VC >/dev/null; docker volume rm $VV >/dev/null
expect "container $VC, image openemr/openemr:8.4.1, created" "20c: a container that never started"
expect "OpenEMR is in /var/www/localhost/htdocs/openemr (its version.php)" "20c: its folder found in the image, with the volume"
expect "sites/ is on a volume: running the doctor in a throwaway container of the same image, with its volumes, on network ${P}_default" "20c: runs the doctor beside it"
expect "^PASS  Database: connected to mysql:3306" "20c: reaching the database on the container's network"
expect "^PASS  Database version" "20c: and checking it"
expect "^PASS  Files: all" "20c: and the image's files"
expect "^exit 0$" "20c: with the doctor's exit code"

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
fetched_doctor() { (cd "$empty" && COMPOSE_FILE=$here/test-doctor-compose.yml COMPOSE_PROJECT_NAME=$P OPENEMR_DOCTOR_HOME=file://$rel bash "$here/openemr-doctor-docker.sh" 2>&1) || true; }
out=$(fetched_doctor)
expect "doctor: downloaded from file://$rel, matches its SHA256SUMS" "25: a doctor downloaded from its home is checked against the SHA256SUMS there"
expect "^PASS  Database version" "25: and then runs"
expect "couldn't reach file://$rel to look for a newer copy; this one is [0-9]* days old" "25: a home without the script: it says how old it is"
echo '// changed' >> "$rel/openemr-doctor.php"; out=$(fetched_doctor)
expect "doesn't match file://$rel/SHA256SUMS" "26: a doctor that doesn't match is refused"
refute "OpenEMR install doctor:" "26: and never runs"
[ -z "$(ls -A "$empty")" ] && echo "ok   26: nothing left in the directory it ran from" || { echo "FAIL 26: files left in $empty"; fails=$((fails+1)); }
out=$(COMPOSE_FILE=test-doctor-compose.yml COMPOSE_PROJECT_NAME=$P DOCTOR=openemr-doctor.php bash openemr-doctor-docker.sh --debug 2>&1 || true)
expect "^+ openemr-doctor-docker.sh:" "27: --debug traces the script"
expect "^DEBUG " "27: and runs the doctor with --debug"
rm -rf "$rel" "$empty" "$TMPDIR_SHORT"

# 27b. A server without internet: the doctor, scan.php and openemr-doctor-facts/ copied beside each
# other. The wrapper hands the folder to the doctor, which reads its facts from it and says how old it is.
air=$(mktemp -d); chmod 755 "$air"
cp openemr-doctor.php scan.php "$air/" && mkdir "$air/openemr-doctor-facts"
for f in releases.json 8.4.1.json 8.4.1-files.json 8.4.1-hashes.json php-changes.json php-security.json; do cp "../site/preflight/$f" "$air/openemr-doctor-facts/"; done
chmod -R a+rX "$air"
out=$(COMPOSE_FILE=test-doctor-compose.yml COMPOSE_PROJECT_NAME=$P DOCTOR=$air/openemr-doctor.php OPENEMR_DOCTOR_NO_UPDATE_CHECK=1 bash openemr-doctor-docker.sh --debug 2>&1 || true)
expect "release facts: $air/openemr-doctor-facts, beside the doctor" "27b: facts beside a doctor of your own are handed to it"
expect "^DEBUG .* facts 8.4.1-files.json: [0-9]* bytes from /tmp/openemr-doctor-facts" "27b: and the doctor reads them there"
expect "^PASS  Files: all" "27b: with every check that needs them"
refute "^+ openemr-doctor-docker.sh:[0-9]*: curl" "27b: and nothing is downloaded"
rm -rf "$air"
x "test ! -e /tmp/openemr-doctor-facts" && echo "ok   27b: nothing left in the container" || { echo "FAIL 27b: /tmp/openemr-doctor-facts left in the container"; fails=$((fails+1)); }

# 27c. How openemr-doctor-docker.sh finds OpenEMR's folder: the script it runs in the image, on
# fake trees. A known web root first; else a version.php of OpenEMR's (it sets $v_database) found
# within five levels of the usual places, passing over another program's; else nothing.
probe=$(sed -n "/^        local probe='/,/done'\$/p" openemr-doctor-docker.sh | sed -e "1s/^        local probe='//" -e "\$s/'\$//")
oe_probe() { docker run --rm --memory 256m --memory-swap 256m --network none --entrypoint sh alpine:3 -c "{ $1; } >/dev/null; $probe" 2>&1 || true; }
v='$v_database = 1;'
out=$(oe_probe "mkdir -p /var/www/localhost/htdocs/openemr && echo '$v' > /var/www/localhost/htdocs/openemr/version.php")
expect "^/var/www/localhost/htdocs/openemr$" "27c: OpenEMR's image's folder"
out=$(oe_probe "mkdir -p /var/www/html/openemr /srv/www/clinic/emr && echo '$v' > /var/www/html/openemr/version.php && echo '$v' > /srv/www/clinic/emr/version.php")
expect "^/var/www/html/openemr$" "27c: a known web root before a search"
out=$(oe_probe "mkdir -p /var/www/html /srv/www/clinic/emr && echo '<?php \$version = 3;' > /var/www/html/version.php && echo '$v' > /srv/www/clinic/emr/version.php")
expect "^/srv/www/clinic/emr$" "27c: elsewhere, by search, passing over another program's version.php"
out=$(oe_probe "mkdir -p /opt/a/b/c/d/e/emr && echo '$v' > /opt/a/b/c/d/e/emr/version.php")
refute "emr" "27c: but not deeper than five levels"

# MySQL over SSL (t/27148): a second database that only accepts encrypted connections,
# with a test CA, and sites pointing at it with each mistake. The certificates are made
# here and deleted with the database.
CERTS=$(mktemp -d); DS=$P-dbssl
trap 'docker rm -f -v $DS >/dev/null 2>&1; rm -rf "$CERTS"; docker compose -p $P -f test-doctor-compose.yml down -v >/dev/null 2>&1' EXIT
docker run --rm --cpus 1 --memory 256m --memory-swap 256m -u "$(id -u):$(id -g)" -v "$CERTS":/c -w /c --entrypoint sh alpine/openssl -c '
openssl req -x509 -newkey rsa:2048 -nodes -days 7 -subj "/CN=Test CA" -keyout ca-key.pem -out ca.pem &&
openssl req -newkey rsa:2048 -nodes -subj "/CN=dbssl" -keyout server-key.pem -out server.csr &&
printf "subjectAltName=DNS:dbssl\n" > ext.cnf &&
openssl x509 -req -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -days 7 -extfile ext.cnf -out server-cert.pem &&
openssl req -x509 -newkey rsa:2048 -nodes -days 7 -subj "/CN=Other CA" -keyout other-key.pem -out other-ca.pem' 2>/dev/null
# mktemp -d makes the folder 0700; MariaDB runs as its own user and must read the files.
chmod 755 "$CERTS"; chmod 644 "$CERTS"/*.pem
docker run -d --cpus 1 --memory 1g --memory-swap 1g --name $DS --network ${P}_default --network-alias dbssl -e MARIADB_ROOT_PASSWORD=root -v "$CERTS":/certs:ro mariadb:11.8 \
    mariadbd --ssl-ca=/certs/ca.pem --ssl-cert=/certs/server-cert.pem --ssl-key=/certs/server-key.pem --require-secure-transport=ON >/dev/null
for _ in $(seq 1 40); do docker exec $DS mariadb -uroot -proot --ssl -e "SELECT 1" >/dev/null 2>&1 && break; sleep 3; done
docker exec $DS mariadb -uroot -proot --ssl -e "SELECT 1" >/dev/null 2>&1 || { echo "FAIL the SSL database didn't start:"; docker logs $DS 2>&1 | tail -5; exit 1; }
docker exec $DS mariadb -uroot -proot --ssl -e "CREATE USER 'oe'@'%' IDENTIFIED BY 'oe'; CREATE DATABASE oe; GRANT ALL ON oe.* TO 'oe'@'%'"
DSIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $DS)
# A site on the SSL database: its host, then the certificate files to put in its documents/certificates.
ssl_site() {
    local name=$1 host=$2; shift 2
    x "cp -a $S $OE/sites/$name && rm -f $OE/sites/$name/documents/certificates/mysql-* && sed -i -e \"s/^\\\$host.*/\\\$host = '$host';/\" -e \"s/^\\\$login.*/\\\$login = 'oe';/\" -e \"s/^\\\$pass.*/\\\$pass = 'oe';/\" -e \"s/^\\\$dbase.*/\\\$dbase = 'oe';/\" $OE/sites/$name/sqlconf.php"
    while [ $# -gt 1 ]; do docker cp "$1" $C:$OE/sites/$name/documents/certificates/$2; shift 2; done
    x "chown -R apache $OE/sites/$name/documents/certificates"
}
ssl_site sslneed dbssl; out=$(run --site=sslneed)
expect "^FAIL  Database: can't connect with sites/sslneed/sqlconf.php (error 3159)" "28: a database that only accepts SSL, without mysql-ca, names error 3159"
expect "only accepts encrypted connections" "28: and says mysql-ca turns SSL on"
ssl_site sslok dbssl "$CERTS/ca.pem" mysql-ca; out=$(run --site=sslok)
expect "^PASS  Database: connected to dbssl:3306 over SSL (" "29: with the server's CA it connects over SSL, as OpenEMR does"
ssl_site sslip "$DSIP" "$CERTS/ca.pem" mysql-ca; out=$(run --site=sslip)
expect "^FAIL  Database: can't connect with sites/sslip/sqlconf.php over SSL (error 2002" "30: by IP, the certificate's name check fails as error 2002"
expect "names 'dbssl', not '$DSIP'" "30: and the doctor reads the certificate and names the mismatch (Cloud SQL by internal IP)"
ssl_site sslotherca dbssl "$CERTS/other-ca.pem" mysql-ca; out=$(run --site=sslotherca)
expect "issued by 'Test CA', and documents/certificates/mysql-ca ('Other CA') didn't sign it" "31: a CA that didn't sign the server's certificate is named"
ssl_site sslhalf dbssl "$CERTS/ca.pem" mysql-ca "$CERTS/other-ca.pem" mysql-cert; out=$(run --site=sslhalf)
expect "^FAIL  Database SSL: documents/certificates has mysql-cert without mysql-key" "32: a client certificate without its key fails (8.1 and later refuse it)"
echo "not a certificate" > "$CERTS/junk.txt"; ssl_site ssljunk dbssl "$CERTS/junk.txt" mysql-ca; out=$(run --site=ssljunk)
expect "^FAIL  Database SSL: documents/certificates/mysql-ca isn't a PEM certificate" "33: a mysql-ca that isn't PEM fails"
x "rm -rf $OE/sites/sslneed $OE/sites/sslok $OE/sites/sslip $OE/sites/sslotherca $OE/sites/sslhalf $OE/sites/ssljunk"

echo; [ $fails -eq 0 ] && echo "PASSED" || { echo "FAILED: $fails"; exit 1; }
