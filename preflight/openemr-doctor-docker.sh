#!/bin/bash
# Run the OpenEMR install doctor against the compose project in this directory.
# With sites/ on a volume (as in OpenEMR's compose files) it runs from a throwaway container
# of the same image, sharing the OpenEMR container's volumes and network, so it works even
# when that container won't stay up. Otherwise it runs inside the running container.
# The idea came from Asher Densmore-Lynn (jesdynf), forum t/27118/8.
#
# Safe to pipe from curl: everything is inside main(), which runs only on the last line, so a
# download cut short stops bash with a syntax error instead of running part of the script.
#   curl -fsSL https://github.com/anun333/openemr-reference/releases/latest/download/openemr-doctor-docker.sh | bash
#
# It says which container it picked and how it runs the doctor, on stderr; the report is on stdout.
# The doctor comes from openemr-doctor.php in this directory if there is one, else from this
# script's own release, checked against that release's SHA256SUMS.
#   --debug (or DEBUG=1): trace every command, and run the doctor with --debug.
#   CONTAINER=name-or-id: the OpenEMR container to check, when the project has more than one.
#   curl ... | bash -s -- --debug
set -euo pipefail

main() {
    VERSION=0.4.0
    BASE=${OPENEMR_REFERENCE_BASE:-https://github.com/anun333/openemr-reference/releases/download/v$VERSION}
    OE=/var/www/localhost/htdocs/openemr
    DEBUG=${DEBUG:-0}
    for arg in "$@"; do
        case "$arg" in
            --debug) DEBUG=1 ;;
            *) echo "openemr-doctor-docker.sh: unknown option $arg (only --debug)" >&2; exit 2 ;;
        esac
    done
    if [ "$DEBUG" = 1 ]; then PS4='+ openemr-doctor-docker.sh:${LINENO}: '; set -x; fi
    say() { echo "openemr-doctor-docker.sh $VERSION: $*" >&2; }
    # Compose v2 (docker compose), or v1 (docker-compose) on older hosts.
    compose() { if docker compose version >/dev/null 2>&1; then docker compose "$@"; else docker-compose "$@"; fi; }
    # The newest openemr-reference release when it's newer than $1, else nothing: this script is
    # pinned to its own release, so it says so and never updates itself. Silent when offline, and
    # skipped when OPENEMR_REFERENCE_BASE points elsewhere.
    newer_release() {
        [[ -z "${OPENEMR_REFERENCE_BASE:-}" && -z "${OPENEMR_REFERENCE_NO_UPDATE_CHECK:-}" ]] || return 0
        local url latest a b i
        url="$(curl -fsS -m 5 -o /dev/null -w '%{redirect_url}' https://github.com/anun333/openemr-reference/releases/latest 2>/dev/null)" || return 0
        latest="${url##*/releases/tag/v}"
        [[ "$latest" =~ ^[0-9]+(\.[0-9]+)*$ ]] || return 0
        IFS=. read -r -a a <<<"$latest"; IFS=. read -r -a b <<<"$1"
        for ((i = 0; i < ${#a[@]} || i < ${#b[@]}; i++)); do
            (( 10#${a[i]:-0} > 10#${b[i]:-0} )) && { echo "$latest"; return 0; }
            (( 10#${a[i]:-0} < 10#${b[i]:-0} )) && return 0
        done
        return 0
    }
    LATEST=$(newer_release "$VERSION")
    [ -z "$LATEST" ] || say "openemr-reference $LATEST is out; this script is $VERSION. The new one: https://github.com/anun333/openemr-reference/releases/latest"

    if [ -n "${CONTAINER:-}" ]; then
        CONTAINER=$(docker inspect --format '{{.Id}}' "$CONTAINER") || { say "no container $CONTAINER"; exit 1; }
        say "using the container you named"
    else
        # The OpenEMR containers, found by the image each was started from: the tag stays in its
        # config even after the tag has been pulled again (docker compose ps then shows sha256:...).
        FOUND=$(compose ps -aq | xargs -r docker inspect --format '{{.Id}} {{.Config.Image}} {{.Name}}' | awk '$2 ~ /openemr\/openemr/')
        [ -n "$FOUND" ] || { say "no openemr/openemr container in this compose project (for an image of your own, set CONTAINER=name)"; exit 1; }
        CONTAINER=$(echo "$FOUND" | awk 'NR == 1 {print $1}')
        if [ "$(echo "$FOUND" | wc -l)" -gt 1 ]; then
            say "this project has $(echo "$FOUND" | wc -l) OpenEMR containers: $(echo "$FOUND" | awk '{printf "%s%s", sep, substr($3, 2); sep = ", "}'); checking the first. Set CONTAINER=name to check another."
        fi
    fi
    say "container $(docker inspect --format '{{.Name}}' "$CONTAINER" | cut -c2-), image $(docker inspect --format '{{.Config.Image}}' "$CONTAINER"), $(docker inspect --format '{{.State.Status}}' "$CONTAINER")"

    WORK=$(mktemp -d)
    trap 'rm -rf "$WORK"' EXIT
    if [ -n "${DOCTOR:-}" ] || [ -f openemr-doctor.php ]; then
        DOCTOR=${DOCTOR:-openemr-doctor.php}
        [ -f "$DOCTOR" ] || { say "DOCTOR=$DOCTOR: no such file"; exit 1; }
        DOCTOR=$(cd "$(dirname "$DOCTOR")" && pwd)/$(basename "$DOCTOR")
        say "doctor: $DOCTOR, a copy of your own (not checked against SHA256SUMS)"
    else
        curl -fsSL -o "$WORK/openemr-doctor.php" "$BASE/openemr-doctor.php" || { say "couldn't download openemr-doctor.php from $BASE"; exit 1; }
        curl -fsSL -o "$WORK/SHA256SUMS" "$BASE/SHA256SUMS" || { say "couldn't download SHA256SUMS from $BASE"; exit 1; }
        WANT=$(awk '$2 == "openemr-doctor.php" || $2 == "*openemr-doctor.php" {print $1}' "$WORK/SHA256SUMS")
        if command -v sha256sum >/dev/null; then GOT=$(sha256sum "$WORK/openemr-doctor.php" | cut -d' ' -f1); else GOT=$(shasum -a 256 "$WORK/openemr-doctor.php" | cut -d' ' -f1); fi
        if [ -z "$WANT" ] || [ "$WANT" != "$GOT" ]; then
            say "the downloaded openemr-doctor.php doesn't match SHA256SUMS of release v$VERSION (expected ${WANT:-no entry}, got $GOT); not running it"
            exit 1
        fi
        chmod 644 "$WORK/openemr-doctor.php"
        DOCTOR=$WORK/openemr-doctor.php
        say "doctor: downloaded from release v$VERSION, matches its SHA256SUMS"
    fi
    # scan.php, which the doctor reads edited files with, beside the doctor: the copy beside a
    # doctor of your own, else this release's, checked the same way. Without it the doctor says so.
    SCAN=""
    if [ -f "$(dirname "$DOCTOR")/scan.php" ]; then
        SCAN=$(dirname "$DOCTOR")/scan.php
        [ "$DOCTOR" = "$WORK/openemr-doctor.php" ] || say "scan.php: $SCAN, beside your doctor (not checked against SHA256SUMS)"
    elif [ "$DOCTOR" = "$WORK/openemr-doctor.php" ] && curl -fsSL -o "$WORK/scan.php" "$BASE/scan.php"; then
        WANT=$(awk '$2 == "scan.php" || $2 == "*scan.php" {print $1}' "$WORK/SHA256SUMS")
        if command -v sha256sum >/dev/null; then GOT=$(sha256sum "$WORK/scan.php" | cut -d' ' -f1); else GOT=$(shasum -a 256 "$WORK/scan.php" | cut -d' ' -f1); fi
        if [ -n "$WANT" ] && [ "$WANT" = "$GOT" ]; then
            chmod 644 "$WORK/scan.php"; SCAN=$WORK/scan.php
            say "scan.php: downloaded from release v$VERSION, matches its SHA256SUMS"
        else
            rm -f "$WORK/scan.php"
            say "the downloaded scan.php doesn't match SHA256SUMS of release v$VERSION (expected ${WANT:-no entry}, got $GOT); the doctor runs without it"
        fi
    fi
    ARGS=(--openemr="$OE")
    [ "$DEBUG" != 1 ] || ARGS+=(--debug)

    MOUNTS=" $(docker inspect --format '{{range .Mounts}}{{.Destination}} {{end}}' "$CONTAINER")"
    if [[ $MOUNTS == *" $OE/sites "* ]]; then
        IMAGE=$(docker inspect --format '{{.Image}}' "$CONTAINER")   # the exact image it runs, so the PHP is the same
        NETWORKS=$(docker inspect --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' "$CONTAINER")
        NETWORK=$(echo "$NETWORKS" | awk '{print $1}')
        [ "$(echo "$NETWORKS" | wc -w)" -le 1 ] || say "the container is on several networks ($NETWORKS); using $NETWORK"
        say "sites/ is on a volume: running the doctor in a throwaway container of the same image, with its volumes, on network $NETWORK"
        SCAN_MOUNT=()
        [ -z "$SCAN" ] || SCAN_MOUNT=(-v "$SCAN:/tools/scan.php:ro")
        docker run --rm --volumes-from "$CONTAINER" --network "$NETWORK" --user apache --entrypoint php \
          -v "$DOCTOR:/tools/openemr-doctor.php:ro" ${SCAN_MOUNT[@]+"${SCAN_MOUNT[@]}"} "$IMAGE" /tools/openemr-doctor.php "${ARGS[@]}"
    elif [ "$(docker inspect --format '{{.State.Running}}' "$CONTAINER")" = true ]; then
        # sites/ lives inside the container, so a throwaway container would see the image's empty one.
        say "sites/ is inside the container: running the doctor in it"
        docker cp "$DOCTOR" "$CONTAINER:/tmp/openemr-doctor.php" >/dev/null
        [ -z "$SCAN" ] || docker cp "$SCAN" "$CONTAINER:/tmp/scan.php" >/dev/null
        docker exec -u apache "$CONTAINER" php /tmp/openemr-doctor.php "${ARGS[@]}" || true
        docker exec "$CONTAINER" rm -f /tmp/openemr-doctor.php /tmp/scan.php
    else
        say "sites/ isn't on a volume and the container isn't running; start it (docker compose up -d), then run this again"
        exit 1
    fi
}

main "$@"
