# `drug_templates`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `drug_id` | `int(11)` | no |  |  |  |
| `selector` | `varchar(255)` | no | `''` |  |  |
| `dosage` | `varchar(10)` | yes | `NULL` |  |  |
| `period` | `int(11)` | no | `0` |  |  |
| `quantity` | `int(11)` | no | `0` |  |  |
| `refills` | `int(11)` | no | `0` |  |  |
| `taxrates` | `varchar(255)` | yes | `NULL` |  |  |
| `pkgqty` | `float` | no | `1` |  | Number of product items per template item |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `drug_id`, `selector` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
