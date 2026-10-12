# `form_vital_details`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. Detailed information of each vital_forms observation column

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `form_id` | `bigint(20)` | no |  |  | FK to vital_forms.id |
| `vitals_column` | `varchar(64)` | no |  |  | Column name from form_vitals |
| `interpretation_list_id` | `varchar(100)` | yes | `NULL` |  | FK to list_options.list_id for observation_interpretation |
| `interpretation_option_id` | `varchar(100)` | yes | `NULL` |  | FK to list_options.option_id for observation_interpretation |
| `interpretation_codes` | `varchar(255)` | yes | `NULL` |  | Archived original codes value from list_options observation_interpretation |
| `interpretation_title` | `varchar(255)` | yes | `NULL` |  | Archived original title value from list_options observation_interpretation |
| `reason_code` | `varchar(31)` | yes | `NULL` |  | Medical code explaining reason of the vital observation value in form codesystem:codetype;...; |
| `reason_description` | `text` | yes | `NULL` |  | Human readable text description of the reason_code column |
| `reason_status` | `varchar(31)` | yes | `NULL` |  | The status of the reason ie completed, in progress, etc |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `fk_form_id` |  | `form_id` |
| `fk_list_options_id` |  | `interpretation_list_id`, `interpretation_option_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
