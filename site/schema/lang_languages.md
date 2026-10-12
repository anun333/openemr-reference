# `lang_languages`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `lang_id` | `int(11)` | no |  | auto_increment |  |
| `lang_code` | `char(2)` | no | `''` |  |  |
| `lang_description` | `varchar(100)` | yes | `NULL` |  |  |
| `lang_is_rtl` | `tinyint(4)` | yes | `0` |  | Set this to 1 for RTL languages Arabic, Farsi, Hebrew, Urdu etc. |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `lang_id` | yes | `lang_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
