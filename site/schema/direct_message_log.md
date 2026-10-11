# `direct_message_log`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `msg_type` | `char(1)` | no |  |  | S=sent,R=received |
| `msg_id` | `varchar(127)` | no |  |  |  |
| `sender` | `varchar(255)` | no |  |  |  |
| `recipient` | `varchar(255)` | no |  |  |  |
| `create_ts` | `timestamp` | no | `current_timestamp()` |  |  |
| `status` | `char(1)` | no |  |  | Q=queued,D=dispatched,R=received,F=failed |
| `status_info` | `varchar(511)` | yes | `NULL` |  |  |
| `status_ts` | `timestamp` | yes | `NULL` |  |  |
| `patient_id` | `bigint(20)` | yes | `NULL` |  |  |
| `user_id` | `bigint(20)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `msg_id` |  | `msg_id` |
| `patient_id` |  | `patient_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
