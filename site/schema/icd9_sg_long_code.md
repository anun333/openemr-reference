# `icd9_sg_long_code`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `sq_id` | `bigint(20) unsigned` | no |  | auto_increment |  |
| `sg_code` | `varchar(5)` | yes | `NULL` |  |  |
| `long_desc` | `varchar(300)` | yes | `NULL` |  |  |
| `active` | `tinyint(4)` | yes | `0` |  |  |
| `revision` | `int(11)` | yes | `0` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `sq_id` | yes | `sq_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
