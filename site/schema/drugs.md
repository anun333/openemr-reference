# `drugs`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `drug_id` | `int(11)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `name` | `varchar(255)` | no | `''` |  |  |
| `ndc_number` | `varchar(20)` | no | `''` |  |  |
| `on_order` | `int(11)` | no | `0` |  |  |
| `reorder_point` | `float` | no | `0` |  |  |
| `max_level` | `float` | no | `0` |  |  |
| `last_notify` | `date` | yes | `NULL` |  |  |
| `reactions` | `text` | yes | `NULL` |  |  |
| `form` | `varchar(31)` | no | `'0'` |  |  |
| `size` | `varchar(25)` | no | `''` |  |  |
| `unit` | `varchar(31)` | no | `'0'` |  |  |
| `route` | `varchar(31)` | no | `'0'` |  |  |
| `substitute` | `int(11)` | no | `0` |  |  |
| `related_code` | `varchar(255)` | no | `''` |  | may reference a related codes.code |
| `cyp_factor` | `float` | no | `0` |  | quantity representing a years supply |
| `active` | `tinyint(1)` | yes | `1` |  | 0 = inactive, 1 = active |
| `allow_combining` | `tinyint(1)` | no | `0` |  | 1 = allow filling an order from multiple lots |
| `allow_multiple` | `tinyint(1)` | no | `1` |  | 1 = allow multiple lots at one warehouse |
| `drug_code` | `varchar(25)` | yes | `NULL` |  |  |
| `consumable` | `tinyint(1)` | no | `0` |  | 1 = will not show on the fee sheet |
| `dispensable` | `tinyint(1)` | no | `1` |  | 0 = pharmacy elsewhere, 1 = dispensed here |
| `date_created` | `datetime` | no | `current_timestamp()` |  |  |
| `last_updated` | `datetime` | no | `current_timestamp()` | on update current_timestamp() |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `drug_id` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.3:** added `date_created` datetime; added `last_updated` datetime

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
