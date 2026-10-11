# `gprelations`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. general purpose relations

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `type1` | `int(2)` | no |  |  |  |
| `id1` | `bigint(20)` | no |  |  |  |
| `type2` | `int(2)` | no |  |  |  |
| `id2` | `bigint(20)` | no |  |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `type1`, `id1`, `type2`, `id2` |
| `key2` |  | `type2`, `id2` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
