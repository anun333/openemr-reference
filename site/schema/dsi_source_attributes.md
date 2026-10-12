# `dsi_source_attributes`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. Holds information about decision support intervention system source attributes

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20) unsigned` | no |  | auto_increment |  |
| `client_id` | `varchar(80)` | no |  |  |  |
| `list_id` | `varchar(100)` | no |  |  |  |
| `option_id` | `varchar(100)` | no |  |  |  |
| `clinical_rule_id` | `varchar(31)` | yes | `NULL` |  |  |
| `source_value` | `text` | yes | `NULL` |  |  |
| `created_by` | `bigint(20)` | yes | `NULL` |  |  |
| `last_updated_by` | `bigint(20)` | yes | `NULL` |  |  |
| `created_at` | `timestamp` | yes | `current_timestamp()` |  |  |
| `last_updated_at` | `timestamp` | yes | `current_timestamp()` | on update current_timestamp() |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `list_id` | yes | `list_id`, `option_id`, `client_id` |

## Changes since 7.0.0

- **7.0.3:** table added

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
