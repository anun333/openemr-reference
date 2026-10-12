# `immunization_observation`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `imo_id` | `int(11)` | no |  | auto_increment |  |
| `imo_im_id` | `int(11)` | no |  |  |  |
| `imo_pid` | `int(11)` | yes | `NULL` |  |  |
| `imo_criteria` | `varchar(255)` | yes | `NULL` |  |  |
| `imo_criteria_value` | `varchar(255)` | yes | `NULL` |  |  |
| `imo_user` | `int(11)` | yes | `NULL` |  |  |
| `imo_code` | `varchar(255)` | yes | `NULL` |  |  |
| `imo_codetext` | `varchar(255)` | yes | `NULL` |  |  |
| `imo_codetype` | `varchar(255)` | yes | `NULL` |  |  |
| `imo_vis_date_published` | `date` | yes | `NULL` |  |  |
| `imo_vis_date_presented` | `date` | yes | `NULL` |  |  |
| `imo_date_observation` | `timestamp` | no | `current_timestamp()` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `imo_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
