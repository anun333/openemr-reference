# `form_eye_mag_impplan`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `form_id` | `bigint(20)` | no |  |  |  |
| `pid` | `bigint(20)` | no |  |  |  |
| `title` | `varchar(255)` | no |  |  |  |
| `code` | `varchar(50)` | yes | `NULL` |  |  |
| `codetype` | `varchar(50)` | yes | `NULL` |  |  |
| `codedesc` | `varchar(255)` | yes | `NULL` |  |  |
| `codetext` | `varchar(255)` | yes | `NULL` |  |  |
| `plan` | `varchar(3000)` | yes | `NULL` |  |  |
| `PMSFH_link` | `varchar(50)` | yes | `NULL` |  |  |
| `IMPPLAN_order` | `tinyint(4)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `second_index` | yes | `form_id`, `pid`, `title`, `plan(20)` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
