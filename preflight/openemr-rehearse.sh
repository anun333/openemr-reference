#!/usr/bin/env bash
# Rehearse an OpenEMR upgrade on a copy of the whole site, in Docker, before doing it for real.
#
#   openemr-rehearse.sh --dump=site.sql --sites=sites.tar.gz --from=7.0.3 [--to=8.5.0] [--site=default]
#                       [--db=mariadb:11.8] [--cpus=3] [--memory=6g] [--sample=10] [--out=DIR]
#                       [--no-access-check] [--convert-utf8mb4] [--keep] [--debug]
#
# The live site is never touched: give it a mysqldump of the site's database and its sites/ folder
# (a .tar.gz of it, or the folder itself, which is only read), on any machine with Docker. It
#   1. checks there is room, and says how much the copy needs;
#   2. starts the target release's official image on a database server that release is tested on,
#      which also installs a fresh database of the target release to compare against;
#   3. restores the dump twice (one copy to upgrade, one to keep as it was) and copies sites/ in:
#      documents, encryption keys, the site's own files;
#   4. takes a receipt of the untouched copy (openemr-receipt.php: counts, money totals and checksums,
#      no patient data), runs the target's own sql_upgrade.php --from=<from> on the other, timed, and
#      takes a receipt of the upgraded copy; the two must match, as they must on the live upgrade;
#   5. compares the upgraded copy's tables, columns and indexes with the fresh install;
#   6. runs the install doctor (openemr-doctor.php) on the upgraded copy, as the live upgrade does;
#   7. reads the data back through OpenEMR itself (the access check): logs in, reads every patient
#      through OpenEMR's API with counts per patient that must match the receipt, fetches every
#      document through OpenEMR's document route and checks it against its stored hash, runs the
#      money reports and the balance of every patient against the receipt, and opens a sample of
#      charts in a browser (random patients, the first and last registered, the oldest, the one with
#      the most encounters, some with documents and some with a balance, and one of each kind of
#      encounter form): every page must load without a PHP error;
#   8. prints a report, writes it with the receipts to --out, and deletes everything (--keep leaves
#      the copy running to look around).
#   With --convert-utf8mb4 it also runs openemr-utf8mb4.sql on the upgraded copy before comparing,
#   to rehearse moving a site installed before 6.0.0 off utf8mb3.
#
# Its containers are capped (--cpus, default 3, and --memory, default 6g, shared equally by the
# database, OpenEMR and the browser), so it can run beside the live site without starving it.
# Needs: Docker with compose, and room for the database about four times over plus sites/ twice. Synthetic
# or real data both work; the copy never leaves this machine, the browser talks only to the copy, and
# nothing is sent anywhere. It downloads the official images (OpenEMR, the database, Playwright's
# browser image) and the pinned Playwright package from PyPI. The target must be 8.2.0 or later
# (sql_upgrade.php runs from the command line from 8.2.0).
set -euo pipefail
SCRIPT_VERSION=0.5.4
REFERENCE_BASE="${OPENEMR_REFERENCE_BASE:-https://github.com/anun333/openemr-reference/releases/download/v$SCRIPT_VERSION}"
PLAYWRIGHT_IMAGE=mcr.microsoft.com/playwright/python:v1.63.0-noble
PLAYWRIGHT_PIP=playwright==1.63.0

DUMP="" FROM="" TO="" DB="" KEEP=0 CONVERT=0 DEBUG=0 SITES="" SITE=default CPUS=3 MEMORY=6g SAMPLE=10 OUT="" ACCESS=1
# The facts: this repository's site/preflight when run from a checkout, else the published copy.
FACTS="$(cd "$(dirname "$0")/.." && pwd)/site/preflight"
[[ -f "$FACTS/releases.json" ]] || FACTS=https://raw.githubusercontent.com/anun333/openemr-reference/main/site/preflight
for arg in "$@"; do
    case "$arg" in
        --dump=*) DUMP="${arg#*=}" ;;
        --sites=*) SITES="${arg#*=}" ;;
        --site=*) SITE="${arg#*=}" ;;
        --from=*) FROM="${arg#*=}" ;;
        --to=*) TO="${arg#*=}" ;;
        --db=*) DB="${arg#*=}" ;;
        --facts=*) FACTS="${arg#*=}" ;;
        --cpus=*) CPUS="${arg#*=}" ;;
        --memory=*) MEMORY="${arg#*=}" ;;
        --sample=*) SAMPLE="${arg#*=}" ;;
        --out=*) OUT="${arg#*=}" ;;
        --no-access-check) ACCESS=0 ;;
        --keep) KEEP=1 ;;
        --convert-utf8mb4) CONVERT=1 ;;
        --debug) DEBUG=1 ;;
        -h|--help) awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"; exit 0 ;;
        *) echo "unknown option: $arg (see --help)" >&2; exit 2 ;;
    esac
done
# --debug: trace every command (the copy's database passwords are the throwaway containers' own).
if (( DEBUG )); then PS4='+ openemr-rehearse.sh:${LINENO}: '; set -x; fi
[[ -r "$DUMP" ]] || { echo "--dump=FILE: a mysqldump of the site's database (not found: '$DUMP')" >&2; exit 2; }
[[ "$FROM" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "--from=X.Y.Z: the release the site runs now (Administration > About)" >&2; exit 2; }
[[ -z "$SITES" || -r "$SITES" ]] || { echo "--sites=FILE.tar.gz or DIR: the site's sites/ folder (not found: '$SITES')" >&2; exit 2; }
[[ "$SITE" =~ ^[A-Za-z0-9_.-]+$ ]] || { echo "--site=NAME: the folder under sites/ (default)" >&2; exit 2; }
[[ "$CPUS" =~ ^[0-9]+([.][0-9]+)?$ ]] && awk "BEGIN { exit !($CPUS >= 0.3) }" || { echo "--cpus=N: CPUs for the rehearsal's containers together (at least 0.3)" >&2; exit 2; }
[[ "$MEMORY" =~ ^[0-9]+[mg]$ ]] || { echo "--memory=SIZE: memory for the containers together, like 6g or 3000m" >&2; exit 2; }
[[ "$SAMPLE" =~ ^[0-9]+$ ]] || { echo "--sample=N: how many random patients' charts to open" >&2; exit 2; }
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
# Each container's share of --cpus and --memory: the database, OpenEMR and the browser.
SHARE_CPUS=$(awk "BEGIN { printf \"%.2f\", $CPUS / 3 }")
mem_mb=$(( ${MEMORY%[mg]} * $([[ "$MEMORY" == *g ]] && echo 1024 || echo 1) ))
SHARE_MEM="$(( mem_mb / 3 ))m"

HERE="$(cd "$(dirname "$0")" && pwd)"
sums() { if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi; }
# A helper ($1): the copy beside this script, else downloaded from this script's own release and
# checked against that release's SHA256SUMS. Prints its path.
fetch_tool() {
    if [[ -f "$HERE/$1" ]]; then echo "$HERE/$1"; return 0; fi
    local dir want got
    dir="$(mktemp -d)"
    curl -fsSL "$REFERENCE_BASE/$1" -o "$dir/$1" || { echo "couldn't download $1 from $REFERENCE_BASE" >&2; return 1; }
    curl -fsSL "$REFERENCE_BASE/SHA256SUMS" -o "$dir/SHA256SUMS" || { echo "couldn't download SHA256SUMS from $REFERENCE_BASE" >&2; return 1; }
    want="$(awk -v f="$1" '$2 == f || $2 == "*" f {print $1}' "$dir/SHA256SUMS")"
    got="$(sums "$dir/$1")"
    [[ -n "$want" && "$want" == "$got" ]] || { echo "$1 from $REFERENCE_BASE doesn't match that release's SHA256SUMS (expected ${want:-no entry}, got $got); not running it" >&2; return 1; }
    echo "$dir/$1"
}
RECEIPT_TOOL="$(fetch_tool openemr-receipt.php)" || exit 1
DOCTOR_TOOL="$(fetch_tool openemr-doctor.php)" || exit 1
SCAN_TOOL="$(fetch_tool scan.php 2>/dev/null)" || SCAN_TOOL=""

# The comparison with the fresh install runs inside the target's container (its PHP and mysqli), so
# this machine needs nothing but Docker. It only reads. The data itself is compared by the receipts.
compare_php() { cat <<'PHP'
<?php
$o = getopt('', ['host:', 'upgraded:', 'fresh:', 'upgrade-output:', 'from:', 'to:']);
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
echo "\nSCHEMA VERDICT: $verdict\n";
PHP
}

# The access check's plan, in the target's container: who to open and what to expect, from the
# upgraded copy and its receipt. It only reads.
access_plan_php() { cat <<'PHP'
<?php
$o = getopt('', ['host:', 'database:', 'receipt:', 'sample:', 'seed:', 'base:', 'out:']);
$db = new mysqli($o['host'], 'root', 'root', $o['database']);
$db->set_charset('utf8mb4');
$db->query("SET SESSION sql_mode = ''");
function rows(mysqli $db, string $sql): array
{
    return $db->query($sql)->fetch_all(MYSQLI_ASSOC);
}
$receipt = json_decode((string) file_get_contents($o['receipt']), true);
mt_srand((int) $o['seed']);
$uuid = fn(?string $b): ?string => $b === null || strlen($b) !== 16 ? null : vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($b), 4));
$patients = [];
foreach (rows($db, 'SELECT pid, uuid, DOB, regdate FROM patient_data ORDER BY pid') as $r) {
    $patients[(int) $r['pid']] = ['pid' => (int) $r['pid'], 'uuid' => $uuid($r['uuid'])];
}
$count = function (string $sql) use ($db): array {
    $out = [];
    foreach ($db->query($sql)->fetch_all(MYSQLI_NUM) as [$k, $n]) {
        $out[(int) $k] = (int) $n;
    }
    return $out;
};
// Per patient, the counts the receipt checksums (openemr-receipt.php's perPatient, the same SQL).
$expect = [
    'encounters' => $count('SELECT pid, COUNT(*) FROM form_encounter GROUP BY pid'),
    'appointments' => $count("SELECT pc_pid, COUNT(*) FROM openemr_postcalendar_events WHERE pc_pid IS NOT NULL AND pc_pid NOT IN ('', '0') GROUP BY pc_pid"),
    'prescriptions' => $count('SELECT patient_id, COUNT(*) FROM prescriptions GROUP BY patient_id'),
    'lab_orders' => $count('SELECT patient_id, COUNT(*) FROM procedure_order GROUP BY patient_id'),
];
$balance = $count("SELECT fe.pid, ROUND(SUM(IFNULL(b.amount, 0) + IFNULL(d.amount, 0) - IFNULL(a.pay, 0) - IFNULL(a.adj, 0)) * 100) FROM form_encounter fe JOIN patient_data p ON p.pid = fe.pid LEFT JOIN (SELECT pid, encounter, SUM(fee) AS amount FROM billing WHERE activity = 1 GROUP BY pid, encounter) b ON b.pid = fe.pid AND b.encounter = fe.encounter LEFT JOIN (SELECT pid, encounter, SUM(fee) AS amount FROM drug_sales GROUP BY pid, encounter) d ON d.pid = fe.pid AND d.encounter = fe.encounter LEFT JOIN (SELECT pid, encounter, SUM(pay_amount) AS pay, SUM(adj_amount) AS adj FROM ar_activity WHERE deleted IS NULL GROUP BY pid, encounter) a ON a.pid = fe.pid AND a.encounter = fe.encounter GROUP BY fe.pid");
// The sample: random patients, and the ones a random pick could miss.
$why = [];
$add = function (?int $pid, string $reason) use (&$why, $patients): void {
    if ($pid !== null && isset($patients[$pid])) {
        $why[$pid][] = $reason;
    }
};
$pids = array_keys($patients);
if ($pids) {
    $add(min($pids), 'first registered');
    $add(max($pids), 'last registered');
    $add((int) (rows($db, "SELECT pid FROM patient_data WHERE DOB IS NOT NULL AND DOB > '0000-00-00' ORDER BY DOB, pid LIMIT 1")[0]['pid'] ?? 0) ?: null, 'oldest');
    arsort($expect['encounters']);
    $add(array_key_first($expect['encounters']), 'most encounters');
    $withDocs = array_column(rows($db, 'SELECT DISTINCT foreign_id FROM documents WHERE foreign_id > 0'), 'foreign_id');
    shuffle($withDocs);
    foreach (array_slice($withDocs, 0, 2) as $p) {
        $add((int) $p, 'has documents');
    }
    $owing = array_keys(array_filter($balance));
    shuffle($owing);
    foreach (array_slice($owing, 0, 2) as $p) {
        $add((int) $p, 'has a balance');
    }
    $withLabs = array_keys($expect['lab_orders']);
    shuffle($withLabs);
    foreach (array_slice($withLabs, 0, 1) as $p) {
        $add((int) $p, 'has lab results');
    }
    $withRx = array_keys($expect['prescriptions']);
    shuffle($withRx);
    foreach (array_slice($withRx, 0, 1) as $p) {
        $add((int) $p, 'has prescriptions');
    }
    $random = $pids;
    shuffle($random);
    foreach (array_slice($random, 0, (int) $o['sample']) as $p) {
        $add($p, 'random');
    }
}
$visits = [];
foreach ($why as $pid => $reasons) {
    $enc = rows($db, "SELECT encounter FROM form_encounter WHERE pid = $pid ORDER BY date DESC, encounter DESC LIMIT 1")[0]['encounter'] ?? null;
    $order = rows($db, "SELECT procedure_order_id FROM procedure_order WHERE patient_id = $pid ORDER BY procedure_order_id DESC LIMIT 1")[0]['procedure_order_id'] ?? null;
    $pages = [
        ['dashboard', "interface/patient_file/summary/demographics.php?set_pid=$pid"],
        ['demographics', 'interface/patient_file/summary/demographics_full.php'],
        ['encounter list', 'interface/patient_file/history/encounters.php'],
        ['documents', "controller.php?document&list&patient_id=$pid"],
        ['prescriptions', "controller.php?prescription&list&id=$pid"],
        ['lab results', 'interface/patient_file/summary/labdata.php'],
    ];
    if ($order !== null) {
        $pages[] = ['lab order and its results', "interface/orders/orders_results.php?review=0&orderid=$order"];
    }
    if ($enc !== null) {
        $pages[] = ['latest encounter: open it', "interface/patient_file/encounter/encounter_top.php?set_encounter=$enc"];
        $pages[] = ['latest encounter: every form in it', 'interface/patient_file/encounter/forms.php'];
    }
    $visits[] = ['pid' => $pid, 'why' => array_values(array_unique($reasons)), 'pages' => $pages, 'balance_cents' => $balance[$pid] ?? 0];
}
// One of each kind of encounter form on this site, opened in its own encounter.
foreach (rows($db, 'SELECT formdir, MIN(id) AS id FROM forms WHERE deleted = 0 AND formdir IS NOT NULL AND formdir <> \'\' GROUP BY formdir ORDER BY formdir') as $k) {
    $f = rows($db, 'SELECT pid, encounter, form_id FROM forms WHERE id = ' . (int) $k['id'])[0];
    $dir = $k['formdir'];
    $visits[] = ['pid' => (int) $f['pid'], 'why' => ["a form of the kind '$dir'"], 'balance_cents' => null, 'pages' => [
        ['dashboard', 'interface/patient_file/summary/demographics.php?set_pid=' . (int) $f['pid']],
        ['the encounter', 'interface/patient_file/encounter/encounter_top.php?set_encounter=' . (int) $f['encounter']],
        ["form '$dir'", 'interface/patient_file/encounter/view_form.php?formname=' . rawurlencode($dir) . '&id=' . (int) $f['form_id']],
    ]];
}
$documents = rows($db, "SELECT id, foreign_id AS pid, hash, IFNULL(storagemethod, 0) AS storagemethod, IFNULL(couch_docid, '') AS couch, IFNULL(type, '') AS type, IFNULL(url, '') AS url FROM documents ORDER BY id");
$fmt = (int) (rows($db, "SELECT gl_value FROM globals WHERE gl_name = 'date_display_format'")[0]['gl_value'] ?? 0);
$g = fn(string $n, string $d) => rows($db, "SELECT gl_value FROM globals WHERE gl_name = '$n'")[0]['gl_value'] ?? $d;
file_put_contents($o['out'], json_encode([
    'base' => $o['base'],
    'seed' => (int) $o['seed'],
    'date_format' => $fmt,
    'money' => ['dec' => $g('currency_dec_point', '.'), 'thousands' => $g('currency_thousands_sep', ',')],
    'patients' => array_values($patients),
    'expect' => $expect,
    'digests' => $receipt['per_patient'],
    'visits' => $visits,
    'documents' => array_map(fn($d) => ['id' => (int) $d['id'], 'pid' => (int) $d['pid'], 'hash' => (string) $d['hash'],
        'on_disk' => (int) $d['storagemethod'] !== 1 && $d['couch'] === '' && $d['type'] !== 'web_url' && $d['url'] !== '' && (int) $d['pid'] > 0], $documents),
    'documents_elsewhere' => count(array_filter($documents, fn($d) => (int) $d['pid'] <= 0 || (int) $d['storagemethod'] === 1 || $d['couch'] !== '' || $d['type'] === 'web_url' || $d['url'] === '')),
    'years' => $receipt['by_year'] ?? [],
    'receipt_balance' => $receipt['figures']['balance'] ?? null,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
printf("planned: %d patients through the API, %d documents, %d chart visits (%d patients sampled), %d report years\n",
    count($patients), count($documents), count($visits), count($why), count($receipt['by_year'] ?? []));
PHP
}

# OpenEMR's own balance for every patient (get_patient_balance, as the Billing card's Total Balance
# Due), run with OpenEMR's code on the upgraded copy: the receipt's balances must be the same.
balances_php() { cat <<'PHP'
<?php
$_GET['site'] = 'default';
$ignoreAuth = true;
$sessionAllowWrite = true;
require_once $argv[1] . '/interface/globals.php';
require_once $GLOBALS['srcdir'] . '/patient.inc.php';
$lines = [];
$total = 0;
$res = sqlStatement('SELECT pid FROM patient_data ORDER BY pid');
while ($row = sqlFetchArray($res)) {
    $cents = (int) round((float) get_patient_balance($row['pid'], true) * 100);
    if ($cents !== 0) {
        $lines[(int) $row['pid']] = (int) $row['pid'] . " $cents";
    }
    $total += $cents;
}
ksort($lines);
echo json_encode(['patients' => count($lines), 'sha256' => hash('sha256', implode("\n", $lines)), 'total_cents' => $total]), "\n";
PHP
}

# The browser, in Playwright's image on the copy's own network: it logs in as a temporary user and
# collects what OpenEMR shows. It talks to the copy only; every other address is refused.
browser_py() { cat <<'PY'
import hashlib, json, re, sys, time
from playwright.sync_api import sync_playwright

plan = json.load(open(sys.argv[1]))
user, password, out = sys.argv[2], sys.argv[3], sys.argv[4]
B = plan["base"]
res = {"login": None, "api": {"patients": 0, "errors": [], "counts": {}}, "documents": [], "pages": [], "reports": [],
       "balances": [], "js_errors": [], "phases": []}
# PHP's own messages, as a page shows them when PHP prints errors: read in the page's text, not its
# source, where scripts carry strings such as alert('Uncaught Error.').
MARKERS = re.compile(r"(Fatal error: |Parse error: |Uncaught (Error|Exception|TypeError|ValueError)[: ]|Stack trace:|^Warning: .* on line |^Deprecated: .* on line )", re.M)


def phase(name, t0):
    res["phases"].append([name, t0, time.time()])


def date(y, m, d):
    return {0: f"{y}-{m:02d}-{d:02d}", 1: f"{m:02d}/{d:02d}/{y}", 2: f"{d:02d}/{m:02d}/{y}"}.get(plan["date_format"], f"{y}-{m:02d}-{d:02d}")


def money(text):
    t = (text or "").replace(plan["money"]["thousands"], "").replace(plan["money"]["dec"], ".") if plan["money"]["thousands"] else (text or "")
    m = re.search(r"-?\(?\d+(\.\d+)?\)?", t.replace(" ", ""))
    if not m:
        return None
    v = m.group(0)
    neg = v.startswith("(") or v.startswith("-")
    return round((-1 if neg else 1) * float(v.strip("()-")), 2)


with sync_playwright() as p:
    browser = p.chromium.launch()
    ctx = browser.new_context(viewport={"width": 1400, "height": 900})
    ctx.route("**/*", lambda r: r.continue_() if r.request.url.startswith(B) else r.abort())
    page = ctx.new_page()
    page.on("pageerror", lambda e: res["js_errors"].append([page.url, str(e)[:200]]))
    t0 = time.time()
    page.goto(f"{B}/interface/login/login.php?site=default", timeout=120000)
    page.fill("#authUser", user)
    page.fill("#clearPass", password)
    page.locator("button[type=submit], input[type=submit]").first.click()
    try:
        page.wait_for_url("**/main/tabs/main.php**", timeout=120000)
        res["login"] = "ok"
    except Exception as e:
        res["login"] = f"failed: {str(e)[:200]}"
        json.dump(res, open(out, "w"))
        sys.exit(0)
    token = page.evaluate("typeof api_csrf_token_js === 'undefined' ? '' : api_csrf_token_js")
    phase("login", t0)

    # Every patient, through OpenEMR's API (the local API, with the login's session).
    t0 = time.time()
    h = {"APICSRFTOKEN": token}
    counts = {k: {} for k in ("encounters", "appointments", "prescriptions", "lab_orders")}

    def get(path):
        r = ctx.request.get(B + path, headers=h, timeout=120000)
        try:
            body = r.json()
        except Exception:
            body = None
        return r.status, body

    def listed(body):
        if isinstance(body, dict):
            body = body.get("data", [])
        return body if isinstance(body, list) else None

    for pt in plan["patients"]:
        pid, uuid = pt["pid"], pt["uuid"]
        if not uuid:
            res["api"]["errors"].append([pid, "patient", "no FHIR id (uuid): the API can't name this patient"])
            continue
        st, body = get(f"/apis/default/api/patient/{uuid}")
        rec = body.get("data") if isinstance(body, dict) else None
        if st != 200 or not isinstance(rec, dict) or int(rec.get("pid", -1)) != pid:
            res["api"]["errors"].append([pid, "patient", f"HTTP {st}"])
            continue
        res["api"]["patients"] += 1
        for kind, path in (("encounters", f"/apis/default/api/patient/{uuid}/encounter"),
                           ("appointments", f"/apis/default/api/patient/{pid}/appointment"),
                           ("prescriptions", f"/apis/default/api/prescription?patient_uuid={uuid}")):
            st, body = get(path)
            items = listed(body)
            if st == 404 or (st == 400 and kind != "prescriptions"):
                items = []
            if st not in (200, 404) or items is None:
                res["api"]["errors"].append([pid, kind, f"HTTP {st}"])
                continue
            if items:
                counts[kind][pid] = len(items)
    st, body = get("/apis/default/api/procedure")
    items = listed(body)
    if st != 200 or items is None:
        res["api"]["errors"].append([0, "lab_orders", f"HTTP {st}"])
    else:
        for it in items:
            k = int(it.get("patient_id") or 0)
            counts["lab_orders"][k] = counts["lab_orders"].get(k, 0) + 1
    res["api"]["counts"] = {k: {str(a): b for a, b in v.items()} for k, v in counts.items()}
    phase("API reads", t0)

    # Every document, through OpenEMR's document route, against the hash OpenEMR stored.
    t0 = time.time()
    for d in plan["documents"]:
        if not d["on_disk"]:
            continue
        r = ctx.request.get(f"{B}/controller.php?document&retrieve&patient_id={d['pid']}&document_id={d['id']}&as_file=false&original_file=true&disable_exit=false&show_original=true", timeout=120000)
        body = r.body()
        stored = d["hash"] or ""
        got = hashlib.sha1(body).hexdigest() if 0 < len(stored) < 50 else hashlib.sha3_512(body).hexdigest()
        res["documents"].append({"id": d["id"], "pid": d["pid"], "status": r.status, "bytes": len(body), "stored_hash": bool(stored),
                                 "matches": (got == stored) if stored else None})
    phase("document fetches", t0)

    # Charts, page by page.
    for v in plan["visits"]:
        for name, url in v["pages"]:
            t0 = time.time()
            entry = {"pid": v["pid"], "why": v["why"], "page": name, "url": url}
            try:
                resp = page.goto(f"{B}/{url}", wait_until="load", timeout=90000)
                entry["status"] = resp.status if resp else 0
                text = page.evaluate("() => document.body ? document.body.innerText : ''")
                m = MARKERS.search(text or "")
                entry["marker"] = m.group(0) if m else None
                if name == "dashboard" and v.get("balance_cents") is not None:
                    # The Billing card: a label cell "Total Balance Due" and the amount in the next cell.
                    text = page.evaluate("""() => { const l = [...document.querySelectorAll('div')].find(e => e.children.length === 0 && e.textContent.trim() === 'Total Balance Due');
                                                    return l && l.nextElementSibling ? l.nextElementSibling.textContent : null; }""")
                    res["balances"].append({"pid": v["pid"], "shown": money(text) if text is not None else None, "expected": v["balance_cents"] / 100})
            except Exception as e:
                entry["status"] = 0
                entry["error"] = str(e)[:200]
            entry["t0"], entry["t1"] = t0, time.time()
            res["pages"].append(entry)

    # The money reports: Receipts by Payment Method for each year, by payment date.
    for y in plan["years"]:
        t0 = time.time()
        entry = {"year": y}
        try:
            page.goto(f"{B}/interface/reports/receipts_by_method_report.php", wait_until="load", timeout=90000)
            page.fill("#form_from_date", date(int(y), 1, 1))
            page.fill("#form_to_date", date(int(y), 12, 31))
            page.select_option("#form_report_by", "2")
            page.select_option("select[name=form_use_edate]", "0")
            with page.expect_navigation(timeout=120000) as nav:
                page.evaluate("document.getElementById('form_refresh').value = 'true'; document.getElementById('theform').submit();")
            status = nav.value.status if nav.value else 0
            if status >= 400:
                entry["error"] = f"HTTP {status}: the report stopped with an error"
            else:
                cells = page.locator("tr.table-info").last.locator("td")
                entry["adjustments"] = money(cells.nth(1).inner_text(timeout=30000))
                entry["receipts"] = money(cells.nth(2).inner_text(timeout=30000))
        except Exception as e:
            entry["error"] = str(e).splitlines()[0][:200]
        entry["t0"], entry["t1"] = t0, time.time()
        res["reports"].append(entry)
    browser.close()
json.dump(res, open(out, "w"))
PY
}

# The access check's report, in the target's container: what the browser saw against the plan and
# the receipt, with the PHP errors OpenEMR logged while each page loaded. Prints PASS or FAIL.
access_report_php() { cat <<'PHP'
<?php
[, $planFile, $resFile, $balFile, $logFile] = $argv;
$plan = json_decode((string) file_get_contents($planFile), true);
$res = json_decode((string) file_get_contents($resFile), true);
$bal = json_decode((string) @file_get_contents($balFile), true);
$fail = [];
$notes = [];
$t = [];
if (($res['login'] ?? '') !== 'ok') {
    echo "  FAIL couldn't log in to the upgraded copy: " . ($res['login'] ?? 'no result') . "\nACCESS: FAIL\n";
    exit(1);
}
$t[] = '  ok   logged in to the upgraded copy (a temporary administrator, removed afterwards)';

// PHP errors OpenEMR logged, matched to what was loading when they were logged.
$windows = [];
foreach ($res['phases'] as [$name, $a, $b]) {
    $windows[] = [$name, $a, $b];
}
foreach ($res['pages'] as $p) {
    $windows[] = ["patient {$p['pid']}: {$p['page']}", $p['t0'], $p['t1']];
}
foreach ($res['reports'] as $r) {
    $windows[] = ["Receipts by Payment Method {$r['year']}", $r['t0'], $r['t1']];
}
$errors = [];
$warnings = [];
foreach (file($logFile) ?: [] as $line) {
    if (!preg_match('/^(\S+)\s.*?(PHP (Fatal error|Parse error|Warning|Deprecated|Notice|Recoverable fatal error)|Uncaught)/', $line, $m)) {
        continue;
    }
    // The page that was loading: the one that started last before the line was logged (one at a time).
    $when = (float) strtotime(preg_replace('/\.\d+Z$/', 'Z', $m[1])) + (preg_match('/\.(\d+)Z$/', $m[1], $f) ? (float) ('0.' . $f[1]) : 0.0);
    $where = 'before the first page';
    $best = -INF;
    foreach ($windows as [$name, $a, $b]) {
        if ($a <= $when && $a > $best) {
            [$best, $where] = [$a, $name];
        }
    }
    $msg = trim(substr(preg_replace('/^.*?(PHP |Uncaught)/', '$1', $line), 0, 240));
    if (preg_match('/Fatal|Parse|Uncaught|Recoverable/', $m[2])) {
        $errors[] = "$where: $msg";
    } else {
        $warnings[$msg] = $where;
    }
}

// 1. Every patient through the API, counts per patient against the receipt.
$api = $res['api'];
$n = count($plan['patients']);
if ($api['patients'] === $n && !$api['errors']) {
    $t[] = "  ok   every patient read through OpenEMR's API: $n of $n";
} else {
    $fail[] = "API: read {$api['patients']} of $n patients";
    foreach (array_slice($api['errors'], 0, 10) as [$pid, $what, $how]) {
        $t[] = "  FAIL API: patient $pid, $what: $how";
    }
}
foreach ($plan['expect'] as $kind => $want) {
    $got = $api['counts'][$kind] ?? [];
    $lines = [];
    foreach ($got as $pid => $c) {
        if ((int) $c !== 0) {
            $lines[(int) $pid] = (int) $pid . ' ' . (int) $c;
        }
    }
    ksort($lines);
    $digest = hash('sha256', implode("\n", $lines));
    $wrong = [];
    foreach (array_unique(array_merge(array_keys($want), array_map('intval', array_keys($got)))) as $pid) {
        if (($want[$pid] ?? 0) !== (int) ($got[$pid] ?? $got[(string) $pid] ?? 0)) {
            $wrong[] = "patient $pid: the API shows " . (int) ($got[$pid] ?? 0) . ', the receipt counts ' . ($want[$pid] ?? 0);
        }
    }
    $label = str_replace('_', ' ', $kind);
    if (!$wrong && $digest === ($plan['digests'][$kind]['sha256'] ?? '')) {
        $t[] = sprintf("  ok   %s per patient: the API's counts match the receipt for all %d patients who have any", $label, count($lines));
    } else {
        $fail[] = "$label per patient differ from the receipt";
        $t[] = "  FAIL $label per patient: " . count($wrong) . ' patients differ from the receipt' . ($wrong ? ' (' . implode('; ', array_slice($wrong, 0, 5)) . ')' : ' (the counts agree, the checksum does not)');
    }
}

// 2. Every document through OpenEMR's document route.
$docs = $res['documents'];
$bad = array_filter($docs, fn($d) => $d['status'] !== 200 || $d['matches'] === false || ($d['matches'] === null && $d['bytes'] === 0));
$unhashed = count(array_filter($docs, fn($d) => $d['matches'] === null && $d['bytes'] > 0));
$onDisk = count(array_filter($plan['documents'], fn($d) => $d['on_disk']));
if (!$docs && $onDisk === 0) {
    $t[] = '  ok   no documents stored on disk to fetch';
} elseif (!$bad && count($docs) === $onDisk) {
    $t[] = "  ok   every document fetched through OpenEMR's document route matches the hash OpenEMR stored: " . count($docs) . ' of ' . $onDisk
        . ($unhashed ? " ($unhashed with no stored hash: read, not compared)" : '');
} else {
    $fail[] = count($bad) . ' documents unreadable or not as stored';
    $t[] = '  FAIL ' . count($bad) . ' of ' . $onDisk . ' documents unreadable or not as stored:';
    foreach (array_slice($bad, 0, 15) as $d) {
        $why = $d['status'] !== 200 ? "HTTP {$d['status']}" : ($d['bytes'] === 0 ? 'OpenEMR returned nothing (the file is missing or unreadable)' : "OpenEMR returned {$d['bytes']} bytes that don't match the hash it stored");
        $t[] = "         document {$d['id']} (patient {$d['pid']}): $why";
    }
}

// 3. Money: the report for each year, and every patient's balance by OpenEMR's own function.
if (!empty($plan['documents_elsewhere'])) {
    $t[] = "  note {$plan['documents_elsewhere']} documents aren't a patient's file on disk (CouchDB, web links, or not filed to a patient): not fetched";
}

foreach ($res['reports'] as $r) {
    $want = $plan['years'][$r['year']] ?? null;
    if (isset($r['error'])) {
        $fail[] = "Receipts by Payment Method {$r['year']} didn't run";
        $t[] = "  FAIL Receipts by Payment Method, {$r['year']}: {$r['error']}";
    } elseif ($want && abs($r['receipts'] - (float) $want['receipts']) < 0.005 && abs($r['adjustments'] - (float) $want['adjustments']) < 0.005) {
        $t[] = sprintf("  ok   Reports > Financial > Receipts by Payment Method, %s (payment date): receipts %s, adjustments %s, as the receipt", $r['year'], number_format($r['receipts'], 2), number_format($r['adjustments'], 2));
    } else {
        $fail[] = "Receipts by Payment Method {$r['year']} differs from the receipt";
        $t[] = sprintf("  FAIL Receipts by Payment Method, %s: the report shows %s / %s, the receipt %s / %s", $r['year'], $r['receipts'] ?? 'n/a', $r['adjustments'] ?? 'n/a', $want['receipts'] ?? 'n/a', $want['adjustments'] ?? 'n/a');
    }
}
if (!is_array($bal)) {
    $fail[] = "OpenEMR's balance function didn't run";
    $t[] = "  FAIL every patient's balance: OpenEMR's get_patient_balance didn't run on the copy";
} elseif ($bal['sha256'] === ($plan['digests']['balance_cents']['sha256'] ?? '') && sprintf('%.2f', $bal['total_cents'] / 100) === sprintf('%.2f', (float) $plan['receipt_balance'])) {
    $t[] = sprintf("  ok   every patient's balance by OpenEMR's own get_patient_balance (the Billing card's Total Balance Due) matches the receipt: %d with a balance, %s in all", $bal['patients'], number_format($bal['total_cents'] / 100, 2));
} else {
    $fail[] = "patients' balances differ from the receipt";
    $t[] = sprintf("  FAIL every patient's balance: OpenEMR's get_patient_balance gives %s in all, the receipt %s, or a patient's differs", number_format($bal['total_cents'] / 100, 2), $plan['receipt_balance']);
}
$shownBad = array_filter($res['balances'], fn($b) => $b['shown'] === null || abs($b['shown'] - $b['expected']) >= 0.005);
if ($res['balances'] && !$shownBad) {
    $t[] = '  ok   the dashboard\'s Billing card shows each sampled patient\'s balance as the receipt has it (' . count($res['balances']) . ' patients)';
} elseif ($shownBad) {
    $fail[] = 'a dashboard balance differs';
    foreach (array_slice($shownBad, 0, 5) as $b) {
        $t[] = "  FAIL patient {$b['pid']}'s dashboard shows Total Balance Due " . ($b['shown'] ?? 'nothing') . ", the receipt {$b['expected']}";
    }
}

// 4. Charts in a browser.
$pages = $res['pages'];
$badPages = array_filter($pages, fn($p) => $p['status'] >= 400 || $p['status'] === 0 || !empty($p['marker']));
$patientsOpened = count(array_unique(array_column($pages, 'pid')));
if (!$badPages && !$errors) {
    $t[] = sprintf('  ok   %d pages of %d patients\' charts opened in a browser without a PHP error', count($pages), $patientsOpened);
} else {
    $fail[] = count($badPages) . ' chart pages failed, ' . count($errors) . ' PHP errors';
    foreach (array_slice($badPages, 0, 15) as $p) {
        $t[] = "  FAIL patient {$p['pid']} ({$p['why'][0]}), {$p['page']}: " . ($p['status'] ? "HTTP {$p['status']}" : ($p['error'] ?? 'no answer')) . (!empty($p['marker']) ? ", the page shows \"{$p['marker']}\"" : '') . "  [{$p['url']}]";
    }
    foreach (array_slice($errors, 0, 15) as $e) {
        $t[] = "  FAIL PHP error while loading $e";
    }
}
$sampled = [];
foreach ($pages as $p) {
    foreach ($p['why'] as $w) {
        $sampled[$w][$p['pid']] = true;
    }
}
$t[] = '       opened: ' . implode('; ', array_map(fn($w) => $w . ' (' . implode(', ', array_keys($sampled[$w])) . ')', array_keys($sampled)));
if ($warnings) {
    $notes[] = count($warnings) . ' PHP warnings';
    $t[] = '  note OpenEMR logged ' . count($warnings) . ' kinds of PHP warning or deprecation while the pages loaded (not errors; the pages loaded):';
    foreach (array_slice($warnings, 0, 8, true) as $msg => $where) {
        $t[] = "         $where: $msg";
    }
}
if ($res['js_errors']) {
    $t[] = '  note ' . count($res['js_errors']) . ' JavaScript errors in the pages (OpenEMR\'s pages are meant to load inside its tabs; a page opened on its own may miss what the tabs provide)';
}
echo implode("\n", $t), "\n";
echo $fail ? 'ACCESS: FAIL (' . implode('; ', $fail) . ")\n" : "ACCESS: PASS\n";
exit($fail ? 1 : 0);
PHP
}

STAMP="$(date +%Y%m%d-%H%M%S)"
P="oe-rehearse-$$"; WORK=$(mktemp -d); OE=/var/www/localhost/htdocs/openemr
OUT="${OUT:-$PWD/openemr-rehearsal-$FROM-to-$TO-$STAMP}"
mkdir -p "$OUT"; chmod 700 "$OUT"
CHECK_USER="oe-rehearsal-check"
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
say() { printf '%s\n' "$*" | tee -a "$OUT/report.txt"; }
: > "$OUT/report.txt"

# 1. Room: the dump restored twice (with indexes, about twice its size each), sites/ unpacked in the
# container and copied into the site, and the images not yet here.
dump_bytes=$(stat -c %s "$DUMP")
sites_bytes=0
if [[ -n "$SITES" && -d "$SITES" ]]; then sites_bytes=$(du -sb "$SITES" | cut -f1)
elif [[ -n "$SITES" ]]; then sites_bytes=$(gzip -dc "$SITES" | wc -c); fi   # gzip -l wraps at 4 GB
images=0
for img in "openemr/openemr:$TO:2700" "$DB:400" "$PLAYWRIGHT_IMAGE:2500"; do
    docker image inspect "${img%:*}" >/dev/null 2>&1 || images=$(( images + ${img##*:} ))
done
need=$(( dump_bytes * 4 + sites_bytes * 2 + images * 1048576 ))
root=$(docker info -f '{{.DockerRootDir}}' 2>/dev/null || echo /var/lib/docker)
free=$(df -PB1 "$root" 2>/dev/null | awk 'NR==2 {print $4}' || echo 0)
say "Rehearsing OpenEMR $FROM -> $TO on $DB with $(basename "$DUMP") ($(( dump_bytes / 1048576 )) MB)${SITES:+ and sites/ from $(basename "$SITES") ($(( sites_bytes / 1048576 )) MB)}"
say "  the copy needs about $(( need / 1048576 )) MB under $root (the database four times over, sites/ twice$( (( images )) && echo ", $images MB of images to download")); $(( free / 1048576 )) MB free"
if (( free > 0 && free < need )); then
    say "STOP: not enough room under $root"; exit 1
fi
say "  capped at $CPUS CPUs and $MEMORY of memory in all ($SHARE_CPUS CPUs and $SHARE_MEM each for the database, OpenEMR and the browser)"
say "  receipts and this report go to $OUT"
[[ -n "$SITES" ]] || say "  NOTE: no --sites: documents and encryption keys aren't in the copy, so documents can't be checked"

cat > "$WORK/compose.yml" <<YML
services:
  mysql:
    image: $DB
    cpus: $SHARE_CPUS
    mem_limit: $SHARE_MEM
    command: ['--character-set-server=utf8mb4', '--max-allowed-packet=1G']
    environment: { MARIADB_ROOT_PASSWORD: root, MYSQL_ROOT_PASSWORD: root }
    healthcheck:
      test: ['CMD-SHELL', 'healthcheck.sh --connect --innodb_initialized 2>/dev/null || mysqladmin ping -uroot -proot --silent']
      interval: 5s
      retries: 60
  openemr:
    image: openemr/openemr:$TO
    cpus: $SHARE_CPUS
    mem_limit: $SHARE_MEM
    environment: { MYSQL_HOST: mysql, MYSQL_ROOT_PASS: root, MYSQL_USER: openemr, MYSQL_PASS: openemr, OE_USER: admin, OE_PASS: rehearsal }
    ports: ['127.0.0.1::80']
    depends_on: { mysql: { condition: service_healthy } }
YML

say "  starting the official image (it installs a fresh $TO database to compare with)..."
docker compose -p "$P" -f "$WORK/compose.yml" pull -q >/dev/null 2>&1 || true
docker compose -p "$P" -f "$WORK/compose.yml" up -d >/dev/null 2>&1
APP="$P-openemr-1" SQL="$P-mysql-1" NET="${P}_default"
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
docker rm -v "$P-pristine" >/dev/null

say "  restoring the dump twice (to upgrade, and to keep as it was)..."
t0=$(date +%s)
for d in rehearsal rehearsal_before; do
    q -e "CREATE DATABASE $d CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci; GRANT ALL ON $d.* TO 'openemr'@'%';"
    q "$d" < "$DUMP"
done
say "  restored in $(( $(date +%s) - t0 )) s"

# sites/: documents, encryption keys and the site's own files, into the copy's site folder. Its
# sqlconf.php stays the copy's own (pointing at the copy's database). The source is only read.
DOCS="$OE/sites/default/documents"
if [[ -n "$SITES" ]]; then
    say "  copying sites/$SITE in (documents, encryption keys, the site's own files)..."
    docker exec "$APP" sh -c 'rm -rf /tmp/site-src && mkdir -p /tmp/site-src'
    if [[ -d "$SITES" ]]; then tar -C "$SITES" -cf - . | docker exec -i "$APP" tar -xf - -C /tmp/site-src
    else docker exec -i "$APP" tar -xzf - -C /tmp/site-src < "$SITES"; fi
    src=$(docker exec "$APP" sh -c "for d in /tmp/site-src/sites/$SITE /tmp/site-src/$SITE /tmp/site-src; do [ -f \"\$d/sqlconf.php\" ] && { echo \"\$d\"; break; }; done")
    [[ -n "$src" ]] || { say "STOP: $SITES has no sites/$SITE/sqlconf.php: give the site's sites/ folder, or name the site with --site="; exit 1; }
    docker exec "$APP" sh -c "cd '$src' && for x in * .[!.]*; do [ -e \"\$x\" ] && [ \"\$x\" != sqlconf.php ] && rm -rf '$OE/sites/default/'\"\$x\" && cp -a \"\$x\" '$OE/sites/default/'; done; chown -R apache:apache '$OE/sites/default'"
    from_n=$(docker exec "$APP" sh -c "find '$src' -not -type d -not -name sqlconf.php | wc -l")
    to_n=$(docker exec "$APP" sh -c "cd '$src' && find . -not -type d -not -name sqlconf.php | while read -r f; do [ -f '$OE/sites/default/'\"\$f\" ] && echo; done | wc -l")
    docker exec "$APP" rm -rf /tmp/site-src
    (( from_n == to_n )) || { say "STOP: sites/$SITE has $from_n files, the copy $to_n"; exit 1; }
    say "  check: sites/$SITE copied whole into the copy ($to_n files)"
fi

# Receipts: the copy as it was, before the upgrade runs (as the live upgrade takes it).
docker cp "$RECEIPT_TOOL" "$APP:/tmp/openemr-receipt.php"
docker exec "$APP" sh -c 'printf root > /tmp/rehearsal-db-pw && chmod 600 /tmp/rehearsal-db-pw'
receipt() {  # $1: database, $2: label, $3: file name, then extra options
    local d="$1" label="$2" name="$3"; shift 3
    docker exec "$APP" php /tmp/openemr-receipt.php --host=mysql --user=root --password-file=/tmp/rehearsal-db-pw --database="$d" \
        ${SITES:+"--documents=$DOCS"} --site="$SITE" --label="$label" --out="/tmp/$name.json" "$@" > "$OUT/$name.txt" \
        || { say "STOP: the receipt of $d didn't finish:"; tail -5 "$OUT/$name.txt"; exit 1; }
    docker cp "$APP:/tmp/$name.json" "$OUT/$name.json"
}
say "  taking the receipt of the copy as it is (before the upgrade)..."
receipt rehearsal_before "the copy before the upgrade" receipt-before

docker exec "$APP" sh -c "cp $OE/sites/default/sqlconf.php /tmp/sqlconf.fresh && sed -i \"s/^\\\$dbase[[:space:]]*=.*/\\\$dbase = 'rehearsal';/\" $OE/sites/default/sqlconf.php"
size() { q -e "SELECT ROUND(SUM(data_length + index_length) / 1048576) FROM information_schema.tables WHERE table_schema='$1'"; }
# What a plain CREATE DATABASE gets on this server: restoring into one that isn't utf8mb4_general_ci
# splits the collations once the upgrade creates tables (openemr/openemr#7784).
plain=$(q -e "CREATE DATABASE rehearsal_probe; SELECT default_collation_name FROM information_schema.schemata WHERE schema_name = 'rehearsal_probe'; DROP DATABASE rehearsal_probe;")
before_mb=$(size rehearsal)

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

say "  taking the receipt of the upgraded copy..."
receipt rehearsal "the copy after the upgrade" receipt-after --against=/tmp/receipt-before.json
set +e; docker exec "$APP" php /tmp/openemr-receipt.php --compare /tmp/receipt-before.json /tmp/receipt-after.json > "$OUT/receipts-compared.txt"; receipts_rc=$?; set -e

# Is the upgraded copy usable? The login page, served from it.
port=$(docker compose -p "$P" -f "$WORK/compose.yml" port openemr 80 | cut -d: -f2)
login=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/interface/login/login.php?site=default" || echo 000)

compare_php | docker exec -i "$APP" sh -c 'cat > /tmp/rehearse-compare.php'
docker cp "$WORK/upgrade.out" "$APP:/tmp/upgrade.out"
docker exec "$APP" php /tmp/rehearse-compare.php --host=mysql --upgraded=rehearsal --fresh=openemr \
    --upgrade-output=/tmp/upgrade.out --from="$FROM" --to="$TO" > "$WORK/schema.txt" || true

# The install doctor on the upgraded copy, as the live upgrade runs it: as the web server's user.
say "  running the install doctor on the upgraded copy..."
docker cp "$DOCTOR_TOOL" "$APP:/tmp/openemr-doctor.php"
[[ -z "$SCAN_TOOL" ]] || docker cp "$SCAN_TOOL" "$APP:/tmp/scan.php"
docker exec "$APP" chmod 644 /tmp/openemr-doctor.php
set +e; docker exec -u apache -e OPENEMR_DOCTOR_NO_UPDATE_CHECK=1 "$APP" php /tmp/openemr-doctor.php --openemr="$OE" --site=default > "$OUT/doctor.txt" 2>&1; doctor_rc=$?; set -e
doctor_fails=$(grep '^FAIL ' "$OUT/doctor.txt" | grep -v '^FAIL  PHP security' || true)

# The access check: OpenEMR itself reads the upgraded copy back.
access_rc=0 access_state=skipped
if (( ACCESS )); then
    say "  reading the data back through OpenEMR (API, documents, money reports, charts in a browser)..."
    pass="$(head -c 18 /dev/urandom | od -An -tx1 | tr -d ' \n')"
    hash="$(docker exec "$APP" php -r 'echo password_hash($argv[1], PASSWORD_DEFAULT);' "$pass")"
    q rehearsal <<SQL
INSERT INTO users (username, password, authorized, active, fname, lname, calendar, see_auth, info) VALUES ('$CHECK_USER', 'NoLongerUsed', 1, 1, 'Rehearsal', 'Check', 0, 1, 'temporary: openemr-rehearse.sh access check');
SET @u = LAST_INSERT_ID();
INSERT INTO users_secure (id, username, password, last_update_password) VALUES (@u, '$CHECK_USER', '$hash', NOW());
INSERT INTO \`groups\` (name, user) VALUES ('Default', '$CHECK_USER');
UPDATE gacl_aro_seq SET id = id + 1;
SET @aro = (SELECT id FROM gacl_aro_seq);
INSERT INTO gacl_aro (id, section_value, value, order_value, name, hidden) VALUES (@aro, 'users', '$CHECK_USER', 10, 'Rehearsal Check', 0);
INSERT INTO gacl_groups_aro_map (group_id, aro_id) SELECT id, @aro FROM gacl_aro_groups WHERE value = 'admin';
SQL
    access_plan_php | docker exec -i "$APP" sh -c 'cat > /tmp/access-plan.php'
    balances_php | docker exec -i "$APP" sh -c 'cat > /tmp/access-balances.php && chmod 644 /tmp/access-balances.php'
    access_report_php | docker exec -i "$APP" sh -c 'cat > /tmp/access-report.php'
    seed=$(( $(date +%s) % 100000 ))
    docker exec "$APP" php /tmp/access-plan.php --host=mysql --database=rehearsal --receipt=/tmp/receipt-after.json --sample="$SAMPLE" \
        --seed="$seed" --base=http://openemr --out=/tmp/access-plan.json > "$WORK/plan.txt"
    docker cp "$APP:/tmp/access-plan.json" "$WORK/plan.json"
    docker exec -u apache "$APP" php /tmp/access-balances.php "$OE" > "$WORK/balances.json" 2> "$WORK/balances.err" || true
    docker cp "$WORK/balances.json" "$APP:/tmp/access-balances.json"
    mkdir -p "$WORK/browser"; browser_py > "$WORK/browser/check.py"; cp "$WORK/plan.json" "$WORK/browser/plan.json"
    since=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    set +e
    docker run --rm --name "$P-browser" --network "$NET" --cpus "$SHARE_CPUS" --memory "$SHARE_MEM" -v "$WORK/browser:/check" -w /tmp \
        "$PLAYWRIGHT_IMAGE" sh -c "pip install -q --break-system-packages '$PLAYWRIGHT_PIP' >/dev/null 2>&1 && python3 /check/check.py /check/plan.json '$CHECK_USER' '$pass' /check/results.json" \
        > "$WORK/browser.out" 2>&1
    brc=$?
    set -e
    docker logs --timestamps --since "$since" "$APP" > "$WORK/php.log" 2>&1 || true
    grep -E 'PHP (Fatal|Parse|Warning|Deprecated|Notice|Recoverable)|Uncaught' "$WORK/php.log" > "$OUT/php-errors.log" || true
    q rehearsal -e "DELETE m FROM gacl_groups_aro_map m JOIN gacl_aro a ON a.id = m.aro_id WHERE a.value = '$CHECK_USER'; DELETE FROM gacl_aro WHERE value = '$CHECK_USER'; DELETE FROM \`groups\` WHERE user = '$CHECK_USER'; DELETE FROM users_secure WHERE username = '$CHECK_USER'; DELETE FROM users WHERE username = '$CHECK_USER';"
    if (( brc != 0 )) || [[ ! -s "$WORK/browser/results.json" ]]; then
        access_rc=1 access_state=failed
        { echo "  FAIL the browser didn't finish (exit $brc):"; tail -5 "$WORK/browser.out" | sed 's/^/       /'; echo "ACCESS: FAIL"; } > "$OUT/access-check.txt"
    else
        docker cp "$WORK/browser/results.json" "$APP:/tmp/access-results.json"
        docker cp "$WORK/php.log" "$APP:/tmp/access-php.log"
        set +e; docker exec "$APP" php /tmp/access-report.php /tmp/access-plan.json /tmp/access-results.json /tmp/access-balances.json /tmp/access-php.log > "$OUT/access-check.txt"; access_rc=$?; set -e
        access_state=$( (( access_rc == 0 )) && echo passed || echo failed )
        cp "$WORK/browser/results.json" "$OUT/access-results.json"
    fi
fi
(( KEEP )) || docker exec "$APP" cp /tmp/sqlconf.fresh "$OE/sites/default/sqlconf.php"

say ""
say "sql_upgrade.php: exit $rc in ${took}s; database now $version; size ${before_mb} MB -> ${after_mb} MB; login page from the upgraded copy: HTTP $login"
grep -v '^SCHEMA VERDICT' "$WORK/schema.txt" | tee -a "$OUT/report.txt"
verdict=$(sed -n 's/^SCHEMA VERDICT: //p' "$WORK/schema.txt")
worse() { case "$verdict:$1" in *:'not ready'|'ready:ready, with notes') verdict="$1" ;; esac; }
[[ -n "$verdict" ]] || verdict='not ready'
say ""
say "Data: receipts of the copy before and after the upgrade (no patient data; in $OUT)"
sed 's/^/  /' "$OUT/receipts-compared.txt" | tee -a "$OUT/report.txt"
if (( receipts_rc != 0 )); then
    worse 'not ready'
    say "  The live upgrade (openemr-upgrade.sh) stops on this and puts everything back: read the DIFF lines before upgrading."
fi
say ""
say "Install doctor on the upgraded copy (exit $doctor_rc; full output: $OUT/doctor.txt)"
grep -E '^(FAIL|WARN) ' "$OUT/doctor.txt" | sed 's/^/  /' | tee -a "$OUT/report.txt" || true
say "  $(grep -cE '^PASS ' "$OUT/doctor.txt" || true) checks pass, $(grep -cE '^FAIL ' "$OUT/doctor.txt" || true) fail, $(grep -cE '^WARN ' "$OUT/doctor.txt" || true) warn"
if [[ -n "$doctor_fails" ]]; then
    worse 'not ready'
    say "  The live upgrade stops before switching on a doctor FAIL (other than PHP security, which is PHP's own update)."
fi
say ""
case "$access_state" in
    skipped)
        say "Access check: left out (--no-access-check)"; worse 'ready, with notes' ;;
    *)
        say "Access check: OpenEMR reads the upgraded copy back (sample seed $seed; $(sed -n 's/^planned: //p' "$WORK/plan.txt"))"
        tee -a "$OUT/report.txt" < "$OUT/access-check.txt"
        (( access_rc == 0 )) || worse 'not ready'
        [[ -n "$SITES" ]] || { say "  NOTE: no --sites, so the copy has no documents folder: documents weren't really checked"; worse 'ready, with notes'; } ;;
esac
say ""
if [[ "$plain" == utf8mb4_general_ci ]]; then
    say "Restoring: this rehearsal created the database CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci, as OpenEMR's installer does; on $DB a plain CREATE DATABASE gets the same."
else
    say "Restoring: this rehearsal created the database CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci, as OpenEMR's installer does. On $DB a plain CREATE DATABASE (or the image's MARIADB_DATABASE) gets $plain instead: do the same as the rehearsal, or the tables the upgrade creates won't match the restored ones (openemr/openemr#7784)."
fi
(( rc == 0 )) && [[ "$login" == 200 ]] || worse 'not ready'
say ""
say "VERDICT: $verdict"
say "Kept in $OUT: this report, the two receipts (.txt and .json) and their comparison, the doctor's output and the access check's"
say "  (none of these holds patient data; php-errors.log, the PHP errors OpenEMR logged during the access check, may quote a record: read it before sending it)."
[[ "$verdict" == ready* ]] && exit 0
exit 1
