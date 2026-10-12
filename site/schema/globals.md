# `globals`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `gl_name` | `varchar(63)` | no |  |  |  |
| `gl_index` | `int(11)` | no | `0` |  |  |
| `gl_value` | `varchar(255)` | no | `''` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `gl_name`, `gl_index` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
