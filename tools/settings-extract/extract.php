<?php

/**
 * Prints OpenEMR's settings metadata as JSON, read from library/globals.inc.php
 * with a PHP parser rather than by running it (running it needs the whole of
 * OpenEMR at that version).
 *
 * The metadata is `$GLOBALS_METADATA = [section => [key => [label, type,
 * default, description, ...]]]`. Labels and descriptions are xl('...') calls;
 * a type is a string or an array of options. Anything that isn't a literal is
 * kept as its source text, marked {"expr": "..."}. Keys written as enum cases
 * (GlobalConnectorsEnum::REST_API->value) are resolved from the enum files
 * given after the settings file, read the same way.
 *
 *     php extract.php path/to/globals.inc.php [path/to/SomeEnum.php ...]
 */

declare(strict_types=1);

require __DIR__ . '/vendor/autoload.php';

use PhpParser\Node;
use PhpParser\Node\Expr;
use PhpParser\Node\Scalar;
use PhpParser\NodeFinder;
use PhpParser\ParserFactory;
use PhpParser\PrettyPrinter\Standard;

set_error_handler(static function (int $no, string $message, string $file, int $line): never {
    throw new ErrorException($message, 0, $no, $file, $line);
});

$path = $argv[1] ?? '';
$code = is_file($path) ? file_get_contents($path) : false;
if ($code === false) {
    fwrite(STDERR, "usage: php extract.php globals.inc.php\n");
    exit(2);
}
$parser = (new ParserFactory())->createForNewestSupportedVersion();
$ast = $parser->parse($code) ?? [];
$printer = new Standard();

// Enum cases, by short class name: 'GlobalConnectorsEnum::REST_API' => 'rest_api'
$enumCases = [];
foreach (array_slice($argv, 2) as $enumFile) {
    foreach ((new NodeFinder())->findInstanceOf($parser->parse((string)file_get_contents($enumFile)) ?? [], Node\Stmt\Enum_::class) as $enum) {
        foreach ($enum->stmts as $stmt) {
            if ($stmt instanceof Node\Stmt\EnumCase && $stmt->expr instanceof Scalar\String_) {
                $enumCases[$enum->name?->toString() . '::' . $stmt->name->toString()] = $stmt->expr->value;
            }
        }
    }
}

/** The value of a literal expression, or its source text when it isn't one. */
$value = static function (Expr $e) use (&$value, $printer, $enumCases): mixed {
    return match (true) {
        // SomeEnum::CASE->value, from the enum files
        $e instanceof Expr\PropertyFetch && $e->name instanceof Node\Identifier && $e->name->toString() === 'value'
            && $e->var instanceof Expr\ClassConstFetch && $e->var->class instanceof Node\Name && $e->var->name instanceof Node\Identifier
            && isset($enumCases[$e->var->class->getLast() . '::' . $e->var->name->toString()])
            => $enumCases[$e->var->class->getLast() . '::' . $e->var->name->toString()],
        $e instanceof Scalar\String_ => $e->value,
        $e instanceof Scalar\Int_ => $e->value,
        $e instanceof Scalar\Float_ => $e->value,
        $e instanceof Expr\ConstFetch && in_array(strtolower($e->name->toString()), ['true', 'false', 'null'], true)
            => ['true' => true, 'false' => false, 'null' => null][strtolower($e->name->toString())],
        // xl('text'), xlt('text'): the text, untranslated
        $e instanceof Expr\FuncCall && $e->name instanceof Node\Name && in_array(strtolower($e->name->toString()), ['xl', 'xlt', 'xla'], true)
            && count($e->args) === 1 && $e->args[0] instanceof Node\Arg && $e->args[0]->value instanceof Scalar\String_
            => $e->args[0]->value->value,
        // 'a' . 'b', xl('a') . '*'
        $e instanceof Expr\BinaryOp\Concat && is_string($l = $value($e->left)) && is_string($r = $value($e->right)) => $l . $r,
        default => ['expr' => $printer->prettyPrintExpr($e)],
    };
};

/** @return array<string, mixed>|list<mixed> */
$arrayValue = static function (Expr\Array_ $a) use (&$arrayValue, $value): array {
    $out = [];
    foreach ($a->items as $item) {
        if ($item === null) {
            continue;
        }
        $v = $item->value instanceof Expr\Array_ ? $arrayValue($item->value) : $value($item->value);
        if ($item->key === null) {
            $out[] = $v;
        } else {
            $k = $value($item->key);
            $out[is_scalar($k) ? (string)$k : json_encode($k)] = $v;
        }
    }
    return $out;
};

$finder = new NodeFinder();
$assign = $finder->findFirst($ast, static fn(Node $n): bool => $n instanceof Expr\Assign
    && $n->var instanceof Expr\Variable && $n->var->name === 'GLOBALS_METADATA' && $n->expr instanceof Expr\Array_);
if (!$assign instanceof Expr\Assign || !$assign->expr instanceof Expr\Array_) {
    fwrite(STDERR, "no \$GLOBALS_METADATA = [...] in $path\n");
    exit(1);
}

$sections = [];
foreach ($assign->expr->items as $sectionItem) {
    if ($sectionItem === null || $sectionItem->key === null || !$sectionItem->value instanceof Expr\Array_) {
        continue;
    }
    $section = (string)$value($sectionItem->key);
    foreach ($sectionItem->value->items as $item) {
        if ($item === null || $item->key === null || !$item->value instanceof Expr\Array_) {
            continue;
        }
        $parts = array_values(array_filter($item->value->items, static fn($i): bool => $i !== null));
        $field = static fn(int $i) => isset($parts[$i])
            ? ($parts[$i]->value instanceof Expr\Array_ ? $arrayValue($parts[$i]->value) : $value($parts[$i]->value))
            : null;
        $type = $field(1);
        $key = $value($item->key);
        if (!is_string($key)) {
            throw new UnexpectedValueException('a setting key that is not a string or a known enum case at line ' . $item->getStartLine() . ': ' . json_encode($key));
        }
        $sections[$section][$key] = [
            'label' => $field(0),
            'type' => is_array($type) && !isset($type['expr']) ? 'select' : $type,
            'options' => is_array($type) && !isset($type['expr']) ? $type : null,
            'default' => $field(2),
            'description' => $field(3),
            'line' => $item->getStartLine(),
        ];
    }
}
echo json_encode($sections, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR), "\n";
