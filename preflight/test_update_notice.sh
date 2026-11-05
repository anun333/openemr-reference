#!/usr/bin/env bash
# The "newer copy" notice in the doctor and openemr-doctor-docker.sh, and the "newer release"
# notice in openemr-upgrade.sh. The doctor and the wrapper look at the doctor's home (DOCTOR_HOME:
# the newest release's files) for a newer copy of themselves; the upgrade script is pinned to its
# own release and asks GitHub which release is newest. An older copy must get the notice, the
# current one mustn't, the opt-outs must silence it, and a copy that can't look (offline, or with
# its facts from a folder) must say how old it is. Needs the network: without the live latest
# release every case would pass vacuously, so that's a failure. The doctor runs in PHP containers
# against a folder holding only version.php; other homes are folders reached as file://.
set -euo pipefail
cd "$(dirname "$0")"
. ./test_lib.sh
serial
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
printf '<?php\n$v_major = "8";\n$v_minor = "4";\n$v_patch = "1";\n$v_tag = "";\n$v_realpatch = "0";\n$v_database = 530;\n' > "$work/version.php"
fails=0
check() {  # check NAME OUTPUT PATTERN
    if echo "$2" | grep -q -- "$3"; then echo "ok   $1"; else echo "FAIL $1"; echo "$2" | sed 's/^/       | /'; fails=$((fails+1)); fi
}
refute() {  # refute NAME OUTPUT PATTERN
    if echo "$2" | grep -q -- "$3"; then echo "FAIL $1"; echo "$2" | grep -- "$3" | sed 's/^/       | /'; fails=$((fails+1)); else echo "ok   $1"; fi
}

url=$(curl -fsS -m 10 -o /dev/null -w '%{redirect_url}' https://github.com/anun333/openemr-reference/releases/latest || true)
latest=${url##*/releases/tag/v}
if ! [[ "$latest" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo "FAIL couldn't read the latest release from GitHub ($url): the notice can't be tested offline"; exit 1
fi
echo "latest release on GitHub: $latest"
current=$(sed -n "s/^define('DOCTOR_VERSION', '\(.*\)');$/\1/p" openemr-doctor.php)
date=$(sed -n "s/^define('DOCTOR_DATE', '\(.*\)');$/\1/p" openemr-doctor.php)
home=$(sed -n "s/^define('DOCTOR_HOME', '\(.*\)');$/\1/p" openemr-doctor.php)
sed "s/^define('DOCTOR_VERSION', '.*');$/define('DOCTOR_VERSION', '0.0.1');/" openemr-doctor.php > "$work/old-doctor.php"
# Another home, with a newer doctor and wrapper (9.9.9), mounted into the containers at /home9.
mkdir -p "$work/home9"
sed "s/^define('DOCTOR_VERSION', '.*');$/define('DOCTOR_VERSION', '9.9.9');/" openemr-doctor.php > "$work/home9/openemr-doctor.php"
sed 's/^    VERSION=.*/    VERSION=9.9.9/' openemr-doctor-docker.sh > "$work/home9/openemr-doctor-docker.sh"
# Days since the doctor's date, the way the doctor counts them.
age=$(python3 -c 'import datetime, sys; print((datetime.datetime.now(datetime.timezone.utc).date() - datetime.date.fromisoformat(sys.argv[1])).days)' "$date")

# doctor IMAGE FILE [ARGS...]: the doctor's lines about itself and its home.
doctor() {
    local img=$1 file=$2; shift 2
    docker run --rm --cpus 1 --memory 512m --memory-swap 512m -v "$file:/d.php:ro" -v "$work:/oe:ro" -v "$work/home9:/home9:ro" ${ENVS:+-e "$ENVS"} --entrypoint php "$img" /d.php --openemr=/oe "$@" 2>&1 \
        | grep -E "Doctor|the doctor at its home|Deprecated|Warning" || true
}
for img in php:8.5-cli php:5.6-cli; do
    check "$img: an older doctor says $latest is at the home" "$(doctor $img "$work/old-doctor.php")" "^NOTE  Doctor: a newer doctor, $latest, is at $home; this one is 0.0.1 of $date"
    out=$(doctor $img "$PWD/openemr-doctor.php" --debug)
    check "$img: every copy says its version and date" "$out" "^Doctor $current of $date\$"
    check "$img: the current doctor ($current) looks at its home" "$out" "the doctor at its home: $latest"
    refute "$img: and has nothing to say" "$out" "^NOTE  Doctor:"
    refute "$img: no PHP warning or deprecation on the way" "$out" "Deprecated\|Warning"
    out=$(ENVS=OPENEMR_DOCTOR_HOME=file:///home9 doctor $img "$PWD/openemr-doctor.php")
    check "$img: OPENEMR_DOCTOR_HOME names another home, which it looks at" "$out" "^NOTE  Doctor: a newer doctor, 9.9.9, is at file:///home9; this one is $current"
    out=$(ENVS=OPENEMR_DOCTOR_HOME=http://127.0.0.1:9 doctor $img "$PWD/openemr-doctor.php")
    check "$img: a home it can't reach: it says how old it is" "$out" "^NOTE  Doctor: this copy is .*($date), and it couldn't reach http://127.0.0.1:9 to look for a newer one"
    refute "$img: and no PHP warning on the way" "$out" "Deprecated\|Warning"
    out=$(ENVS=OPENEMR_DOCTOR_NO_UPDATE_CHECK=1 doctor $img "$work/old-doctor.php" --debug)
    refute "$img: OPENEMR_DOCTOR_NO_UPDATE_CHECK=1 silences it" "$out" "Doctor:"
    check "$img: and says it didn't ask" "$out" "the doctor at its home: not asked"
    out=$(doctor $img "$work/old-doctor.php" --facts=/nonexistent --debug)
    refute "$img: with local facts (an offline server) it doesn't look" "$out" "newer doctor"
    check "$img: and says how old it is instead" "$out" "^NOTE  Doctor: this copy is .*($date), and with the facts from a folder it doesn't look for a newer one"
done
check "the age is counted in days ($age)" "$(doctor php:8.5-cli "$PWD/openemr-doctor.php" --facts=/nonexistent)" "this copy is $( [ "$age" = 0 ] && echo 'from today' || { [ "$age" = 1 ] && echo '1 day old' || echo "$age days old"; } ) ($date)"

# openemr-upgrade.sh's own copy, sourced from the script.
# shellcheck disable=SC1090
source <(sed -n '/^ *newer_release() {/,/^ *}$/p' openemr-upgrade.sh)
check "openemr-upgrade.sh: 0.0.1 is told about $latest" "$(newer_release 0.0.1)" "^$latest\$"
check "openemr-upgrade.sh: the release itself isn't" "[$(newer_release "$latest")]" "^\[\]\$"
check "openemr-upgrade.sh: compared as numbers: a tool at 999.0 is not told about $latest" "[$(newer_release 999.0)]" "^\[\]\$"
check "openemr-upgrade.sh: OPENEMR_REFERENCE_BASE elsewhere skips it" "[$(OPENEMR_REFERENCE_BASE=file:///x newer_release 0.0.1)]" "^\[\]\$"
check "openemr-upgrade.sh: OPENEMR_REFERENCE_NO_UPDATE_CHECK=1 skips it" "[$(OPENEMR_REFERENCE_NO_UPDATE_CHECK=1 newer_release 0.0.1)]" "^\[\]\$"
unset -f newer_release

# openemr-doctor-docker.sh's own functions, sourced from the script: the home's version, the
# comparison, and the age.
# shellcheck disable=SC1090
source <(sed -n -e '/^    newer() {/,/^    }$/p' -e '/^    home_version() {/,/^    }$/p' -e '/^    days_old() {/,/^    }$/p' openemr-doctor-docker.sh)
DOCTOR_HOME=$(sed -n 's/^    DOCTOR_HOME=${OPENEMR_DOCTOR_HOME:-\(.*\)}$/\1/p' openemr-doctor-docker.sh)
check "openemr-doctor-docker.sh: its home is the doctor's ($home)" "$DOCTOR_HOME=$home" "^\(https://[^=]*\)=\1\$"
check "openemr-doctor-docker.sh: the home's copy is $latest" "[$(home_version)]" "^\[$latest\]\$"
DOCTOR_HOME=file://$work/home9
check "openemr-doctor-docker.sh: another home's copy is 9.9.9" "[$(home_version)]" "^\[9.9.9\]\$"
DOCTOR_HOME=file://$work/nothing-here
check "openemr-doctor-docker.sh: a home it can't read gives nothing (so it says its age)" "[$(home_version)]" "^\[\]\$"
newer 9.9.9 0.5.2; check "openemr-doctor-docker.sh: 9.9.9 is newer than 0.5.2" "$NEWER" "^1\$"
newer 0.5.2 0.5.2; check "openemr-doctor-docker.sh: a copy isn't newer than itself" "$NEWER" "^0\$"
newer 0.10.0 0.9.9; check "openemr-doctor-docker.sh: compared as numbers: 0.10.0 is newer than 0.9.9" "$NEWER" "^1\$"
newer 0.9.9 0.10.0; check "openemr-doctor-docker.sh: and 0.9.9 isn't newer than 0.10.0" "$NEWER" "^0\$"
# shellcheck disable=SC2034 # DATE is read by days_old, sourced above
DATE=$date; check "openemr-doctor-docker.sh: its age is counted in days ($age)" "$(days_old)" "^$age\$"
# shellcheck disable=SC2034
DATE=2024-02-29; check "openemr-doctor-docker.sh: across a leap day" "$(days_old)" "^$(python3 -c 'import datetime; print((datetime.datetime.now(datetime.timezone.utc).date() - datetime.date(2024, 2, 29)).days)')\$"
unset -f newer home_version days_old

echo
if [ "$fails" -eq 0 ]; then echo "all update-notice checks passed"; else echo "$fails failed"; exit 1; fi
