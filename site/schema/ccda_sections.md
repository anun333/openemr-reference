# `ccda_sections`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `ccda_sections_id` | `int(11)` | no |  | auto_increment |  |
| `ccda_components_id` | `int(11)` | yes | `NULL` |  |  |
| `ccda_sections_field` | `varchar(100)` | yes | `NULL` |  |  |
| `ccda_sections_name` | `varchar(100)` | yes | `NULL` |  |  |
| `ccda_sections_req_mapping` | `tinyint(4)` | no | `1` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `ccda_sections_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
