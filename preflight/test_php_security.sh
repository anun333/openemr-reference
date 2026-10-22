#!/usr/bin/env bash
# The doctor's PHP security check (php2shell, PHP's advisory of 2026-10-21) under each kind of
# PHP it meets: Alpine's php85 package in OpenEMR's own image, before and after the in-place
# update; PHP built from source (the official php images); a Debian build, whose number stays
# low after a fixed update; and branches PHP no longer fixes (8.1, 5.6). The doctor runs against
# a folder holding only version.php, so no OpenEMR install is needed. Each expectation follows
# the PHP the container actually runs, so a rebuilt image turns a FAIL case into a PASS case
# instead of breaking the test. Everything runs in containers deleted at the end.
set -euo pipefail
cd "$(dirname "$0")"
. ./test_lib.sh
serial
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
printf '<?php\n$v_major = "8";\n$v_minor = "4";\n$v_patch = "1";\n$v_tag = "";\n$v_realpatch = "0";\n$v_database = 530;\n' > "$work/version.php"
fails=0

# doctor IMAGE [SHELL_PREFIX]: the doctor's PHP security lines, run with the image's PHP.
doctor() {
    docker run --rm --cpus 1 -v "$PWD/openemr-doctor.php:/d.php:ro" -v "$work:/oe:ro" --entrypoint sh "$1" \
        -c "${2:-true} && php /d.php --openemr=/oe --facts=/nonexistent" 2>&1 | grep -A1 "PHP security" || true
}
php_of() {
    docker run --rm --entrypoint sh "$1" -c "${2:-true} >/dev/null 2>&1; php -r 'echo PHP_VERSION;'"
}
check() {  # check NAME OUTPUT PATTERN
    if echo "$2" | grep -q -- "$3"; then echo "ok   $1"; else echo "FAIL $1"; echo "$2" | sed 's/^/       | /'; fails=$((fails+1)); fi
}
older() {  # older VERSION FIXED: true if VERSION < FIXED
    [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ]
}

# 1. OpenEMR's image as published: Alpine's php85 package.
img=openemr/openemr:flex
v=$(php_of $img)
out=$(doctor $img)
if older "$v" 8.5.12; then
    check "1: OpenEMR's image, PHP $v, fails with the in-place update" "$out" "^FAIL  PHP security: $v is older than 8.5.12"
    check "1: the fix names Alpine's package and says not to recreate" "$out" "apk upgrade .*grep '^php85'.*recreating it brings the old PHP back"
else
    check "1: OpenEMR's image, PHP $v (already rebuilt), passes" "$out" "^PASS  PHP security: $v has PHP's fix"
fi

# 2. The same image after the advisory's update.
upd="apk update >/dev/null 2>&1 && apk upgrade \$(apk info -q | grep '^php85') >/dev/null 2>&1"
if v2=$(php_of $img "$upd") && ! older "$v2" 8.5.12; then
    check "2: after the in-place update ($v2), it passes" "$(doctor $img "$upd")" "^PASS  PHP security: $v2 has PHP's fix for php2shell"
else
    echo "SKIP 2: the update didn't reach 8.5.12 here (no network, or Alpine hasn't published it)"
fi

# 3. PHP built from source (the official image): its number is PHP's own.
img=php:8.5-cli
v=$(php_of $img)
out=$(doctor $img)
if older "$v" 8.5.12; then
    check "3: a source build, PHP $v, fails and says to update PHP" "$out" "^FAIL  PHP security: $v is older than 8.5.12"
    check "3: its fix is updating PHP, not apk" "$out" "Update PHP to 8.5.12 or later"
else
    check "3: a source build, PHP $v, passes" "$out" "^PASS  PHP security: $v has PHP's fix"
fi

# 4. A distribution's own PHP. Ubuntu 24.04 keeps 8.3.6 and backports fixes into it, so a low
# number only warns (this case must take the warning branch). Debian follows PHP's numbers.
img=ubuntu:24.04
inst="apt-get update -qq >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq php8.3-cli >/dev/null 2>&1"
v=$(php_of $img "$inst")
out=$(doctor $img "$inst")
check "4: Ubuntu's PHP $v warns, naming its package" "$out" "^WARN  PHP security: $v (package php8.3-common $v-[0-9]*ubuntu.*) is numbered below 8.3.36"
check "4: the advice is the distribution's notice" "$out" "Check your distribution's security notice"
img=debian:bookworm-slim
inst="apt-get update -qq >/dev/null && apt-get install -y -qq php8.2-cli >/dev/null 2>&1"
v=$(php_of $img "$inst")
out=$(doctor $img "$inst")
if older "$v" 8.2.35; then
    check "4: Debian's PHP $v warns" "$out" "^WARN  PHP security: $v (package php8.2-common .*) is numbered below 8.2.35"
else
    check "4: Debian's PHP $v passes" "$out" "^PASS  PHP security: $v has PHP's fix"
fi

# 5. Branches PHP no longer fixes: a warning, without claiming they are affected.
check "5: PHP 8.1 gets no fixes from PHP" "$(doctor php:8.1-cli)" "^WARN  PHP security: PHP 8.1 gets no security fixes from PHP"
check "5: PHP 5.6 runs the check too" "$(doctor php:5.6-cli)" "^WARN  PHP security: PHP 5.6 gets no security fixes from PHP"

echo
if [ "$fails" -eq 0 ]; then echo "all PHP security checks passed"; else echo "$fails failed"; exit 1; fi
