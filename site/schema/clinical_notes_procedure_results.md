# `clinical_notes_procedure_results`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. Links clinical notes to procedure results/lab values

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `clinical_note_id` | `bigint(20)` | no |  |  | Foreign key to form_clinical_notes.id |
| `procedure_result_id` | `bigint(20)` | no |  |  | Foreign key to procedure_result.procedure_result_id |
| `created_at` | `timestamp` | no | `current_timestamp()` |  | When the link was created |
| `created_by` | `varchar(255)` | yes | `NULL` |  | Username who created the link |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `idx_clinical_note_id` |  | `clinical_note_id` |
| `idx_created_at` |  | `created_at` |
| `idx_procedure_result_id` |  | `procedure_result_id` |
| `unique_note_result` | yes | `clinical_note_id`, `procedure_result_id` |

## Changes since 7.0.0

- **7.0.4:** table added

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
