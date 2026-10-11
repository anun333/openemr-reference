# `patient_care_experience_preferences`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `patient_id` | `int(11)` | no |  |  |  |
| `observation_code` | `varchar(50)` | no |  |  | LOINC code |
| `observation_code_text` | `varchar(255)` | yes | `NULL` |  |  |
| `value_type` | `enum('coded','text','boolean')` | yes | `'coded'` |  |  |
| `value_code` | `varchar(50)` | yes | `NULL` |  | fk to preference_value_sets.answer_code |
| `value_code_system` | `varchar(255)` | yes | `NULL` |  | fk to preference_value_sets.answer_system |
| `value_display` | `varchar(255)` | yes | `NULL` |  | fk to preference_value_sets.answer_display |
| `value_text` | `text` | yes | `NULL` |  |  |
| `value_boolean` | `tinyint(1)` | yes | `NULL` |  |  |
| `effective_datetime` | `datetime` | no | `current_timestamp()` |  |  |
| `status` | `varchar(20)` | yes | `'final'` |  | valid options are final,amended,preliminary |
| `note` | `text` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `observation_code` |  | `observation_code` |
| `patient_id` |  | `patient_id` |
| `status` |  | `status` |
| `unq_uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.4:** table added

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
