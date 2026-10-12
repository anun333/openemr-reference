# `preference_value_sets`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. Answer lists for preference codes

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `loinc_code` | `varchar(50)` | no |  |  |  |
| `answer_code` | `varchar(100)` | no |  |  |  |
| `answer_system` | `varchar(255)` | no |  |  |  |
| `answer_display` | `varchar(255)` | no |  |  |  |
| `answer_definition` | `text` | yes | `NULL` |  |  |
| `sort_order` | `int(11)` | yes | `0` |  |  |
| `active` | `tinyint(1)` | yes | `1` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `loinc_code` |  | `loinc_code` |

## Changes since 7.0.0

- **7.0.4:** table added

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
