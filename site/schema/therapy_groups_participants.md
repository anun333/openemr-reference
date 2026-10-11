# `therapy_groups_participants`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `group_id` | `int(11)` | no |  |  |  |
| `pid` | `bigint(20)` | no |  |  |  |
| `group_patient_status` | `int(11)` | no |  |  |  |
| `group_patient_start` | `date` | no |  |  |  |
| `group_patient_end` | `date` | yes | `NULL` |  |  |
| `group_patient_comment` | `text` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `group_id`, `pid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
