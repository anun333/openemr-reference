# `openemr_module_vars`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `pn_id` | `int(11) unsigned` | no |  | auto_increment |  |
| `pn_modname` | `varchar(64)` | yes | `NULL` |  |  |
| `pn_name` | `varchar(64)` | yes | `NULL` |  |  |
| `pn_value` | `longtext` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `pn_id` |
| `pn_modname` |  | `pn_modname` |
| `pn_name` |  | `pn_name` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
