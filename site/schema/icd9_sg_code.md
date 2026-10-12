# `icd9_sg_code`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `sg_id` | `bigint(20) unsigned` | no |  | auto_increment |  |
| `sg_code` | `varchar(5)` | yes | `NULL` |  |  |
| `formatted_sg_code` | `varchar(6)` | yes | `NULL` |  |  |
| `short_desc` | `varchar(60)` | yes | `NULL` |  |  |
| `long_desc` | `varchar(300)` | yes | `NULL` |  |  |
| `active` | `tinyint(4)` | yes | `0` |  |  |
| `revision` | `int(11)` | yes | `0` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `active` |  | `active` |
| `formatted_sg_code` |  | `formatted_sg_code` |
| `sg_code` |  | `sg_code` |
| `sg_id` | yes | `sg_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
