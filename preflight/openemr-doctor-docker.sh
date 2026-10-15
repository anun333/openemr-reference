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
set -euo pipefail

main() {
    OE=/var/www/localhost/htdocs/openemr
    # Compose v2 (docker compose), or v1 (docker-compose) on older hosts.
    compose() { if docker compose version >/dev/null 2>&1; then docker compose "$@"; else docker-compose "$@"; fi; }
    # The OpenEMR container, found by the image it was started from: the tag stays in its
    # config even after the tag has been pulled again (docker compose ps then shows sha256:...).
    CONTAINER=$(compose ps -aq | xargs docker inspect --format '{{.Id}} {{.Config.Image}}' | awk '$2 ~ /openemr\/openemr/ {print $1; exit}')
    [ -n "$CONTAINER" ] || { echo "openemr-doctor-docker.sh: no openemr/openemr container in this compose project" >&2; exit 1; }
    DOCTOR=${DOCTOR:-openemr-doctor.php}
    [ -f "$DOCTOR" ] || curl -fsSL -o "$DOCTOR" https://github.com/anun333/openemr-reference/releases/latest/download/openemr-doctor.php
    DOCTOR=$(cd "$(dirname "$DOCTOR")" && pwd)/$(basename "$DOCTOR")
    MOUNTS=" $(docker inspect --format '{{range .Mounts}}{{.Destination}} {{end}}' "$CONTAINER")"
    if [[ $MOUNTS == *" $OE/sites "* ]]; then
        IMAGE=$(docker inspect --format '{{.Image}}' "$CONTAINER")   # the exact image it runs, so the PHP is the same
        NETWORK=$(docker inspect --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' "$CONTAINER" | awk '{print $1}')
        docker run --rm --volumes-from "$CONTAINER" --network "$NETWORK" --user apache --entrypoint php \
          -v "$DOCTOR:/tools/openemr-doctor.php:ro" "$IMAGE" /tools/openemr-doctor.php --openemr="$OE"
    elif [ "$(docker inspect --format '{{.State.Running}}' "$CONTAINER")" = true ]; then
        # sites/ lives inside the container, so a throwaway container would see the image's empty one.
        docker cp "$DOCTOR" "$CONTAINER:/tmp/openemr-doctor.php" >/dev/null
        docker exec -u apache "$CONTAINER" php /tmp/openemr-doctor.php --openemr="$OE" || true
        docker exec "$CONTAINER" rm -f /tmp/openemr-doctor.php
    else
        echo "openemr-doctor-docker.sh: sites/ isn't on a volume and the container isn't running; start it (docker compose up -d), then run this again" >&2
        exit 1
    fi
}

main "$@"
