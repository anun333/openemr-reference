# `report_itemized`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `report_id` | `bigint(20)` | no |  |  |  |
| `itemized_test_id` | `smallint(6)` | no |  |  |  |
| `numerator_label` | `varchar(25)` | no | `''` |  | Only used in special cases |
| `pass` | `tinyint(1)` | no | `0` |  | 0 is fail, 1 is pass, 2 is excluded |
| `pid` | `bigint(20)` | no |  |  |  |
| `rule_id` | `varchar(31)` | yes | `NULL` |  | fk to clinical_rules.rule_id |
| `item_details` | `text` | yes | `NULL` |  | JSON with specific sub item results for a clinical rule |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `report_id` |  | `report_id`, `itemized_test_id`, `numerator_label`, `pass` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
