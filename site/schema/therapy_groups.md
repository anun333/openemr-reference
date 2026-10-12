# `therapy_groups`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `group_id` | `int(11)` | no |  | auto_increment |  |
| `group_name` | `varchar(255)` | no |  |  |  |
| `group_start_date` | `date` | no |  |  |  |
| `group_end_date` | `date` | yes | `NULL` |  |  |
| `group_type` | `tinyint(4)` | no |  |  |  |
| `group_participation` | `tinyint(4)` | no |  |  |  |
| `group_status` | `int(11)` | no |  |  |  |
| `group_notes` | `text` | yes | `NULL` |  |  |
| `group_guest_counselors` | `varchar(255)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `group_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
