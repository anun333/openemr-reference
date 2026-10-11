# `template_users`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `tu_id` | `int(11)` | no |  | auto_increment |  |
| `tu_user_id` | `int(11)` | yes | `NULL` |  |  |
| `tu_facility_id` | `int(11)` | yes | `NULL` |  |  |
| `tu_template_id` | `int(11)` | yes | `NULL` |  |  |
| `tu_template_order` | `int(11)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `tu_id` |
| `templateuser` | yes | `tu_user_id`, `tu_template_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
