# `medex_prefs`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `MedEx_id` | `int(11)` | yes | `0` |  |  |
| `ME_username` | `varchar(100)` | yes | `NULL` |  |  |
| `ME_api_key` | `text` | yes | `NULL` |  |  |
| `ME_facilities` | `varchar(50)` | yes | `NULL` |  |  |
| `ME_providers` | `varchar(100)` | yes | `NULL` |  |  |
| `ME_hipaa_default_override` | `varchar(3)` | yes | `NULL` |  |  |
| `PHONE_country_code` | `int(4)` | no | `1` |  |  |
| `MSGS_default_yes` | `varchar(3)` | yes | `NULL` |  |  |
| `POSTCARDS_local` | `varchar(3)` | yes | `NULL` |  |  |
| `POSTCARDS_remote` | `varchar(3)` | yes | `NULL` |  |  |
| `LABELS_local` | `varchar(3)` | yes | `NULL` |  |  |
| `LABELS_choice` | `varchar(50)` | yes | `NULL` |  |  |
| `combine_time` | `tinyint(4)` | yes | `NULL` |  |  |
| `postcard_top` | `varchar(255)` | yes | `NULL` |  |  |
| `status` | `text` | yes | `NULL` |  |  |
| `MedEx_lastupdated` | `timestamp` | no | `current_timestamp()` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `ME_username` | yes | `ME_username` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
