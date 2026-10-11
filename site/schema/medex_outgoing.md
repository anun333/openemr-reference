# `medex_outgoing`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `msg_uid` | `int(11)` | no |  | auto_increment |  |
| `msg_pid` | `int(11)` | no |  |  |  |
| `msg_pc_eid` | `varchar(11)` | no |  |  |  |
| `campaign_uid` | `int(11)` | no | `0` |  |  |
| `msg_date` | `timestamp` | no | `current_timestamp()` |  |  |
| `msg_type` | `varchar(50)` | no |  |  |  |
| `msg_reply` | `varchar(50)` | yes | `NULL` |  |  |
| `msg_extra_text` | `text` | yes | `NULL` |  |  |
| `medex_uid` | `int(11)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `msg_uid` |
| `msg_eid` | yes | `msg_uid`, `msg_pc_eid`, `medex_uid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
