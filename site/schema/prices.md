# `prices`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `pr_id` | `varchar(11)` | no | `''` |  |  |
| `pr_selector` | `varchar(255)` | no | `''` |  | template selector for drugs, empty for codes |
| `pr_level` | `varchar(31)` | no | `''` |  |  |
| `pr_price` | `decimal(12,2)` | no | `0.00` |  | price in local currency |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `pr_id`, `pr_selector`, `pr_level` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
