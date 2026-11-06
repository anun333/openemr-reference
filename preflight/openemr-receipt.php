<?php

/**
 * OpenEMR receipt: what a site holds, as counts, money totals and checksums, so that two moments
 * (before and after an upgrade, a copy and its source) can be shown to hold the same data.
 *
 *     php openemr-receipt.php --openemr=/var/www/html/openemr [--site=default] [--out=FILE.json] [--label=TEXT] [--against=FIRST.json]
 *     php openemr-receipt.php --compare [--strict] FIRST.json SECOND.json
 *
 * It only reads. A receipt holds no patient data: no names, no dates of birth, no values from any
 * record. It holds counts, money totals, and checksums of each table and column, from which nothing
 * about a patient can be read back. It is safe to send to someone helping with the upgrade.
 *
 * It has three parts:
 *   - a header: the site, the OpenEMR version of the files and of the database, the server, when;
 *   - what the clinic has, in plain words: patients, encounters, appointments, prescriptions, lab
 *     orders and results, documents (rows, and the files on disk with their count, bytes and a
 *     checksum), charges, co-pays, drug sales, payments, adjustments, the total balance, and receipts
 *     by year as OpenEMR's Receipts by Payment Method report shows them;
 *   - every table: its rows, the rows of a patient, a checksum of its rows, and one of each column.
 *
 * --against=FIRST.json takes this receipt the way the first was taken, so the two compare even where
 * an upgrade changed a column's type (date to datetime, float to decimal): openemr-upgrade.sh and
 * openemr-rehearse.sh take the second receipt that way.
 *
 * --compare prints MATCH when nothing differs but what the upgrade is known to change, with the
 * explanation for each. Every other difference is listed, and so is any change at all to a figure in
 * "what the clinic has": those are never explained away. Exit code 0 for MATCH, 1 otherwise, 2 for a
 * usage error. --strict (for a database restored from a backup) allows no difference at all: every
 * table the same (rows, row and column checksums, column types and collations), not even what an
 * upgrade is known to change.
 *
 * For openemr-rehearse.sh, which runs it in a container on a database copy:
 *     --host=H --port=P --user=U --password-file=F --database=D --documents=DIR [--openemr=DIR]
 * --require=patients,payments,... exits 1 if any of those figures is zero (the tests' floors).
 *
 * Written for PHP 7.4 and later (it runs on the current install's PHP). openemr-rehearse.sh shares this
 * file's comparison: a rehearsal and an upgrade report the data the same way.
 *
 * @license GPL-3.0-or-later
 */

error_reporting(E_ALL);
ini_set('display_errors', 'stderr');
const RECEIPT_VERSION = '0.5.5';
const RECEIPT_FORMAT = 1;

// What an upgrade is known to change, measured on rehearsals and upgrades of synthetic 7.0.3 sites to
// 8.5.0 (and, for the removals, real installs of 5.0.2, 6.1.0 and 7.0.3). One place, read by the
// receipt (which leaves the volatile columns out of each row checksum and checks each rename exactly)
// and by the comparison. Nothing in "what the clinic has" is ever on this list.
const KNOWN = [
    // Columns an upgrade sets to the time it ran (or clears): left out of the row checksums; when
    // they change, the comparison says why. Nothing else in the table may change with them.
    'volatile' => [
        'patient_data.last_updated' => 'the 7.0.4 script updates every patient (sex_identified, interpreter_needed), so last_updated, and with it FHIR meta.lastUpdated and _lastUpdated searches, show the upgrade time',
        'document_templates.send_date' => '8.1.0 replaces zero dates: send_date becomes the upgrade time',
        'document_templates.end_date' => '8.1.0 replaces zero dates: end_date becomes NULL',
    ],
    // Values an upgrade renames. Proved exactly, not assumed: the first receipt also checksums the
    // column with the rename applied, and that must equal the second receipt's checksum.
    'renamed' => [
        'patient_data.race' => [['declne_to_specfy' => 'decline_to_specify'], "8.1.0 corrects the misspelled code 'declne_to_specfy' to 'decline_to_specify'"],
        'patient_data.language' => [['declne_to_specfy' => 'decline_to_specify'], "8.1.0 corrects the misspelled code 'declne_to_specfy' to 'decline_to_specify'"],
        'patient_data.ethnicity' => [['declne_to_specfy' => 'decline_to_specify'], "8.1.0 corrects the misspelled code 'declne_to_specfy' to 'decline_to_specify'"],
        'openemr_postcalendar_events.pc_endDate' => [['0000-00-00' => null], "8.1.0 and 8.1.1 store a single appointment's empty end date as NULL instead of 0000-00-00 (openemr/openemr#11179, #12518); the appointment itself is unchanged"],
    ],
    // Rows an upgrade removes from tables that aren't a patient's.
    'removals' => [
        'uuid_registry' => '7.0.4 retires the FHIR ids of four vital-sign Observations (the two blood pressure parts, inhaled oxygen flow and concentration); a client that stored them looks them up again',
        'uuid_mapping' => 'the mappings of those retired vital-sign Observation ids (7.0.4)',
    ],
    // Two kinds of column, recognised by what they are rather than listed:
    //  - uuid: every upgrade gives each row without a FHIR id (uuid) one (UuidRegistry's backfill).
    //    Checked: fewer rows are without one, and every uuid that was there is still there (the second
    //    receipt sets aside the ids uuid_registry says were created after the first receipt).
    //  - a timestamp that updates itself when its row is written (ON UPDATE CURRENT_TIMESTAMP): it
    //    shows the upgrade time on the rows the upgrade wrote to. Left out of the row checksums; every
    //    other column of those rows is still compared.
    'uuid' => 'the upgrade gave each row that had no FHIR id (uuid) one; checked: every id that was there is still there, on as many rows',
    'auto_update' => 'updates itself whenever its row is written (ON UPDATE CURRENT_TIMESTAMP), so it shows the upgrade time on the rows the upgrade wrote to; every other column of those rows is compared and the same',
];
// Differences that are never explained away, but whose likely cause can be named.
const CAUSES = [
    'calendar_without_date' => "8.1.0 deletes calendar events with no date (pc_eventDate 0000-00-00): OpenEMR can't show them now. To keep them, give each a date on the live site; or delete them there yourself, knowingly. Then rehearse again",
];
// Tables of a patient: those naming one, as pid, patient_id (immunizations, prescriptions,
// procedure_order, claims, ar_session...) or pc_pid (the calendar). 0 or empty holds site-wide rows.
const PATIENT_COLUMNS = ['pid', 'patient_id', 'pc_pid'];
const NUMERIC_TYPES = ['tinyint', 'smallint', 'mediumint', 'int', 'bigint', 'decimal', 'float', 'double'];
const DATE_TYPES = ['date', 'datetime', 'timestamp'];
const BINARY_TYPES = ['binary', 'varbinary', 'tinyblob', 'blob', 'mediumblob', 'longblob', 'bit'];

// The figures of "what the clinic has", in the order printed. Money is a string with two decimals.
const FIGURES = [
    'patients' => 'Patients',
    'encounters' => 'Encounters (visits)',
    'appointments' => 'Appointments (with a patient)',
    'prescriptions' => 'Prescriptions',
    'lab_orders' => 'Lab orders',
    'lab_results' => 'Lab results',
    'documents' => 'Documents (database rows)',
    'document_files' => 'Document files on disk',
    'document_bytes' => 'Document files: bytes',
    'document_files_missing' => 'Document files missing',
    'document_files_sha256' => 'Document files: checksum',
    'charges' => 'Charges (fee sheet)',
    'copays' => 'Co-pays (billing lines)',
    'drug_sales' => 'Drug sales',
    'payments' => 'Payments',
    'adjustments' => 'Adjustments',
    'balance' => 'Balance (charges and drug sales, less co-pays, payments and adjustments)',
];
const MONEY = ['charges', 'copays', 'drug_sales', 'payments', 'adjustments', 'balance'];

/** Prints to stderr and exits 2. */
function usage(string $why): void
{
    fwrite(STDERR, "$why\nusage: php openemr-receipt.php --openemr=DIR [--site=default] [--out=FILE.json] [--label=TEXT] [--against=FIRST.json]\n"
        . "       php openemr-receipt.php --compare FIRST.json SECOND.json\n");
    exit(2);
}

/** A site's database settings, read the way OpenEMR reads them: by including its sqlconf.php. */
function siteConfig(string $file): array
{
    $sqlconf = [];
    $host = $port = $login = $pass = $dbase = null;
    include $file;
    $c = $sqlconf ?: ['host' => $host, 'port' => $port, 'login' => $login, 'pass' => $pass, 'dbase' => $dbase];
    return ['host' => (string)($c['host'] ?? 'localhost'), 'port' => (int)($c['port'] ?? 0) ?: 3306, 'user' => (string)($c['login'] ?? ''),
        'password' => (string)($c['pass'] ?? ''), 'database' => (string)($c['dbase'] ?? '')];
}

/** Connects as OpenEMR does: over SSL when the site's documents/certificates/mysql-ca is there. */
function connect(array $c, ?string $docs): mysqli
{
    mysqli_report(MYSQLI_REPORT_OFF);
    $db = mysqli_init();
    $db->options(MYSQLI_OPT_CONNECT_TIMEOUT, 15);
    $flags = 0;
    if ($docs !== null && is_file("$docs/certificates/mysql-ca")) {
        $cert = is_file("$docs/certificates/mysql-cert") && is_file("$docs/certificates/mysql-key");
        $db->ssl_set($cert ? "$docs/certificates/mysql-key" : null, $cert ? "$docs/certificates/mysql-cert" : null, "$docs/certificates/mysql-ca", null, null);
        $flags = MYSQLI_CLIENT_SSL;
    }
    if (!@$db->real_connect($c['host'], $c['user'], $c['password'], $c['database'], $c['port'], null, $flags)) {
        fwrite(STDERR, "can't connect to the database {$c['database']} on {$c['host']}:{$c['port']}: " . mysqli_connect_error() . "\n");
        exit(1);
    }
    $db->set_charset('utf8mb4');
    // As OpenEMR's own connection: no strict mode, so zero dates read as they are.
    $db->query("SET SESSION sql_mode = ''");
    // Timestamps read in UTC, whatever the server's zone: two receipts then agree across a DST change.
    $db->query("SET SESSION time_zone = '+00:00'");
    return $db;
}

/** All rows of $sql, as lists. Stops with the statement and the server's message if it fails. */
function rows(mysqli $db, string $sql): array
{
    $r = $db->query($sql);
    if ($r === false) {
        throw new RuntimeException($db->error . ' in: ' . substr($sql, 0, 300));
    }
    return $r->fetch_all(MYSQLI_NUM);
}

/** One value of $sql, or null when the query fails (a table or column this release doesn't have). */
function one(mysqli $db, string $sql): ?string
{
    try {
        $v = rows($db, $sql)[0][0] ?? null;
    } catch (RuntimeException $e) {
        return null;
    }
    return $v === null ? null : (string)$v;
}

function money(?string $v): ?string
{
    return $v === null ? null : number_format((float)$v, 2, '.', '');
}

/**
 * The SQL that reads column $c for its checksum. $t is [data_type, column_type, numeric_scale].
 * 'exact' is the value itself (text through utf8mb4, so utf8mb3 and utf8mb4 agree; binary as bytes).
 * 'norm' is a form two types share, so a conversion that keeps the value (date -> datetime,
 * float(5,2) -> decimal(12,6)) checksums the same; $scale is the first receipt's, when given.
 */
function expr(string $c, array $t, string $kind, ?int $scale = null): string
{
    [$dt] = $t;
    if ($kind === 'norm' && in_array($dt, DATE_TYPES, true)) {
        return "DATE_FORMAT(`$c`, '%Y-%m-%d %H:%i:%s')";
    }
    if ($kind === 'norm' && in_array($dt, NUMERIC_TYPES, true)) {
        $s = $scale ?? normScale($t);
        return "CAST(ROUND(`$c`, $s) AS DECIMAL(40, $s))";
    }
    if (in_array($dt, BINARY_TYPES, true)) {
        return "`$c`";
    }
    return "CAST(`$c` AS CHAR CHARACTER SET utf8mb4)";
}

function normScale(array $t): int
{
    return $t[2] === null || (int)$t[2] > 10 ? 4 : (int)$t[2];
}

function family(string $dt): string
{
    return in_array($dt, DATE_TYPES, true) ? 'date' : (in_array($dt, NUMERIC_TYPES, true) ? 'numeric' : 'other');
}

/** The value of $c with a known rename applied (to a value, or to NULL), for its 'renamed' checksum. */
function renamedExpr(string $c, array $t, array $map, mysqli $db): string
{
    $e = expr($c, $t, 'exact');
    $case = "CASE $e";
    foreach ($map as $from => $to) {
        $case .= " WHEN '" . $db->real_escape_string((string)$from) . "' THEN " . ($to === null ? 'NULL' : "'" . $db->real_escape_string($to) . "'");
    }
    return "$case ELSE $e END";
}

/** A FHIR id column: named uuid, 16 bytes. */
function isUuid(string $c, array $t): bool
{
    return $c === 'uuid' && $t[1] === 'binary(16)';
}

/** SUM of CRC32 of $e, NULL counted as its own value, never NULL itself. */
function crcSum(string $e): string
{
    return "IFNULL(SUM(CRC32(IFNULL($e, '\\0null'))), 0)";
}

/**
 * Every table: rows, rows of a patient, a row checksum, and per column an exact checksum, a
 * normalized one (dates and numbers) and, for a known rename, one with the rename applied.
 * $against: the first receipt, whose column list and scales this one follows.
 */
function tables(mysqli $db, string $schema, ?array $against): array
{
    $s = $db->real_escape_string($schema);
    $cols = [];
    $collation = [];
    foreach (rows($db, "SELECT c.table_name, c.column_name, c.data_type, c.column_type, c.numeric_scale, c.extra, c.collation_name FROM information_schema.columns c JOIN information_schema.tables t ON t.table_schema = c.table_schema AND t.table_name = c.table_name AND t.table_type = 'BASE TABLE' WHERE c.table_schema = '$s' ORDER BY c.table_name, c.ordinal_position") as [$t, $c, $dt, $ct, $scale, $extra, $coll]) {
        $cols[$t][$c] = [strtolower($dt), strtolower($ct), $scale === null ? null : (int)$scale, stripos((string)$extra, 'on update') !== false];
        $collation[$t][$c] = $coll;
    }
    // The ids uuid_registry says were created after the first receipt: the backfill's, set aside
    // so that every id that was there can be shown to be there still.
    $since = $against['db_now'] ?? null;
    $newIds = $since !== null && isset($cols['uuid_registry']['created'])
        ? "(SELECT r.uuid FROM `$s`.`uuid_registry` r WHERE r.created >= '" . $db->real_escape_string($since) . "')" : null;
    $out = [];
    foreach ($cols as $t => $columns) {
        $first = $against['tables'][$t]['columns'] ?? null;
        $pidColumn = array_values(array_intersect(PATIENT_COLUMNS, array_keys($columns)))[0] ?? null;
        $select = ['COUNT(*)', $pidColumn ? "IFNULL(SUM(IFNULL(`$pidColumn`, 0) <> 0), 0)" : '0'];
        // The row checksum: over the first receipt's columns when there is one (an upgrade adds
        // columns), each through its normalized form, renames applied; left out: the columns an
        // upgrade sets to its own time (named, or updating themselves) and FHIR ids, compared apart.
        $rowCols = $first !== null ? array_keys($first) : array_keys($columns);
        $parts = [];
        $complete = true;
        foreach ($rowCols as $c) {
            if (!isset($columns[$c])) {
                $complete = false;
                continue;
            }
            $auto = $columns[$c][3] || !empty($first[$c]['auto_update']);
            if (isset(KNOWN['volatile']["$t.$c"]) || $auto || isUuid($c, $columns[$c])) {
                continue;
            }
            $scale = isset($first[$c]['scale']) ? $first[$c]['scale'] : null;
            $e = isset(KNOWN['renamed']["$t.$c"]) ? renamedExpr($c, $columns[$c], KNOWN['renamed']["$t.$c"][0], $db)
                : (family($columns[$c][0]) === 'other' ? expr($c, $columns[$c], 'exact') : expr($c, $columns[$c], 'norm', $scale));
            $parts[] = "CAST(IFNULL($e, '\\0null') AS BINARY)";
        }
        $select[] = $parts ? 'IFNULL(SUM(CRC32(CONCAT_WS(0x1f, ' . implode(', ', $parts) . '))), 0)' : '0';
        $plan = [];
        foreach ($columns as $c => $type) {
            $plan[] = [$c, 'sum'];
            $select[] = crcSum(expr($c, $type, 'exact'));
            if (family($type[0]) !== 'other') {
                $scale = $first[$c]['scale'] ?? null;
                $plan[] = [$c, 'norm'];
                $select[] = crcSum(expr($c, $type, 'norm', $scale));
            }
            if (isset(KNOWN['renamed']["$t.$c"])) {
                $plan[] = [$c, 'renamed'];
                $select[] = crcSum(renamedExpr($c, $type, KNOWN['renamed']["$t.$c"][0], $db));
            }
            if (isUuid($c, $type)) {
                // Rows without one, and the ids there were (in the second receipt: not counting the
                // ones created since the first).
                $kept = "`$c` IS NOT NULL AND `$c` <> ''" . ($newIds !== null ? " AND `$c` NOT IN $newIds" : '');
                $plan[] = [$c, 'empty'];
                $select[] = "IFNULL(SUM(`$c` IS NULL OR `$c` = ''), 0)";
                $plan[] = [$c, 'kept_rows'];
                $select[] = "IFNULL(SUM($kept), 0)";
                $plan[] = [$c, 'kept'];
                $select[] = "IFNULL(SUM(IF($kept, CRC32(`$c`), 0)), 0)";
            }
        }
        $r = rows($db, 'SELECT ' . implode(', ', $select) . " FROM `$s`.`$t`")[0];
        $entry = ['rows' => (int)$r[0], 'patient_rows' => (int)$r[1], 'patient_column' => $pidColumn, 'row_sum' => (string)$r[2],
            'row_columns' => $complete ? count($parts) : null, 'columns' => []];
        foreach ($columns as $c => $type) {
            $entry['columns'][$c] = ['type' => $type[1], 'family' => family($type[0]), 'collation' => $collation[$t][$c]];
            if ($type[3]) {
                $entry['columns'][$c]['auto_update'] = true;
            }
            if (family($type[0]) !== 'other') {
                $entry['columns'][$c]['scale'] = family($type[0]) === 'numeric' ? ($first[$c]['scale'] ?? normScale($type)) : null;
            }
        }
        foreach ($plan as $i => [$c, $what]) {
            $entry['columns'][$c][$what] = (string)$r[$i + 3];
        }
        $out[$t] = $entry;
    }
    return $out;
}

/** The file a documents row points to, found the way OpenEMR's document route finds it. */
function documentFile(string $url, int $depth, string $docs): ?array
{
    $path = preg_replace('|^(.*)://|', '', $url);
    $parts = explode('/', $path);
    $name = array_pop($parts);
    if ($name === '' || $name === null) {
        return null;
    }
    $dirs = [];
    for ($i = 0; $i < max(1, $depth); $i++) {
        array_unshift($dirs, array_pop($parts));
    }
    $rel = implode('/', $dirs) . '/' . $name;
    if (is_file("$docs/$rel")) {
        return [$rel, "$docs/$rel"];
    }
    // Where the row says, when that isn't under this site's documents folder (OpenEMR tries it too).
    return is_file($path) ? ["url:$path", $path] : [$rel, null];
}

/** Documents: rows, and the files on disk they point to, with count, bytes and a checksum. */
function documents(mysqli $db, ?string $docs): array
{
    $out = ['rows' => (int)one($db, 'SELECT COUNT(*) FROM documents'), 'files' => 0, 'bytes' => 0, 'missing' => 0, 'not_on_disk' => 0, 'sha256' => null, 'read' => $docs !== null];
    if ($docs === null) {
        return $out;
    }
    $lines = [];
    $res = $db->query("SELECT id, url, IFNULL(path_depth, 1), IFNULL(storagemethod, 0), IFNULL(couch_docid, ''), IFNULL(type, '') FROM documents ORDER BY id");
    if ($res === false) {
        throw new RuntimeException('reading the documents table: ' . $db->error);
    }
    while ($r = $res->fetch_row()) {
        [$id, $url, $depth, $storage, $couch, $type] = $r;
        if ((int)$storage === 1 || $couch !== '' || $type === 'web_url' || (string)$url === '') {
            $out['not_on_disk']++;
            continue;
        }
        $f = documentFile((string)$url, (int)$depth, $docs);
        if ($f === null || $f[1] === null) {
            $out['missing']++;
            $lines[] = "$id\t" . ($f[0] ?? '') . "\tmissing";
            continue;
        }
        $size = filesize($f[1]);
        $out['files']++;
        $out['bytes'] += $size;
        $lines[] = "$id\t{$f[0]}\t$size\t" . hash_file('sha256', $f[1]);
    }
    $out['sha256'] = hash('sha256', implode("\n", $lines));
    return $out;
}

/** Per patient, one checksum per kind of record: lines "pid count" for each patient that has any. */
function perPatient(mysqli $db): array
{
    $queries = [
        'encounters' => 'SELECT pid, COUNT(*) FROM form_encounter GROUP BY pid',
        'appointments' => "SELECT pc_pid, COUNT(*) FROM openemr_postcalendar_events WHERE pc_pid IS NOT NULL AND pc_pid NOT IN ('', '0') GROUP BY pc_pid",
        'prescriptions' => 'SELECT patient_id, COUNT(*) FROM prescriptions GROUP BY patient_id',
        'lab_orders' => 'SELECT patient_id, COUNT(*) FROM procedure_order GROUP BY patient_id',
        'lab_results' => 'SELECT o.patient_id, COUNT(*) FROM procedure_result r JOIN procedure_report p ON p.procedure_report_id = r.procedure_report_id JOIN procedure_order o ON o.procedure_order_id = p.procedure_order_id GROUP BY o.patient_id',
        'documents' => 'SELECT foreign_id, COUNT(*) FROM documents GROUP BY foreign_id',
        'balance_cents' => balanceSql(true),
    ];
    $out = [];
    foreach ($queries as $k => $sql) {
        try {
            $lines = [];
            foreach (rows($db, $sql) as [$pid, $n]) {
                if ($k === 'balance_cents') {
                    $n = (int)round((float)$n * 100);
                }
                if ((string)$pid !== '' && (int)$n !== 0) {
                    $lines[(int)$pid] = (int)$pid . ' ' . (int)$n;
                }
            }
            ksort($lines);
            $out[$k] = ['patients' => count($lines), 'sha256' => hash('sha256', implode("\n", $lines))];
        } catch (RuntimeException $e) {
            $out[$k] = null;
        }
    }
    return $out;
}

/**
 * The balance as OpenEMR's get_patient_balance($pid, true) computes it (the dashboard's Billing card,
 * Total Balance Due), for every patient: per encounter, fee-sheet lines still active (co-pays, which
 * are negative, included) and drug sales, less payments and adjustments not voided.
 */
function balanceSql(bool $perPatient): string
{
    return 'SELECT ' . ($perPatient ? 'fe.pid, ' : '') . "IFNULL(SUM(IFNULL(b.amount, 0) + IFNULL(d.amount, 0) - IFNULL(a.pay, 0) - IFNULL(a.adj, 0)), 0) FROM form_encounter fe"
        . ' JOIN patient_data p ON p.pid = fe.pid'
        . ' LEFT JOIN (SELECT pid, encounter, SUM(fee) AS amount FROM billing WHERE activity = 1 GROUP BY pid, encounter) b ON b.pid = fe.pid AND b.encounter = fe.encounter'
        . ' LEFT JOIN (SELECT pid, encounter, SUM(fee) AS amount FROM drug_sales GROUP BY pid, encounter) d ON d.pid = fe.pid AND d.encounter = fe.encounter'
        . ' LEFT JOIN (SELECT pid, encounter, SUM(pay_amount) AS pay, SUM(adj_amount) AS adj FROM ar_activity WHERE deleted IS NULL GROUP BY pid, encounter) a ON a.pid = fe.pid AND a.encounter = fe.encounter'
        . ($perPatient ? ' GROUP BY fe.pid' : '');
}

/** Receipts and adjustments by year, the way Reports > Financial > Receipts by Payment Method adds them up. */
function byYear(mysqli $db): ?array
{
    // The report's own query (interface/reports/receipts_by_method_report.php, the same in 7.0.3 and
    // 8.5.0), by payment date: a payment's deposit date, else when it was posted; co-pays on the fee
    // sheet count as patient payments on the visit's date.
    $payments = 'SELECT YEAR(IF(s.deposit_date IS NOT NULL, s.deposit_date, a.post_time)) AS y, SUM(a.pay_amount), SUM(a.adj_amount) FROM ar_activity AS a'
        . ' JOIN form_encounter AS fe ON fe.pid = a.pid AND fe.encounter = a.encounter'
        . " JOIN forms AS f ON f.pid = a.pid AND f.encounter = a.encounter AND f.formdir = 'newpatient'"
        . ' LEFT JOIN ar_session AS s ON s.session_id = a.session_id'
        . ' LEFT OUTER JOIN billing AS b ON b.pid = a.pid AND b.encounter = a.encounter AND b.code = a.code AND b.modifier = a.modifier'
        . " AND b.activity = 1 AND b.code_type != 'COPAY' AND b.code_type != 'TAX'"
        . ' WHERE a.deleted IS NULL AND (a.pay_amount != 0 OR a.adj_amount != 0) GROUP BY y';
    $copays = 'SELECT YEAR(fe.date) AS y, SUM(0 - b.fee) FROM billing AS b JOIN form_encounter AS fe ON fe.pid = b.pid AND fe.encounter = b.encounter'
        . " WHERE b.code_type = 'COPAY' AND b.activity = 1 AND b.fee != 0 GROUP BY y";
    try {
        $out = [];
        foreach (rows($db, $payments) as [$y, $pay, $adj]) {
            $out[(string)$y] = ['receipts' => (float)$pay, 'adjustments' => (float)$adj];
        }
        foreach (rows($db, $copays) as [$y, $copay]) {
            $out[(string)$y] = ['receipts' => ($out[(string)$y]['receipts'] ?? 0) + (float)$copay, 'adjustments' => $out[(string)$y]['adjustments'] ?? 0];
        }
    } catch (RuntimeException $e) {
        return null;
    }
    ksort($out);
    foreach ($out as $y => $v) {
        $out[$y] = ['receipts' => money((string)$v['receipts']), 'adjustments' => money((string)$v['adjustments'])];
    }
    return $out;
}

function figures(mysqli $db, array $docs): array
{
    return [
        'patients' => one($db, 'SELECT COUNT(*) FROM patient_data'),
        'encounters' => one($db, 'SELECT COUNT(*) FROM form_encounter'),
        'appointments' => one($db, "SELECT COUNT(*) FROM openemr_postcalendar_events WHERE pc_pid IS NOT NULL AND pc_pid NOT IN ('', '0')"),
        'prescriptions' => one($db, 'SELECT COUNT(*) FROM prescriptions'),
        'lab_orders' => one($db, 'SELECT COUNT(*) FROM procedure_order'),
        'lab_results' => one($db, 'SELECT COUNT(*) FROM procedure_result'),
        'documents' => (string)$docs['rows'],
        'document_files' => $docs['read'] ? (string)$docs['files'] : null,
        'document_bytes' => $docs['read'] ? (string)$docs['bytes'] : null,
        'document_files_missing' => $docs['read'] ? (string)$docs['missing'] : null,
        'document_files_sha256' => $docs['sha256'],
        'charges' => money(one($db, "SELECT IFNULL(SUM(fee), 0) FROM billing WHERE activity = 1 AND code_type != 'COPAY'")),
        'copays' => money(one($db, "SELECT IFNULL(SUM(0 - fee), 0) FROM billing WHERE activity = 1 AND code_type = 'COPAY'")),
        'drug_sales' => money(one($db, 'SELECT IFNULL(SUM(fee), 0) FROM drug_sales')),
        'payments' => money(one($db, 'SELECT IFNULL(SUM(pay_amount), 0) FROM ar_activity WHERE deleted IS NULL')),
        'adjustments' => money(one($db, 'SELECT IFNULL(SUM(adj_amount), 0) FROM ar_activity WHERE deleted IS NULL')),
        'balance' => money(one($db, balanceSql(false))),
    ];
}

/** Takes the receipt of the database $c (and the documents folder $docs, when given). */
function take(array $c, ?string $docs, ?string $openemr, ?string $site, string $label, ?array $against): array
{
    $db = connect($c, $docs);
    $schema = $c['database'];
    $code = null;
    if ($openemr !== null && is_file("$openemr/version.php")) {
        $v_major = $v_minor = $v_patch = $v_realpatch = $v_database = null;
        include "$openemr/version.php";
        $code = "$v_major.$v_minor.$v_patch" . ((int)$v_realpatch > 0 ? " (patch $v_realpatch)" : '') . ", database version $v_database";
    }
    $now = one($db, 'SELECT NOW()');
    $docInfo = documents($db, $docs);
    $r = [
        'receipt' => RECEIPT_FORMAT,
        'tool' => 'openemr-receipt.php ' . RECEIPT_VERSION,
        'label' => $label,
        'taken' => date('Y-m-d H:i:s O'),
        'db_now' => $now,
        'site' => $site,
        'database' => $schema,
        'server' => (string)one($db, 'SELECT VERSION()'),
        'openemr_files' => $code,
        'openemr_database' => one($db, "SELECT CONCAT(v_major, '.', v_minor, '.', v_patch, IF(v_realpatch > 0, CONCAT(' (patch ', v_realpatch, ')'), ''), ', database version ', v_database) FROM version"),
        'documents_folder' => $docs,
        'figures' => figures($db, $docInfo),
        'documents_not_on_disk' => $docInfo['not_on_disk'],
        'calendar_without_date' => one($db, "SELECT COUNT(*) FROM openemr_postcalendar_events WHERE pc_eventDate = '0000-00-00'"),
        'by_year' => byYear($db),
        'per_patient' => perPatient($db),
        'against' => $against['taken'] ?? null,
        'tables' => tables($db, $schema, $against),
    ];
    $db->close();
    return $r;
}

function n(?string $v): string
{
    return $v === null ? 'n/a' : number_format((float)$v, 0, '.', ',');
}

function m(?string $v): string
{
    return $v === null ? 'n/a' : number_format((float)$v, 2, '.', ',');
}

function figureText(string $k, ?string $v): string
{
    if ($v === null) {
        return 'n/a';
    }
    if (in_array($k, MONEY, true)) {
        return m($v);
    }
    if ($k === 'document_files_sha256') {
        return substr($v, 0, 16);
    }
    return n($v);
}

/** The receipt in plain words. */
function receiptText(array $r): string
{
    $t = [];
    $t[] = "OpenEMR receipt" . ($r['label'] !== '' ? ": {$r['label']}" : '');
    $t[] = "  site " . ($r['site'] ?? '?') . ", database {$r['database']} on {$r['server']}; taken {$r['taken']}";
    $t[] = "  OpenEMR: the database says {$r['openemr_database']}" . ($r['openemr_files'] ? "; the files say {$r['openemr_files']}" : '');
    $t[] = "  Holds no patient data: counts, money totals and checksums only.";
    $t[] = "";
    $t[] = "What the clinic has";
    $f = $r['figures'];
    foreach (['patients', 'encounters', 'appointments', 'prescriptions', 'lab_orders', 'lab_results', 'documents'] as $k) {
        $t[] = sprintf("  %-46s %s", FIGURES[$k], n($f[$k]));
    }
    if ($f['document_files'] === null) {
        $t[] = "  Document files on disk                         not read (no documents folder given)";
    } else {
        $t[] = sprintf("  %-46s %s files, %s bytes, checksum %s", 'Document files on disk', n($f['document_files']), n($f['document_bytes']), substr((string)$f['document_files_sha256'], 0, 16));
        $t[] = sprintf("  %-46s %s%s", 'Document files missing', n($f['document_files_missing']),
            $r['documents_not_on_disk'] ? sprintf(" (and %s stored elsewhere: CouchDB or web links, not read)", n((string)$r['documents_not_on_disk'])) : '');
    }
    $t[] = "";
    $t[] = "Money, all dates";
    foreach (MONEY as $k) {
        $t[] = sprintf("  %-46s %s", $k === 'balance' ? 'Balance' : FIGURES[$k], m($f[$k]));
    }
    $t[] = "  (Balance: charges and drug sales, less co-pays, payments and adjustments, per visit, as each patient's";
    $t[] = "  Billing card adds up Total Balance Due; voided payments and removed fee-sheet lines don't count.)";
    $t[] = "";
    $t[] = "Receipts by year, by payment date, as Reports > Financial > Receipts by Payment Method shows them";
    foreach ($r['by_year'] ?? [] as $y => $v) {
        $t[] = sprintf("  %-6s receipts %14s   adjustments %14s", $y, m($v['receipts']), m($v['adjustments']));
    }
    if (empty($r['by_year'])) {
        $t[] = '  none';
    }
    $rows = 0;
    foreach ($r['tables'] as $x) {
        $rows += $x['rows'];
    }
    $t[] = "";
    $t[] = sprintf("Every table: %s tables, %s rows; each table's rows and columns have a checksum (in the .json)", n((string)count($r['tables'])), n((string)$rows));
    return implode("\n", $t) . "\n";
}

/**
 * Compares two receipts. Returns [$match, $lines]: $match is true when nothing differs but what the
 * upgrade is known to change.
 */
function compare(array $a, array $b, bool $strict = false): array
{
    $t = [];
    $bad = [];   // unexplained differences, in plain words
    $okNotes = [];
    $t[] = "Receipts compared";
    $t[] = "  first:  " . ($a['label'] ?: 'receipt') . " ({$a['openemr_database']}; {$a['taken']})";
    $t[] = "  second: " . ($b['label'] ?: 'receipt') . " ({$b['openemr_database']}; {$b['taken']})";
    if (($a['receipt'] ?? 0) !== RECEIPT_FORMAT || ($b['receipt'] ?? 0) !== RECEIPT_FORMAT) {
        $bad[] = 'a receipt is not in this tool\'s format (' . RECEIPT_FORMAT . '): take both with the same openemr-receipt.php';
    }
    $sameTool = ($a['tool'] ?? '') === ($b['tool'] ?? '');
    if (!$sameTool) {
        $t[] = "  NOTE the receipts were taken by different versions ({$a['tool']}, {$b['tool']}); row checksums aren't compared";
    }

    // 1. What the clinic has: every figure must be the same. None is ever explained away.
    $t[] = "";
    $t[] = "What the clinic has, and the money";
    $changed = 0;
    foreach (FIGURES as $k => $label) {
        $x = $a['figures'][$k] ?? null;
        $y = $b['figures'][$k] ?? null;
        if ($k === 'document_files_sha256') {
            $label = 'Document files: checksum of every file';
        }
        $same = $x === $y;
        if (!$same && $x !== null && $y !== null && in_array($k, MONEY, true)) {
            $same = money($x) === money($y);
        }
        // Nothing read is not the same as nothing changed: a figure neither receipt could read is a
        // difference (the document files only when neither receipt was given the documents folder).
        if ($x === null && $y === null && !in_array($k, ['document_files', 'document_bytes', 'document_files_missing', 'document_files_sha256'], true)) {
            $bad[] = "$label: neither receipt could read it";
        }
        if (!$same) {
            $changed++;
            $bad[] = "$label: " . figureText($k, $x) . ' before, ' . figureText($k, $y) . ' after';
        }
        $t[] = sprintf("  %-4s %-46s %s%s", $same ? 'same' : 'DIFF', $label, figureText($k, $x), $same ? '' : ' -> ' . figureText($k, $y));
    }
    foreach (array_unique(array_merge(array_keys($a['by_year'] ?? []), array_keys($b['by_year'] ?? []))) as $y) {
        $x = $a['by_year'][$y] ?? null;
        $z = $b['by_year'][$y] ?? null;
        $same = $x === $z;
        if (!$same) {
            $bad[] = "receipts for $y: " . m($x['receipts'] ?? null) . ' (adjustments ' . m($x['adjustments'] ?? null) . ') before, ' . m($z['receipts'] ?? null) . ' (adjustments ' . m($z['adjustments'] ?? null) . ') after';
        }
        $t[] = sprintf("  %-4s %-46s %s / %s%s", $same ? 'same' : 'DIFF', "Receipts / adjustments, $y", m($x['receipts'] ?? null), m($x['adjustments'] ?? null),
            $same ? '' : ' -> ' . m($z['receipts'] ?? null) . ' / ' . m($z['adjustments'] ?? null));
    }
    if (!isset($a['by_year']) || !isset($b['by_year'])) {
        $bad[] = 'receipts by year: a receipt couldn\'t read them';
    }
    if (count($a['tables']) === 0 || count($a['per_patient'] ?? []) === 0) {
        $bad[] = 'the first receipt read no tables: there is nothing to compare';
    }
    foreach ($a['per_patient'] ?? [] as $k => $pp) {
        $qq = $b['per_patient'][$k] ?? null;
        $what = $k === 'balance_cents' ? 'balance' : 'number of ' . str_replace('_', ' ', $k);
        if ($pp === null || $qq === null) {
            $bad[] = "each patient's $what: couldn't be read";
        } elseif ($pp !== $qq) {
            $bad[] = "each patient's $what: differs for at least one patient";
            $t[] = "  DIFF each patient's $what (a checksum of every patient's)";
        }
    }
    if (!$bad) {
        $t[] = "  every figure the same, and each patient's counts and balance too";
    }

    // 2. Every table.
    $created = array_diff_key($b['tables'], $a['tables']);
    $dropped = array_diff_key($a['tables'], $b['tables']);
    $explained = [];   // reason => [table.column or table...]
    $settings = ['added' => [], 'changed' => []];
    foreach ($a['tables'] as $name => $x) {
        if (!isset($b['tables'][$name])) {
            if ($x['rows'] > 0) {
                $bad[] = "the table $name, with {$x['rows']} rows, is gone";
            }
            continue;
        }
        $y = $b['tables'][$name];
        $patient = $x['patient_column'] !== null;
        $site = [$x['rows'] - $x['patient_rows'], $y['rows'] - $y['patient_rows']];
        if ($y['patient_rows'] < $x['patient_rows']) {
            $cause = $name === 'openemr_postcalendar_events' && (int)($a['calendar_without_date'] ?? 0) > 0 ? ' (' . $a['calendar_without_date'] . ' had no date. ' . CAUSES['calendar_without_date'] . ')' : '';
            $bad[] = "$name lost rows of a patient: {$x['patient_rows']} -> {$y['patient_rows']}$cause";
        } elseif ($y['patient_rows'] > $x['patient_rows']) {
            $bad[] = "$name gained rows of a patient: {$x['patient_rows']} -> {$y['patient_rows']}";
        }
        if ($site[1] < $site[0]) {
            if (isset(KNOWN['removals'][$name])) {
                $explained[KNOWN['removals'][$name]][] = "$name ($site[0] -> $site[1] rows)";
            } else {
                $bad[] = "$name lost rows" . ($patient ? ' that aren\'t a patient\'s' : '') . ": $site[0] -> $site[1]";
            }
        } elseif ($site[1] > $site[0]) {
            $settings['added'][] = $name;
        }
        if ($x['rows'] !== $y['rows'] || $x['patient_rows'] !== $y['patient_rows']) {
            continue;   // values are compared only where the rows are the same in number
        }
        $moved = [];
        $knownHere = [];
        foreach ($x['columns'] as $c => $cx) {
            $cy = $y['columns'][$c] ?? null;
            if ($cy === null) {
                continue;   // dropped by the upgrade; its values went with it (the row checksum notes it)
            }
            $how = null;
            if ($cx['type'] === $cy['type']) {
                $same = $cx['sum'] === $cy['sum'];
            } elseif ($cx['family'] !== 'other' && $cx['family'] === $cy['family']) {
                // A type change within dates or numbers: through the form both share, at the first's scale.
                $same = ($cx['scale'] ?? null) === ($cy['scale'] ?? null) && $cx['norm'] === $cy['norm'];
                if (($cx['scale'] ?? null) !== ($cy['scale'] ?? null)) {
                    $how = 'its type changed and the second receipt wasn\'t taken against the first (--against), so it can\'t be compared';
                }
            } else {
                $same = $cx['sum'] === $cy['sum'];
            }
            if ($same) {
                continue;
            }
            if (isset($cx['empty'], $cy['empty'])) {
                // A FHIR id: filled in where there was none, and every id that was there still there.
                if ((int)$cy['empty'] < (int)$cx['empty'] && $cx['kept'] === $cy['kept'] && $cx['kept_rows'] === $cy['kept_rows']) {
                    $filled = (int)$cx['empty'] - (int)$cy['empty'];
                    $knownHere[KNOWN['uuid']][] = "$name.$c ($filled row" . ($filled === 1 ? '' : 's') . ')';
                } else {
                    $moved[] = "$c (FHIR ids: " . ($cx['kept'] !== $cy['kept'] || $cx['kept_rows'] !== $cy['kept_rows'] ? 'an id that was there changed or is gone' : 'changed, though no row was without one') . ')';
                }
                continue;
            }
            if (isset(KNOWN['volatile']["$name.$c"])) {
                $knownHere[KNOWN['volatile']["$name.$c"]][] = "$name.$c";
            } elseif (!empty($cx['auto_update']) || !empty($cy['auto_update'])) {
                $knownHere[KNOWN['auto_update']][] = "$name.$c";
            } elseif (isset(KNOWN['renamed']["$name.$c"]) && isset($cx['renamed']) && $cx['renamed'] === $cy['sum']) {
                $knownHere[KNOWN['renamed']["$name.$c"][1] . ' (checked: exactly that rename, nothing else)'][] = "$name.$c";
            } else {
                $moved[] = $c . ($how ? " ($how)" : '');
            }
        }
        $rowMoved = $sameTool && $x['row_columns'] !== null && $y['row_columns'] !== null && $x['row_columns'] === $y['row_columns'] && $x['row_sum'] !== $y['row_sum'] && !$moved;
        if ($patient && ($moved || $rowMoved)) {
            $bad[] = "$name, a patient table, changed in place: " . ($moved ? implode(', ', $moved) : 'values moved between rows (each column\'s checksum is the same, the rows\' isn\'t)');
        } elseif ($moved || $rowMoved) {
            $settings['changed'][] = $name;
        }
        foreach ($knownHere as $why => $where) {
            foreach ($where as $w) {
                $explained[$why][] = $w;
            }
        }
    }
    foreach ($created as $name => $y) {
        if ($y['patient_rows'] > 0) {
            $bad[] = "the upgrade created $name with {$y['patient_rows']} rows of a patient";
        }
    }

    $t[] = "";
    $patientTables = $patientRows = 0;
    foreach ($a['tables'] as $x) {
        if ($x['patient_column'] !== null) {
            $patientTables++;
            $patientRows += $x['patient_rows'];
        }
    }
    $t[] = sprintf("Every table: %d compared (%d of them a patient's, with %s rows of patients), %d created by the upgrade, %d gone",
        count(array_intersect_key($a['tables'], $b['tables'])), $patientTables, n((string)$patientRows), count($created), count($dropped));
    foreach ($explained as $why => $where) {
        $t[] = "  ok   " . implode(', ', array_unique($where)) . ": $why.";
    }
    if ($settings['added'] || $settings['changed'] || $created) {
        $t[] = sprintf("  ok   settings, lists and other tables that aren't a patient's: %d gained rows, %d changed in place, %d created (the upgrade scripts' own work)",
            count($settings['added']), count($settings['changed']), count($created));
    }
    // --strict, for a restore: nothing may differ at all, not even what an upgrade is known to change.
    // Every table there and gone alike, with the same rows, row checksum and column checksums.
    if ($strict) {
        foreach (array_keys($created) as $name) {
            $bad[] = "strict: the table $name is in the second receipt only";
        }
        foreach ($a['tables'] as $name => $x) {
            $y = $b['tables'][$name] ?? null;
            if ($y === null) {
                $bad[] = "strict: the table $name is in the first receipt only";
                continue;
            }
            $cols = [];
            foreach ($x['columns'] as $c => $cx) {
                $cy = $y['columns'][$c] ?? null;
                if ($cy === null || $cx['type'] !== $cy['type'] || $cx['sum'] !== $cy['sum'] || ($cx['collation'] ?? null) !== ($cy['collation'] ?? null)) {
                    $cols[] = $c;
                }
            }
            $cols = array_merge($cols, array_keys(array_diff_key($y['columns'], $x['columns'])));
            if ($x['rows'] !== $y['rows'] || $x['row_sum'] !== $y['row_sum'] || $cols) {
                $bad[] = "strict: $name differs (" . ($x['rows'] !== $y['rows'] ? "{$x['rows']} -> {$y['rows']} rows" : ($cols ? 'columns ' . implode(', ', array_slice($cols, 0, 5)) : 'its rows')) . ')';
            }
        }
        $bad = array_values(array_unique($bad));
    }
    foreach ($bad as $line) {
        $t[] = "  DIFF $line";
    }
    $t[] = "";
    if ($bad) {
        $t[] = 'RESULT: DIFFERENT. ' . count($bad) . ' difference' . (count($bad) === 1 ? '' : 's') . ($strict ? ' (strict: every table must be the same)' : ' that the upgrade isn\'t known to make') . ' (the DIFF lines above).';
    } elseif ($strict) {
        $t[] = 'RESULT: MATCH (strict). Every table is the same: rows, the checksum of every row and column, and each column\'s type and collation; every document file and money figure too.';
    } else {
        $t[] = 'RESULT: MATCH. Every patient record, document and money figure is the same' . ($explained ? '; the changes marked ok are the upgrade\'s own, each explained.' : '.');
    }
    return [!$bad, $t, $bad];
}

function readReceipt(string $file): array
{
    $r = json_decode((string)@file_get_contents($file), true);
    if (!is_array($r) || !isset($r['tables'], $r['figures'])) {
        usage("$file isn't a receipt written by openemr-receipt.php");
    }
    return $r;
}

// ------------------------------------------------------------------ command line
if (PHP_SAPI !== 'cli' || realpath($_SERVER['SCRIPT_FILENAME'] ?? '') !== realpath(__FILE__)) {
    return;   // included as a library
}
$opts = getopt('', ['openemr:', 'site:', 'out:', 'label:', 'against:', 'compare', 'strict', 'host:', 'port:', 'user:', 'password-file:', 'database:', 'documents:', 'require:', 'help', 'version']);
if (isset($opts['version'])) {
    echo RECEIPT_VERSION, "\n";
    exit(0);
}
if (isset($opts['help'])) {
    $lines = file(__FILE__);
    foreach (array_slice($lines, 3, 36) as $l) {
        echo preg_replace('/^ \* ?/', '', rtrim($l, "\n")), "\n";
    }
    exit(0);
}
if (isset($opts['compare'])) {
    $files = array_values(array_filter(array_slice($argv, 1), function ($x) {
        return $x !== '--compare' && strpos($x, '--') !== 0;
    }));
    if (count($files) !== 2) {
        usage('--compare takes two receipt files');
    }
    [$match, $lines] = compare(readReceipt($files[0]), readReceipt($files[1]), isset($opts['strict']));
    $text = implode("\n", $lines) . "\n";
    echo $text;
    if (!empty($opts['out'])) {
        file_put_contents((string)$opts['out'], $text);
    }
    exit($match ? 0 : 1);
}

$site = (string)($opts['site'] ?? 'default');
$openemr = isset($opts['openemr']) ? rtrim((string)$opts['openemr'], '/') : null;
if (isset($opts['database'])) {
    $password = isset($opts['password-file']) ? rtrim((string)file_get_contents((string)$opts['password-file']), "\r\n") : '';
    $c = ['host' => (string)($opts['host'] ?? 'localhost'), 'port' => (int)($opts['port'] ?? 3306), 'user' => (string)($opts['user'] ?? 'root'),
        'password' => $password, 'database' => (string)$opts['database']];
    $docs = isset($opts['documents']) ? rtrim((string)$opts['documents'], '/') : null;
} elseif ($openemr !== null) {
    if (!is_file("$openemr/sites/$site/sqlconf.php")) {
        usage("no sites/$site/sqlconf.php under $openemr");
    }
    $c = siteConfig("$openemr/sites/$site/sqlconf.php");
    $docs = isset($opts['documents']) ? rtrim((string)$opts['documents'], '/') : "$openemr/sites/$site/documents";
} else {
    usage('give --openemr=DIR (or, for the rehearsal, --database= and the connection)');
}
if ($docs !== null && !is_dir($docs)) {
    usage("the documents folder $docs isn't there");
}
$against = isset($opts['against']) ? readReceipt((string)$opts['against']) : null;
try {
    $r = take($c, $docs, $openemr, $site, (string)($opts['label'] ?? ''), $against);
} catch (RuntimeException $e) {
    fwrite(STDERR, 'the receipt stopped: ' . $e->getMessage() . "\n");
    exit(1);
}
if (!empty($opts['out'])) {
    $json = json_encode($r, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    if ($json === false || file_put_contents((string)$opts['out'], $json . "\n") === false) {
        fwrite(STDERR, "couldn't write {$opts['out']}\n");
        exit(1);
    }
    @chmod((string)$opts['out'], 0600);
}
echo receiptText($r);
if (!empty($opts['out'])) {
    echo "Written to {$opts['out']}\n";
}
// Floors: a receipt of nothing would match another receipt of nothing.
$short = [];
foreach (array_filter(array_map('trim', explode(',', (string)($opts['require'] ?? '')))) as $k) {
    if (!array_key_exists($k, $r['figures'])) {
        usage("--require: no figure named '$k'; the figures are " . implode(', ', array_keys(FIGURES)));
    }
    if ($r['figures'][$k] === null || (float)$r['figures'][$k] == 0) {
        $short[] = $k;
    }
}
if ($short) {
    fwrite(STDERR, 'FLOOR: zero or missing: ' . implode(', ', $short) . "\n");
    exit(1);
}
exit(0);
