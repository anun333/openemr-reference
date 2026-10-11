# `documents_legal_categories`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `dlc_id` | `int(10) unsigned` | no |  | auto_increment |  |
| `dlc_category_type` | `int(10) unsigned` | no |  |  | 1 category 2 subcategory |
| `dlc_category_name` | `varchar(45)` | no |  |  |  |
| `dlc_category_parent` | `int(10) unsigned` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `dlc_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
