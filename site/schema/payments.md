# `payments`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `pid` | `bigint(20)` | no | `0` |  |  |
| `dtime` | `datetime` | no |  |  |  |
| `encounter` | `bigint(20)` | no | `0` |  |  |
| `user` | `varchar(255)` | yes | `NULL` |  |  |
| `method` | `varchar(255)` | yes | `NULL` |  |  |
| `source` | `varchar(255)` | yes | `NULL` |  |  |
| `amount1` | `decimal(12,2)` | no | `0.00` |  |  |
| `amount2` | `decimal(12,2)` | no | `0.00` |  |  |
| `posted1` | `decimal(12,2)` | no | `0.00` |  |  |
| `posted2` | `decimal(12,2)` | no | `0.00` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `pid` |  | `pid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
