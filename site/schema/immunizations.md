# `immunizations`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `patient_id` | `bigint(20)` | yes | `NULL` |  |  |
| `administered_date` | `datetime` | yes | `NULL` |  |  |
| `immunization_id` | `int(11)` | yes | `NULL` |  |  |
| `cvx_code` | `varchar(64)` | yes | `NULL` |  |  |
| `manufacturer` | `varchar(100)` | yes | `NULL` |  |  |
| `lot_number` | `varchar(50)` | yes | `NULL` |  |  |
| `administered_by_id` | `bigint(20)` | yes | `NULL` |  |  |
| `administered_by` | `varchar(255)` | yes | `NULL` |  | Alternative to administered_by_id |
| `education_date` | `date` | yes | `NULL` |  |  |
| `vis_date` | `date` | yes | `NULL` |  | Date of VIS Statement |
| `note` | `text` | yes | `NULL` |  |  |
| `create_date` | `datetime` | yes | `NULL` |  |  |
| `update_date` | `timestamp` | no |  |  |  |
| `created_by` | `bigint(20)` | yes | `NULL` |  |  |
| `updated_by` | `bigint(20)` | yes | `NULL` |  |  |
| `amount_administered` | `float` | yes | `NULL` |  |  |
| `amount_administered_unit` | `varchar(50)` | yes | `NULL` |  |  |
| `expiration_date` | `date` | yes | `NULL` |  |  |
| `route` | `varchar(100)` | yes | `NULL` |  |  |
| `administration_site` | `varchar(100)` | yes | `NULL` |  |  |
| `added_erroneously` | `tinyint(1)` | no | `0` |  |  |
| `external_id` | `varchar(20)` | yes | `NULL` |  |  |
| `completion_status` | `varchar(50)` | yes | `NULL` |  |  |
| `information_source` | `varchar(31)` | yes | `NULL` |  |  |
| `refusal_reason` | `varchar(31)` | yes | `NULL` |  |  |
| `ordering_provider` | `int(11)` | yes | `NULL` |  |  |
| `reason_code` | `varchar(31)` | yes | `NULL` |  | Medical code explaining reason of the vital observation value in form codesystem:codetype;...; |
| `reason_description` | `text` | yes | `NULL` |  | Human readable text description of the reason_code column |
| `encounter_id` | `bigint(20)` | yes | `NULL` |  | fk to form_encounter.encounter to link immunization to encounter record |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `patient_id` |  | `patient_id` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.4:** added `encounter_id` bigint(20)

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
