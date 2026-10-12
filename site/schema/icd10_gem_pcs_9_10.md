# `icd10_gem_pcs_9_10`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `map_id` | `bigint(20) unsigned` | no |  | auto_increment |  |
| `pcs_icd9_source` | `varchar(5)` | yes | `NULL` |  |  |
| `pcs_icd10_target` | `varchar(7)` | yes | `NULL` |  |  |
| `flags` | `varchar(5)` | yes | `NULL` |  |  |
| `active` | `tinyint(4)` | yes | `0` |  |  |
| `revision` | `int(11)` | yes | `0` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `map_id` | yes | `map_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
