# `enc_category_map`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `rule_enc_id` | `varchar(31)` | no | `''` |  | encounter id from rule_enc_types list in list_options |
| `main_cat_id` | `int(11)` | no | `0` |  | category id from event category in openemr_postcalendar_categories |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `rule_enc_id` |  | `rule_enc_id`, `main_cat_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
