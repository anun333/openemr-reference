# `therapy_groups_participant_attendance`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `form_id` | `int(11)` | no |  |  |  |
| `pid` | `bigint(20)` | no |  |  |  |
| `meeting_patient_comment` | `text` | yes | `NULL` |  |  |
| `meeting_patient_status` | `varchar(15)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `form_id`, `pid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
