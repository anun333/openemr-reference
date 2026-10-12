# `product_warehouse`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `pw_drug_id` | `int(11)` | no |  |  |  |
| `pw_warehouse` | `varchar(31)` | no |  |  |  |
| `pw_min_level` | `float` | yes | `0` |  |  |
| `pw_max_level` | `float` | yes | `0` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `pw_drug_id`, `pw_warehouse` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
