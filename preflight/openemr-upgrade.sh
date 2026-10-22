#!/usr/bin/env bash
# Upgrade an OpenEMR installed from the release tarball (not the Docker image), with a way back.
#
#   openemr-upgrade.sh --openemr=/var/www/html/openemr --to=8.4.1 [--tarball=FILE] [--backup-dir=DIR]
#                      [--service=apache2] [--customizations=apply|leave] [--force] [--yes] [--debug]
#   openemr-upgrade.sh --rollback --openemr=/var/www/html/openemr [--debug]
#
# It does what the manual upgrade does, in order, and stops at the first thing that goes wrong:
#   1. checks the server with openemr-preflight.php (stops on a FAIL unless --force);
#   2. gets the target release (downloaded from GitHub and its sha256 checked, or --tarball);
#   3. unpacks it beside the old folder;
#   4. finds OpenEMR's own files changed or added here, saves them, and tries each change on the
#      target; stops unless --customizations=apply (carry what applies) or =leave. Until here
#      nothing on the server has changed, and a stop removes the unpacked folder;
#   5. stops the web server (--service), or asks you to keep users out, and backs up each site's
#      database (mysqldump) and the whole sites/ folder: documents, keys;
#   6. carries over sites/, the modules this install added and, with =apply, its changes;
#   7. runs the target's own sql_upgrade.php --from=<current> for each site, as the web server's user;
#   8. checks the new folder with openemr-doctor.php (stops on a FAIL unless --force);
#   9. swaps the folders (the old one is kept as <folder>.old-<version>) and starts the web server.
# Nothing is deleted. --rollback first saves each database as it is (everything entered since the
# upgrade) and, apart, the tables the upgrade created; then restores the backup and swaps the folders back.
#
# It checks its own work: after each step it verifies the result (the unpacked release's version, each
# dump complete and with every table, sites/ copied whole, each database at the target's version, the
# folders switched) and prints a "check:" line, or stops. Everything it prints also goes to a log in the
# backup folder. If it stops after the backup, it says how far it got and the exact --rollback command.
# Only one run at a time per install. --debug also traces every command (passwords are left out).
# The pre-flight check and the doctor come from beside this script, else from this script's own
# release, checked against that release's SHA256SUMS.
#
# Run it as root on the server, after rehearsing the upgrade on a copy (openemr-rehearse.sh).
# The target must be 8.2.0 or later (sql_upgrade.php runs from the command line from 8.2.0).
set -euo pipefail
SCRIPT_VERSION=0.3.8
# Where the helpers come from when they aren't beside this script: this script's own release.
REFERENCE_BASE="${OPENEMR_REFERENCE_BASE:-https://github.com/anun333/openemr-reference/releases/download/v$SCRIPT_VERSION}"

OE="" TO="" TARBALL="" BACKUP="" SERVICE="" CUSTOM="" FORCE=0 YES=0 ROLLBACK=0 DEBUG=0
for arg in "$@"; do
    case "$arg" in
        --openemr=*) OE="${arg#*=}" ;;
        --to=*) TO="${arg#*=}" ;;
        --tarball=*) TARBALL="${arg#*=}" ;;
        --backup-dir=*) BACKUP="${arg#*=}" ;;
        --service=*) SERVICE="${arg#*=}" ;;
        --customizations=*) CUSTOM="${arg#*=}" ;;
        --force) FORCE=1 ;;
        --yes) YES=1 ;;
        --rollback) ROLLBACK=1 ;;
        --debug) DEBUG=1 ;;
        -h|--help) sed -n '2,34p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $arg (see --help)" >&2; exit 2 ;;
    esac
done
die() { echo "STOP: $*" >&2; exit 1; }
say() { printf '%s\n' "$*"; }
STEP_NOW="the start"
step() {
    STEP_NOW="step $*"
    # For the tests only: stop just before a step, as a failure there would.
    if [[ -n "${OPENEMR_UPGRADE_TEST_FAIL_BEFORE_STEP:-}" && "${1%%.*}" == "$OPENEMR_UPGRADE_TEST_FAIL_BEFORE_STEP" ]]; then
        die "stopped before step ${1%%.*} for a test (OPENEMR_UPGRADE_TEST_FAIL_BEFORE_STEP)"
    fi
    printf '\n== %s\n' "$*"
}
audit() { say "  check: $*"; }
OE="${OE%/}"
[[ -n "$OE" && -f "$OE/version.php" && -d "$OE/sites" ]] || die "--openemr=DIR: an OpenEMR folder (with version.php and sites/), not '$OE'"
[[ ! -f /.dockerenv && ! -f "$OE/openemr.sh" ]] || say "Note: this looks like a Docker container. For the official image, upgrading means changing the image tag; this script is for installs from the release tarball."
HERE="$(cd "$(dirname "$0")" && pwd)"
PARENT="$(dirname "$OE")"
NAME="$(basename "$OE")"
STATE="$PARENT/.$NAME-upgrade-state"
WEBUSER="$(stat -c %U "$OE/sites")"
LOGFILE="" NEW="" NEW_MADE=0 LOCK_DIR="" SERVICE_STOPPED=0

# One run at a time on this install: two would back up, upgrade and swap the same folders.
LOCK="$PARENT/.$NAME-upgrade.lock"
if command -v flock >/dev/null; then
    exec 9>"$LOCK"
    flock -n 9 || die "another openemr-upgrade.sh is already running on $OE (it holds $LOCK)"
else
    mkdir "$LOCK.d" 2>/dev/null || die "another openemr-upgrade.sh is already running on $OE ($LOCK.d exists; remove it if no run is going)"
    LOCK_DIR="$LOCK.d"
fi

# Whatever stops the run says how far it got and, once there is a backup, how to get back.
on_exit() {
    local rc=$?
    set +x
    [[ -z "$LOCK_DIR" ]] || rmdir "$LOCK_DIR" 2>/dev/null || true
    (( rc != 0 )) || return 0
    if (( ROLLBACK )); then
        say ""
        say "The rollback stopped during $STEP_NOW (exit $rc). Nothing was deleted: the backup is still in ${BACKUP_DIR:-?},"
        say "and $STATE is kept. Fix what the message above says, then run the same command again:  $0 --rollback --openemr=$OE"
    elif [[ ! -f "$STATE" ]]; then
        if (( NEW_MADE )) && [[ -n "$NEW" && -d "$NEW" ]]; then rm -rf "$NEW"; fi
        say ""
        say "Stopped during $STEP_NOW (exit $rc), before the backup was finished: nothing on the server was changed."
        if (( SERVICE_STOPPED )); then
            if service_do start; then say "  Started $SERVICE again."; else say "  $SERVICE was stopped at step 5 and didn't start again: start it by hand."; fi
        fi
    else
        local switched; switched="$(sed -n 's/^SWITCHED=//p' "$STATE")"
        say ""
        say "Stopped during $STEP_NOW (exit $rc), after the backup."
        say "  The backup (each database and sites/) is in $BACKUP_DIR."
        if [[ "$switched" == 1 ]]; then say "  $OE is already the new release; the old folder is $OLD_DIR."
        else say "  $OE is still the old folder; the new one, not yet switched to, is $NEW."; fi
        [[ -z "$SERVICE" ]] || say "  This run stopped $SERVICE at step 5; check whether it is running before letting users in."
        say "  To put everything back as it was before the upgrade:  $0 --rollback --openemr=$OE"
    fi
    [[ -z "$LOGFILE" ]] || say "  The log of this run: $LOGFILE"
}
trap on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
start_log() {  # $1: the log file. From here on everything printed also goes there.
    LOGFILE="$1"
    exec > >(tee -a "$LOGFILE") 2>&1
    say "openemr-upgrade.sh $SCRIPT_VERSION, $(date '+%Y-%m-%d %H:%M:%S %z'), on $(hostname), as $(id -un); log: $LOGFILE"
    if (( DEBUG )); then
        say "  debug: bash $BASH_VERSION; $(php -r 'echo "PHP ", PHP_VERSION;'); $("$(client)" --version 2>/dev/null | head -n 1)"
        say "  debug: free space where the backup goes: $(df -h "$(dirname "$LOGFILE")" | tail -n 1)"
        PS4='+ openemr-upgrade.sh:${LINENO}: '
        set -x
    fi
}

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
# The lock's descriptor (9) is closed for the web server: a server started by a SysV "service"
# script keeps the descriptors it was given, and would hold the lock long after this script ends,
# refusing the next run, the rollback included.
service_do() {
    [[ -n "$SERVICE" ]] || return 0
    if command -v systemctl >/dev/null; then systemctl "$1" "$SERVICE" 9>&-; else service "$SERVICE" "$1" 9>&-; fi
}
# A client option file from the site settings in the array c (host port login pass dbase), so the
# password is never on a command line, nor in a --debug trace: tracing is off while it's written.
mycnf() {
    local f xtrace=0
    if [[ $- == *x* ]]; then xtrace=1; set +x; fi
    f="$(mktemp)"; chmod 600 "$f"
    printf '[client]\nhost=%s\nport=%s\nuser=%s\npassword=%s\n' "${c[0]}" "${c[1]}" "${c[2]}" "${c[3]}" > "$f"
    if (( xtrace )); then set -x; fi
    echo "$f"
}
v_database_of() { php -r 'include $argv[1] . "/version.php"; echo $v_database;' "$1"; }
# The version table of the database the option file $1 reaches, as "X.Y.Z v_database".
db_version() { "$(client)" --defaults-extra-file="$1" -N -B -e "SELECT CONCAT(v_major, '.', v_minor, '.', v_patch, ' ', v_database) FROM version" "$2"; }
base_tables() { "$(client)" --defaults-extra-file="$1" -N -B -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'" "$2"; }
sums() { if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi; }
# A helper this script runs ($1): the copy beside this script, else downloaded from this script's own
# release and checked against that release's SHA256SUMS. Sets TOOL to its path.
fetch_tool() {
    if [[ -f "$HERE/$1" ]]; then
        TOOL="$HERE/$1"; say "  $1: the copy beside this script ($TOOL)"; return 0
    fi
    local dir want got
    dir="$(mktemp -d)"; chmod 755 "$dir"
    curl -fsSL "$REFERENCE_BASE/$1" -o "$dir/$1" || die "couldn't download $1 from $REFERENCE_BASE"
    curl -fsSL "$REFERENCE_BASE/SHA256SUMS" -o "$dir/SHA256SUMS" || die "couldn't download SHA256SUMS from $REFERENCE_BASE"
    want="$(awk -v f="$1" '$2 == f || $2 == "*" f {print $1}' "$dir/SHA256SUMS")"
    got="$(sums "$dir/$1")"
    [[ -n "$want" && "$want" == "$got" ]] || die "$1 from $REFERENCE_BASE doesn't match that release's SHA256SUMS (expected ${want:-no entry}, got $got); not running it"
    chmod 644 "$dir/$1"; TOOL="$dir/$1"
    audit "$1 downloaded from release v$SCRIPT_VERSION matches its SHA256SUMS"
}

# ---------------------------------------------------------------- rollback
if (( ROLLBACK )); then
    [[ -f "$STATE" ]] || die "no upgrade to undo: $STATE not found"
    # shellcheck disable=SC1090
    source "$STATE"
    start_log "$BACKUP_DIR/openemr-rollback-$(date +%Y%m%d-%H%M%S).log"
    STEP_NOW="the rollback's start"
    if (( SWITCHED )); then
        [[ -d "$OLD_DIR" ]] || die "the old folder $OLD_DIR is gone; restore it from $BACKUP_DIR first"
        CONF_DIR="$OLD_DIR"
    else
        CONF_DIR="$OE"
    fi
    step "Rolling back $NAME to $FROM_VERSION (backup in $BACKUP_DIR)"
    service_do stop
    RB="$(date +%Y%m%d-%H%M%S)"
    for site in $SITES; do
        STEP_NOW="the rollback of site $site"
        mapfile -t c < <(sqlconf "$CONF_DIR/sites/$site/sqlconf.php")
        cnf="$(mycnf)"
        # The tables the upgrade created: neither in the dump nor in the list taken just before the
        # upgrade. (A lookup, not "printf | grep -q": under pipefail, grep -q closing the pipe early
        # makes printf fail and a table that IS there look missing.)
        declare -A keep=()
        while IFS= read -r t; do keep["$t"]=1; done < <(grep -oE '^CREATE TABLE `[^`]+`' "$BACKUP_DIR/$site.sql" | cut -d'`' -f2)
        [[ -f "$BACKUP_DIR/$site.tables" ]] && while IFS= read -r t; do [[ -n "$t" ]] && keep["$t"]=1; done < "$BACKUP_DIR/$site.tables"
        (( ${#keep[@]} > 0 )) || die "found no tables in $BACKUP_DIR/$site.sql; not touching ${c[4]}"
        mapfile -t now < <("$(client)" --defaults-extra-file="$cnf" -N -B "${c[4]}" -e 'SHOW FULL TABLES WHERE Table_type = "BASE TABLE"' | cut -f1)
        created=()
        for t in "${now[@]}"; do
            if [[ -z "${keep[$t]:-}" ]]; then created+=("$t"); fi
        done
        unset keep
        # Nothing is discarded: the restore below replaces every table with its pre-upgrade copy, so
        # whatever was entered since the upgrade is saved first, all of it and the new tables apart.
        saved="$BACKUP_DIR/$site.before-rollback-$RB.sql"
        "$(dumper)" --defaults-extra-file="$cnf" --single-transaction --skip-lock-tables --routines --triggers "${c[4]}" > "$saved"
        say "  $site: saved ${c[4]} as it is now, with everything entered since the upgrade -> $saved"
        if (( ${#created[@]} )); then
            "$(dumper)" --defaults-extra-file="$cnf" --single-transaction --skip-lock-tables "${c[4]}" "${created[@]}" > "$BACKUP_DIR/$site.created-tables-$RB.sql"
            say "  $site: and the ${#created[@]} tables the upgrade created, on their own -> $BACKUP_DIR/$site.created-tables-$RB.sql"
        fi
        say "  $site: restoring ${c[4]} from $BACKUP_DIR/$site.sql"
        "$(client)" --defaults-extra-file="$cnf" "${c[4]}" < "$BACKUP_DIR/$site.sql"
        for t in "${created[@]}"; do
            say "    dropping $t (created by the upgrade; saved above)"
            "$(client)" --defaults-extra-file="$cnf" "${c[4]}" -e "DROP TABLE \`$t\`"
        done
        dumped="$(grep -c '^CREATE TABLE `' "$BACKUP_DIR/$site.sql" || true)"
        live="$(base_tables "$cnf" "${c[4]}")"
        (( dumped == live )) || die "$site: ${c[4]} has $live tables after the restore, the backup $dumped"
        restored="$(db_version "$cnf" "${c[4]}")"
        [[ "${restored%% *}" == "$FROM_VERSION" ]] || die "$site: ${c[4]} says it is ${restored%% *} after the restore, not $FROM_VERSION"
        audit "$site: ${c[4]} is $FROM_VERSION again (database version ${restored##* }), with the backup's $dumped tables"
        rm -f "$cnf"
    done
    STEP_NOW="the rollback's folder switch"
    if (( SWITCHED )); then
        mv "$OE" "$OE.failed-$TO_VERSION-$(date +%Y%m%d%H%M%S)"
        mv "$OLD_DIR" "$OE"
    elif [[ -d "$NEW_DIR" ]]; then
        mv "$NEW_DIR" "$OE.failed-$TO_VERSION-$(date +%Y%m%d%H%M%S)"   # never switched to; the old folder is still in place
    fi
    back="$(version_of "$OE")"
    [[ "$back" == "$FROM_VERSION" ]] || die "$OE is $back after switching back, not $FROM_VERSION"
    audit "$OE is the $FROM_VERSION folder again"
    service_do start
    rm -f "$STATE"
    say ""; say "Rolled back: $OE is $FROM_VERSION again, and its databases are as they were at $STAMP."
    say "Kept, nothing discarded: each database as it was before this rollback ($BACKUP_DIR/*.before-rollback-$RB.sql),"
    say "the tables the upgrade created on their own (*.created-tables-$RB.sql), and the $TO_VERSION folder with any"
    say "documents uploaded since the upgrade ($OE.failed-$TO_VERSION-*)."
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
[[ -z "$CUSTOM" || "$CUSTOM" == apply || "$CUSTOM" == leave ]] || die "--customizations is apply or leave, not '$CUSTOM'"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP:-$PARENT}/$NAME-backup-$FROM-to-$TO-$STAMP"
NEW="$PARENT/$NAME.new-$TO"
OLD_DIR="$PARENT/$NAME.old-$FROM"
[[ ! -e "$NEW" && ! -e "$OLD_DIR" ]] || die "$NEW or $OLD_DIR already exists; move it out of the way first"
mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"
start_log "$BACKUP_DIR/openemr-upgrade.log"

say "Upgrading OpenEMR $FROM -> $TO in $OE (sites: $SITES; web server user: $WEBUSER)"
say "Backup to: $BACKUP_DIR"

patch="$(php -r 'include $argv[1] . "/version.php"; echo (int)($v_realpatch ?? 0);' "$OE")"
facts="$HERE/../site/preflight"; [[ -f "$facts/releases.json" ]] || facts="https://raw.githubusercontent.com/anun333/openemr-reference/main/site/preflight"

# Which of OpenEMR's own files this install changed or added, and what each change would do on the
# target. Run before anything on the server changes; writes into the backup folder's customizations/.
customizations_php() { cat <<'PHP'
<?php
// Which of OpenEMR's own files this install changed or added, and what each change would do on the
// target, unpacked beside it. Reads only; writes into the backup folder's customizations/.
[, $oe, $facts, $from, $patch, $new, $out] = $argv;
$patch = (int)$patch;
$fromTag = 'v' . str_replace('.', '_', $from) . ($patch > 0 ? "_$patch" : '');
$get = function (string $name) use ($facts) {
    $raw = @file_get_contents("$facts/$name");
    return $raw === false ? null : json_decode($raw, true);
};
$hashes = $get($patch > 0 ? "$from-p$patch-hashes.json" : "$from-hashes.json");
$files = $get($patch > 0 ? "$from-p$patch-files.json" : "$from-files.json");
if (!is_array($hashes) || !is_array($files)) {
    file_put_contents("$out/report.json", json_encode(['facts' => false]));
    echo "  couldn't read the facts for $fromTag, so local changes can't be told apart; nothing checked\n";
    exit(0);
}
$join = function (string $dir, string $name): string { return $dir === '' ? $name : "$dir/$name"; };
$under = function (string $rel, array $prefixes): bool {
    foreach ($prefixes as $p) {
        if ($rel === $p || strpos($rel, "$p/") === 0) {
            return true;
        }
    }
    return false;
};
// Changed: a shipped file whose git blob hash differs from the release's, modules the release ships
// included. Not sites/: it is carried over whole, and configured on every install.
$changed = [];
foreach ($hashes['dirs'] as $dir => $names) {
    foreach ($names as $name => $sha) {
        $rel = $join($dir, $name);
        $f = "$oe/$rel";
        if (!$under($rel, ['sites']) && is_file($f) && !is_link($f)) {
            $c = (string)file_get_contents($f);
            if (substr(sha1('blob ' . strlen($c) . "\0" . $c), 0, strlen($sha)) !== $sha) {
                $changed[] = $rel;
            }
        }
    }
}
// Added: files the release's source doesn't have, outside what installing and running puts there.
// One the target's package has too is built by the release (compiled CSS, for one), not the site's.
$shipped = [];
foreach ($files['dirs'] as $dir => $names) {
    foreach ($names as $name) {
        $shipped[$join($dir, $name)] = true;
    }
}
// Module folders are carried whole, as modules, when this install added them (step 6).
$skip = ['sites', 'interface/modules/custom_modules', 'interface/modules/zend_modules/module', 'vendor', 'node_modules', 'public/assets', '.git'];
$filter = function (SplFileInfo $f) use ($oe, $skip, $under): bool {
    $rel = substr($f->getPathname(), strlen($oe) + 1);
    return !$f->isDir() || (!$under($rel, $skip) && basename($rel) !== 'node_modules');
};
$added = [];
$built = 0;
$walk = new RecursiveIteratorIterator(new RecursiveCallbackFilterIterator(new RecursiveDirectoryIterator($oe, FilesystemIterator::SKIP_DOTS), $filter));
foreach ($walk as $f) {
    $rel = substr($f->getPathname(), strlen($oe) + 1);
    if ($f->isFile() && !isset($shipped[$rel])) {
        if (file_exists("$new/$rel")) {
            $built++;
        } else {
            $added[] = $rel;
        }
    }
}
sort($changed);
sort($added);
$keep = function (string $kind, string $rel) use ($oe, $out): void {
    @mkdir(dirname("$out/$kind/$rel"), 0700, true);
    copy("$oe/$rel", "$out/$kind/$rel");
};
foreach ($changed as $rel) {
    $keep('changed', $rel);
}
foreach ($added as $rel) {
    $keep('added', $rel);
}
// Each change against the release's original (from GitHub, at the installed tag), tried on the target.
$fetch = function (string $tag, string $rel): ?string {
    $url = "https://raw.githubusercontent.com/openemr/openemr/$tag/" . implode('/', array_map('rawurlencode', explode('/', $rel)));
    $body = @file_get_contents($url, false, stream_context_create(['http' => ['ignore_errors' => true, 'timeout' => 30]]));
    $ok = isset($http_response_header[0]) && strpos($http_response_header[0], ' 200 ') !== false;
    return $ok && $body !== false ? $body : null;
};
$have = function (string $tool): bool { return trim((string)shell_exec('command -v ' . $tool . ' 2>/dev/null')) !== ''; };
$diffOk = $have('diff');
$patchOk = $have('patch');
$result = [];
foreach ($changed as $rel) {
    $orig = $fetch($fromTag, $rel);
    if ($orig === null) {
        $result[$rel] = ['status' => 'nofetch'];
        continue;
    }
    $work = sys_get_temp_dir() . '/oe-custom-' . bin2hex(random_bytes(4));
    foreach (['a' => $orig, 'b' => (string)file_get_contents("$oe/$rel")] as $side => $content) {
        @mkdir(dirname("$work/$side/$rel"), 0700, true);
        file_put_contents("$work/$side/$rel", $content);
    }
    @mkdir(dirname("$out/patches/$rel"), 0700, true);
    if ($diffOk) {
        file_put_contents("$out/patches/$rel.patch", (string)shell_exec('cd ' . escapeshellarg($work) . ' && diff -u ' . escapeshellarg("a/$rel") . ' ' . escapeshellarg("b/$rel")));
    }
    if (!file_exists("$new/$rel")) {
        $result[$rel] = ['status' => 'gone'];
    } elseif ((string)file_get_contents("$new/$rel") === $orig) {
        $result[$rel] = ['status' => 'applies', 'how' => 'copy'];   // the target left the file as it was: yours replaces it
    } elseif (!$patchOk || !$diffOk) {
        $result[$rel] = ['status' => 'needs-patch'];
    } else {
        @mkdir(dirname("$work/t/$rel"), 0700, true);
        copy("$new/$rel", "$work/t/$rel");
        exec('patch -d ' . escapeshellarg("$work/t") . ' -p1 -s -i ' . escapeshellarg("$out/patches/$rel.patch") . ' >/dev/null 2>&1', $o, $rc);
        $result[$rel] = $rc === 0 ? ['status' => 'applies', 'how' => 'patch'] : ['status' => 'conflicts'];
    }
    exec('rm -rf ' . escapeshellarg($work));
}
file_put_contents("$out/report.json", json_encode(['facts' => true, 'from' => $fromTag, 'changed' => $result, 'added' => $added, 'built' => $built], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
$to = basename($new);
$why = [
    'applies' => 'applies to the new release',
    'conflicts' => 'the new release changed the same lines: merge by hand',
    'gone' => 'the new release no longer has this file',
    'nofetch' => "couldn't fetch the original from GitHub to compare",
    'needs-patch' => 'the new release changed this file too: install patch (and diff) to check whether yours applies',
];
printf("  %d of OpenEMR's own files changed here and %d added (compared with %s as released)%s\n", count($result), count($added), $fromTag,
    $built ? "; $built more files the old release's package built aren't counted" : '');
foreach ($result as $rel => $r) {
    printf("    changed  %-60s %s\n", $rel, $why[$r['status']]);
}
foreach (array_slice($added, 0, 40) as $rel) {
    printf("    added    %s\n", $rel);
}
if (count($added) > 40) {
    printf("    ... and %d more added (all in %s/added)\n", count($added) - 40, $out);
}
PHP
}

step "1. Pre-flight check"
fetch_tool openemr-preflight.php; pf="$TOOL"
# As root: it only reads, and it must see the backup folder, which may be one the web server's user can't.
set +e; php "$pf" --openemr="$OE" --target="$TO" --backup-dir="${BACKUP:-$PARENT}"; rc=$?; set -e
(( rc == 0 )) || (( FORCE )) || die "the pre-flight check found something to fix first (above); fix it, or pass --force"


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

step "3. Unpacking $TO beside the current folder"
mkdir "$NEW"
# Until the backup is taken, nothing on the live site has changed: if anything stops the run before
# then, the unpacked folder goes too (on_exit).
NEW_MADE=1
tar -xzf "$TARBALL" -C "$NEW" --strip-components=1
say "  $NEW"
got="$(version_of "$NEW")"
[[ "$got" == "$TO" ]] || die "the unpacked release says it is $got, not $TO"
audit "the unpacked folder is OpenEMR $got (database version $(v_database_of "$NEW"))"

step "4. Local changes to OpenEMR's own files"
CUSTOM_DIR="$BACKUP_DIR/customizations"
mkdir -p "$CUSTOM_DIR"; chmod 700 "$BACKUP_DIR" "$CUSTOM_DIR"
helper="$(mktemp)"; customizations_php > "$helper"
php "$helper" "$OE" "$facts" "$FROM" "$patch" "$NEW" "$CUSTOM_DIR"
rm -f "$helper"
found="$(php -r '$r = json_decode((string)@file_get_contents($argv[1]), true); echo count($r["changed"] ?? []) + count($r["added"] ?? []);' "$CUSTOM_DIR/report.json")"
if (( found > 0 )); then
    say "  saved: the changed and added files, and each change as a patch, in $CUSTOM_DIR"
    case "$CUSTOM" in
        apply) say "  --customizations=apply: the changes that apply, and the added files, go into $TO at step 6" ;;
        leave) say "  --customizations=leave: $TO goes in without them; they stay in $CUSTOM_DIR" ;;
        *) die "this install has local changes to OpenEMR's own files (above). Nothing on the server has changed. Rerun with --customizations=apply to carry over the changes that apply and the added files, or --customizations=leave to upgrade without them (they stay saved in $CUSTOM_DIR)." ;;
    esac
else
    say "  none: every shipped file is as $FROM${patch:+ patch $patch} released it"
fi

if (( ! YES )); then
    printf '\nContinue? Users must stay out of OpenEMR until it finishes%s. [y/N] ' "${SERVICE:+ ($SERVICE will be stopped)}"
    read -r answer; [[ "$answer" == [yY]* ]] || die "stopped at your request; nothing on the server changed"
fi

step "5. Stopping the web server and backing up"
service_do stop
[[ -z "$SERVICE" ]] || SERVICE_STOPPED=1
mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"
for site in $SITES; do
    mapfile -t c < <(sqlconf "$OE/sites/$site/sqlconf.php")
    cnf="$(mycnf)"
    # --comments: the dump then ends with its "Dump completed" line (checked below), even when the
    # server's my.cnf sets skip-comments for mysqldump; the command line wins over option files.
    "$(dumper)" --defaults-extra-file="$cnf" --comments --single-transaction --skip-lock-tables --routines --triggers "${c[4]}" > "$BACKUP_DIR/$site.sql"
    say "  $site: database ${c[4]} -> $site.sql ($(du -h "$BACKUP_DIR/$site.sql" | cut -f1))"
    # The way back is only as good as this file: check it is whole before changing anything.
    [[ "$(tail -n 1 "$BACKUP_DIR/$site.sql")" == "-- Dump completed"* ]] || die "$site: $site.sql doesn't end with the dump's 'Dump completed' line, so it may be cut short (is the disk full?)"
    dumped="$(grep -c '^CREATE TABLE `' "$BACKUP_DIR/$site.sql" || true)"
    live="$(base_tables "$cnf" "${c[4]}")"
    (( dumped == live )) || die "$site: $site.sql has $dumped tables, the database $live"
    audit "$site: the dump is complete ('Dump completed') and has all $live tables"
    rm -f "$cnf"
done
tar -czf "$BACKUP_DIR/sites.tar.gz" -C "$OE" sites
say "  sites/ (documents, encryption keys, settings) -> sites.tar.gz ($(du -h "$BACKUP_DIR/sites.tar.gz" | cut -f1))"
in_tar="$(tar -tzf "$BACKUP_DIR/sites.tar.gz" | grep -vc '/$' || true)"
on_disk="$(find "$OE/sites" -not -type d | wc -l)"
(( in_tar == on_disk )) || die "sites.tar.gz has $in_tar files, sites/ $on_disk (were users still working? use --service)"
for site in $SITES; do
    tar -tzf "$BACKUP_DIR/sites.tar.gz" "sites/$site/sqlconf.php" >/dev/null 2>&1 || die "sites.tar.gz has no sites/$site/sqlconf.php"
done
audit "sites.tar.gz reads back whole: $in_tar files, the same as sites/, with each site's sqlconf.php"
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

step "6. Carrying over sites/, this install's modules and its changes"
rm -rf "$NEW/sites"
cp -a "$OE/sites" "$NEW/sites"
# What the site added: module folders and Composer packages that aren't in the current release's own
# lists (this repository's facts, at the patch level installed). Those, and only those, are carried
# over; a module the release itself had and the target dropped stays behind, as upstream intended.
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
        for d in "$OE/$kind"/*/; do [[ -d "$d" && ! -e "$NEW/$kind/$(basename "$d")" ]] && say "    $kind/$(basename "$d"): yours? copy it into $NEW before step 7"; done
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
if [[ "$CUSTOM" == apply && -f "$CUSTOM_DIR/report.json" ]]; then
    while IFS=$'\t' read -r what how rel; do
        case "$what" in
            applies)
                if [[ "$how" == copy ]]; then cp -a "$CUSTOM_DIR/changed/$rel" "$NEW/$rel"; say "  carried over your change to $rel ($TO left the file as it was)"
                elif patch -d "$NEW" -p1 -s -i "$CUSTOM_DIR/patches/$rel.patch"; then say "  applied your change to $rel"
                else say "  NOT carried: your change to $rel no longer applies; see $CUSTOM_DIR/patches/$rel.patch"; fi ;;
            added)
                mkdir -p "$(dirname "$NEW/$rel")"; cp -a "$CUSTOM_DIR/added/$rel" "$NEW/$rel"; say "  carried over $rel (added here)" ;;
            *) say "  NOT carried: your change to $rel ($what); see $CUSTOM_DIR/patches/$rel.patch" ;;
        esac
    done < <(php -r '$r = json_decode((string)file_get_contents($argv[1]), true);
        foreach ($r["changed"] ?? [] as $p => $w) { echo $w["status"], "\t", $w["how"] ?? "-", "\t", $p, "\n"; }
        foreach ($r["added"] ?? [] as $p) { echo "added\t-\t", $p, "\n"; }' "$CUSTOM_DIR/report.json")
fi
chown -R "$(stat -c %u:%g "$OE")" "$NEW"
chown -R "$WEBUSER" "$NEW/sites"
copied="$(find "$NEW/sites" -not -type d | wc -l)"
(( copied == on_disk )) || die "the new folder's sites/ has $copied files, the old one $on_disk"
audit "sites/ copied whole into the new folder ($copied files)"

step "7. Upgrading the databases with $TO's sql_upgrade.php --from=$FROM"
failed=0
for site in $SITES; do
    mapfile -t c < <(sqlconf "$OE/sites/$site/sqlconf.php")
    cnf="$(mycnf)"
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
want_db="$(v_database_of "$NEW")"
for site in $SITES; do
    mapfile -t c < <(sqlconf "$NEW/sites/$site/sqlconf.php")
    cnf="$(mycnf)"
    upgraded="$(db_version "$cnf" "${c[4]}")"
    rm -f "$cnf"
    [[ "$upgraded" == "$TO $want_db" ]] || die "$site: after sql_upgrade.php the database says $upgraded, not $TO $want_db"
    audit "$site: ${c[4]} is now $TO, database version $want_db, as the new folder's version.php says"
done

step "8. Checking the new folder with the install doctor"
fetch_tool openemr-doctor.php; dr="$TOOL"
# As the web server's user, since it checks what that user can read and write; from a folder it can read.
drdir="$(mktemp -d)"; chmod 755 "$drdir"; cp "$dr" "$drdir/openemr-doctor.php"; chmod 644 "$drdir/openemr-doctor.php"
doctor_failed=0
for site in $SITES; do
    debug_flag=(); (( ! DEBUG )) || debug_flag=(--debug)
    set +e; as_web php "$drdir/openemr-doctor.php" --openemr="$NEW" --site="$site" ${debug_flag[@]+"${debug_flag[@]}"}; rc=$?; set -e
    (( rc == 0 )) || doctor_failed=1
done
if (( doctor_failed && ! FORCE )); then
    service_do start
    die "the install doctor found a problem in $NEW (above). Nothing is switched yet; fix it and run '$0 --rollback --openemr=$OE' or switch by hand. --force switches anyway."
fi

step "9. Switching to $TO"
if [[ -L "$OE" ]]; then
    target="$(readlink -f "$OE")"; ln -sfn "$NEW" "$OE.tmp-link" && mv -T "$OE.tmp-link" "$OE"
    sed -i "s|^OLD_DIR=.*|OLD_DIR=$target|" "$STATE"
else
    mv "$OE" "$OLD_DIR" && mv "$NEW" "$OE"
fi
sed -i 's/^SWITCHED=0$/SWITCHED=1/' "$STATE"
switched_to="$(version_of "$OE")"
[[ "$switched_to" == "$TO" ]] || die "$OE is $switched_to after the switch, not $TO"
audit "$OE is the $TO folder; the $FROM folder is $OLD_DIR"
service_do start
say ""
say "Done: $OE is OpenEMR $TO. The old folder is $OLD_DIR; the backup is $BACKUP_DIR."
say "Log in and open a patient and a report. If anything is wrong:  $0 --rollback --openemr=$OE"
say "When you're sure, delete $STATE (the rollback needs it), and later the old folder and the backup."
