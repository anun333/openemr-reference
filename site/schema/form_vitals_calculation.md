# `form_vitals_calculation`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. Main calculation records - one per logical calculation (e.g., average BP)

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `encounter` | `bigint(20)` | yes | `NULL` |  | fk to form_encounter.id |
| `pid` | `bigint(20)` | no |  |  | fk to patient_data.pid |
| `date_start` | `datetime` | yes | `NULL` |  |  |
| `date_end` | `datetime` | yes | `NULL` |  |  |
| `created_at` | `datetime` | yes | `NULL` |  |  |
| `updated_at` | `datetime` | yes | `NULL` |  |  |
| `created_by` | `bigint(20)` | yes | `NULL` |  |  |
| `updated_by` | `bigint(20)` | yes | `NULL` |  |  |
| `calculation_id` | `varchar(64)` | yes | `NULL` |  | application identifier representing calculation e.g., bp-MeanLast5, bp-Mean3Day, bp-MeanEncounter |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `idx_calculation_id` |  | `calculation_id` |
| `idx_encounter` |  | `encounter` |
| `idx_pid` |  | `pid` |
| `unq_uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.4:** table added

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
