#!/usr/bin/env bash
# The "newer release" notice in the doctor, openemr-upgrade.sh and openemr-doctor-docker.sh. Each
# tool is pinned to its own release, so it only says when a newer one is out: an older version
# must get the notice, the current one mustn't, and the opt-outs must silence it. Needs the
# network: without the live latest release every case would pass vacuously, so that's a failure.
# The doctor runs in PHP containers against a folder holding only version.php.
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
sed "s/^define('DOCTOR_VERSION', '.*');$/define('DOCTOR_VERSION', '0.0.1');/" openemr-doctor.php > "$work/old-doctor.php"

# doctor IMAGE FILE [ARGS...]: the doctor's NOTE and DEBUG lines about releases.
doctor() {
    local img=$1 file=$2; shift 2
    docker run --rm --cpus 1 -v "$file:/d.php:ro" -v "$work:/oe:ro" ${ENVS:+-e "$ENVS"} --entrypoint php "$img" /d.php --openemr=/oe "$@" 2>&1 \
        | grep -E "Doctor:|openemr-reference release|Deprecated|Warning" || true
}
for img in php:8.5-cli php:5.6-cli; do
    check "$img: an older doctor says $latest is out" "$(doctor $img "$work/old-doctor.php")" "^NOTE  Doctor: openemr-reference $latest is out; this doctor is 0.0.1"
    out=$(doctor $img "$PWD/openemr-doctor.php" --debug)
    check "$img: the current doctor ($current) looks" "$out" "newest openemr-reference release: $latest"
    refute "$img: and has nothing to say" "$out" "^NOTE  Doctor:"
    refute "$img: no PHP warning or deprecation on the way" "$out" "Deprecated\|Warning"
    out=$(ENVS=OPENEMR_REFERENCE_NO_UPDATE_CHECK=1 doctor $img "$work/old-doctor.php" --debug)
    refute "$img: OPENEMR_REFERENCE_NO_UPDATE_CHECK=1 silences it" "$out" "Doctor:\|openemr-reference release"
    out=$(doctor $img "$work/old-doctor.php" --facts=/nonexistent --debug)
    refute "$img: with local facts (an offline server) it doesn't look" "$out" "Doctor:\|openemr-reference release"
done

# The scripts' own copy, sourced from each script.
for script in openemr-upgrade.sh openemr-doctor-docker.sh; do
    # shellcheck disable=SC1090
    source <(sed -n '/^ *newer_release() {/,/^ *}$/p' "$script")
    check "$script: 0.0.1 is told about $latest" "$(newer_release 0.0.1)" "^$latest\$"
    check "$script: the release itself isn't" "[$(newer_release "$latest")]" "^\[\]\$"
    check "$script: compared as numbers: a tool at 999.0 is not told about $latest" "[$(newer_release 999.0)]" "^\[\]\$"
    check "$script: OPENEMR_REFERENCE_BASE elsewhere skips it" "[$(OPENEMR_REFERENCE_BASE=file:///x newer_release 0.0.1)]" "^\[\]\$"
    check "$script: OPENEMR_REFERENCE_NO_UPDATE_CHECK=1 skips it" "[$(OPENEMR_REFERENCE_NO_UPDATE_CHECK=1 newer_release 0.0.1)]" "^\[\]\$"
    unset -f newer_release
done

echo
if [ "$fails" -eq 0 ]; then echo "all update-notice checks passed"; else echo "$fails failed"; exit 1; fi
