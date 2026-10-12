# `ccda_table_mapping`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `ccda_component` | `varchar(100)` | yes | `NULL` |  |  |
| `ccda_component_section` | `varchar(100)` | yes | `NULL` |  |  |
| `form_dir` | `varchar(100)` | yes | `NULL` |  |  |
| `form_type` | `smallint(6)` | yes | `NULL` |  |  |
| `form_table` | `varchar(100)` | yes | `NULL` |  |  |
| `user_id` | `int(11)` | yes | `NULL` |  |  |
| `deleted` | `tinyint(4)` | no | `0` |  |  |
| `timestamp` | `timestamp` | no | `current_timestamp()` | on update current_timestamp() |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
