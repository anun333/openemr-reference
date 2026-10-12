# `patient_portal_menu`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `patient_portal_menu_id` | `int(11)` | no |  | auto_increment |  |
| `patient_portal_menu_group_id` | `int(11)` | yes | `NULL` |  |  |
| `menu_name` | `varchar(40)` | yes | `NULL` |  |  |
| `menu_order` | `smallint(4)` | yes | `NULL` |  |  |
| `menu_status` | `tinyint(2)` | yes | `1` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `patient_portal_menu_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
