# `verify_email`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `pid_holder` | `bigint(20)` | yes | `NULL` |  |  |
| `email` | `varchar(255)` | yes | `NULL` |  |  |
| `language` | `varchar(100)` | yes | `NULL` |  |  |
| `fname` | `varchar(255)` | yes | `NULL` |  |  |
| `mname` | `varchar(255)` | yes | `NULL` |  |  |
| `lname` | `varchar(255)` | yes | `NULL` |  |  |
| `dob` | `date` | yes | `NULL` |  |  |
| `token_onetime` | `varchar(255)` | yes | `NULL` |  |  |
| `active` | `tinyint(4)` | no | `1` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `email` | yes | `email` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
