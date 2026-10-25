<?php

/**
 * OpenEMR upgrade pre-flight check.
 *
 * Run it on the server, before upgrading, with the PHP your web server uses:
 *
 *     php openemr-preflight.php --openemr=/var/www/html/openemr [--target=8.4.1] [--site=default] [--facts=DIR_OR_URL] [--skip=NAME,...]
 *
 * It compares the install with what the target release needs and changes, from
 * facts generated from OpenEMR's source (downloaded from https://github.com/anun333/openemr-reference,
 * or read from --facts=DIR on a server without internet), and
 * lists what to fix first. It only reads: nothing in the install or its database is
 * changed. It never prints passwords or setting values.
 *
 * --skip leaves checks out by name (room, local-changes, site-code and the rest: see CHECKS below and
 * the README); each one left out prints a SKIP line, and the summary says how many.
 *
 * Written for PHP 7.4 and later, since it runs on the current install's PHP.
 * Exit code: 1 if any check fails, else 0.
 *
 * @license GPL-3.0-or-later
 */

error_reporting(E_ALL);
ini_set('display_errors', 'stderr');

$opts = getopt('', ['openemr:', 'target:', 'site:', 'facts:', 'backup-dir:', 'skip:', 'list-checks', 'help']);
if (isset($opts['list-checks'])) {
    // The names --skip takes, one per line, for openemr-upgrade.sh and for people.
    $listing = true;
} elseif (isset($opts['help']) || empty($opts['openemr'])) {
    fwrite(STDERR, "usage: php openemr-preflight.php --openemr=/path/to/openemr [--target=X.Y.Z] [--site=default] [--facts=DIR_OR_URL] [--backup-dir=DIR] [--skip=NAME,...] | --list-checks\n");
    exit(2);
}
// The checks --skip can leave out, by name. The version and the database connection aren't among
// them: every other check needs them.
const CHECKS = [
    'xampp' => 'XAMPP', 'php' => 'PHP', 'php-extensions' => 'PHP extensions', 'database-server' => 'Database server',
    'previous-upgrade' => 'Previous upgrade', 'settings' => 'Settings', 'modules' => 'Modules', 'custom-menus' => 'Custom menus',
    'local-changes' => 'Local changes', 'site-code' => 'Site code on the new PHP', 'room' => 'Room',
    'room-in-database' => 'Room in the database', 'memory' => 'Memory',
];
if (!empty($listing)) {
    echo implode("\n", array_keys(CHECKS)), "\n";
    exit(0);
}
$skip = [];
foreach ((array)($opts['skip'] ?? []) as $list) {
    foreach (array_filter(array_map('trim', explode(',', (string)$list)), 'strlen') as $name) {
        if (!isset(CHECKS[$name])) {
            fwrite(STDERR, "--skip: no check named '$name'; the names are " . implode(', ', array_keys(CHECKS)) . "\n");
            exit(2);
        }
        $skip[$name] = true;
    }
}
$skipped = [];
/** Whether the check named $name is left out (--skip); says so when it is. */
function skipped(string $name): bool
{
    global $skip, $skipped;
    if (!isset($skip[$name])) {
        return false;
    }
    echo 'SKIP  ' . CHECKS[$name] . ": left out (--skip=$name)\n";
    $skipped[] = $name;
    return true;
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
if (!skipped('xampp') && $onXampp && version_compare($to['php'], '8.3', '>=')) {
    report('FAIL', 'XAMPP', "this install runs on XAMPP, whose newest release (8.2.12, November 2023) has PHP 8.2 and MariaDB 10.4; OpenEMR $target needs PHP {$to['php']} or later",
        'Replacing PHP inside XAMPP is not enough (the database and extensions are too old too). The project supports moving to Docker: https://www.open-emr.org/wiki/index.php/XAMPP_to_Docker_Migration (migrate at your current version first, then upgrade).');
}

// ------------------------------------------------------------ PHP

$phpNeed = $to['php'];
if (skipped('php')) {
    // left out
} elseif (version_compare(PHP_VERSION, $phpNeed, '>=')) {
    report('PASS', 'PHP', PHP_VERSION . " (OpenEMR $target needs $phpNeed or later)");
} else {
    report('FAIL', 'PHP', PHP_VERSION . " is too old: OpenEMR $target needs $phpNeed or later",
        'Upgrade PHP first. Check the web server runs the same PHP as the command line (php -v, and phpinfo() in the browser).');
}
$missing = [];
foreach (skipped('php-extensions') ? [] : $to['extensions'] as $ext) {
    if (!extension_loaded($ext)) {
        $missing[] = $ext;
    }
}
if (isset($skip['php-extensions'])) {
    // left out
} elseif ($missing === []) {
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
    if (skipped('database-server')) {
        $tested = [];   // and so no step for it in the plan
    } elseif (in_array($short, $tested, true)) {
        report('PASS', 'Database server', "$name $short is among those CI tested OpenEMR $target with");
    } elseif ($tested !== [] && cmpVersion($short, $tested[0]) < 0) {
        report('WARN', 'Database server', "$name $short is older than any $name CI tested OpenEMR $target with (" . implode(', ', $tested) . ')',
            "Not tested is not the same as unsupported, but consider upgrading the database first.");
    } else {
        report('WARN', 'Database server', "$name $short isn't one CI tested OpenEMR $target with (" . ($tested ? implode(', ', $tested) : "no $name versions") . ')');
    }

    $ver = $mysqli->query('SELECT v_major, v_minor, v_patch, v_database FROM version LIMIT 1');
    $dbv = $ver ? $ver->fetch_assoc() : null;
    if (skipped('previous-upgrade')) {
        // left out
    } elseif (!$dbv) {
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
    if (skipped('settings')) {
        // left out
    } elseif ($removed !== []) {
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
// The list is worked out either way: the site-code check reads the modules it finds.
if (skipped('modules')) {
    // left out
} elseif ($composerNow !== []) {
    report('WARN', 'Modules', implode(', ', $composerNow) . " is installed by Composer in $target, no longer bundled",
        'A release package includes it. If you install from git, run composer install after upgrading.');
}
if (!isset($skip['modules']) && $thirdParty !== []) {
    report('WARN', 'Modules', 'not part of OpenEMR ' . $target . ': ' . implode(', ', $thirdParty),
        "Copy each into the new tree (or reinstall it) and check with its developer that it supports $target.");
}
if (!isset($skip['modules']) && $composerNow === [] && $thirdParty === []) {
    report('PASS', 'Modules', count($installed) . " installed modules, all part of OpenEMR $target");
}

if (!skipped('custom-menus')) {
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
}

// ------------------------------------------------------------ local changes to OpenEMR's own files
// A file the release shipped whose content differs here was changed on this server, and the new
// release's copy replaces it. Compared by git blob hash with the release (or patch) as published
// (<release>[-p<N>]-hashes.json): on the official 8.4.1 image, every shipped file matches.

if (!skipped('local-changes') && $base === $current) {
    $label = $current . ($patch > 0 ? " patch $patch" : '');
    $hashes = facts($factsBase, $current . ($patch > 0 ? "-p$patch" : '') . '-hashes');
    if ($hashes === null || !isset($hashes['dirs'])) {
        echo "NOTE  Local changes: the facts have no file hashes for $label, so changed files can't be found\n";
    } else {
        $changedFiles = [];
        // Its own variable names: this file is one scope, and $name and $c are used elsewhere.
        foreach ($hashes['dirs'] as $hashDir => $hashNames) {
            foreach ($hashNames as $hashName => $hashSha) {
                $hashRel = $hashDir === '' ? $hashName : "$hashDir/$hashName";
                $hashFile = "$root/$hashRel";
                // Not sites/: it holds this install's own settings, and is carried over whole.
                if (strpos($hashRel, 'sites/') !== 0 && is_file($hashFile) && !is_link($hashFile)) {
                    $hashContent = (string) file_get_contents($hashFile);
                    if (substr(sha1('blob ' . strlen($hashContent) . "\0" . $hashContent), 0, strlen($hashSha)) !== $hashSha) {
                        $changedFiles[] = $hashRel;
                    }
                }
            }
        }
        if ($changedFiles === []) {
            report('PASS', 'Local changes', "every file OpenEMR ships is as $label released it");
        } else {
            report('WARN', 'Local changes', count($changedFiles) . " of OpenEMR's own files were changed here, and the new release's copies replace them: "
                . implode(', ', array_slice($changedFiles, 0, 8)) . (count($changedFiles) > 8 ? ', ...' : ''),
                'openemr-upgrade.sh saves them, and with --customizations=apply carries over the changes that still apply; the rest need merging by hand.');
        }
    }
}

// ------------------------------------------------------------ the site's own code on the new PHP
// Files this site added, and the modules the target doesn't ship, carry over as they are, so they
// meet the new PHP unchanged. scan.php (php-upgrade-catalogue, pinned beside this file) reads them
// for what PHP removes or changes between this PHP and the one the target needs; it never runs
// them, and a use behind function_exists() and the like isn't counted. Changed copies of
// OpenEMR's own files aren't scanned here: the new release's copies replace them, and
// openemr-upgrade.sh checks each change on the new copy.

$scanFix = '';
$scanNow = PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;
$scanNew = implode('.', array_slice(versionKey($to['php']), 0, 2));
$scanTool = __DIR__ . '/scan.php';
$scanOff = skipped('site-code');
$scanFacts = !$scanOff && cmpVersion($scanNow, $scanNew) < 0 && is_file($scanTool) ? facts($factsBase, 'php-changes') : null;
if ($scanOff) {
    // left out
} elseif (cmpVersion($scanNow, $scanNew) >= 0) {
    echo "NOTE  Site code on the new PHP: $target runs on this PHP ($scanNow), so the code this site added meets no PHP change\n";
} elseif (!is_file($scanTool)) {
    echo "NOTE  Site code on the new PHP: scan skipped: put scan.php beside this file (it comes with this file's release) to check the code this site added for what PHP $scanNew removes\n";
} elseif ($scanFacts === null) {
    echo "NOTE  Site code on the new PHP: the facts have no php-changes.json, so the code this site added wasn't checked\n";
} else {
    require_once $scanTool;
    $scanList = $base === $current ? facts($factsBase, $current . ($patch > 0 ? "-p$patch" : '') . '-files') : null;
    $scanFiles = [];
    $scanAdded = 0;
    if ($scanList !== null && isset($scanList['dirs'])) {
        $scanShipped = [];
        foreach ($scanList['dirs'] as $scanDir => $scanNames) {
            foreach ($scanNames as $scanName) {
                $scanShipped[$scanDir === '' ? $scanName : "$scanDir/$scanName"] = true;
            }
        }
        // As openemr-upgrade.sh tells added files apart: not under what installing and running puts there.
        $scanSkip = ['sites', 'interface/modules/custom_modules', 'interface/modules/zend_modules/module', 'vendor', 'node_modules', 'public/assets', '.git'];
        $scanUnder = function (string $rel) use ($scanSkip): bool {
            foreach ($scanSkip as $p) {
                if ($rel === $p || strpos($rel, "$p/") === 0 || basename($rel) === 'node_modules') {
                    return true;
                }
            }
            return false;
        };
        $scanWalk = new RecursiveIteratorIterator(new RecursiveCallbackFilterIterator(new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS),
            function (SplFileInfo $f) use ($root, $scanUnder): bool { return !$f->isDir() || !$scanUnder(substr($f->getPathname(), strlen($root) + 1)); }));
        foreach ($scanWalk as $f) {
            $rel = substr($f->getPathname(), strlen($root) + 1);
            if ($f->isFile() && !is_link($f->getPathname()) && !isset($scanShipped[$rel]) && preg_match('/\.(php|inc|phtml)$/i', $rel)) {
                $scanFiles[] = $f->getPathname();
                $scanAdded++;
            }
        }
    } else {
        echo "NOTE  Site code on the new PHP: the facts have no file list for $current, so files this site added can't be told apart; only its modules are checked\n";
    }
    $scanMissing = [];
    $scanFiles = array_merge($scanFiles, upgradeScanFiles(array_map(function ($d) use ($moduleDir) { return "$moduleDir/$d"; }, $thirdParty), $scanMissing));
    // Polyfills anywhere in the install count, though only the files above are reported on.
    $scanDefs = upgradeScanFiles(array_values(array_filter(["$root/vendor", "$root/library", "$root/src"], 'is_dir')), $scanMissing);
    $scanResult = upgradeScanRun($scanFacts, $scanNow, $scanNew, $scanFiles, $scanDefs);
    $scanWhat = ($scanAdded === 1 ? 'the 1 file' : "the $scanAdded files") . ' this site added' . ($thirdParty !== [] ? ' and its ' . count($thirdParty) . (count($thirdParty) === 1 ? ' module' : ' modules') : '');
    $scanBad = [];
    foreach ($scanResult['findings'] as $x) {
        if ($x['guard'] === null && in_array($x['kind'], ['wontload', 'fatal', 'silent'], true)) {
            $scanBad[] = substr($x['file'], strlen($root) + 1) . ' line ' . $x['line'] . ' ' . $x['name'] . ' ('
                . ['wontload' => "won't load", 'fatal' => 'error when it runs', 'silent' => 'works differently'][$x['kind']] . ')';
        }
    }
    $scanStops = $scanResult['counts']['wontload'] + $scanResult['counts']['fatal'];
    if ($scanStops > 0) {
        report('FAIL', 'Site code on the new PHP', ($scanStops === 1 ? '1 use' : "$scanStops uses") . " in $scanWhat won't load or stop with an error on PHP $scanNew: "
            . implode(', ', array_slice($scanBad, 0, 8)) . (count($scanBad) > 8 ? ', ...' : ''),
            "Fix them before moving PHP, or every page that loads one breaks. Uses behind function_exists() and the like aren't counted.");
        $scanFix = 'Fix the ' . ($scanStops === 1 ? 'use' : "$scanStops uses") . " of what PHP $scanNew removes in the code this site added (listed above), before moving PHP.";
    } elseif ($scanBad !== []) {
        report('WARN', 'Site code on the new PHP', (count($scanBad) === 1 ? '1 use' : count($scanBad) . ' uses') . " in $scanWhat work differently on PHP $scanNew: " . implode(', ', array_slice($scanBad, 0, 8)));
    } else {
        report('PASS', 'Site code on the new PHP', "$scanWhat use nothing PHP $scanNow to $scanNew removes (" . count($scanFiles) . ' PHP files read)');
    }
    $scanDeprecated = (array)$scanResult['deprecated_by_name'];
    if ($scanDeprecated !== []) {
        $scanTop = [];
        foreach (array_slice($scanDeprecated, 0, 6, true) as $scanName => $scanN) {
            $scanTop[] = "$scanName ($scanN)";
        }
        $scanD = $scanResult['counts']['deprecated'];
        echo 'NOTE  Site code on the new PHP: ' . ($scanD === 1 ? '1 use' : "$scanD uses") . " deprecated between PHP $scanNow and $scanNew still " . ($scanD === 1 ? 'works' : 'work') . ', with a warning: '
            . implode(', ', $scanTop) . (count($scanDeprecated) > 6 ? ', ...' : '') . "\n";
    }
    if ($scanResult['beyond_facts']) {
        echo 'NOTE  Site code on the new PHP: the PHP changes known cover PHP up to ' . $scanResult['facts_cover'] . ", so what PHP $scanNew itself changes isn't checked yet\n";
    }
}

// ------------------------------------------------------------ room for the whole process
// Each step needs room on a particular disk, and an upgrade that runs out part-way is the worst
// outcome. The backup needs the database (a dump holds about its data, not its indexes) and the
// site's documents; the new release unpacks beside the old one; and MariaDB or MySQL may rebuild
// each table an upgrade script alters, which needs free space in its data directory about as
// large as that table (the facts list each script's altered tables).

$gb = function ($b) { return $b >= 1073741824 ? number_format($b / 1073741824, 1) . ' GB' : number_format($b / 1048576) . ' MB'; };
$measure = function (string $dir, ?string $skip, float $seconds): array {
    $size = 0;
    $deadline = microtime(true) + $seconds;
    if (!is_dir($dir)) {
        return [0, false];
    }
    $it = new RecursiveIteratorIterator(new RecursiveCallbackFilterIterator(
        new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS),
        function ($f, $key, $it) use ($skip) {
            return $skip === null || !($it->hasChildren() && preg_match($skip, $f->getPathname()));
        }
    ));
    foreach ($it as $f) {
        if ($f->isFile()) {
            $size += $f->getSize();
        }
        if (microtime(true) > $deadline) {
            return [$size, true];
        }
    }
    return [$size, false];
};
$roomOff = skipped('room');
[$codeSize, $codeCapped] = $roomOff ? [0, false] : $measure($root, '#/sites/[^/]+/documents$#', 20);
[$docsSize, $docsCapped] = $roomOff ? [0, false] : $measure("$root/sites/$site/documents", null, 30);
$atLeast = function (bool $capped) { return $capped ? 'at least ' : ''; };

$scripts = [];
foreach ($to['upgrade_scripts'] as $f) {
    if (preg_match('/^(\d+)_(\d+)_(\d+)-to-(\d+)_(\d+)_(\d+)_upgrade\.sql$/', $f, $m)
        && cmpVersion("$m[1].$m[2].$m[3]", $base) >= 0 && cmpVersion("$m[4].$m[5].$m[6]", $target) <= 0) {
        $scripts[] = $f;
    }
}
usort($scripts, function ($a, $b) { return cmpVersion(preg_replace('/\D+/', '.', $a), preg_replace('/\D+/', '.', $b)); });
$altered = [];
foreach ($scripts as $f) {
    foreach ($to['upgrade_alters'][$f] ?? [] as $t) {
        $altered[$t] = true;
    }
}

$dbData = 0;
$dbTotal = 0;
$largest = ['', 0];
$datadir = null;
$dbRoomOff = skipped('room-in-database');
if ($connected && !($roomOff && $dbRoomOff)) {
    $res = $mysqli->query('SELECT table_name AS t, COALESCE(data_length, 0) AS d, COALESCE(index_length, 0) AS i FROM information_schema.tables WHERE table_schema = DATABASE()');
    while ($res && ($r = $res->fetch_assoc())) {
        $dbData += (int)$r['d'];
        $dbTotal += (int)$r['d'] + (int)$r['i'];
        if (isset($altered[$r['t']]) && (int)$r['d'] + (int)$r['i'] > $largest[1]) {
            $largest = [$r['t'], (int)$r['d'] + (int)$r['i']];
        }
    }
    $row = $mysqli->query('SELECT @@datadir AS d');
    $datadir = $row ? (string)($row->fetch_assoc()['d'] ?? '') : null;
}

// The backup and the new release, on whichever disks they land; when they share one, they add up.
$backupDir = isset($opts['backup-dir']) ? rtrim((string)$opts['backup-dir'], '/') : dirname($root);
$needs = [
    $backupDir => ['what' => [], 'bytes' => 0],
];
$needs[$backupDir]['what'][] = 'backup: database ' . $gb($dbData) . ', documents ' . $atLeast($docsCapped) . $gb($docsSize);
$needs[$backupDir]['bytes'] += $dbData + $docsSize;
$release = $to['package_unpacked_bytes'] ?? null;
$releaseBytes = is_int($release) ? $release : $codeSize;
$installDisk = dirname($root);
$sameDisk = @stat($backupDir) && @stat($installDisk) && stat($backupDir)['dev'] === stat($installDisk)['dev'];
$key = $sameDisk ? $backupDir : $installDisk;
$needs[$key] = $needs[$key] ?? ['what' => [], 'bytes' => 0];
$needs[$key]['what'][] = "new release $target " . (is_int($release) ? $gb($release) : 'about ' . $atLeast($codeCapped) . $gb($codeSize) . ' (the current code\'s size)');
$needs[$key]['bytes'] += $releaseBytes;
foreach ($roomOff ? [] : $needs as $dir => $need) {
    $want = (int)($need['bytes'] * 1.2);
    $free = @disk_free_space($dir);
    $detail = 'need about ' . $gb($want) . ' with a 20% margin (' . implode('; ', $need['what']) . ')';
    if ($free === false) {
        report('WARN', 'Room', "can't read the free space at $dir; $detail");
    } elseif ($free < $want) {
        report('FAIL', 'Room', "$dir has " . $gb($free) . " free; $detail",
            $dir === $backupDir ? 'Free space there, or put the backup on another disk with --backup-dir.' : 'Free space on this disk before unpacking the new release.');
    } else {
        report('PASS', 'Room', "$dir has " . $gb($free) . " free; $detail");
    }
}

// The database server's own disk, for the tables the upgrade alters.
if ($dbRoomOff) {
    // left out
} elseif (!$connected) {
    report('WARN', 'Room in the database', "can't connect, so the tables the upgrade alters can't be measured");
} elseif ($altered === []) {
    report('PASS', 'Room in the database', "the upgrade scripts from $base to $target alter no existing table");
} else {
    $need = (int)($largest[1] * 1.2);
    $what = count($altered) . ' tables altered from ' . $base . ' to ' . $target . ($largest[0] !== '' ? ', the largest here `' . $largest[0] . '` (' . $gb($largest[1]) . ')' : '');
    $free = ($datadir !== null && $datadir !== '' && @is_dir($datadir)) ? @disk_free_space($datadir) : false;
    if ($free === false) {
        report('NOTE', 'Room in the database', "$what; the database's data folder isn't visible from here",
            'Check that the database server has at least ' . $gb($need) . ' free where it keeps its data (' . ($datadir ?: 'its datadir') . '): rebuilding a table needs about as much again as the table.');
    } elseif ($free < $need) {
        report('FAIL', 'Room in the database', "$what; its data folder $datadir has " . $gb($free) . ' free, under the ' . $gb($need) . ' a rebuild of it can take',
            'Free space on the database server first, or archive old rows from that table.');
    } else {
        report('PASS', 'Room in the database', "$what; its data folder has " . $gb($free) . ' free');
    }
}

// Memory, on Linux.
$meminfo = skipped('memory') ? false : @file_get_contents('/proc/meminfo');
if (is_string($meminfo) && preg_match('/^MemAvailable:\s+(\d+) kB/m', $meminfo, $mm)) {
    $available = (int)$mm[1] * 1024;
    if ($available < 1073741824) {
        report('WARN', 'Memory', $gb($available) . ' available', 'Upgrades of large databases can need more; close other work or add memory first.');
    } else {
        report('PASS', 'Memory', $gb($available) . ' available');
    }
}

// ------------------------------------------------------------ summary

// The plan: what to do, in order, from what the checks found. The platform comes first, because
// the target's code won't run on the old PHP; when the current release was never tested on the PHP
// the target needs, the old version may not run on it either, so the platform change and the
// upgrade belong in one maintenance window, with the site down between them.
$phpShort = PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;
$needPhp = cmpVersion(PHP_VERSION, $to['php']) < 0;
$oldTested = $from['ci_php'] ?? [];
$newPhp = $needPhp ? implode('.', array_slice(versionKey($to['php']), 0, 2)) : $phpShort;
$oldRunsOnNew = $oldTested === [] || in_array($newPhp, $oldTested, true);
$plan = [];
$plan[] = 'Back up the database, all of sites/ (documents and the keys in sites/' . $site . '/documents/logs_and_misc/methods), and check the backup restores.';
if ($needPhp || $missing !== []) {
    $plan[] = ($needPhp ? "Move to PHP $newPhp or later (now " . PHP_VERSION . ')' : 'Keep PHP ' . $phpShort)
        . ($missing !== [] ? ', with the extensions ' . implode(', ', $missing) : '') . '.'
        . ($needPhp && !$oldRunsOnNew ? " OpenEMR $base was tested on PHP " . implode(', ', $oldTested) . " only, so it may not run on PHP $newPhp: do this and the next step in one maintenance window, with OpenEMR closed between them." : '');
}
if ($connected && !empty($tested) && !in_array($short, $tested, true) && cmpVersion($short, $tested[0]) < 0) {
    $plan[] = "Upgrade the database server from $name $short to one CI tested $target with (" . implode(', ', $tested) . ').';
}
if ($scanFix !== '') {
    $plan[] = $scanFix;
}
$plan[] = "Unpack OpenEMR $target beside the current folder, copy sites/ into it, and run sql_upgrade.php from $base"
    . ($scripts ? ' (it runs ' . count($scripts) . ' upgrade scripts)' : '') . '. Keep the old folder until the new one works.';
$plan[] = 'Check the result with openemr-doctor.php, then switch the web server to the new folder.';
$plan[] = 'If anything fails: point the web server back at the old folder and restore the database backup.';
echo "\nThe plan, from what was found:\n";
foreach ($plan as $i => $line) {
    echo '  ' . ($i + 1) . '. ' . $line . "\n";
}
echo "\nsql_upgrade.php will run, from $base: " . ($scripts ? implode(', ', $scripts) : 'no version-to-version script') . "\n";
echo "What changes at each step:\n";
foreach ($steps as $s) {
    echo "  $s\n";
}
$fails = count(array_keys($results, 'FAIL', true));
$warns = count(array_keys($results, 'WARN', true));
echo "\n" . ($fails ? "Fix the $fails failed check(s) before upgrading." : 'No blocking problems found.') . ($warns ? " $warns warning(s) to read." : '')
    . ($skipped ? ' ' . count($skipped) . ' check(s) left out with --skip, so not checked: ' . implode(', ', $skipped) . '.' : '') . "\n";
exit($fails ? 1 : 0);
