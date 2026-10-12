# `onsite_portal_activity`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `patient_id` | `bigint(20)` | yes | `NULL` |  |  |
| `activity` | `varchar(255)` | yes | `NULL` |  |  |
| `require_audit` | `tinyint(1)` | yes | `1` |  |  |
| `pending_action` | `varchar(255)` | yes | `NULL` |  |  |
| `action_taken` | `varchar(255)` | yes | `NULL` |  |  |
| `status` | `varchar(255)` | yes | `NULL` |  |  |
| `narrative` | `longtext` | yes | `NULL` |  |  |
| `table_action` | `longtext` | yes | `NULL` |  |  |
| `table_args` | `longtext` | yes | `NULL` |  |  |
| `action_user` | `int(11)` | yes | `NULL` |  |  |
| `action_taken_time` | `datetime` | yes | `NULL` |  |  |
| `checksum` | `longtext` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `date` |  | `date` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
