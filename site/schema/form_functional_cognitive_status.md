# `form_functional_cognitive_status`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  |  |  |
| `date` | `date` | yes | `NULL` |  |  |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `encounter` | `varchar(255)` | yes | `NULL` |  |  |
| `user` | `varchar(255)` | yes | `NULL` |  |  |
| `groupname` | `varchar(255)` | yes | `NULL` |  |  |
| `authorized` | `tinyint(4)` | yes | `NULL` |  |  |
| `activity` | `tinyint(4)` | yes | `NULL` |  |  |
| `code` | `varchar(255)` | yes | `NULL` |  |  |
| `codetext` | `text` | yes | `NULL` |  |  |
| `description` | `text` | yes | `NULL` |  |  |
| `external_id` | `varchar(30)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
