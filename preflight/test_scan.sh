#!/usr/bin/env bash
# scan.php beside the tools and site/preflight/php-changes.json are php-upgrade-catalogue's pinned
# release byte for byte (gen/catalogue.json; gen/check.py fails otherwise). This runs that release's
# own tests on these exact copies: every rule and finding measured with real PHP 5.4 to 8.5 in
# Docker, guarded uses left out, exit codes and the JSON the tools read. The catalogue's runner exits
# 1 if a check fails and 2 if it can't run (no Docker, an image missing), so this can't pass by
# accident: anything but 0 is a failure here.
# Needs Docker, git and the network (it clones the catalogue at the pinned tag).
set -euo pipefail
cd "$(dirname "$0")"
. ./test_lib.sh
serial
version=$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["version"])' ../gen/catalogue.json)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
git -c advice.detachedHead=false clone -q --depth 1 --branch "v$version" https://github.com/anun333/php-upgrade-catalogue "$work/catalogue"
fails=0
set +e
SCAN="$PWD/scan.php" FACTS="$PWD/../site/preflight/php-changes.json" "$work/catalogue/tests/run.sh" > "$work/out" 2>&1
rc=$?
set -e
sed 's/^/  | /' "$work/out" | tail -15
summary=$(grep -E '^[0-9]+ passed, [0-9]+ failed$' "$work/out" | tail -1)
if [ "$rc" -eq 0 ] && [ -n "$summary" ] && [ "${summary##*, }" = "0 failed" ]; then
    echo "ok   php-upgrade-catalogue $version's own tests pass on the copies these tools ship: $summary"
else
    grep '^FAIL' "$work/out" | head -10 | sed 's/^FAIL: /FAIL /'
    echo "FAIL php-upgrade-catalogue $version's tests on these copies: exit $rc (2: they couldn't run), ${summary:-no summary}"
    fails=1
fi
# The tools' own copies are the ones tested: the same bytes as the pinned release.
for f in scan.php ../site/preflight/php-changes.json; do
    want=$(python3 -c 'import json, sys; p = json.load(open(sys.argv[1])); print(next(v["sha256"] for v in p["files"].values() if v["to"].endswith(sys.argv[2])))' ../gen/catalogue.json "$(basename "$f")")
    got=$(sha256sum "$f" | cut -d' ' -f1)
    if [ "$want" = "$got" ]; then echo "ok   $(basename "$f") is the pinned release's"; else echo "FAIL $(basename "$f") isn't the pinned release's ($got, pinned $want)"; fails=1; fi
done
echo; [ $fails -eq 0 ] && echo "PASSED" || { echo "FAILED"; exit 1; }
