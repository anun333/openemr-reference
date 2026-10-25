#!/usr/bin/env bash
# Release openemr-reference. Every check and every end-to-end suite runs first, one at a time;
# nothing is tagged or published unless all of them pass. Then the tag, the GitHub release with
# the tools and their SHA256SUMS, and a check of what was published: each file downloaded
# again and compared with SHA256SUMS, and /releases/latest pointing at the new release.
#
#   ./release.sh 0.3.10 --title="v0.3.10: ..." --notes=FILE    # release
#   ./release.sh 0.3.10 --dry-run                              # everything but the tag and release
#
# The version must already be set in the three tools and committed (gen/check.py checks they
# agree); the tree must be clean and on main. Logs go to a folder it names. Written after
# v0.3.8 went out with the doctor's suites run but not the upgrade suite, which runs the doctor.
#
# RELEASE_SUITES="test_a.sh test_b.sh" runs only those suites, and only with --dry-run: a release
# always runs every suite.
set -euo pipefail
cd "$(dirname "$0")"
REPO=anun333/openemr-reference
ASSETS=(openemr-doctor-docker.sh openemr-doctor.php openemr-preflight.php openemr-rehearse.sh openemr-upgrade.sh openemr-utf8mb4.sql scan.php)
# Quick ones first; each suite takes the shared lock in test_lib.sh, so they never overlap.
SUITES=(test_scan.sh test_update_notice.sh test_php_security.sh test_preflight.sh test_doctor.sh test_doctor_patch.sh test_upgrade.sh)

VERSION="" TITLE="" NOTES="" DRY=0
for arg in "$@"; do
    case "$arg" in
        --title=*) TITLE="${arg#*=}" ;;
        --notes=*) NOTES="${arg#*=}" ;;
        --dry-run) DRY=1 ;;
        -h|--help) awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"; exit 0 ;;
        [0-9]*) VERSION="$arg" ;;
        *) echo "unknown option: $arg (see --help)" >&2; exit 2 ;;
    esac
done
die() { echo "STOP: $*" >&2; exit 1; }
say() { printf '%s\n' "$*"; }
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "give the version, like ./release.sh 0.3.10"
TAG="v$VERSION"
(( DRY )) || { [[ -n "$TITLE" ]] || die "--title is needed"; [[ -f "$NOTES" ]] || die "--notes=FILE is needed (the release notes)"; }
if [[ -n "${RELEASE_SUITES:-}" ]]; then
    (( DRY )) || die "RELEASE_SUITES is only for --dry-run: a release runs every suite"
    read -r -a SUITES <<<"$RELEASE_SUITES"
fi
LOGS="$(mktemp -d "${TMPDIR:-/tmp}/openemr-reference-release-$VERSION.XXXX")"
say "release $TAG$( (( DRY )) && echo ' (dry run)'); logs in $LOGS"

say "== 1. The tree"
[[ "$(git rev-parse --abbrev-ref HEAD)" == main ]] || die "not on main"
if (( ! DRY )) || [[ -z "${RELEASE_SUITES:-}" ]]; then
    [[ -z "$(git status --porcelain)" ]] || die "the tree has changes that aren't committed: a release is built from a commit"
fi
git fetch -q origin
git merge-base --is-ancestor origin/main HEAD || die "origin/main has commits this branch doesn't: pull first"
! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || die "the tag $TAG already exists here"
[[ -z "$(git ls-remote --tags origin "refs/tags/$TAG")" ]] || die "the tag $TAG already exists on GitHub"
! gh release view "$TAG" -R "$REPO" >/dev/null 2>&1 || die "the release $TAG already exists"
say "  main at $(git rev-parse --short HEAD), clean, not behind origin; $TAG is free"

say "== 2. Versions"
for f in "openemr-upgrade.sh:^SCRIPT_VERSION=" "openemr-doctor-docker.sh:^    VERSION=" "openemr-doctor.php:^define('DOCTOR_VERSION', '"; do
    file="preflight/${f%%:*}" pattern="${f#*:}"
    grep -q "${pattern}${VERSION}\(');\)\{0,1\}\$" "$file" || die "$file doesn't say $VERSION ($(grep -m1 "$pattern" "$file"))"
done
say "  the three tools say $VERSION"
# Every suite in preflight/ is in the list, so a new one can't be skipped by forgetting it here.
for t in preflight/test_*.sh; do
    n="$(basename "$t")"; [[ "$n" == test_lib.sh ]] && continue
    [[ " ${SUITES[*]} " == *" $n "* || -n "${RELEASE_SUITES:-}" ]] || die "$n isn't in release.sh's SUITES: add it"
done

say "== 3. Fast checks (as CI runs them)"
shellcheck -S warning preflight/*.sh release.sh || die "ShellCheck"
for v in 5.5 5.6 7.0 7.4 8.1 8.3 8.5; do
    docker run --rm -v "$PWD:/app" -w /app "php:$v-cli" php -l preflight/openemr-doctor.php >/dev/null || die "the doctor doesn't parse on PHP $v"
    docker run --rm -v "$PWD:/app" -w /app "php:$v-cli" php -l preflight/scan.php >/dev/null || die "scan.php doesn't parse on PHP $v"
    [[ "$v" == 5.* || "$v" == 7.0 ]] || docker run --rm -v "$PWD:/app" -w /app "php:$v-cli" php -l preflight/openemr-preflight.php >/dev/null || die "the pre-flight check doesn't parse on PHP $v"
done
python3 gen/check.py > "$LOGS/check.log" 2>&1 || { tail -20 "$LOGS/check.log"; die "gen/check.py (log: $LOGS/check.log)"; }
say "  ShellCheck, PHP 5.5 to 8.5 (the doctor, scan.php, the pre-flight check from 7.4), gen/check.py (with the pinned php-upgrade-catalogue): pass"

say "== 4. End-to-end suites, one at a time"
for s in "${SUITES[@]}"; do
    [[ -x "preflight/$s" ]] || die "no suite preflight/$s"
    started=$SECONDS
    if ./"preflight/$s" > "$LOGS/$s.log" 2>&1; then
        say "  $s: $(grep -c '^ok ' "$LOGS/$s.log") checks pass ($(( (SECONDS - started) / 60 ))m$(( (SECONDS - started) % 60 ))s)"
    else
        grep -E '^FAIL ' "$LOGS/$s.log" | head -10 | sed 's/^/    /'
        die "$s failed (log: $LOGS/$s.log): nothing tagged or published"
    fi
done

say "== 5. The files"
OUT="$LOGS/assets"; mkdir -p "$OUT"
for a in "${ASSETS[@]}"; do cp "preflight/$a" "$OUT/"; done
(cd "$OUT" && sha256sum "${ASSETS[@]}" > SHA256SUMS)
sed 's/^/  /' "$OUT/SHA256SUMS"
if (( DRY )); then
    say "dry run: everything passed; nothing tagged or published. The files are in $OUT"
    exit 0
fi

say "== 6. Tag, push and publish"
git tag "$TAG"
git push -q origin main "$TAG"
gh release create "$TAG" -R "$REPO" --title "$TITLE" --notes-file "$NOTES" "${ASSETS[@]/#/$OUT/}" "$OUT/SHA256SUMS" >/dev/null
say "  $TAG pushed and published"

say "== 7. What was published"
DL="$LOGS/published"; mkdir -p "$DL"
for f in SHA256SUMS "${ASSETS[@]}"; do
    curl -fsSL -o "$DL/$f" "https://github.com/$REPO/releases/download/$TAG/$f" || die "couldn't download $f from the release"
done
(cd "$DL" && sha256sum -c --quiet SHA256SUMS) || die "a published file doesn't match SHA256SUMS"
cmp -s "$DL/SHA256SUMS" "$OUT/SHA256SUMS" || die "the published SHA256SUMS isn't the one built here"
# GitHub caches the /releases/latest redirect: v0.3.10's still pointed at v0.3.9 for about half a
# minute after publishing. Wait up to five minutes before calling it wrong.
for _ in $(seq 20); do
    latest="$(curl -fsS -o /dev/null -w '%{redirect_url}' "https://github.com/$REPO/releases/latest")"
    [[ "$latest" == */releases/tag/$TAG ]] && break
    sleep 15
done
[[ "$latest" == */releases/tag/$TAG ]] || die "/releases/latest still points at $latest, not $TAG, after five minutes"
say "  every file downloads and matches SHA256SUMS; /releases/latest is $TAG"
say "done: https://github.com/$REPO/releases/tag/$TAG"
