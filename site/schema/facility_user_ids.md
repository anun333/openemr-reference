# `facility_user_ids`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `uid` | `bigint(20)` | yes | `NULL` |  |  |
| `facility_id` | `bigint(20)` | yes | `NULL` |  |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `field_id` | `varchar(31)` | no |  |  | references layout_options.field_id |
| `field_value` | `text` | yes | `NULL` |  |  |
| `date_created` | `datetime` | no | `current_timestamp()` |  |  |
| `last_updated` | `datetime` | no | `current_timestamp()` | on update current_timestamp() |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `uid` |  | `uid`, `facility_id`, `field_id` |
| `uuid` |  | `uuid` |

## Changes since 7.0.0

- **7.0.3:** added `date_created` datetime; added `last_updated` datetime

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
