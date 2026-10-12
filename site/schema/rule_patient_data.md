# `rule_patient_data`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `pid` | `bigint(20)` | no |  |  |  |
| `category` | `varchar(31)` | no | `''` |  | Maps to the category item in the rule_action_item table |
| `item` | `varchar(31)` | no | `''` |  | Maps to the item column in the rule_action_item table |
| `complete` | `varchar(31)` | no | `''` |  | Maps to list_options list yesno |
| `result` | `varchar(255)` | no | `''` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `category` |  | `category`, `item` |
| `pid` |  | `pid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
