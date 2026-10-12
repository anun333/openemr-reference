# `care_teams`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `pid` | `int(11)` | no |  |  | fk to patient_data.pid |
| `status` | `varchar(100)` | yes | `'active'` |  | fk to list_options.option_id where list_id=Care_Team_Status |
| `team_name` | `varchar(255)` | yes | `NULL` |  |  |
| `note` | `text` | yes | `NULL` |  |  |
| `date_created` | `datetime` | yes | `current_timestamp()` |  |  |
| `date_updated` | `datetime` | yes | `current_timestamp()` | on update current_timestamp() |  |
| `created_by` | `bigint(20)` | yes | `NULL` |  | fk to users.id for user who created this record |
| `updated_by` | `bigint(20)` | yes | `NULL` |  | fk to users.id for user who last updated this record |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.4:** table added

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
