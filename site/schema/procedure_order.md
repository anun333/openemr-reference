# `procedure_order`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `procedure_order_id` | `bigint(20)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `provider_id` | `bigint(20)` | no | `0` |  | references users.id, the ordering provider |
| `patient_id` | `bigint(20)` | no |  |  | references patient_data.pid |
| `encounter_id` | `bigint(20)` | no | `0` |  | references form_encounter.encounter |
| `date_collected` | `datetime` | yes | `NULL` |  | time specimen collected |
| `date_ordered` | `datetime` | yes | `NULL` |  |  |
| `order_priority` | `varchar(31)` | no | `''` |  |  |
| `order_status` | `varchar(31)` | no | `''` |  | pending,routed,complete,canceled |
| `patient_instructions` | `text` | yes | `NULL` |  |  |
| `activity` | `tinyint(1)` | no | `1` |  | 0 if deleted |
| `control_id` | `varchar(255)` | no | `''` |  | This is the CONTROL ID that is sent back from lab |
| `lab_id` | `bigint(20)` | no | `0` |  | references procedure_providers.ppid |
| `specimen_type` | `varchar(31)` | no | `''` |  | from the Specimen_Type list |
| `specimen_location` | `varchar(31)` | no | `''` |  | from the Specimen_Location list |
| `specimen_volume` | `varchar(30)` | no | `''` |  | from a text input field |
| `date_transmitted` | `datetime` | yes | `NULL` |  | time of order transmission, null if unsent |
| `clinical_hx` | `varchar(255)` | no | `''` |  | clinical history text that may be relevant to the order |
| `external_id` | `varchar(20)` | yes | `NULL` |  |  |
| `history_order` | `enum('0','1')` | yes | `'0'` |  | references order is added for history purpose only. |
| `order_diagnosis` | `varchar(255)` | yes | `''` |  | primary order diagnosis |
| `billing_type` | `varchar(4)` | yes | `NULL` |  |  |
| `specimen_fasting` | `varchar(31)` | yes | `NULL` |  |  |
| `order_psc` | `tinyint(4)` | yes | `NULL` |  |  |
| `order_abn` | `varchar(31)` | no | `'not_required'` |  |  |
| `collector_id` | `bigint(11)` | no | `0` |  |  |
| `account` | `varchar(60)` | yes | `NULL` |  |  |
| `account_facility` | `int(11)` | yes | `NULL` |  |  |
| `provider_number` | `varchar(30)` | yes | `NULL` |  |  |
| `procedure_order_type` | `varchar(32)` | no | `'laboratory_test'` |  |  |
| `scheduled_date` | `datetime` | yes | `NULL` |  | Scheduled date for service (FHIR occurrence[x]) |
| `scheduled_start` | `datetime` | yes | `NULL` |  | Scheduled start time (FHIR occurrencePeriod.start) |
| `scheduled_end` | `datetime` | yes | `NULL` |  | Scheduled end time (FHIR occurrencePeriod.end) |
| `performer_type` | `varchar(50)` | yes | `NULL` |  | Type of performer: laboratory, radiology, pathology (SNOMED CT) |
| `order_intent` | `varchar(31)` | no | `'order'` |  | FHIR intent: order, plan, directive, proposal |
| `location_id` | `int(11)` | yes | `NULL` |  | References facility.id for service location (FHIR locationReference) |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `procedure_order_id` |
| `datepid` |  | `date_ordered`, `patient_id` |
| `idx_location_id` |  | `location_id` |
| `idx_order_intent` |  | `order_intent` |
| `idx_scheduled_date` |  | `scheduled_date` |
| `idx_specimen_type` |  | `specimen_type` |
| `patient_id` |  | `patient_id` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.4:** added `scheduled_date` datetime; added `scheduled_start` datetime; added `scheduled_end` datetime; added `performer_type` varchar(50); added `order_intent` varchar(31); added `location_id` int(11); index `idx_location_id` added (location_id); index `idx_order_intent` added (order_intent); index `idx_scheduled_date` added (scheduled_date); index `idx_specimen_type` added (specimen_type)

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
