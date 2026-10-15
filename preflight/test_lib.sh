# shellcheck shell=bash
# Shared by the end-to-end tests (sourced, not run).

# One suite at a time on this machine: several OpenEMR containers starting at once is what made a
# pristine image look like it was missing files (the container was still settling them).
serial() {
    exec 8>"${TMPDIR:-/tmp}/openemr-reference-tests.lock"
    if ! flock -n 8; then
        echo "another test suite is running; waiting for it to finish..."
        flock 8
    fi
}

# A container is ready when OpenEMR says "Setup Complete", its login page answers, and its files
# have stopped changing. The log line alone comes too early under load.
#   wait_ready CONTAINER OPENEMR_DIR
wait_ready() {
    local c="$1" oe="$2" a b
    until docker logs "$c" 2>&1 | grep -q "Setup Complete"; do sleep 6; done
    until [ "$(docker exec "$c" curl -s -o /dev/null -w '%{http_code}' http://localhost/interface/login/login.php?site=default)" = 200 ]; do sleep 3; done
    a=$(docker exec "$c" sh -c "find $oe -xdev | wc -l")
    while sleep 5; b=$(docker exec "$c" sh -c "find $oe -xdev | wc -l"); [ "$a" != "$b" ]; do a=$b; done
    echo "ready: $c answers, with $b files in $oe, unchanged for 5 seconds"
}
