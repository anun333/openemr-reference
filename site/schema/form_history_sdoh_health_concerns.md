# `form_history_sdoh_health_concerns`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. Links SDOH assessments to health concern conditions

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `sdoh_history_id` | `bigint(20) unsigned` | no |  |  | FK to form_history_sdoh.id |
| `health_concern_id` | `bigint(20)` | no |  |  | FK to lists.id where type=health_concern or medical_problem |
| `created_at` | `datetime` | no | `current_timestamp()` |  |  |
| `created_by` | `bigint(20)` | yes | `NULL` |  | FK to users.id |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `idx_health_concern` |  | `health_concern_id` |
| `idx_sdoh_history` |  | `sdoh_history_id` |
| `unique_sdoh_concern` | yes | `sdoh_history_id`, `health_concern_id` |

## Changes since 7.0.0

- **7.0.4:** table added

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
