# `patient_tracker_element`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `pt_tracker_id` | `bigint(20)` | no | `0` |  | maps to id column in patient_tracker table |
| `start_datetime` | `datetime` | yes | `NULL` |  |  |
| `room` | `varchar(20)` | no | `''` |  |  |
| `status` | `varchar(31)` | no | `''` |  |  |
| `seq` | `varchar(4)` | no | `''` |  | This is a numerical sequence for this pt_tracker_id events |
| `user` | `varchar(255)` | no | `''` |  | This is the user that created this element |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `pt_tracker_id` |  | `pt_tracker_id`, `seq` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
