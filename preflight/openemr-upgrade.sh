#!/usr/bin/env bash
# Upgrade an OpenEMR installed from the release tarball (not the Docker image), with a way back.
#
#   openemr-upgrade.sh --openemr=/var/www/html/openemr --to=8.4.1 [--tarball=FILE] [--backup-dir=DIR]
#                      [--service=apache2] [--force] [--yes]
#   openemr-upgrade.sh --rollback --openemr=/var/www/html/openemr
#
# It does what the manual upgrade does, in order, and stops at the first thing that goes wrong:
#   1. checks the server with openemr-preflight.php (stops on a FAIL unless --force);
#   2. stops the web server (--service), or asks you to keep users out;
#   3. backs up each site's database (mysqldump) and the whole sites/ folder: documents, keys;
#   4. unpacks the target release (downloaded from GitHub and its sha256 checked, or --tarball)
#      beside the old folder, and carries over sites/ and any modules the release doesn't have;
#   5. runs the target's own sql_upgrade.php --from=<current> for each site, as the web server's user;
#   6. checks the new folder with openemr-doctor.php (stops on a FAIL unless --force);
#   7. swaps the folders (the old one is kept as <folder>.old-<version>) and starts the web server.
# Nothing is deleted. --rollback restores the databases from the backup and swaps the folders back.
#
# Run it as root on the server, after rehearsing the upgrade on a copy (openemr-rehearse.sh).
# The target must be 8.2.0 or later (sql_upgrade.php runs from the command line from 8.2.0).
set -euo pipefail

OE="" TO="" TARBALL="" BACKUP="" SERVICE="" FORCE=0 YES=0 ROLLBACK=0
for arg in "$@"; do
    case "$arg" in
        --openemr=*) OE="${arg#*=}" ;;
        --to=*) TO="${arg#*=}" ;;
        --tarball=*) TARBALL="${arg#*=}" ;;
        --backup-dir=*) BACKUP="${arg#*=}" ;;
        --service=*) SERVICE="${arg#*=}" ;;
        --force) FORCE=1 ;;
        --yes) YES=1 ;;
        --rollback) ROLLBACK=1 ;;
        -h|--help) sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $arg (see --help)" >&2; exit 2 ;;
    esac
done
die() { echo "STOP: $*" >&2; exit 1; }
say() { printf '%s\n' "$*"; }
step() { printf '\n== %s\n' "$*"; }
OE="${OE%/}"
[[ -n "$OE" && -f "$OE/version.php" && -d "$OE/sites" ]] || die "--openemr=DIR: an OpenEMR folder (with version.php and sites/), not '$OE'"
[[ ! -f /.dockerenv && ! -f "$OE/openemr.sh" ]] || say "Note: this looks like a Docker container. For the official image, upgrading means changing the image tag; this script is for installs from the release tarball."
HERE="$(cd "$(dirname "$0")" && pwd)"
PARENT="$(dirname "$OE")"
NAME="$(basename "$OE")"
STATE="$PARENT/.$NAME-upgrade-state"
WEBUSER="$(stat -c %U "$OE/sites")"

as_web() {
    if command -v runuser >/dev/null; then runuser -u "$WEBUSER" -- "$@"
    elif command -v su-exec >/dev/null; then su-exec "$WEBUSER" "$@"
    else su -s /bin/sh "$WEBUSER" -c "$(printf '%q ' "$@")"; fi
}
version_of() { php -r 'include $argv[1] . "/version.php"; echo "$v_major.$v_minor.$v_patch";' "$1"; }
# Each site's database settings, read by PHP from its own sqlconf.php: host port login pass dbase.
sqlconf() {
    php -r '$sqlconf = []; include $argv[1]; $c = $sqlconf ?: ["host" => $host ?? "", "port" => $port ?? "", "login" => $login ?? "", "pass" => $pass ?? "", "dbase" => $dbase ?? ""];
        echo implode("\n", [$c["host"], $c["port"] ?: "3306", $c["login"], $c["pass"], $c["dbase"]]);' "$1"
}
client() { command -v mariadb >/dev/null && echo mariadb || echo mysql; }
dumper() { command -v mariadb-dump >/dev/null && echo mariadb-dump || echo mysqldump; }
sites() { for d in "$OE"/sites/*/; do [[ -f "$d/sqlconf.php" ]] && basename "$d"; done; }
service_do() {
    [[ -n "$SERVICE" ]] || return 0
    if command -v systemctl >/dev/null; then systemctl "$1" "$SERVICE"; else service "$SERVICE" "$1"; fi
}
mycnf() {  # a client option file, so the password isn't on a command line
    local f; f="$(mktemp)"; chmod 600 "$f"
    printf '[client]\nhost=%s\nport=%s\nuser=%s\npassword=%s\n' "$1" "$2" "$3" "$4" > "$f"; echo "$f"
}

# ---------------------------------------------------------------- rollback
if (( ROLLBACK )); then
    [[ -f "$STATE" ]] || die "no upgrade to undo: $STATE not found"
    # shellcheck disable=SC1090
    source "$STATE"
    if (( SWITCHED )); then
        [[ -d "$OLD_DIR" ]] || die "the old folder $OLD_DIR is gone; restore it from $BACKUP_DIR first"
        CONF_DIR="$OLD_DIR"
    else
        CONF_DIR="$OE"
    fi
    step "Rolling back $NAME to $FROM_VERSION (backup in $BACKUP_DIR)"
    service_do stop
    for site in $SITES; do
        mapfile -t c < <(sqlconf "$CONF_DIR/sites/$site/sqlconf.php")
        cnf="$(mycnf "${c[0]}" "${c[1]}" "${c[2]}" "${c[3]}")"
        say "  $site: restoring ${c[4]} from $BACKUP_DIR/$site.sql"
        "$(client)" --defaults-extra-file="$cnf" "${c[4]}" < "$BACKUP_DIR/$site.sql"
        # Drop only what the upgrade created: a table that is neither in the dump nor in the list taken
        # just before the upgrade. (A lookup, not "printf | grep -q": under pipefail, grep -q closing the
        # pipe early makes printf fail and a table that IS there look missing.)
        declare -A keep=()
        while IFS= read -r t; do keep["$t"]=1; done < <(grep -oE '^CREATE TABLE `[^`]+`' "$BACKUP_DIR/$site.sql" | cut -d'`' -f2)
        [[ -f "$BACKUP_DIR/$site.tables" ]] && while IFS= read -r t; do [[ -n "$t" ]] && keep["$t"]=1; done < "$BACKUP_DIR/$site.tables"
        (( ${#keep[@]} > 0 )) || die "found no tables in $BACKUP_DIR/$site.sql; not dropping anything"
        mapfile -t now < <("$(client)" --defaults-extra-file="$cnf" -N -B "${c[4]}" -e 'SHOW FULL TABLES WHERE Table_type = "BASE TABLE"' | cut -f1)
        for t in "${now[@]}"; do
            if [[ -z "${keep[$t]:-}" ]]; then
                say "    dropping $t (created by the upgrade)"
                "$(client)" --defaults-extra-file="$cnf" "${c[4]}" -e "DROP TABLE \`$t\`"
            fi
        done
        unset keep
        rm -f "$cnf"
    done
    if (( SWITCHED )); then
        mv "$OE" "$OE.failed-$TO_VERSION-$(date +%Y%m%d%H%M%S)"
        mv "$OLD_DIR" "$OE"
    elif [[ -d "$NEW_DIR" ]]; then
        mv "$NEW_DIR" "$OE.failed-$TO_VERSION-$(date +%Y%m%d%H%M%S)"   # never switched to; the old folder is still in place
    fi
    service_do start
    rm -f "$STATE"
    say ""; say "Rolled back: $OE is $FROM_VERSION again, and its databases are as they were at $STAMP."
    exit 0
fi

# ---------------------------------------------------------------- upgrade
[[ "$TO" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "--to=X.Y.Z: the release to upgrade to"
IFS=. read -r a b _ <<<"$TO"
(( a > 8 || (a == 8 && b >= 2) )) || die "--to must be 8.2.0 or later: earlier sql_upgrade.php doesn't run from the command line"
[[ ! -f "$STATE" ]] || die "an earlier upgrade isn't finished or rolled back ($STATE): run --rollback, or delete that file if it was fine"
FROM="$(version_of "$OE")"
[[ "$(printf '%s\n%s\n' "$FROM" "$TO" | sort -V | tail -1)" == "$TO" && "$FROM" != "$TO" ]] || die "$OE is $FROM; --to=$TO isn't newer"
SITES="$(sites | tr '\n' ' ' | sed 's/ *$//')"
[[ -n "$SITES" ]] || die "no site in $OE/sites has a sqlconf.php"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP:-$PARENT}/$NAME-backup-$FROM-to-$TO-$STAMP"
NEW="$PARENT/$NAME.new-$TO"
OLD_DIR="$PARENT/$NAME.old-$FROM"
[[ ! -e "$NEW" && ! -e "$OLD_DIR" ]] || die "$NEW or $OLD_DIR already exists; move it out of the way first"

say "Upgrading OpenEMR $FROM -> $TO in $OE (sites: $SITES; web server user: $WEBUSER)"
say "Backup to: $BACKUP_DIR"

step "1. Pre-flight check"
pf="$HERE/openemr-preflight.php"
[[ -f "$pf" ]] || { pf="$(mktemp --suffix=.php)"; curl -fsSL https://github.com/anun333/openemr-reference/releases/latest/download/openemr-preflight.php -o "$pf"; chmod 644 "$pf"; }
# As root: it only reads, and it must see the backup folder, which may be one the web server's user can't.
set +e; php "$pf" --openemr="$OE" --target="$TO" --backup-dir="${BACKUP:-$PARENT}"; rc=$?; set -e
(( rc == 0 )) || (( FORCE )) || die "the pre-flight check found something to fix first (above); fix it, or pass --force"

if (( ! YES )); then
    printf '\nContinue? Users must stay out of OpenEMR until it finishes%s. [y/N] ' "${SERVICE:+ ($SERVICE will be stopped)}"
    read -r answer; [[ "$answer" == [yY]* ]] || die "stopped at your request; nothing changed"
fi

step "2. Getting OpenEMR $TO"
work="$(mktemp -d)"
if [[ -z "$TARBALL" ]]; then
    url="https://github.com/openemr/openemr/releases/download/v${TO//./_}/openemr-$TO.tar.gz"
    say "  downloading $url"
    curl -fSL --progress-bar "$url" -o "$work/openemr-$TO.tar.gz"
    curl -fsSL "$url.sha256" -o "$work/openemr-$TO.tar.gz.sha256"
    TARBALL="$work/openemr-$TO.tar.gz"
fi
if [[ -f "$TARBALL.sha256" ]]; then
    want="$(cut -d' ' -f1 < "$TARBALL.sha256")"; got="$(sha256sum "$TARBALL" | cut -d' ' -f1)"
    [[ "$want" == "$got" ]] || die "$TARBALL doesn't match its published sha256"
    say "  sha256 matches the published one"
else
    say "  no $TARBALL.sha256 beside it: not verified"
fi

step "3. Stopping the web server and backing up"
service_do stop
mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"
for site in $SITES; do
    mapfile -t c < <(sqlconf "$OE/sites/$site/sqlconf.php")
    cnf="$(mycnf "${c[0]}" "${c[1]}" "${c[2]}" "${c[3]}")"
    "$(dumper)" --defaults-extra-file="$cnf" --single-transaction --skip-lock-tables --routines --triggers "${c[4]}" > "$BACKUP_DIR/$site.sql"
    rm -f "$cnf"
    say "  $site: database ${c[4]} -> $site.sql ($(du -h "$BACKUP_DIR/$site.sql" | cut -f1))"
done
tar -czf "$BACKUP_DIR/sites.tar.gz" -C "$OE" sites
say "  sites/ (documents, encryption keys, settings) -> sites.tar.gz ($(du -h "$BACKUP_DIR/sites.tar.gz" | cut -f1))"
cat > "$STATE" <<EOF
FROM_VERSION=$FROM
TO_VERSION=$TO
OLD_DIR=$OLD_DIR
BACKUP_DIR=$BACKUP_DIR
SITES="$SITES"
STAMP=$STAMP
NEW_DIR=$NEW
SWITCHED=0
EOF

step "4. Unpacking $TO beside the current folder"
mkdir "$NEW"
tar -xzf "$TARBALL" -C "$NEW" --strip-components=1
rm -rf "$NEW/sites"
cp -a "$OE/sites" "$NEW/sites"
# What the site added: module folders and Composer packages that aren't in the current release's own
# lists (this repository's facts, at the patch level installed). Those, and only those, are carried
# over; a module the release itself had and the target dropped stays behind, as upstream intended.
patch="$(php -r 'include $argv[1] . "/version.php"; echo (int)($v_realpatch ?? 0);' "$OE")"
facts="$HERE/../site/preflight"; [[ -f "$facts/releases.json" ]] || facts="https://raw.githubusercontent.com/anun333/openemr-reference/main/site/preflight"
added="$(php -r '
    [$oe, $facts, $from, $patch] = array_slice($argv, 1);
    $get = function (string $name) use ($facts) { $raw = @file_get_contents("$facts/$name"); return $raw === false ? null : json_decode($raw, true); };
    $files = $get($patch > 0 ? "$from-p$patch-files.json" : "$from-files.json");
    $release = $get("$from.json");
    if (!is_array($files) || !is_array($release)) { echo "NOFACTS\n"; exit; }
    $shipped = $patch > 0 ? ($release["patches"][$patch]["composer"] ?? $release["composer"] ?? []) : ($release["composer"] ?? []);
    $shipped = array_flip(array_column($shipped, 0));
    foreach (["interface/modules/custom_modules", "interface/modules/zend_modules/module"] as $kind) {
        foreach (glob("$oe/$kind/*", GLOB_ONLYDIR) ?: [] as $d) {
            $rel = "$kind/" . basename($d);
            if (!isset($files["dirs"][$rel])) { echo "MODULE $rel\n"; }
        }
    }
    $installed = json_decode((string)@file_get_contents("$oe/vendor/composer/installed.json"), true);
    foreach ($installed["packages"] ?? $installed ?? [] as $pkg) {
        if (($pkg["type"] ?? "") === "metapackage" || ($pkg["install-path"] ?? "") === "") { continue; }  // no files of its own
        $parts = [];
        foreach (explode("/", "vendor/composer/" . ($pkg["install-path"] ?? "")) as $seg) { if ($seg === "..") { array_pop($parts); } elseif ($seg !== "" && $seg !== ".") { $parts[] = $seg; } }
        if (!isset($shipped[implode("/", $parts)])) { echo "COMPOSER " . $pkg["name"] . "\n"; }
    }' "$OE" "$facts" "$FROM" "$patch")"
if [[ "$added" == NOFACTS* ]]; then
    say "  couldn't read the facts for $FROM, so nothing is carried over beyond sites/. Folders here that $TO doesn't have:"
    for kind in interface/modules/custom_modules interface/modules/zend_modules/module; do
        for d in "$OE/$kind"/*/; do [[ -d "$d" && ! -e "$NEW/$kind/$(basename "$d")" ]] && say "    $kind/$(basename "$d"): yours? copy it into $NEW before step 5"; done
    done
else
    while read -r what rel; do
        case "$what" in
            MODULE)
                if [[ -e "$NEW/$rel" ]]; then say "  $rel: added here, and $TO has its own; keeping $TO's"
                else cp -a "$OE/$rel" "$NEW/$rel"; say "  carried over $rel (added to this install)"; fi ;;
            COMPOSER) say "  NOTE: $rel was installed with Composer here; install it again in the new folder: composer require $rel" ;;
        esac
    done <<<"$added"
fi
chown -R "$(stat -c %u:%g "$OE")" "$NEW"
chown -R "$WEBUSER" "$NEW/sites"

step "5. Upgrading the databases with $TO's sql_upgrade.php --from=$FROM"
failed=0
for site in $SITES; do
    mapfile -t c < <(sqlconf "$OE/sites/$site/sqlconf.php")
    cnf="$(mycnf "${c[0]}" "${c[1]}" "${c[2]}" "${c[3]}")"
    "$(client)" --defaults-extra-file="$cnf" -N -B "${c[4]}" -e 'SHOW FULL TABLES WHERE Table_type = "BASE TABLE"' | cut -f1 > "$BACKUP_DIR/$site.tables"
    rm -f "$cnf"
done
for site in $SITES; do
    tmp="$NEW/TEMPsql_upgrade_$site.php"
    { echo "<?php \$_GET['site'] = '$site'; ?>"; cat "$NEW/sql_upgrade.php"; } > "$tmp"; chown "$WEBUSER" "$tmp"
    set +e
    # From inside the new folder: sql_upgrade.php requires 'interface/globals.php' by a relative path,
    # which PHP looks for in the current directory first. Run from the old folder, it loads the old one.
    (cd "$NEW" && OPENEMR_UPGRADE_SITE="$site" as_web php -d memory_limit=-1 "$tmp" --from="$FROM") > "$BACKUP_DIR/upgrade-$site.log" 2>&1; rc=$?
    set -e
    rm -f "$tmp"
    n="$(grep -c 'The above statement failed' "$BACKUP_DIR/upgrade-$site.log" || true)"
    say "  $site: exit $rc, $n statement(s) failed (log: $BACKUP_DIR/upgrade-$site.log)"
    (( rc == 0 && n == 0 )) || failed=1
done
if (( failed )); then
    service_do start
    die "the database upgrade didn't finish cleanly. The old folder is untouched but the database is part-upgraded: run '$0 --rollback --openemr=$OE' to put everything back, then look at the log."
fi

step "6. Checking the new folder with the install doctor"
dr="$HERE/openemr-doctor.php"
[[ -f "$dr" ]] || { dr="$(mktemp --suffix=.php)"; curl -fsSL https://github.com/anun333/openemr-reference/releases/latest/download/openemr-doctor.php -o "$dr"; chmod 644 "$dr"; }
# As the web server's user, since it checks what that user can read and write; from a folder it can read.
drdir="$(mktemp -d)"; chmod 755 "$drdir"; cp "$dr" "$drdir/openemr-doctor.php"; chmod 644 "$drdir/openemr-doctor.php"
doctor_failed=0
for site in $SITES; do
    set +e; as_web php "$drdir/openemr-doctor.php" --openemr="$NEW" --site="$site"; rc=$?; set -e
    (( rc == 0 )) || doctor_failed=1
done
if (( doctor_failed && ! FORCE )); then
    service_do start
    die "the install doctor found a problem in $NEW (above). Nothing is switched yet; fix it and run '$0 --rollback --openemr=$OE' or switch by hand. --force switches anyway."
fi

step "7. Switching to $TO"
if [[ -L "$OE" ]]; then
    target="$(readlink -f "$OE")"; ln -sfn "$NEW" "$OE.tmp-link" && mv -T "$OE.tmp-link" "$OE"
    sed -i "s|^OLD_DIR=.*|OLD_DIR=$target|" "$STATE"
else
    mv "$OE" "$OLD_DIR" && mv "$NEW" "$OE"
fi
sed -i 's/^SWITCHED=0$/SWITCHED=1/' "$STATE"
service_do start
say ""
say "Done: $OE is OpenEMR $TO. The old folder is $OLD_DIR; the backup is $BACKUP_DIR."
say "Log in and open a patient and a report. If anything is wrong:  $0 --rollback --openemr=$OE"
say "When you're sure, delete $STATE (the rollback needs it), and later the old folder and the backup."
