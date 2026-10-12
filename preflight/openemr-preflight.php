<?php

/**
 * OpenEMR upgrade pre-flight check.
 *
 * Run it on the server, before upgrading, with the PHP your web server uses:
 *
 *     php openemr-preflight.php --openemr=/var/www/html/openemr [--target=8.4.1] [--site=default] [--facts=DIR_OR_URL]
 *
 * It compares the install with what the target release needs and changes, from
 * facts generated from OpenEMR's source (downloaded from https://github.com/anun333/openemr-reference,
 * or read from --facts=DIR on a server without internet), and
 * lists what to fix first. It only reads: nothing in the install or its database is
 * changed. It never prints passwords or setting values.
 *
 * Written for PHP 7.4 and later, since it runs on the current install's PHP.
 * Exit code: 1 if any check fails, else 0.
 *
 * @license GPL-3.0-or-later
 */

error_reporting(E_ALL);
ini_set('display_errors', 'stderr');

$opts = getopt('', ['openemr:', 'target:', 'site:', 'facts:', 'help']);
if (isset($opts['help']) || empty($opts['openemr'])) {
    fwrite(STDERR, "usage: php openemr-preflight.php --openemr=/path/to/openemr [--target=X.Y.Z] [--site=default] [--facts=DIR_OR_URL]\n");
    exit(2);
}
$root = rtrim((string)$opts['openemr'], '/');
$site = isset($opts['site']) ? (string)$opts['site'] : 'default';
// Facts: --facts, else the generator's own output beside this file, else the published copy
// (updated from OpenEMR's release tags every day).
$factsBase = isset($opts['facts']) ? rtrim((string)$opts['facts'], '/')
    : (is_file(__DIR__ . '/../site/preflight/releases.json') ? __DIR__ . '/../site/preflight' : 'https://raw.githubusercontent.com/anun333/openemr-reference/main/site/preflight');
$notesBase = 'https://github.com/anun333/openemr-reference/blob/main/site/upgrade';

$results = [];
function report(string $status, string $check, string $detail, string $fix = ''): void
{
    global $results;
    $results[] = $status;
    echo str_pad($status, 5) . ' ' . $check . ': ' . $detail . "\n";
    if ($fix !== '') {
        echo '      ' . $fix . "\n";
    }
}

function facts(string $base, string $name): ?array
{
    $context = stream_context_create(['http' => ['timeout' => 15, 'user_agent' => 'openemr-preflight']]);
    $raw = @file_get_contents($base . '/' . $name . '.json', false, $context);
    if ($raw === false) {
        return null;
    }
    $data = json_decode($raw, true);
    return is_array($data) ? $data : null;
}

/** The variables a PHP config file sets, without running it in this scope. */
function readConfig(string $path, array $names): array
{
    $read = static function (string $__path) {
        include $__path;
        return get_defined_vars();
    };
    $vars = $read($path);
    return array_intersect_key($vars, array_flip($names));
}

function versionKey(string $v): array
{
    return array_map('intval', explode('.', $v));
}

function cmpVersion(string $a, string $b): int
{
    return versionKey($a) <=> versionKey($b);
}

// ------------------------------------------------------------ the install

if (!is_file("$root/version.php") || !is_file("$root/sites/$site/sqlconf.php")) {
    fwrite(STDERR, "$root doesn't look like an OpenEMR directory (no version.php or sites/$site/sqlconf.php)\n");
    exit(2);
}
$code = readConfig("$root/version.php", ['v_major', 'v_minor', 'v_patch', 'v_realpatch', 'v_database']);
$patch = (int)($code['v_realpatch'] ?? 0);
$current = "{$code['v_major']}.{$code['v_minor']}.{$code['v_patch']}";

$releases = facts($factsBase, 'releases');
if ($releases === null) {
    fwrite(STDERR, "can't read the release facts from $factsBase (use --facts=DIR or URL)\n");
    exit(2);
}
$target = isset($opts['target']) ? (string)$opts['target'] : end($releases);
if (!in_array($target, $releases, true)) {
    fwrite(STDERR, "no facts for release $target; known: " . implode(', ', $releases) . "\n");
    exit(2);
}

echo "OpenEMR upgrade pre-flight: $root (site $site), $current to $target\n\n";

$base = null;
foreach ($releases as $r) {
    if (cmpVersion($r, $current) <= 0) {
        $base = $r;
    }
}
if ($base === null) {
    report('FAIL', 'Version', "this install is $current, older than any release with facts (" . $releases[0] . ')', 'Upgrade in steps with the wiki guides first.');
    exit(1);
}
if ($base !== $current) {
    report('WARN', 'Version', "$current isn't a release with facts; comparing from $base, the closest earlier one");
}
if ($patch > 0) {
    echo "NOTE  Version: patch $patch of $current is applied; the facts are for $current as released, so a few changes may already be in place.\n";
}
if (cmpVersion($target, $base) <= 0) {
    report('PASS', 'Version', "this install is already at $current; nothing to upgrade to $target");
    exit(0);
}
$from = facts($factsBase, $base);
$to = facts($factsBase, $target);
if ($from === null || $to === null) {
    fwrite(STDERR, "can't read the facts for $base or $target\n");
    exit(2);
}
$steps = [];
$prev = null;
foreach ($releases as $r) {
    if (cmpVersion($r, $base) >= 0 && cmpVersion($r, $target) <= 0) {
        if ($prev !== null) {
            $steps[] = "$notesBase/$prev-to-$r.md";
        }
        $prev = $r;
    }
}

// ------------------------------------------------------------ XAMPP
// XAMPP for Windows stopped at 8.2.12 (2023-11-21): PHP 8.2 and MariaDB 10.4, below what
// OpenEMR 8.3.0 and later need. The project's answer is its XAMPP to Docker migration guide.
$xamppPath = '#[/\\\\]xampp[/\\\\]#i';
$onXampp = preg_match($xamppPath, $root) || preg_match($xamppPath, realpath($root) ?: '') || preg_match($xamppPath, PHP_BINARY);
if ($onXampp && version_compare($to['php'], '8.3', '>=')) {
    report('FAIL', 'XAMPP', "this install runs on XAMPP, whose newest release (8.2.12, November 2023) has PHP 8.2 and MariaDB 10.4; OpenEMR $target needs PHP {$to['php']} or later",
        'Replacing PHP inside XAMPP is not enough (the database and extensions are too old too). The project supports moving to Docker: https://www.open-emr.org/wiki/index.php/XAMPP_to_Docker_Migration (migrate at your current version first, then upgrade).');
}

// ------------------------------------------------------------ PHP

$phpNeed = $to['php'];
if (version_compare(PHP_VERSION, $phpNeed, '>=')) {
    report('PASS', 'PHP', PHP_VERSION . " (OpenEMR $target needs $phpNeed or later)");
} else {
    report('FAIL', 'PHP', PHP_VERSION . " is too old: OpenEMR $target needs $phpNeed or later",
        'Upgrade PHP first. Check the web server runs the same PHP as the command line (php -v, and phpinfo() in the browser).');
}
$missing = [];
foreach ($to['extensions'] as $ext) {
    if (!extension_loaded($ext)) {
        $missing[] = $ext;
    }
}
if ($missing === []) {
    report('PASS', 'PHP extensions', count($to['extensions']) . " required by $target, all loaded");
} else {
    report('FAIL', 'PHP extensions', 'missing: ' . implode(', ', $missing) . " (OpenEMR $target's composer.json requires them)",
        'Install them for the PHP the web server uses (for example php-' . $missing[0] . '). Composer refuses to install without them, and a packaged release fails wherever a missing one is used.');
}

// ------------------------------------------------------------ database

$db = readConfig("$root/sites/$site/sqlconf.php", ['host', 'port', 'login', 'pass', 'dbase']);
mysqli_report(MYSQLI_REPORT_OFF);
$mysqli = mysqli_init();
$mysqli->options(MYSQLI_OPT_CONNECT_TIMEOUT, 10);
$connected = @$mysqli->real_connect($db['host'] ?? 'localhost', $db['login'] ?? '', $db['pass'] ?? '', $db['dbase'] ?? '', (int)($db['port'] ?? 3306));
if (!$connected) {
    report('FAIL', 'Database', "can't connect with sites/$site/sqlconf.php (" . mysqli_connect_error() . ')', 'Run this on the OpenEMR server, as a user that can read sqlconf.php.');
} else {
    $row = $mysqli->query('SELECT VERSION() AS v')->fetch_assoc();
    $server = (string)$row['v'];
    $flavor = stripos($server, 'mariadb') !== false ? 'mariadb' : 'mysql';
    preg_match('/^(\d+)\.(\d+)/', $server, $m);
    $short = isset($m[1]) ? "$m[1].$m[2]" : $server;
    $tested = [];
    foreach ($to['ci_databases'] as $pair) {
        if ($pair[0] === $flavor) {
            $tested[] = $pair[1];
        }
    }
    usort($tested, 'cmpVersion');
    $name = $flavor === 'mariadb' ? 'MariaDB' : 'MySQL';
    if (in_array($short, $tested, true)) {
        report('PASS', 'Database server', "$name $short is among those CI tested OpenEMR $target with");
    } elseif ($tested !== [] && cmpVersion($short, $tested[0]) < 0) {
        report('WARN', 'Database server', "$name $short is older than any $name CI tested OpenEMR $target with (" . implode(', ', $tested) . ')',
            "Not tested is not the same as unsupported, but consider upgrading the database first.");
    } else {
        report('WARN', 'Database server', "$name $short isn't one CI tested OpenEMR $target with (" . ($tested ? implode(', ', $tested) : "no $name versions") . ')');
    }

    $ver = $mysqli->query('SELECT v_major, v_minor, v_patch, v_database FROM version LIMIT 1');
    $dbv = $ver ? $ver->fetch_assoc() : null;
    if (!$dbv) {
        report('FAIL', 'Database version', "can't read the version table");
    } elseif ((int)$dbv['v_database'] < (int)$code['v_database']) {
        report('FAIL', 'Previous upgrade', "the code is $current (database version {$code['v_database']}) but the database is still at {$dbv['v_major']}.{$dbv['v_minor']}.{$dbv['v_patch']} (database version {$dbv['v_database']})",
            "A previous upgrade's sql_upgrade.php didn't finish. Run it for the current version, or restore the backup, before starting another upgrade.");
    } elseif ((int)$dbv['v_database'] > (int)$code['v_database']) {
        report('FAIL', 'Previous upgrade', "the database (version {$dbv['v_database']}) is newer than the code ({$code['v_database']})",
            'The code was rolled back without the database. Restore matching code and database before upgrading.');
    } else {
        report('PASS', 'Previous upgrade', "the database matches the code (database version {$dbv['v_database']})");
    }

    // Settings the target removes that this install has changed from the default
    $removed = array_diff_key($from['settings'], $to['settings']);
    if ($removed !== []) {
        $names = array_keys($removed);
        $in = implode(',', array_fill(0, count($names), '?'));
        $stmt = $mysqli->prepare("SELECT gl_name, gl_value FROM globals WHERE gl_index = 0 AND gl_name IN ($in)");
        $stmt->bind_param(str_repeat('s', count($names)), ...$names);
        $stmt->execute();
        $res = $stmt->get_result();
        $changed = [];
        while ($s = $res->fetch_assoc()) {
            $f = $removed[$s['gl_name']];
            if (!$f['default_at_run_time'] && (string)$s['gl_value'] !== (string)$f['default']) {
                $changed[] = $s['gl_name'] . ' (' . $f['section'] . ': ' . $f['label'] . ')';
            }
        }
        if ($changed === []) {
            report('PASS', 'Settings', count($removed) . " settings are gone in $target; this install uses none of them");
        } else {
            report('WARN', 'Settings', "$target removes settings this install has changed: " . implode('; ', $changed),
                'Whatever they turned on goes away. Read the upgrade notes for each.');
        }
    } else {
        report('PASS', 'Settings', "no setting is removed between $base and $target");
    }
}

// ------------------------------------------------------------ modules and customizations

$moduleDir = "$root/interface/modules/custom_modules";
$installed = is_dir($moduleDir) ? array_values(array_filter(scandir($moduleDir), function ($d) use ($moduleDir) {
    return $d[0] !== '.' && is_dir("$moduleDir/$d");
})) : [];
$thirdParty = [];
$composerNow = [];
foreach ($installed as $dir) {
    if (in_array($dir, $to['modules']['bundled'], true)) {
        continue;
    }
    $viaComposer = false;
    foreach ($to['modules']['composer'] as $pkg) {
        if (substr($pkg, -strlen('/' . $dir)) === '/' . $dir) {
            $viaComposer = true;
        }
    }
    if ($viaComposer) {
        $composerNow[] = $dir;
    } else {
        $thirdParty[] = $dir;
    }
}
if ($composerNow !== []) {
    report('WARN', 'Modules', implode(', ', $composerNow) . " is installed by Composer in $target, no longer bundled",
        'A release package includes it. If you install from git, run composer install after upgrading.');
}
if ($thirdParty !== []) {
    report('WARN', 'Modules', 'not part of OpenEMR ' . $target . ': ' . implode(', ', $thirdParty),
        "Copy each into the new tree (or reinstall it) and check with its developer that it supports $target.");
}
if ($composerNow === [] && $thirdParty === []) {
    report('PASS', 'Modules', count($installed) . " installed modules, all part of OpenEMR $target");
}

$gone = array_values(array_diff($from['pages'], $to['pages']));
// Menu files only matter when a user is assigned them (users.main_menu_role / patient_menu_role).
$assigned = [];
if ($connected) {
    $res = $mysqli->query("SELECT main_menu_role AS m, 'main' AS kind, COUNT(*) AS n FROM users GROUP BY main_menu_role
                           UNION ALL SELECT patient_menu_role, 'patient', COUNT(*) FROM users GROUP BY patient_menu_role");
    while ($res && ($u = $res->fetch_assoc())) {
        $assigned[$u['kind'] . '/' . $u['m']] = (int)$u['n'];
    }
}
$menuFiles = [];
foreach (glob("$root/sites/$site/documents/custom_menus/*.json") ?: [] as $f) {
    $menuFiles[$f] = 'main/' . basename($f);
}
foreach (glob("$root/sites/$site/documents/custom_menus/patient_menus/*.json") ?: [] as $f) {
    $menuFiles[$f] = 'patient/' . basename($f);
}
$broken = [];
$unused = 0;
foreach ($menuFiles as $file => $role) {
    $text = (string)file_get_contents($file);
    $hits = array_values(array_filter($gone, function ($page) use ($text) { return strpos($text, $page) !== false; }));
    if ($hits === []) {
        continue;
    }
    if (($assigned[$role] ?? 0) > 0) {
        $broken[] = basename($file) . ' (assigned to ' . $assigned[$role] . ($assigned[$role] === 1 ? ' user' : ' users') . ') → ' . implode(', ', $hits);
    } else {
        $unused++;
    }
}
if ($broken !== []) {
    report('WARN', 'Custom menus', 'menus in use point to files removed by ' . $target . ': ' . implode('; ', $broken),
        'The upgrade copies sites/ over, so these menus keep the old entries. Edit them after upgrading.');
} else {
    report('PASS', 'Custom menus', count($menuFiles) . ' menu files; none in use points to a removed file'
        . ($unused ? " ($unused more " . ($unused === 1 ? 'does' : 'do') . ', but no user is assigned it)' : ''));
}

// ------------------------------------------------------------ disk

$free = @disk_free_space($root);
$size = 0;
$deadline = microtime(true) + 20;
$capped = false;
$it = new RecursiveIteratorIterator(new RecursiveCallbackFilterIterator(
    new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS),
    function ($f, $key, $it) use ($root) {
        return !($it->hasChildren() && preg_match('#/sites/[^/]+/documents$#', $f->getPathname()));
    }
));
foreach ($it as $f) {
    if ($f->isFile()) {
        $size += $f->getSize();
    }
    if (microtime(true) > $deadline) {
        $capped = true;
        break;
    }
}
$gb = function ($b) { return number_format($b / 1073741824, 1) . ' GB'; };
if ($free === false) {
    report('WARN', 'Disk space', "can't read the free space for $root");
} elseif ($free < 2 * $size) {
    report('WARN', 'Disk space', $gb($free) . ' free; the code (not counting documents) is ' . ($capped ? 'at least ' : '') . $gb($size),
        'The upgrade unpacks a new copy beside the old one, and the backup needs room too.');
} else {
    report('PASS', 'Disk space', $gb($free) . ' free; the code (not counting documents) is ' . ($capped ? 'at least ' : '') . $gb($size));
}

// ------------------------------------------------------------ summary

echo "\nThe upgrade itself: back up the database and sites/ first, then follow the wiki's Linux Upgrade guide.\n";
$scripts = [];
foreach ($to['upgrade_scripts'] as $f) {
    if (preg_match('/^(\d+)_(\d+)_(\d+)-to-(\d+)_(\d+)_(\d+)_upgrade\.sql$/', $f, $m)
        && cmpVersion("$m[1].$m[2].$m[3]", $base) >= 0 && cmpVersion("$m[4].$m[5].$m[6]", $target) <= 0) {
        $scripts[] = $f;
    }
}
usort($scripts, function ($a, $b) { return cmpVersion(preg_replace('/\D+/', '.', $a), preg_replace('/\D+/', '.', $b)); });
echo "sql_upgrade.php will run, from $base: " . ($scripts ? implode(', ', $scripts) : 'no version-to-version script') . "\n";
echo "What changes at each step:\n";
foreach ($steps as $s) {
    echo "  $s\n";
}
$fails = count(array_keys($results, 'FAIL', true));
$warns = count(array_keys($results, 'WARN', true));
echo "\n" . ($fails ? "Fix the $fails failed check(s) before upgrading." : 'No blocking problems found.') . ($warns ? " $warns warning(s) to read." : '') . "\n";
exit($fails ? 1 : 0);
