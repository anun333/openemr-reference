# `misc_address_book`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `fname` | `varchar(255)` | yes | `NULL` |  |  |
| `mname` | `varchar(255)` | yes | `NULL` |  |  |
| `lname` | `varchar(255)` | yes | `NULL` |  |  |
| `street` | `varchar(60)` | yes | `NULL` |  |  |
| `city` | `varchar(30)` | yes | `NULL` |  |  |
| `state` | `varchar(30)` | yes | `NULL` |  |  |
| `zip` | `varchar(20)` | yes | `NULL` |  |  |
| `phone` | `varchar(30)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
