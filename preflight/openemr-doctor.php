<?php

/**
 * OpenEMR install doctor: why a blank page, an error 500, a failed setup or a broken
 * screen after copying or moving an install.
 *
 * On the server, with the PHP your web server uses:
 *
 *     php openemr-doctor.php --openemr=/var/www/html/openemr [--site=default] [--facts=DIR_OR_URL] [--debug]
 *
 * Or, to check the web server's own PHP (it can differ from the command line's), copy this
 * file into the OpenEMR folder and open http://localhost/openemr/openemr-doctor.php in a
 * browser on the server itself. It answers no one else. Delete it when you are done.
 *
 * It compares the install with the facts for its release (generated from OpenEMR's source and
 * downloaded from https://github.com/anun333/openemr-reference, or read from --facts=DIR on a
 * server without internet) and with what OpenEMR needs to start. It only reads:
 * nothing in the install or its database is changed. It never prints passwords or keys.
 *
 * Written for PHP 5.4 and later, so that it can explain a PHP that is too old instead of
 * failing to start on it. Exit code: 1 if any check fails, else 0. --debug (or ?debug=1 in the
 * browser) also prints where each fact came from and how much of it there was, and the timings.
 *
 * @license GPL-3.0-or-later
 */

error_reporting(E_ALL);
// Facts: a folder beside this file (openemr-doctor-facts/), else the generator's own output,
// else the published copy, which is updated from OpenEMR's release tags every day.
$factsDefault = 'https://raw.githubusercontent.com/anun333/openemr-reference/main/site/preflight';
foreach (array(dirname(__FILE__) . '/openemr-doctor-facts', dirname(__FILE__) . '/../site/preflight') as $dir) {
    if (is_file("$dir/releases.json")) {
        $factsDefault = $dir;
        break;
    }
}
define('DOCTOR_FACTS_DEFAULT', $factsDefault);

$web = PHP_SAPI !== 'cli';
if ($web) {
    // Only the server itself, and not through a proxy that would make every visitor local.
    $addr = isset($_SERVER['REMOTE_ADDR']) ? $_SERVER['REMOTE_ADDR'] : '';
    $proxied = isset($_SERVER['HTTP_X_FORWARDED_FOR']) || isset($_SERVER['HTTP_FORWARDED']) || isset($_SERVER['HTTP_X_REAL_IP']);
    if (!in_array($addr, array('127.0.0.1', '::1', '::ffff:127.0.0.1'), true) || $proxied) {
        header('HTTP/1.1 403 Forbidden');
        header('Content-Type: text/plain; charset=utf-8');
        echo "The OpenEMR install doctor only answers a browser on this server (http://localhost/...).\nDelete this file when you are done with it.\n";
        exit;
    }
    header('Content-Type: text/plain; charset=utf-8');
    ini_set('display_errors', '1');
    $root = dirname(__FILE__);
    $site = isset($_GET['site']) ? preg_replace('/[^A-Za-z0-9._-]/', '', (string)$_GET['site']) : 'default';
    $factsBase = DOCTOR_FACTS_DEFAULT;
    $debug = !empty($_GET['debug']);
} else {
    ini_set('display_errors', 'stderr');
    $opts = getopt('', array('openemr:', 'site:', 'facts:', 'help', 'debug'));
    if (isset($opts['help']) || empty($opts['openemr'])) {
        fwrite(STDERR, "usage: php openemr-doctor.php --openemr=/path/to/openemr [--site=default] [--facts=DIR_OR_URL] [--debug]\n");
        exit(2);
    }
    $root = rtrim((string)$opts['openemr'], '/\\');
    $site = isset($opts['site']) ? (string)$opts['site'] : 'default';
    $factsBase = isset($opts['facts']) ? rtrim((string)$opts['facts'], '/') : DOCTOR_FACTS_DEFAULT;
    $debug = isset($opts['debug']);
}
define('DOCTOR_DEBUG', $debug);
define('DOCTOR_START', microtime(true));

/** With --debug: what the doctor decided and why, prefixed so it can't be mistaken for a check. */
function debug($message)
{
    if (DOCTOR_DEBUG) {
        echo 'DEBUG ' . sprintf('%6.2fs', microtime(true) - DOCTOR_START) . ' ' . $message . "\n";
    }
}

$results = array();
function report($status, $check, $detail, $fix = '')
{
    global $results;
    $results[] = $status;
    echo str_pad($status, 5) . ' ' . $check . ': ' . $detail . "\n";
    if ($fix !== '') {
        echo '      ' . $fix . "\n";
    }
}

function facts($base, $name)
{
    if ($base === '') {
        return null;
    }
    $context = stream_context_create(array('http' => array('timeout' => 15, 'user_agent' => 'openemr-doctor')));
    $started = microtime(true);
    $raw = @file_get_contents($base . '/' . $name . '.json', false, $context);
    if ($raw === false) {
        debug("facts $name.json: not read from $base");
        return null;
    }
    $data = json_decode($raw, true);
    debug("facts $name.json: " . strlen($raw) . ' bytes from ' . $base . sprintf(' in %.2fs', microtime(true) - $started) . (is_array($data) ? '' : ', not valid JSON'));
    return is_array($data) ? $data : null;
}

/** The variables a PHP config file sets, without running it in this scope. */
function readConfig($path, $names)
{
    $read = function ($__path) {
        include $__path;
        return get_defined_vars();
    };
    $vars = $read($path);
    return array_intersect_key($vars, array_flip($names));
}

function versionKey($v)
{
    return array_map('intval', explode('.', $v));
}

function cmpVersion($a, $b)
{
    $x = versionKey($a);
    $y = versionKey($b);
    for ($i = 0; $i < max(count($x), count($y)); $i++) {
        $p = isset($x[$i]) ? $x[$i] : 0;
        $q = isset($y[$i]) ? $y[$i] : 0;
        if ($p !== $q) {
            return $p < $q ? -1 : 1;
        }
    }
    return 0;
}

/** A php.ini size in bytes; -1 for unlimited. */
function bytes($v)
{
    $v = trim((string)$v);
    if ($v === '' || $v === '-1') {
        return -1.0;
    }
    $n = (float)$v;
    switch (strtoupper(substr($v, -1))) {
        case 'G':
            return $n * 1073741824;
        case 'M':
            return $n * 1048576;
        case 'K':
            return $n * 1024;
    }
    return (float)$n;
}

/** Whether OpenEMR's own PHP (not vendor/, node_modules/ or sites/) uses a class or function of the intl extension. */
function codeUsesIntl($root)
{
    $tokens = array('Normalizer::', 'IntlDateFormatter', 'NumberFormatter', 'Locale::', 'Collator', 'MessageFormatter',
        'Transliterator', 'IntlCalendar', 'grapheme_', 'idn_to_');
    $skip = array('vendor', 'node_modules', 'sites', '.git');
    $dirs = new RecursiveIteratorIterator(new RecursiveCallbackFilterIterator(
        new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS),
        function ($file, $key, $iterator) use ($skip) {
            return !($iterator->hasChildren() && in_array($file->getFilename(), $skip, true));
        }
    ));
    foreach ($dirs as $file) {
        if (substr($file->getFilename(), -4) !== '.php' || !$file->isReadable()) {
            continue;
        }
        $content = (string)file_get_contents($file->getPathname());
        foreach ($tokens as $token) {
            if (strpos($content, $token) !== false) {
                return true;
            }
        }
    }
    return false;
}

function listSome($items, $n = 5)
{
    return implode(', ', array_slice($items, 0, $n)) . (count($items) > $n ? ' and ' . (count($items) - $n) . ' more' : '');
}

function iniOn($name)
{
    return in_array(strtolower((string)ini_get($name)), array('1', 'on', 'yes', 'true', 'stdout', 'stderr'), true);
}

// ------------------------------------------------------------ the install

if (!is_file("$root/version.php")) {
    $msg = "$root doesn't look like an OpenEMR folder (no version.php)";
    if ($web) {
        echo $msg . "\nCopy this file into the OpenEMR folder itself (the one with version.php and setup.php).\n";
        exit;
    }
    fwrite(STDERR, $msg . "\n");
    exit(2);
}
$code = is_readable("$root/version.php") ? readConfig("$root/version.php", array('v_major', 'v_minor', 'v_patch', 'v_realpatch', 'v_database', 'v_tag')) : array();
// Everything below depends on the version: say so plainly when it can't be read, instead of
// comparing an empty one with the facts.
$versionKnown = isset($code['v_major'], $code['v_minor'], $code['v_patch']) && is_numeric($code['v_major']) && is_numeric($code['v_minor']) && is_numeric($code['v_patch']);
$current = $versionKnown ? $code['v_major'] . '.' . $code['v_minor'] . '.' . $code['v_patch'] : '0.0.0';
$patch = isset($code['v_realpatch']) ? (int)$code['v_realpatch'] : 0;
// A release has an empty tag; a build from the development branch says -dev (or -rc1 ...).
$tag = isset($code['v_tag']) ? trim((string)$code['v_tag']) : '';

echo "OpenEMR install doctor: $root (site $site), OpenEMR " . ($versionKnown ? "$current$tag" . ($patch ? " patch $patch" : '') : '(version unknown)') . "\n";
echo ($web ? 'Checked by the web server\'s PHP' : 'Checked by the command-line PHP') . ', ' . PHP_VERSION . ' (' . PHP_SAPI . ")\n\n";

if (!$versionKnown) {
    $who = function_exists('posix_geteuid') && function_exists('posix_getpwuid') ? posix_getpwuid(posix_geteuid()) : null;
    $who = is_array($who) ? $who['name'] : "this PHP's user";
    report('FAIL', 'Version', is_file("$root/version.php")
        ? (is_readable("$root/version.php") ? "version.php doesn't set the version (v_major, v_minor, v_patch)" : "$who can't read version.php (" . substr(sprintf('%o', fileperms("$root/version.php")), -4) . ')')
        : 'version.php is missing',
        'OpenEMR reads its version from it on every page. Make the web server\'s user able to read OpenEMR\'s files, or copy version.php again from the package. The checks that depend on the release are skipped.');
}
$releases = $versionKnown ? facts($factsBase, 'releases') : null;
$base = null;
$f = null;
if (!$versionKnown) {
    debug('release facts not read: the version is unknown');
} elseif ($releases === null) {
    $online = preg_match('#^https?://#', $factsBase);
    report('NOTE', 'Release facts', $online ? "couldn't download them from $factsBase" . (ini_get('allow_url_fopen') ? '' : ' (allow_url_fopen is off)') . (extension_loaded('openssl') ? '' : ' (openssl is missing)') : "not found at $factsBase",
        'The checks that depend on the release (PHP range, extensions, files) are skipped; the rest still run. For a server without internet, download site/preflight from https://github.com/anun333/openemr-reference and pass --facts=that folder.');
} else {
    foreach ($releases as $r) {
        if (cmpVersion($r, $current) <= 0) {
            $base = $r;
        }
    }
    $f = $base !== null ? facts($factsBase, $base) : null;
    if ($base === null) {
        report('NOTE', 'Release facts', "$current is older than any release with facts (" . $releases[0] . '); release checks skipped');
    } elseif ($f === null) {
        report('NOTE', 'Release facts', "can't read the facts for $base; release checks skipped");
    } elseif ($tag !== '') {
        report('NOTE', 'Release facts', "$current$tag is an unreleased build; comparing it with $base, the closest release with facts",
            "Files and packages it no longer has since $base show as missing, so those are notes here, not failures.");
    } elseif ($base !== $current) {
        report('NOTE', 'Release facts', "$current isn't a release with facts yet; using $base, the closest earlier one",
            "Files and packages $current removed show as missing, so those are notes here, not failures. The facts gain each new release within a day.");
    }
}
// Compared with another release than the one installed: what that release has and this one dropped
// looks missing, so missing files, packages and assets can't be called failures.
$approx = $f !== null && ($base !== $current || $tag !== '');
debug('version ' . $current . ($tag !== '' ? " tag $tag" : ' (no tag)') . ($patch ? " patch $patch" : '') . ', database version ' . (isset($code['v_database']) ? $code['v_database'] : '?')
    . '; facts from ' . $factsBase . '; compared with ' . ($base === null ? 'nothing' : $base) . ($approx ? ' (another release, so missing files are notes)' : ''));

// A patched install has the patch tag's files: Docker images are built from it, and a patch
// zip adds and overwrites but never deletes. Patches remove files (7.0.3 patch 4 dropped
// the old login templates), so compare with the patch's facts when there are some.
$label = "OpenEMR $base";
$fileFacts = $base !== null ? $base . '-files' : null;
$composerList = ($f !== null && isset($f['composer'])) ? $f['composer'] : null;
$assetList = ($f !== null && isset($f['assets'])) ? $f['assets'] : null;
if ($f !== null && $patch > 0 && $base === $current) {
    if (isset($f['patches'][$patch])) {
        $label = "OpenEMR $base patch $patch";
        $fileFacts = "$base-p$patch-files";
        $composerList = $f['patches'][$patch]['composer'];
        $assetList = $f['patches'][$patch]['assets'];
    } else {
        report('NOTE', 'Release facts', "none for patch $patch of $base; comparing files with $base as released, so files the patch removed may show as missing");
        $approx = true;
    }
}

// ------------------------------------------------------------ PHP
// Forum: a PHP too old fails with a parse error before OpenEMR can say anything
// (t/24361, t/24365, t/24048); one newer than tested breaks too (t/24282, t/26030, t/26133).

$phpShort = PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;
if ($f !== null) {
    $need = $f['php'];
    $tested = isset($f['ci_php']) ? $f['ci_php'] : array();
    if (cmpVersion(PHP_VERSION, $need) < 0) {
        report('FAIL', 'PHP', PHP_VERSION . " is too old: OpenEMR $base needs $need or later",
            $web ? 'This is the PHP the web server runs. Install a newer PHP and point the web server at it.'
                 : 'Install a newer PHP. If `php -v` shows a newer one than the web page does, the web server is using a different PHP: open this doctor from a browser on the server to check that one.');
    } elseif ($tested !== array() && cmpVersion($phpShort, end($tested)) > 0) {
        report('WARN', 'PHP', PHP_VERSION . " is newer than any PHP OpenEMR $base was tested with (" . implode(', ', $tested) . ')',
            'Newer PHP versions remove things older code relies on. Use a tested version, or upgrade OpenEMR.');
    } else {
        report('PASS', 'PHP', PHP_VERSION . " (OpenEMR $base needs $need or later" . ($tested ? '; tested with ' . implode(', ', $tested) : '') . ')');
    }
} else {
    report('NOTE', 'PHP', PHP_VERSION . ' (no release facts to compare with)');
}
if (!$web) {
    report('NOTE', 'Which PHP', 'this is the command-line PHP (' . PHP_BINARY . ', settings from ' . (php_ini_loaded_file() ?: 'no php.ini') . ')',
        'The web server can run a different PHP with different settings. To check that one, copy this file into the OpenEMR folder and open it as http://localhost/<openemr folder>/openemr-doctor.php on the server, then delete it.');
}

// Extensions: the release's composer.json requirements, or OpenEMR setup's own four plus
// intl. Forum: intl missing shows the calendar as "Unknown" and stops setup (t/25453,
// t/25214, t/26800); setup.php checks only xml, mysqli, mbstring and openssl.
$why = array(
    'intl' => 'without it the calendar shows "Unknown" and setup can stop with a fatal error',
    'mysqli' => 'OpenEMR can\'t reach its database without it',
    'openssl' => 'encryption, logins and the API need it',
    'mbstring' => 'text handling fails without it',
    'xml' => 'setup and C-CDA need it',
    'sodium' => 'encryption needs it',
    'gd' => 'images and charts need it',
);
// intl is in the fallback from 7.0.0 on: OpenEMR's own code uses it from 7.0.3 (Normalizer in
// library/sanitize.inc.php), and the forum's intl failures are all on 7.0.3 or later. 5.0.2 and
// 6.1.0 use no intl class, and 5.0.2's own Docker image ships without it, so before 7.0.0 it is
// required only if this install's code uses it.
$baseline = array('xml', 'mysqli', 'mbstring', 'openssl');
$intlWhy = '';
if (cmpVersion($current, '7.0.0') >= 0) {
    $baseline[] = 'intl';
    $intlWhy = ' and intl';
} elseif (codeUsesIntl($root)) {
    $baseline[] = 'intl';
    $intlWhy = ' and intl, which this install\'s code uses';
}
$wanted = ($f !== null && $f['extensions'] !== array()) ? $f['extensions'] : $baseline;
$wantedFrom = ($f !== null && $f['extensions'] !== array()) ? " by $base" : ($f !== null ? " ($base's composer.json lists none, so OpenEMR setup's own four$intlWhy)" : " (OpenEMR setup's own four$intlWhy)");
$missing = array();
foreach ($wanted as $ext) {
    if (!extension_loaded($ext)) {
        $missing[] = $ext;
    }
}
if ($missing === array()) {
    report('PASS', 'PHP extensions', count($wanted) . ' required' . $wantedFrom . ', all loaded');
} else {
    $notes = array();
    foreach ($missing as $ext) {
        if (isset($why[$ext])) {
            $notes[] = "$ext: " . $why[$ext];
        }
    }
    report('FAIL', 'PHP extensions', 'missing: ' . implode(', ', $missing) . ($notes ? ' (' . implode('; ', $notes) . ')' : ''),
        'Install them for the PHP the web server uses (Linux: the php-' . $missing[0] . ' package; XAMPP or Windows: uncomment extension=' . $missing[0] . ' in php.ini), then restart the web server.');
}

// php.ini. Forum: errors shown on the page break it (t/24048). The limits are the ones
// OpenEMR's setup recommends (setup.php: max_input_vars 3000, max_execution_time 60,
// post_max_size 30M, memory_limit 512M).
$where = $web ? '' : ' (command-line settings; the web server has its own, so check from the browser)';
$iniLevel = $web ? 'WARN' : 'NOTE';
if (iniOn('display_errors') && (error_reporting() & E_DEPRECATED)) {
    report($iniLevel, 'Error display', 'PHP prints warnings and deprecation notices into pages' . $where,
        'A notice printed into a page can blank it or break the screens that load data in the background. Set display_errors = Off in php.ini (errors still go to the log).');
}
$limits = array();
if ((int)ini_get('max_input_vars') < 3000) {
    $limits[] = 'max_input_vars ' . ini_get('max_input_vars') . ' (3000)';
}
if ($web && (int)ini_get('max_execution_time') !== 0 && (int)ini_get('max_execution_time') < 60) {
    $limits[] = 'max_execution_time ' . ini_get('max_execution_time') . ' (60)';
}
$post = bytes(ini_get('post_max_size'));
$memory = bytes(ini_get('memory_limit'));
if ($post >= 0 && $post < 30 * 1048576) {
    $limits[] = 'post_max_size ' . ini_get('post_max_size') . ' (30M)';
}
if ($memory >= 0 && $memory < 512 * 1048576) {
    $limits[] = 'memory_limit ' . ini_get('memory_limit') . ' (512M)';
}
if (!iniOn('file_uploads')) {
    $limits[] = 'file_uploads Off (On)';
}
if ($limits === array()) {
    report('PASS', 'php.ini', 'meets the limits OpenEMR\'s setup recommends' . $where);
} else {
    report($iniLevel, 'php.ini', 'below what OpenEMR\'s setup recommends: ' . implode(', ', $limits) . $where,
        'Raise them in php.ini and restart the web server. On shared hosting where you can\'t, setup can stop part-way (t/25023).');
}
if ($web) {
    $save = session_save_path() ?: sys_get_temp_dir();
    if (!is_writable($save)) {
        report('FAIL', 'Sessions', "PHP can't write its session folder ($save)", 'Logins fail without it. Make it writable by the web server, or set session.save_path in php.ini.');
    }
}

// ------------------------------------------------------------ the files
// Forum: missing files blank the page or stop it with "Class not found" (t/25717: a
// templates folder lost while patching; t/23699: an upload that didn't finish); a tree
// without its built assets shows an unstyled login whose button does nothing (t/26790).

if (!is_file("$root/vendor/autoload.php")) {
    report('FAIL', 'PHP libraries', 'vendor/ is missing: this looks like source code from git, not a release package',
        'Download the release package (it includes vendor/ and the built assets), or run composer install --no-dev and npm ci && npm run build in this folder.');
} elseif ($composerList !== null) {
    $lib = array();
    $mods = array();
    foreach ($composerList as $pkg) {
        if (!is_dir("$root/" . $pkg[0])) {
            if ($pkg[1] === 'openemr-module') {
                $mods[] = basename($pkg[0]);
            } else {
                $lib[] = substr($pkg[0], 7);
            }
        }
    }
    debug('PHP libraries: ' . count($composerList) . " packages in the facts for $label, " . count($lib) . ' missing, ' . count($mods) . ' modules missing');
    if (count($composerList) < 20) {
        report('WARN', 'Release facts', "the Composer list for $label has only " . count($composerList) . ' packages, which looks incomplete', 'Missing packages may go unnoticed. Download the facts again, or pass --facts= a full copy of site/preflight.');
    }
    if ($lib !== array()) {
        report($approx ? 'NOTE' : 'FAIL', 'PHP libraries', count($lib) . ' of the ' . count($composerList) . " packages $label installs with Composer are missing from vendor/: " . listSome($lib),
            $approx ? "Expected if $current$tag no longer uses them. If OpenEMR misbehaves, copy vendor/ again from the same build." : 'The upload or copy of vendor/ didn\'t finish. Copy vendor/ again from the release package.');
    } else {
        report('PASS', 'PHP libraries', 'all ' . count($composerList) . " packages $label installs with Composer are present");
    }
    if ($mods !== array()) {
        report('WARN', 'Modules', 'Composer installs ' . implode(', ', $mods) . ' into interface/modules/custom_modules/, and it isn\'t there',
            'Only matters if you use it. The release package includes it; some builds copy only vendor/ and leave it out.');
    }
}

if ($assetList !== null) {
    $gone = array();
    foreach ($assetList as $a) {
        if (!is_file("$root/$a")) {
            $gone[] = $a;
        }
    }
    debug('Page assets: ' . count($assetList) . " in the facts for $label, " . count($gone) . ' missing');
    if ($gone !== array()) {
        report($approx ? 'NOTE' : 'FAIL', 'Page assets', count($gone) . ' of the ' . count($assetList) . ' files every page loads are missing: ' . listSome($gone),
            ($approx ? "$label's list, so a build that renamed them looks the same. " : '') . 'They come from the npm build, not from git. Without them the login page looks broken and its button does nothing. Use the release package, or run npm ci && npm run build.');
    } else {
        report('PASS', 'Page assets', 'the ' . count($assetList) . ' built files every page loads are present');
    }
}

// Files the release package ships from git. Folders nothing runs from are optional. The
// setup and upgrade scripts are removed once setup is done by the Docker image (openemr.sh
// cleanup_setup_scripts) and by careful admins, so their absence is reported, not failed.
$setupScripts = array('admin.php', 'setup.php', 'acl_upgrade.php', 'sql_patch.php', 'sql_upgrade.php', 'ippf_upgrade.php');
$removedScripts = array();
$optionalDirs = array('Documentation', 'contrib', 'tests', 'ci', '.github', '.phpstan', 'docker', 'docs', 'tools', 'swagger', 'ccdaservice', 'scripts', 'webpack', 'sites');
$manifest = $fileFacts !== null ? facts($factsBase, $fileFacts) : null;
if ($fileFacts !== null && $f !== null && $manifest === null) {
    report('NOTE', 'Files', "the file list for $label ($fileFacts.json) isn't in the facts; files not checked");
}
if ($manifest !== null) {
    $required = array();
    $optional = 0;
    $total = 0;
    foreach ($manifest['dirs'] as $dir => $names) {
        $top = $dir === '' ? '' : strtok($dir, '/');
        foreach ($names as $name) {
            $path = $dir === '' ? $name : "$dir/$name";
            $total++;
            if (file_exists("$root/$path")) {
                continue;
            }
            if ($dir === '' && in_array($name, $setupScripts, true)) {
                $removedScripts[] = $name;
                continue;
            }
            $isOptional = $dir === '' ? !preg_match('/\.php$|^\.htaccess$/', $name) : in_array($top, $optionalDirs, true);
            if ($isOptional) {
                $optional++;
            } else {
                $required[] = $path;
            }
        }
    }
    debug("Files: $total in the facts for $label, " . count($required) . " missing, $optional optional missing, " . count($removedScripts) . ' setup scripts removed');
    if ($total < 1000) {
        report('WARN', 'Release facts', "the file list for $label has only $total files, which looks incomplete", 'Missing files may go unnoticed. Download the facts again, or pass --facts= a full copy of site/preflight.');
    }
    if ($required !== array()) {
        $areas = array();
        foreach ($required as $p) {
            $parts = explode('/', $p);
            $area = count($parts) > 2 ? $parts[0] . '/' . $parts[1] : $parts[0];
            $areas[$area] = isset($areas[$area]) ? $areas[$area] + 1 : 1;
        }
        arsort($areas);
        $byArea = array();
        foreach (array_slice($areas, 0, 5, true) as $area => $n) {
            $byArea[] = "$area ($n)";
        }
        report($approx ? 'NOTE' : 'FAIL', 'Files', count($required) . " files of the $label package are missing, in " . implode(', ', $byArea) . '. For example: ' . listSome($required, 3),
            $approx ? "Expected for files $current$tag removed or moved since $base. If OpenEMR misbehaves, copy the same build again." : 'Copy the package again (or unpack the patch into this folder, not a subfolder). A partial upload or copy is the usual cause.');
    } else {
        report('PASS', 'Files', "all $total files of the $label package that it runs from are present" . ($optional ? " ($optional optional ones, documentation or tooling, are not)" : ''));
    }
    if ($removedScripts !== array()) {
        report('NOTE', 'Setup scripts', 'removed after setup, as the Docker image does: ' . implode(', ', $removedScripts),
            'Fine for a running install. Copy sql_upgrade.php (and sql_patch.php) back from the package before the next upgrade or patch.');
    }
}

// ------------------------------------------------------------ local changes
// A shipped file whose content differs from the release ($label's git blob hashes,
// <release>[-p<N>]-hashes.json) was edited on this server: by a quick fix, a customization,
// or a patch unpacked over the wrong release. Edited files are named, and edited PHP files are
// parsed with this PHP (7.0 and later can): one that doesn't parse blanks every page that
// loads it. Only when the facts are for exactly this release and patch, or every file the
// patch changed would show as edited. sites/ is this install's own and isn't compared.
$hashFacts = ($fileFacts !== null && $base === $current && ($patch === 0 || strpos($fileFacts, "-p$patch-") !== false))
    ? preg_replace('/-files$/', '-hashes', $fileFacts) : null;
$hashes = $hashFacts !== null && $manifest !== null ? facts($factsBase, $hashFacts) : null;
if ($hashFacts !== null && $manifest !== null && ($hashes === null || !isset($hashes['dirs']))) {
    report('NOTE', 'Local changes', "the file hashes for $label ($hashFacts.json) aren't in the facts; edited files not checked");
}
if ($hashes !== null && isset($hashes['dirs'])) {
    $compared = 0;
    $edited = array();
    $unparsable = array();
    foreach ($hashes['dirs'] as $dir => $names) {
        foreach ($names as $name => $sha) {
            $path = $dir === '' ? $name : "$dir/$name";
            $file = "$root/$path";
            if (strpos($path, 'sites/') === 0 || !is_file($file) || is_link($file)) {
                continue;
            }
            $compared++;
            $content = (string)file_get_contents($file);
            if (substr(sha1('blob ' . strlen($content) . "\0" . $content), 0, strlen($sha)) === $sha) {
                continue;
            }
            $edited[] = $path;
            // PHP 7.0+ only, behind defined('TOKEN_PARSE'); PHP 5 never reaches it.
            // phpcs:disable PHPCompatibility.FunctionUse.NewFunctionParameters, PHPCompatibility.Constants.NewConstants, PHPCompatibility.Classes.NewClasses
            if (substr($path, -4) === '.php' && defined('TOKEN_PARSE')) {
                try {
                    token_get_all($content, TOKEN_PARSE);
                } catch (ParseError $e) {
                    $unparsable[] = "$path line " . $e->getLine() . ' (' . $e->getMessage() . ')';
                }
            }
            // phpcs:enable
        }
    }
    if ($unparsable !== array()) {
        report('FAIL', 'Local changes', count($unparsable) . ' edited ' . (count($unparsable) === 1 ? "file of OpenEMR's own doesn't" : "files of OpenEMR's own don't") . ' parse with this PHP: ' . listSome($unparsable, 3),
            "Every page that loads one is blank or an error 500. Fix the line, or put back the file from the $label package.");
    }
    // version.php is one of them, and the doctor stops earlier without it, so $compared > 0.
    if ($edited === array()) {
        report('PASS', 'Local changes', "all $compared files of the $label package that are here are as released");
    } else {
        report('NOTE', 'Local changes', count($edited) . " of OpenEMR's own files differ from $label as released: " . listSome($edited, 8),
            'Edited here, or copied from another release. If a screen broke after one was changed, compare it with the package\'s copy.');
    }
}

// ------------------------------------------------------------ the site

if (!is_file("$root/sites/$site/sqlconf.php")) {
    $sites = array();
    foreach (glob("$root/sites/*/sqlconf.php") ?: array() as $s) {
        $sites[] = basename(dirname($s));
    }
    report('FAIL', 'Site', "there is no sites/$site/sqlconf.php" . ($sites ? '; sites here: ' . implode(', ', $sites) : ''),
        $sites ? 'Run the doctor with --site=' . $sites[0] . ' (or ?site=' . $sites[0] . ' in the browser).' : 'The sites folder is missing or incomplete. Copy it from the package (new install) or the old server (move).');
    summary($results);
}
$db = readConfig("$root/sites/$site/sqlconf.php", array('host', 'port', 'login', 'pass', 'dbase', 'config'));
if (!isset($db['config']) || (int)$db['config'] !== 1) {
    if (!is_file("$root/setup.php")) {
        report('FAIL', 'Setup', "sites/$site/sqlconf.php says setup hasn't finished, and setup.php is missing", 'Copy setup.php from the package, then open it in the browser.');
    } else {
        report('NOTE', 'Setup', "sites/$site/sqlconf.php says setup hasn't finished (\$config is not 1)",
            'Open setup.php in the browser to finish it. If setup stopped part-way, the PHP error log says why; the checks above cover the usual causes.');
    }
}

// Permissions. Forum: unreadable keys and certificates (t/24855).
$docs = "$root/sites/$site/documents";
if (!is_dir($docs)) {
    report('FAIL', 'Documents folder', "sites/$site/documents is missing", 'It holds uploaded documents, the encryption keys and certificates. Copy it from the package (new install) or the old server (move).');
} elseif ($web) {
    $ro = array();
    foreach (array('', '/logs_and_misc/methods', '/certificates', '/temp') as $sub) {
        if (is_dir($docs . $sub) && !is_writable($docs . $sub)) {
            $ro[] = "documents$sub";
        }
    }
    if ($ro !== array()) {
        report('FAIL', 'Documents folder', 'the web server can\'t write ' . implode(', ', $ro), 'Give the web server\'s user ownership of sites/' . $site . '/documents (Linux: chown -R www-data or apache).');
    } else {
        report('PASS', 'Documents folder', 'the web server can write it');
    }
} else {
    $owner = function_exists('posix_getpwuid') ? posix_getpwuid(fileowner($docs)) : false;
    $name = $owner ? $owner['name'] : (string)fileowner($docs);
    $perms = substr(sprintf('%o', fileperms($docs)), -3);
    if ($name === 'root' && !(fileperms($docs) & 0x0012)) {
        report('WARN', 'Documents folder', "sites/$site/documents belongs to root ($perms)", 'The web server usually runs as www-data, apache or nginx and then can\'t save uploads, keys or certificates. Give its user ownership.');
    } else {
        report('NOTE', 'Documents folder', "owned by $name ($perms); the browser check confirms what the web server can write");
    }
}

if (!isset($db['config']) || (int)$db['config'] !== 1) {
    summary($results);
}

// ------------------------------------------------------------ the database

if (!class_exists('mysqli')) {
    report('FAIL', 'Database', 'can\'t check: the mysqli extension is missing (see PHP extensions)');
    summary($results);
}
if (function_exists('mysqli_report')) {
    mysqli_report(MYSQLI_REPORT_OFF);
}
$host = isset($db['host']) ? (string)$db['host'] : 'localhost';
$port = isset($db['port']) ? (int)$db['port'] : 3306;
$mysqli = mysqli_init();
$mysqli->options(MYSQLI_OPT_CONNECT_TIMEOUT, 10);
$ok = false;
try {
    $ok = @$mysqli->real_connect($host, isset($db['login']) ? $db['login'] : '', isset($db['pass']) ? $db['pass'] : '', isset($db['dbase']) ? $db['dbase'] : '', $port);
} catch (Exception $e) {
    $ok = false;
}
if (!$ok) {
    // Forum: the database stopped or never started (t/23921, t/26432); shared hosting
    // names (t/25245).
    $errno = mysqli_connect_errno();
    $hints = array(
        1045 => 'The user name or password in sites/' . $site . '/sqlconf.php is wrong, or that user may not connect from this server.',
        1044 => 'The user in sqlconf.php has no access to database ' . (isset($db['dbase']) ? $db['dbase'] : '') . '.',
        1049 => 'Database ' . (isset($db['dbase']) ? $db['dbase'] : '') . ' doesn\'t exist on that server. On shared hosting the real name usually has your account name in front.',
        2002 => "Nothing answers at $host:$port. Is the database server running? (XAMPP: start MySQL in the control panel.) With 'localhost' PHP uses a socket file; try 127.0.0.1 instead.",
        2003 => "Nothing answers at $host:$port. Is the database server running, and on that port?",
        2005 => "The database host name '$host' doesn't resolve from this server.",
        2054 => 'The database asks for a login method this PHP doesn\'t support (MySQL 8 caching_sha2_password with an old PHP).',
    );
    report('FAIL', 'Database', "can't connect with sites/$site/sqlconf.php (error $errno)",
        isset($hints[$errno]) ? $hints[$errno] : 'Check host, port, user and database in sqlconf.php against the database server.');
    summary($results);
}
report('PASS', 'Database', "connected to $host:$port");

$q = function ($sql) use ($mysqli) {
    $res = $mysqli->query($sql);
    $rows = array();
    while ($res && ($row = $res->fetch_assoc())) {
        $rows[] = $row;
    }
    return $rows;
};
$rows = $q('SELECT VERSION() AS v');
$server = (string)$rows[0]['v'];
$flavor = stripos($server, 'mariadb') !== false ? 'mariadb' : 'mysql';
$label = $flavor === 'mariadb' ? 'MariaDB' : 'MySQL';
$short = preg_match('/^(\d+)\.(\d+)/', $server, $m) ? "$m[1].$m[2]" : $server;
if ($f !== null) {
    $tested = array();
    foreach ($f['ci_databases'] as $pair) {
        if ($pair[0] === $flavor) {
            $tested[] = $pair[1];
        }
    }
    usort($tested, 'cmpVersion');
    if (in_array($short, $tested, true)) {
        report('PASS', 'Database server', "$label $short, which CI tested OpenEMR $base with");
    } elseif ($tested !== array() && cmpVersion($short, $tested[0]) < 0) {
        report('WARN', 'Database server', "$label $short is older than any $label CI tested OpenEMR $base with (" . implode(', ', $tested) . ')', 'Not tested is not the same as broken, but upgrade the database server if anything fails.');
    } else {
        report('NOTE', 'Database server', "$label $short (CI tested OpenEMR $base with $label " . ($tested ? implode(', ', $tested) : 'none') . ')');
    }
}

// Code and database versions. Forum: a patch's files copied without sql_patch.php, or an
// upgrade's without sql_upgrade.php (t/26790, t/26133, t/24492).
$ver = $q('SELECT * FROM version LIMIT 1');
if ($ver === array()) {
    report('FAIL', 'Database version', 'the version table is empty or missing', 'Setup didn\'t finish, or this database isn\'t OpenEMR\'s.');
} else {
    $v = $ver[0];
    $dbPatch = isset($v['v_realpatch']) ? (int)$v['v_realpatch'] : 0;
    if (!isset($code['v_database'])) {
        report('NOTE', 'Database version', "the database is at {$v['v_major']}.{$v['v_minor']}.{$v['v_patch']} (database version {$v['v_database']}); the code's version is unknown (see Version)");
    } elseif ((int)$v['v_database'] < (int)$code['v_database']) {
        report('FAIL', 'Database version', "the code is $current (database version {$code['v_database']}) but the database is at {$v['v_major']}.{$v['v_minor']}.{$v['v_patch']} (database version {$v['v_database']})",
            'Open sql_upgrade.php in the browser and upgrade from the version the database is at' . (is_file("$root/sql_upgrade.php") ? '.' : ' (copy it from the package first; it was removed).'));
    } elseif ((int)$v['v_database'] > (int)$code['v_database']) {
        report('FAIL', 'Database version', "the database (version {$v['v_database']}) is newer than the code ({$code['v_database']})", 'The code was rolled back without the database. Put matching code and database back.');
    } elseif ($patch > $dbPatch) {
        report('FAIL', 'Database version', "patch $patch's files are in place but the database is at patch $dbPatch", 'Open sql_patch.php in the browser to finish the patch' . (is_file("$root/sql_patch.php") ? '.' : ' (copy it from the patch first; it was removed).'));
    } else {
        report('PASS', 'Database version', "the database matches the code (database version {$v['v_database']}" . ($patch ? ", patch $patch" : '') . ')');
    }
}

$globals = array();
foreach ($q("SELECT gl_name, gl_value FROM globals WHERE gl_index = 0 AND gl_name IN ('css_header', 'user_debug', 'user_php_debug', 'rest_api', 'rest_fhir_api', 'rest_portal_api')") as $g) {
    $globals[$g['gl_name']] = (string)$g['gl_value'];
}
// The theme stylesheet the login page and every screen load (public/themes, built by npm).
if (isset($globals['css_header']) && $globals['css_header'] !== '') {
    $css = basename($globals['css_header']);
    if (!is_file("$root/public/themes/$css")) {
        report('FAIL', 'Theme', "the chosen theme public/themes/$css is missing" . (glob("$root/public/themes/*.css") ? '' : ', and public/themes has no stylesheets at all'),
            'Screens show without styling. The themes come from the npm build; use the release package or run npm ci && npm run build.');
    } else {
        report('PASS', 'Theme', "public/themes/$css is present");
    }
}
// Showing PHP errors on pages. Up to 8.0.x the setting was user_debug (above 1); from
// 8.2.0, user_php_debug (interface/globals.php). Forum: t/27005.
$phpDebugKey = ($f !== null && isset($f['settings']['user_php_debug'])) ? 'user_php_debug' : 'user_debug';
$phpDebugOn = $phpDebugKey === 'user_php_debug' ? (int)(isset($globals['user_php_debug']) ? $globals['user_php_debug'] : 0) > 0
    : (int)(isset($globals['user_debug']) ? $globals['user_debug'] : 0) > 1;
if ($phpDebugOn) {
    $loc = ($f !== null && isset($f['settings'][$phpDebugKey])) ? ' (Administration > Config > ' . $f['settings'][$phpDebugKey]['section'] . ' > ' . $f['settings'][$phpDebugKey]['label'] . ')' : '';
    report('WARN', 'Error display', "OpenEMR's $phpDebugKey setting is on, so PHP errors are shown on pages$loc", 'A message printed into a page can blank it. Turn it off once you have read the error.');
}

// Modules. An active module whose files are missing can stop OpenEMR starting; from 7.0.4
// OpenEMR switches such a module off (src/Core/ModulesApplication.php). Forum: t/25702.
$lost = array();
foreach ($q('SELECT mod_directory, type FROM modules WHERE mod_active = 1') as $mod) {
    $dir = (int)$mod['type'] === 1 ? "$root/interface/modules/zend_modules/module/" . $mod['mod_directory']
        : "$root/interface/modules/custom_modules/" . $mod['mod_directory'] . '/openemr.bootstrap.php';
    if (!file_exists($dir)) {
        $lost[] = $mod['mod_directory'];
    }
}
if ($lost !== array()) {
    report(cmpVersion($current, '7.0.4') < 0 ? 'FAIL' : 'WARN', 'Modules', 'switched on, but their files are missing: ' . implode(', ', $lost),
        cmpVersion($current, '7.0.4') < 0 ? 'This can stop OpenEMR from starting. Copy the module back, or set mod_active = 0 for it in the modules table.'
            : 'OpenEMR switches them off at the next start. Copy them back if you use them.');
}

// Encryption keys. OpenEMR keeps one set in the keys table and one in
// documents/logs_and_misc/methods, encrypted with the first. A missing drive key is
// silently replaced by a new one, after which existing encrypted data can't be read
// (src/Common/Crypto/CryptoGen.php collectDriveKey). Forum: "Decryption failed HMAC"
// (t/25795), keys after an upgrade or move (t/27005).
$versions = array('one', 'two', 'three', 'four', 'five', 'six', 'seven');
$dbKeys = array();
foreach ($q('SELECT name, value FROM `keys`') as $k) {
    if (preg_match('/^(' . implode('|', $versions) . ')[ab]$/', $k['name'])) {
        $dbKeys[$k['name']] = base64_decode((string)$k['value']);
    }
}
$methods = "$docs/logs_and_misc/methods";
$driveKeys = array();
foreach (glob("$methods/*") ?: array() as $file) {
    if (preg_match('/^(' . implode('|', $versions) . ')[ab]$/', basename($file))) {
        $driveKeys[basename($file)] = $file;
    }
}
if ($dbKeys === array() && $driveKeys === array()) {
    report('PASS', 'Encryption keys', 'none yet; OpenEMR creates them the first time it encrypts something');
} elseif ($driveKeys === array()) {
    report('FAIL', 'Encryption keys', 'the database has encryption keys (' . implode(', ', array_keys($dbKeys)) . ") but sites/$site/documents/logs_and_misc/methods has none",
        'If this install was copied or moved, copy that folder from the old server before anyone uses it: OpenEMR will otherwise make new keys, and everything already encrypted becomes unreadable.');
} elseif ($dbKeys === array()) {
    report('FAIL', 'Encryption keys', 'the keys folder has keys (' . implode(', ', array_keys($driveKeys)) . ') but the database has none',
        'The database comes from a different install than the documents folder, or its keys table wasn\'t restored. Restore the matching pair.');
} else {
    $bad = array();
    $unpaired = array();
    $unreadable = array();
    foreach ($driveKeys as $name => $file) {
        if (!is_readable($file)) {
            $unreadable[] = $name;
            continue;
        }
        $content = (string)file_get_contents($file);
        $prefix = substr($content, 0, 3);
        if (!preg_match('/^\d{3}$/', $prefix) || (int)$prefix <= 4) {
            continue; // versions 1-4 store the key on its own, with nothing to match
        }
        $hmacKey = (int)$prefix <= count($versions) ? $versions[(int)$prefix - 1] . 'b' : '';
        if ($hmacKey === '' || !isset($dbKeys[$hmacKey])) {
            $unpaired[] = $name;
            continue;
        }
        $raw = base64_decode(substr($content, 3), true);
        $ok = $raw !== false && strlen($raw) > 64 && hash_hmac('sha384', substr($raw, 48), $dbKeys[$hmacKey], true) === substr($raw, 0, 48);
        if (!$ok) {
            $bad[] = $name;
        }
    }
    if ($unreadable !== array()) {
        report($web ? 'FAIL' : 'NOTE', 'Encryption keys', ($web ? 'the web server' : 'this user') . ' can\'t read ' . implode(', ', $unreadable) . ' in the keys folder',
            $web ? 'Give the web server\'s user ownership of sites/' . $site . '/documents.' : 'Run the doctor as root or as the web server\'s user to check them.');
    } elseif ($bad !== array() || $unpaired !== array()) {
        report('FAIL', 'Encryption keys', 'the keys folder and the database don\'t belong together: ' . implode(', ', array_merge($bad, $unpaired)) . ' can\'t be unlocked with the database\'s keys',
            'The database and sites/' . $site . '/documents come from different installs or different backups. Restore a matching pair; encrypted data can\'t be read until then.');
    } else {
        report('PASS', 'Encryption keys', count($driveKeys) . ' in the keys folder, and they match the database\'s keys');
    }
}

// Documents whose files aren't where OpenEMR looks: under this site's documents folder,
// by the last path_depth parts of the stored URL (library/classes/Document.class.php
// get_filesystem_filepath). Forum: documents listed but not opening after a move (t/26815).
$onDisk = "FROM documents WHERE storagemethod = 0 AND type = 'file_url' AND deleted = 0";
$count = $q("SELECT COUNT(*) AS n $onDisk");
$total = (int)$count[0]['n'];
$couch = $q('SELECT COUNT(*) AS n FROM documents WHERE storagemethod = 1 AND deleted = 0');
$absent = array();
$checked = 0;
$deadline = microtime(true) + 20;
$res = $mysqli->query("SELECT id, url, path_depth $onDisk ORDER BY id", MYSQLI_USE_RESULT);
while ($res && ($d = $res->fetch_assoc())) {
    $parts = explode('/', preg_replace('|^(.*)://|', '', (string)$d['url']));
    $file = array_pop($parts);
    $sub = array_slice($parts, -max(1, (int)$d['path_depth']));
    if (!file_exists($docs . '/' . implode('/', $sub) . '/' . $file)) {
        $absent[] = $d['id'];
    }
    $checked++;
    if (microtime(true) > $deadline) {
        break;
    }
}
if ($res) {
    $res->free();
}
if ($total === 0) {
    report('PASS', 'Documents', 'no documents stored on disk yet');
} elseif ($absent !== array()) {
    report('WARN', 'Documents', count($absent) . " of $checked documents checked have no file in sites/$site/documents (document ids " . listSome($absent, 5) . ')',
        'After a move, copy sites/' . $site . '/documents from the old server. The list shows them, but they open blank.');
} else {
    report('PASS', 'Documents', "all $checked documents checked have their file" . ($checked < $total ? " (stopped after 20 seconds; $total in all)" : ''));
}
if ((int)$couch[0]['n'] > 0) {
    report('NOTE', 'Documents', $couch[0]['n'] . ' documents are stored in CouchDB; not checked');
}

// API certificates, only when an API is on. Forum: "Unable to read key from file" (t/24855).
$apiOn = (isset($globals['rest_api']) && $globals['rest_api'] === '1') || (isset($globals['rest_fhir_api']) && $globals['rest_fhir_api'] === '1')
    || (isset($globals['rest_portal_api']) && $globals['rest_portal_api'] === '1');
if ($apiOn) {
    $certs = array();
    foreach (array('oaprivate.key', 'oapublic.key') as $k) {
        if (!is_file("$docs/certificates/$k") || ($web && !is_readable("$docs/certificates/$k"))) {
            $certs[] = $k;
        }
    }
    if ($certs !== array()) {
        report('WARN', 'API keys', 'an API is on but documents/certificates/' . implode(' and ', $certs) . ($web ? ' is missing or unreadable' : ' is missing'),
            'API logins fail with "Unable to read key from file". After a move, copy the certificates folder; otherwise OpenEMR recreates them when the web server can write the folder.');
    } else {
        report('PASS', 'API keys', 'the API\'s key pair is present');
    }
}

summary($results);

function summary($results)
{
    $fails = count(array_keys($results, 'FAIL', true));
    $warns = count(array_keys($results, 'WARN', true));
    debug(count($results) . ' results: ' . count(array_keys($results, 'PASS', true)) . ' pass, ' . count(array_keys($results, 'NOTE', true)) . " note, $warns warn, $fails fail");
    echo "\n" . ($fails ? "Fix the $fails failed check(s) first." : 'No blocking problems found.') . ($warns ? " $warns warning(s) to read." : '') . "\n";
    $log = (string)ini_get('error_log');
    echo "A blank page or an error 500 always leaves a line in the PHP error log"
        . ($log !== '' ? " (this PHP writes to $log)" : ' (often the web server\'s error log: /var/log/apache2/error.log, /var/log/httpd/error_log, C:\\xampp\\apache\\logs\\error.log)')
        . ". Reload the broken page, then read the newest lines.\n";
    if (PHP_SAPI !== 'cli') {
        echo "\nDelete openemr-doctor.php from the OpenEMR folder now.\n";
        exit;
    }
    exit($fails ? 1 : 0);
}
