# `icd10_dx_order_code`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `dx_id` | `bigint(20) unsigned` | no |  | auto_increment |  |
| `dx_code` | `varchar(7)` | yes | `NULL` |  |  |
| `formatted_dx_code` | `varchar(10)` | yes | `NULL` |  |  |
| `valid_for_coding` | `char(1)` | yes | `NULL` |  |  |
| `short_desc` | `varchar(60)` | yes | `NULL` |  |  |
| `long_desc` | `text` | yes | `NULL` |  |  |
| `active` | `tinyint(4)` | yes | `0` |  |  |
| `revision` | `int(11)` | yes | `0` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `active` |  | `active` |
| `dx_id` | yes | `dx_id` |
| `formatted_dx_code` |  | `formatted_dx_code` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
