# `lbf_data`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. contains all data from layout-based forms

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `form_id` | `int(11)` | no |  | auto_increment | references forms.form_id |
| `field_id` | `varchar(31)` | no |  |  | references layout_options.field_id |
| `field_value` | `longtext` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `form_id`, `field_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
