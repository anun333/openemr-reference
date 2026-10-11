# `erx_rx_log`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(20)` | no |  | auto_increment |  |
| `prescription_id` | `int(6)` | no |  |  |  |
| `date` | `varchar(25)` | no |  |  |  |
| `time` | `varchar(15)` | no |  |  |  |
| `code` | `int(6)` | no |  |  |  |
| `status` | `text` | yes | `NULL` |  |  |
| `message_id` | `varchar(100)` | yes | `NULL` |  |  |
| `read` | `int(1)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
