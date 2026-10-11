# `list_options`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `list_id` | `varchar(100)` | no | `''` |  |  |
| `option_id` | `varchar(100)` | no | `''` |  |  |
| `title` | `varchar(255)` | no | `''` |  |  |
| `seq` | `int(11)` | no | `0` |  |  |
| `is_default` | `tinyint(1)` | no | `0` |  |  |
| `option_value` | `float` | no | `0` |  |  |
| `mapping` | `varchar(31)` | no | `''` |  |  |
| `notes` | `text` | yes | `NULL` |  |  |
| `codes` | `varchar(255)` | no | `''` |  |  |
| `toggle_setting_1` | `tinyint(1)` | no | `0` |  |  |
| `toggle_setting_2` | `tinyint(1)` | no | `0` |  |  |
| `activity` | `tinyint(4)` | no | `1` |  |  |
| `subtype` | `varchar(31)` | no | `''` |  |  |
| `edit_options` | `tinyint(1)` | no | `1` |  |  |
| `timestamp` | `timestamp` | no | `current_timestamp()` |  |  |
| `last_updated` | `datetime` | no | `current_timestamp()` | on update current_timestamp() |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `list_id`, `option_id` |

## Changes since 7.0.0

- **7.0.3:** added `last_updated` datetime

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
