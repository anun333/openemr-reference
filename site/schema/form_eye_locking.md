# `form_eye_locking`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  |  | Links to forms.form_id |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `IMP` | `text` | yes | `NULL` |  |  |
| `PLAN` | `text` | yes | `NULL` |  |  |
| `Resource` | `varchar(50)` | yes | `NULL` |  |  |
| `Technician` | `varchar(50)` | yes | `NULL` |  |  |
| `LOCKED` | `varchar(3)` | yes | `NULL` |  |  |
| `LOCKEDDATE` | `timestamp` | no | `current_timestamp()` | on update current_timestamp() |  |
| `LOCKEDBY` | `varchar(50)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `id_pid` | yes | `id`, `pid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
