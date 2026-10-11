# `rule_filter`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `varchar(31)` | no | `''` |  | Maps to the id column in the clinical_rules table |
| `include_flag` | `tinyint(1)` | no | `0` |  | 0 is exclude and 1 is include |
| `required_flag` | `tinyint(1)` | no | `0` |  | 0 is optional and 1 is required |
| `method` | `varchar(31)` | no | `''` |  | Maps to list_options list rule_filters |
| `method_detail` | `varchar(31)` | no | `''` |  | Maps to list_options lists rule__intervals |
| `value` | `varchar(255)` | no | `''` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `id` |  | `id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
