# `transactions`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `title` | `varchar(255)` | no | `''` |  |  |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `user` | `varchar(255)` | no | `''` |  |  |
| `groupname` | `varchar(255)` | no | `''` |  |  |
| `authorized` | `tinyint(4)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `pid` |  | `pid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
