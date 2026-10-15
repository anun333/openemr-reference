#!/usr/bin/env bash
# Rehearse an OpenEMR upgrade on a copy of the site's database, in Docker, before doing it for real.
#
#   openemr-rehearse.sh --dump=site.sql --from=7.0.3 [--to=8.4.1] [--db=mariadb:11.8] [--convert-utf8mb4] [--keep] [--debug]
#
# The live site is never touched: give it a mysqldump of the site's database (the same backup
# the upgrade needs anyway), on any machine with Docker. It
#   1. starts the target release's official image on a database server that release is tested on,
#      which also installs a fresh database of the target release to compare against;
#   2. restores the dump twice, once to upgrade and once to keep as it was;
#   3. runs the target release's own sql_upgrade.php --from=<from> on the copy, timed;
#   4. compares the upgraded copy with the fresh install (tables, columns, indexes) and with the
#      untouched copy (row counts and the values of every column), and checks the login page
#      answers from the upgraded copy;
#   5. prints a report and deletes everything (--keep leaves it running to look around).
#   With --convert-utf8mb4 it also runs openemr-utf8mb4.sql on the upgraded copy before comparing,
#   to rehearse moving a site installed before 6.0.0 off utf8mb3.
#
# Needs: Docker with compose, and room for the database about four times over. Synthetic or real
# data both work; the copy never leaves this machine, and nothing is sent anywhere. The target
# must be 8.2.0 or later (sql_upgrade.php runs from the command line from 8.2.0).
set -euo pipefail

DUMP="" FROM="" TO="" DB="" KEEP=0 CONVERT=0 DEBUG=0
# The facts: this repository's site/preflight when run from a checkout, else the published copy.
FACTS="$(cd "$(dirname "$0")/.." && pwd)/site/preflight"
[[ -f "$FACTS/releases.json" ]] || FACTS=https://raw.githubusercontent.com/anun333/openemr-reference/main/site/preflight
for arg in "$@"; do
    case "$arg" in
        --dump=*) DUMP="${arg#*=}" ;;
        --from=*) FROM="${arg#*=}" ;;
        --to=*) TO="${arg#*=}" ;;
        --db=*) DB="${arg#*=}" ;;
        --facts=*) FACTS="${arg#*=}" ;;
        --keep) KEEP=1 ;;
        --convert-utf8mb4) CONVERT=1 ;;
        --debug) DEBUG=1 ;;
        -h|--help) sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $arg (see --help)" >&2; exit 2 ;;
    esac
done
# --debug: trace every command (the copy's database passwords are the throwaway containers' own).
if (( DEBUG )); then PS4='+ openemr-rehearse.sh:${LINENO}: '; set -x; fi
[[ -r "$DUMP" ]] || { echo "--dump=FILE: a mysqldump of the site's database (not found: '$DUMP')" >&2; exit 2; }
[[ "$FROM" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "--from=X.Y.Z: the release the site runs now (Administration > About)" >&2; exit 2; }
command -v docker >/dev/null && docker compose version >/dev/null 2>&1 || { echo "needs Docker with compose" >&2; exit 2; }

fetch() { if [[ "$FACTS" =~ ^https?:// ]]; then curl -fsSL "$FACTS/$1"; else cat "$FACTS/$1"; fi; }
if [[ -z "$TO" ]]; then
    TO=$(fetch releases.json 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1 || true)
    [[ -n "$TO" ]] || { echo "couldn't read the newest release from the facts; pass --to=X.Y.Z" >&2; exit 2; }
fi
IFS=. read -r a b _ <<<"$TO"
(( a > 8 || (a == 8 && b >= 2) )) || { echo "--to must be 8.2.0 or later: earlier sql_upgrade.php doesn't run from the command line" >&2; exit 2; }
if [[ -z "$DB" ]]; then
    # The newest MariaDB the target's own tests run on, from the facts; else a safe default.
    DB=$(fetch "$TO.json" 2>/dev/null | tr -d '\n ' | grep -oE '\["mariadb","[0-9.]+"\]' | grep -oE '[0-9]+\.[0-9]+' | sort -V | tail -1 || true)
    DB="mariadb:${DB:-11.8}"
fi

# The comparison runs inside the target's container (its PHP and mysqli), so this machine needs
# nothing but Docker. It only reads.
compare_php() { cat <<'PHP'
<?php
$o = getopt('', ['host:', 'upgraded:', 'before:', 'fresh:', 'upgrade-output:', 'from:', 'to:']);
$db = new mysqli($o['host'], 'root', 'root');
$db->set_charset('utf8mb4');
function rows(mysqli $db, string $sql): array
{
    return $db->query($sql)->fetch_all(MYSQLI_NUM);
}
$verdict = 'ready';
function worse(string $to): void
{
    global $verdict;
    $order = ['ready' => 0, 'ready, with notes' => 1, 'not ready' => 2];
    if ($order[$to] > $order[$verdict]) {
        $verdict = $to;
    }
}

// 1. What sql_upgrade.php said.
$text = preg_replace(['#<script.*?</script>#s', '#<[^>]+>#'], ' ', (string) file_get_contents($o['upgrade-output']));
preg_match_all('/The above statement failed:\s*(.*?)\s*Upgrading will continue/s', $text, $m);
preg_match_all('/PHP (?:Fatal error|Parse error):[^\n]*|Uncaught [^\n]*/', $text, $fatal);
printf("Upgrade: %d statements failed and were skipped; %d PHP fatal errors\n", count($m[1]), count($fatal[0]));
foreach (array_slice(array_merge($m[1], $fatal[0]), 0, 10) as $e) {
    echo '  ' . substr(preg_replace('/\s+/', ' ', $e), 0, 200) . "\n";
}
if ($m[1] || $fatal[0]) {
    worse('not ready');
}

// 2. Schema: the upgraded copy against a fresh install of the target.
function schema(mysqli $db, string $s): array
{
    $out = ['table' => [], 'column' => [], 'index' => []];
    foreach (rows($db, "SELECT table_name, engine, table_collation FROM information_schema.tables WHERE table_schema = '$s' AND table_type = 'BASE TABLE'") as $r) {
        $out['table'][$r[0]] = "$r[1] $r[2]";
    }
    foreach (rows($db, "SELECT table_name, column_name, column_type, is_nullable, IFNULL(column_default, '<none>'), extra, IFNULL(collation_name, '') FROM information_schema.columns WHERE table_schema = '$s'") as $r) {
        $out['column']["$r[0].$r[1]"] = "$r[2] null=$r[3] default=$r[4] $r[5] $r[6]";
    }
    foreach (rows($db, "SELECT table_name, index_name, MIN(non_unique), GROUP_CONCAT(column_name, IFNULL(CONCAT('(', sub_part, ')'), '') ORDER BY seq_in_index) FROM information_schema.statistics WHERE table_schema = '$s' GROUP BY table_name, index_name") as $r) {
        $out['index']["$r[0].$r[1]"] = ($r[2] ? '' : 'unique ') . $r[3];
    }
    return $out;
}
$f = schema($db, $o['fresh']);
$u = schema($db, $o['upgraded']);
$diffs = [];
foreach ($f as $kind => $fresh) {
    foreach (array_diff_key($fresh, $u[$kind]) as $name => $v) {
        $diffs[] = [$kind, $name, 'missing', $v, ''];
    }
    foreach (array_diff_key($u[$kind], $fresh) as $name => $v) {
        $diffs[] = [$kind, $name, 'extra', '', $v];
    }
    foreach (array_intersect_key($fresh, $u[$kind]) as $name => $v) {
        if ($v !== $u[$kind][$name]) {
            $diffs[] = [$kind, $name, 'differs', $v, $u[$kind][$name]];
        }
    }
}
$extraTables = array_keys(array_diff_key($u['table'], $f['table']));
// Each known difference: what it is, which sites have it, and what it means. Measured by upgrading
// fresh and real installs of 5.0.2 to 8.5.0-dev (anun333/openemr-reference, 2026-10).
$known = [
    'utf8mb3' => ['note', 'tables and text columns still in the old utf8 (utf8mb3)', 'sites installed before 6.0.0: no upgrade converts them. OpenEMR connects as utf8mb4, so emoji and other 4-byte characters typed into these columns are saved as "?" without an error. openemr-utf8mb4.sql converts them, keeping column types; rehearse it with --convert-utf8mb4.'],
    'collation-mix' => ['note', 'tables in another utf8mb4 collation than a fresh install', "the dump was restored into a database created with the new server's default collation. Comparing text across tables in two collations can fail with \"Illegal mix of collations\" (openemr/openemr#7784): create the database with COLLATE utf8mb4_general_ci and restore again."],
    'timestamps' => ['ok', 'timestamp columns with the old server\'s defaults', 'set by the database server the site was installed on (explicit_defaults_for_timestamp off before MariaDB 10.10); harmless.'],
    'contact_address' => ['ok', 'contact_address lacks created_by, updated_date, updated_by', 'every site from before 7.0.4: a guard in the 7.0.3-to-7.0.4 script skips them. No code uses them yet.'],
    'specimen' => ['ok', 'procedure_order lacks the index idx_specimen_type', 'sites from 7.0.3 or earlier; slower searches by specimen type only.'],
    'drug_sales' => ['ok', 'drug_sales: the uuid index is named uuid_unique', 'sites from 7.0.3 or earlier; same index, another name.'],
    'leftover' => ['ok', 'tables or indexes a fresh install no longer has', 'created along the upgrade path and never dropped; harmless. A leftover table may hold old data: keep it.'],
    'vitals' => ['ok', 'form_vitals measurements default to NULL, not 0', 'sites from 6.1.0 or earlier (the 7.0.0 conversion); an unrecorded measurement reads NULL instead of 0.'],
    'facility' => ['ok', 'facility flags default to 0, not 1', 'sites from before 6.0.0; affects only facilities added without those fields set.'],
];
$classify = function (array $d) use ($extraTables): ?string {
    [$kind, $name, $how, $fresh, $up] = $d;
    $table = explode('.', $name)[0];
    if (preg_match('/ utf8(mb3)?_/', " $up") && !preg_match('/ utf8(mb3)?_/', " $fresh")) {
        return 'utf8mb3';
    }
    if ($how === 'differs' && preg_match('/utf8mb4_(?!general_ci)\w+/', $up) && str_contains($fresh, 'utf8mb4_general_ci')) {
        return 'collation-mix';
    }
    if (in_array($table, $extraTables, true) || in_array($name, ['medex_outgoing.i_msg_date', 'medex_recalls.i_eventDate', 'openemr_postcalendar_events.index_pcid'], true)) {
        return 'leftover';
    }
    if ($kind === 'column' && $how === 'differs' && str_starts_with($fresh, 'timestamp') && str_starts_with($up, 'timestamp')) {
        return 'timestamps';
    }
    if ($kind === 'column' && $how === 'missing' && in_array($name, ['contact_address.created_by', 'contact_address.updated_date', 'contact_address.updated_by'], true)) {
        return 'contact_address';
    }
    if ($name === 'procedure_order.idx_specimen_type' && $how === 'missing') {
        return 'specimen';
    }
    if (in_array($name, ['drug_sales.uuid', 'drug_sales.uuid_unique'], true)) {
        return 'drug_sales';
    }
    if ($table === 'form_vitals' && $how === 'differs' && str_contains($up, 'default=NULL') && preg_match('/default=0\.0*/', $fresh)) {
        return 'vitals';
    }
    if ($table === 'facility' && $how === 'differs' && str_contains($fresh, 'default=1') && str_contains($up, 'default=0')) {
        return 'facility';
    }
    return null;
};
$groups = [];
$unexpected = [];
foreach ($diffs as $d) {
    $k = $classify($d);
    if ($k === null) {
        $unexpected[] = $d;
    } else {
        $groups[$k][] = $d;
    }
}
printf("\nSchema against a fresh %s install: %d differences, %d of them not known\n", $o['to'], count($diffs), count($unexpected));
foreach ($known as $k => [$level, $what, $why]) {
    if (!empty($groups[$k])) {
        printf("  %-4s %4d  %s: %s\n", $level === 'ok' ? 'ok' : 'NOTE', count($groups[$k]), $what, $why);
        if ($level === 'note') {
            worse('ready, with notes');
        }
    }
}
foreach (array_slice($unexpected, 0, 30) as [$kind, $name, $how, $fresh, $up]) {
    printf("  NEW  %s %s %s%s\n", $kind, $name, $how, $how === 'differs' ? ": fresh [$fresh] / upgraded [$up]" : '');
}
if ($unexpected) {
    worse('not ready');
    echo "  Differences not known from earlier rehearsals: read them before upgrading the live site.\n";
}

// 3. Data: the upgraded copy against the copy as it was. Patient tables are those with a pid, patient_id or pc_pid column.
$types = function (string $schema) use ($db): array {
    $out = [];
    foreach (rows($db, "SELECT c.table_name, c.column_name, c.data_type, c.column_type, c.numeric_scale FROM information_schema.columns c JOIN information_schema.tables t ON t.table_schema = c.table_schema AND t.table_name = c.table_name AND t.table_type = 'BASE TABLE' WHERE c.table_schema = '$schema' ORDER BY c.ordinal_position") as [$t, $c, $dt, $ct, $scale]) {
        $out[$t][$c] = [$dt, $ct, $scale];
    }
    return $out;
};
$cols = $types($o['before']);
$after = $types($o['upgraded']);
// A column whose type the upgrade changed is compared through a form both types share, so a
// conversion that keeps the value (date -> datetime, float(5,2) -> decimal(12,6)) isn't a change.
$numeric = ['tinyint', 'smallint', 'mediumint', 'int', 'bigint', 'decimal', 'float', 'double'];
$dates = ['date', 'datetime', 'timestamp'];
$expr = function (string $c, array $before, array $now) use ($numeric, $dates): string {
    if ($before[1] !== $now[1] && in_array($before[0], $dates, true) && in_array($now[0], $dates, true)) {
        return "DATE_FORMAT(`$c`, '%Y-%m-%d %H:%i:%s')";
    }
    if ($before[1] !== $now[1] && in_array($before[0], $numeric, true) && in_array($now[0], $numeric, true)) {
        $scale = $before[2] === null || (int) $before[2] > 10 ? 4 : (int) $before[2];
        return "CAST(ROUND(`$c`, $scale) AS DECIMAL(40, $scale))";
    }
    return "CAST(`$c` AS CHAR CHARACTER SET utf8mb4)";
};
// Per table: all rows, rows of a patient (a patient column other than 0: 0 holds site-wide rows,
// such as clinical_rules), then one checksum per shared column. Tables name the patient pid,
// patient_id (immunizations, prescriptions, procedure_order, claims...) or pc_pid (the calendar).
$patientColumn = fn(array $columns): ?string => array_values(array_intersect(['pid', 'patient_id', 'pc_pid'], array_keys($columns)))[0] ?? null;
$sums = function (string $s, string $t, array $shared, ?string $pidColumn) use ($db, $cols, $after, $expr): array {
    $parts = array_map(fn($c) => "IFNULL(SUM(CRC32(IFNULL(" . $expr($c, $cols[$t][$c], $after[$t][$c]) . ", '\\0null'))), 0)", $shared);
    $patientRows = $pidColumn ? "SUM(IFNULL(`$pidColumn`, 0) <> 0)" : '0';
    return rows($db, "SELECT COUNT(*), IFNULL($patientRows, 0)" . ($parts ? ', ' . implode(', ', $parts) : '') . " FROM `$s`.`$t`")[0];
};
$patient = ['lost' => [], 'changed' => [], 'added' => [], 'tables' => 0, 'rows' => 0];
$other = ['lost' => [], 'changed' => 0, 'added' => 0];
$dropped = [];
foreach ($cols as $t => $columns) {
    $pidColumn = $patientColumn($columns);
    $isPatient = $pidColumn !== null;
    if (!isset($after[$t])) {
        $n = (int) rows($db, "SELECT COUNT(*) FROM `{$o['before']}`.`$t`")[0][0];
        if ($n) {
            $dropped[] = "$t ($n rows)";
            if ($isPatient) {
                worse('not ready');
            }
        }
        continue;
    }
    $shared = array_values(array_intersect(array_keys($columns), array_keys($after[$t])));
    $b = $sums($o['before'], $t, $shared, $pidColumn);
    $a = $sums($o['upgraded'], $t, $shared, $pidColumn);
    if ($isPatient) {
        $patient['tables']++;
        $patient['rows'] += (int) $b[1];
        if ((int) $a[1] < (int) $b[1]) {
            $patient['lost'][] = "$t: $b[1] -> $a[1]";
            worse('not ready');
        } elseif ((int) $a[1] > (int) $b[1]) {
            $patient['added'][] = "$t: $b[1] -> $a[1]";
        }
    }
    $site = [(int) $b[0] - (int) $b[1], (int) $a[0] - (int) $a[1]];
    if ($site[1] < $site[0]) {
        $other['lost'][$t] = "$t: $site[0] -> $site[1]";
    } elseif ($site[1] > $site[0]) {
        $other['added']++;
    }
    if ($a[0] === $b[0] && $a[1] === $b[1]) {
        $moved = [];
        foreach ($shared as $i => $c) {
            if ($a[$i + 2] !== $b[$i + 2]) {
                $moved[] = $c;
            }
        }
        if ($moved && $isPatient) {
            $patient['changed'][$t] = $moved;
        } elseif ($moved) {
            $other['changed']++;
        }
    }
}
// Changes the upgrade scripts make on purpose, measured on rehearsals from 7.0.3 with synthetic patients.
$knownChanges = [
    'patient_data' => [['last_updated'], 'the 7.0.4 script updates every patient (sex_identified, interpreter_needed), so last_updated, and with it FHIR meta.lastUpdated and _lastUpdated searches, show the upgrade time'],
    'document_templates' => [['send_date', 'end_date'], '8.1.0 replaces zero dates: send_date becomes the upgrade time, end_date NULL'],
];
// patient_data changes that depend on what the site holds: listed when present, with their cause.
$knownValues = [
    'patient_data.ethnicity' => "8.1.0 corrects the misspelled code 'declne_to_specfy' to 'decline_to_specify' (also in race and language)",
];
$knownRemovals = [
    'uuid_registry' => '7.0.4 retires the FHIR ids of four vital-sign Observations (the two blood pressure parts, inhaled oxygen flow and concentration); a client that stored them looks them up again',
    'uuid_mapping' => 'the mappings of those retired vital-sign Observation ids (7.0.4)',
];
printf("\nData against the copy before the upgrade: %d patient tables, %d rows\n", $patient['tables'], $patient['rows']);
printf("  patient rows lost: %s\n", $patient['lost'] ? implode('; ', $patient['lost']) : 'none');
printf("  patient rows added by the upgrade: %s\n", $patient['added'] ? implode('; ', $patient['added']) : 'none');
printf("  tables dropped that held rows: %s\n", $dropped ? implode('; ', $dropped) : 'none');
foreach ($patient['changed'] as $t => $moved) {
    foreach ($moved as $i => $c) {
        if (isset($knownValues["$t.$c"])) {
            printf("  ok   %s.%s changed: %s.\n", $t, $c, $knownValues["$t.$c"]);
            unset($moved[$i]);
        }
    }
    if (!$moved) {
        continue;
    }
    if (isset($knownChanges[$t]) && !array_diff($moved, $knownChanges[$t][0])) {
        printf("  ok   %s (%s) changed: %s.\n", $t, implode(', ', $moved), $knownChanges[$t][1]);
    } else {
        printf("  NOTE %s (%s) changed by the upgrade, and not explained here: compare a few rows in the two copies (--keep) before upgrading.\n", $t, implode(', ', $moved));
        worse('ready, with notes');
    }
}
foreach ($other['lost'] as $t => $line) {
    printf("  %s rows removed from %s%s\n", isset($knownRemovals[$t]) ? 'ok  ' : 'NOTE', $line, isset($knownRemovals[$t]) ? ": {$knownRemovals[$t]}." : ' (settings or lists).');
}
printf("  settings and lists: %d tables gained rows, %d changed in place\n", $other['added'], $other['changed']);

echo "\nVERDICT: $verdict\n";
PHP
}

P="oe-rehearse-$$"; WORK=$(mktemp -d); OE=/var/www/localhost/htdocs/openemr
cleanup() {
    if (( KEEP )); then
        echo; echo "Left running (--keep): project $P. Browse with: docker compose -p $P -f $WORK/compose.yml port openemr 80"
        echo "Delete with:  docker compose -p $P -f $WORK/compose.yml down -v && rm -r $WORK"
    else
        docker compose -p "$P" -f "$WORK/compose.yml" down -v >/dev/null 2>&1 || true
        rm -rf "$WORK"
    fi
}
trap cleanup EXIT

need=$(( $(stat -c %s "$DUMP") * 4 ))
root=$(docker info -f '{{.DockerRootDir}}' 2>/dev/null || echo /var/lib/docker)
free=$(df -PB1 "$root" 2>/dev/null | awk 'NR==2 {print $4}' || echo 0)
if (( free > 0 && free < need )); then
    echo "not enough room under $root: about $((need / 1048576)) MB needed, $((free / 1048576)) MB free" >&2; exit 1
fi

cat > "$WORK/compose.yml" <<YML
services:
  mysql:
    image: $DB
    command: ['--character-set-server=utf8mb4', '--max-allowed-packet=1G']
    environment: { MARIADB_ROOT_PASSWORD: root, MYSQL_ROOT_PASSWORD: root }
    healthcheck:
      test: ['CMD-SHELL', 'healthcheck.sh --connect --innodb_initialized 2>/dev/null || mysqladmin ping -uroot -proot --silent']
      interval: 5s
      retries: 60
  openemr:
    image: openemr/openemr:$TO
    environment: { MYSQL_HOST: mysql, MYSQL_ROOT_PASS: root, MYSQL_USER: openemr, MYSQL_PASS: openemr, OE_USER: admin, OE_PASS: rehearsal }
    ports: ['127.0.0.1::80']
    depends_on: { mysql: { condition: service_healthy } }
YML

say() { printf '%s\n' "$*"; }
say "Rehearsing OpenEMR $FROM -> $TO on $DB with $(basename "$DUMP") ($(( $(stat -c %s "$DUMP") / 1048576 )) MB)"
say "  starting the official image (it installs a fresh $TO database to compare with)..."
docker compose -p "$P" -f "$WORK/compose.yml" pull -q >/dev/null 2>&1 || true
docker compose -p "$P" -f "$WORK/compose.yml" up -d >/dev/null 2>&1
APP="$P-openemr-1" SQL="$P-mysql-1"
for _ in $(seq 1 150); do docker logs "$APP" 2>&1 | grep -qE "Starting Apache|Fatal error" && break; sleep 6; done
docker exec "$SQL" sh -c 'command -v mariadb >/dev/null && echo mariadb || echo mysql' > "$WORK/client"
CLIENT=$(cat "$WORK/client")
q() { docker exec -i "$SQL" "$CLIENT" -uroot -proot -N -B "$@"; }
[[ "$(q -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='openemr'")" -gt 200 ]] \
    || { say "the fresh $TO install didn't finish:"; docker logs "$APP" 2>&1 | tail -5; exit 1; }

# The image deletes sql_upgrade.php and acl_upgrade.php once set up; take them from a pristine copy.
docker create --name "$P-pristine" "openemr/openemr:$TO" >/dev/null
for f in sql_upgrade.php acl_upgrade.php; do
    docker cp "$P-pristine:$OE/$f" "$WORK/$f" && docker cp "$WORK/$f" "$APP:$OE/$f"
done
docker rm "$P-pristine" >/dev/null

say "  restoring the dump twice (to upgrade, and to keep as it was)..."
t0=$(date +%s)
for d in rehearsal rehearsal_before; do
    q -e "CREATE DATABASE $d CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci; GRANT ALL ON $d.* TO 'openemr'@'%';"
    q "$d" < "$DUMP"
done
say "  restored in $(( $(date +%s) - t0 )) s"
size() { q -e "SELECT ROUND(SUM(data_length + index_length) / 1048576) FROM information_schema.tables WHERE table_schema='$1'"; }
# What a plain CREATE DATABASE gets on this server: restoring into one that isn't utf8mb4_general_ci
# splits the collations once the upgrade creates tables (openemr/openemr#7784).
plain=$(q -e "CREATE DATABASE rehearsal_probe; SELECT default_collation_name FROM information_schema.schemata WHERE schema_name = 'rehearsal_probe'; DROP DATABASE rehearsal_probe;")
before_mb=$(size rehearsal)
docker exec "$APP" sh -c "cp $OE/sites/default/sqlconf.php /tmp/sqlconf.fresh && sed -i \"s/^\\\$dbase[[:space:]]*=.*/\\\$dbase = 'rehearsal';/\" $OE/sites/default/sqlconf.php"

say "  running $TO's sql_upgrade.php --from=$FROM on the copy..."
t0=$(date +%s); set +e
docker exec -u apache "$APP" php -d memory_limit=-1 "$OE/sql_upgrade.php" "--from=$FROM" > "$WORK/upgrade.out" 2>&1
rc=$?; set -e; took=$(( $(date +%s) - t0 ))
if (( CONVERT )); then
    conv="$(dirname "$0")/openemr-utf8mb4.sql"
    [[ -f "$conv" ]] || { conv="$WORK/openemr-utf8mb4.sql"; curl -fsSL https://raw.githubusercontent.com/anun333/openemr-reference/main/preflight/openemr-utf8mb4.sql > "$conv"; }
    say "  converting utf8mb3 tables to utf8mb4 on the upgraded copy (--convert-utf8mb4)..."
    t1=$(date +%s)
    q -r rehearsal < "$conv" > "$WORK/convert.sql"
    set +e; q rehearsal < "$WORK/convert.sql" > "$WORK/convert.out" 2>&1; crc=$?; set -e
    say "  converted: $(grep -c . "$WORK/convert.sql" || true) statements in $(( $(date +%s) - t1 ))s, exit $crc$( (( crc )) && echo ": $(tail -c 300 "$WORK/convert.out")")"
fi
after_mb=$(size rehearsal)
version=$(q rehearsal -e "SELECT CONCAT(v_major,'.',v_minor,'.',v_patch,' (database ',v_database,')') FROM version" 2>/dev/null || echo '?')

# Is the upgraded copy usable? The login page, served from it.
port=$(docker compose -p "$P" -f "$WORK/compose.yml" port openemr 80 | cut -d: -f2)
login=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/interface/login/login.php?site=default" || echo 000)

compare_php | docker exec -i "$APP" sh -c 'cat > /tmp/rehearse-compare.php'
docker cp "$WORK/upgrade.out" "$APP:/tmp/upgrade.out"
docker exec "$APP" php /tmp/rehearse-compare.php --host=mysql --upgraded=rehearsal --before=rehearsal_before --fresh=openemr \
    --upgrade-output=/tmp/upgrade.out --from="$FROM" --to="$TO" > "$WORK/report.txt" || true
(( KEEP )) || docker exec "$APP" cp /tmp/sqlconf.fresh "$OE/sites/default/sqlconf.php"

say ""
say "sql_upgrade.php: exit $rc in ${took}s; database now $version; size ${before_mb} MB -> ${after_mb} MB; login page from the upgraded copy: HTTP $login"
cat "$WORK/report.txt"
say ""
if [[ "$plain" == utf8mb4_general_ci ]]; then
    say "Restoring: this rehearsal created the database CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci, as OpenEMR's installer does; on $DB a plain CREATE DATABASE gets the same."
else
    say "Restoring: this rehearsal created the database CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci, as OpenEMR's installer does. On $DB a plain CREATE DATABASE (or the image's MARIADB_DATABASE) gets $plain instead: do the same as the rehearsal, or the tables the upgrade creates won't match the restored ones (openemr/openemr#7784)."
fi
grep -q '^VERDICT: ready' "$WORK/report.txt" && (( rc == 0 )) && [[ "$login" == 200 ]] && exit 0
exit 1
