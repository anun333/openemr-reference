# `rule_action`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `varchar(31)` | no | `''` |  | Maps to the id column in the clinical_rules table |
| `group_id` | `bigint(20)` | no | `1` |  | Contains group id to identify collection of targets in a rule |
| `category` | `varchar(31)` | no | `''` |  | Maps to the category item in the rule_action_item table |
| `item` | `varchar(31)` | no | `''` |  | Maps to the item column in the rule_action_item table |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `id` |  | `id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
