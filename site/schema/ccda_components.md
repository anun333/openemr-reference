# `ccda_components`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `ccda_components_id` | `int(11)` | no |  | auto_increment |  |
| `ccda_components_field` | `varchar(100)` | yes | `NULL` |  |  |
| `ccda_components_name` | `varchar(100)` | yes | `NULL` |  |  |
| `ccda_type` | `int(11)` | no |  |  | 0=>sections,1=>components |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `ccda_components_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
