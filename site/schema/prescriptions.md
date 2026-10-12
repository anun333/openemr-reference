# `prescriptions`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `patient_id` | `bigint(20)` | yes | `NULL` |  |  |
| `filled_by_id` | `int(11)` | yes | `NULL` |  |  |
| `pharmacy_id` | `int(11)` | yes | `NULL` |  |  |
| `date_added` | `datetime` | yes | `NULL` |  | Datetime the prescriptions was initially created |
| `date_modified` | `datetime` | yes | `NULL` |  | Datetime the prescriptions was last modified |
| `provider_id` | `int(11)` | yes | `NULL` |  |  |
| `encounter` | `int(11)` | yes | `NULL` |  |  |
| `start_date` | `date` | yes | `NULL` |  |  |
| `drug` | `varchar(150)` | yes | `NULL` |  |  |
| `drug_id` | `int(11)` | no | `0` |  |  |
| `rxnorm_drugcode` | `varchar(25)` | yes | `NULL` |  |  |
| `form` | `int(3)` | yes | `NULL` |  |  |
| `dosage` | `varchar(100)` | yes | `NULL` |  |  |
| `quantity` | `varchar(31)` | yes | `NULL` |  |  |
| `size` | `varchar(25)` | yes | `NULL` |  |  |
| `unit` | `int(11)` | yes | `NULL` |  |  |
| `route` | `varchar(100)` | yes | `NULL` |  | Max size 100 characters is same max as immunizations |
| `interval` | `int(11)` | yes | `NULL` |  |  |
| `substitute` | `int(11)` | yes | `NULL` |  |  |
| `refills` | `int(11)` | yes | `NULL` |  |  |
| `per_refill` | `int(11)` | yes | `NULL` |  |  |
| `filled_date` | `date` | yes | `NULL` |  |  |
| `medication` | `int(11)` | yes | `NULL` |  |  |
| `note` | `text` | yes | `NULL` |  |  |
| `active` | `int(11)` | no | `1` |  |  |
| `datetime` | `datetime` | yes | `NULL` |  |  |
| `user` | `varchar(50)` | yes | `NULL` |  |  |
| `site` | `varchar(50)` | yes | `NULL` |  |  |
| `prescriptionguid` | `varchar(50)` | yes | `NULL` |  |  |
| `erx_source` | `tinyint(4)` | no | `0` |  | 0-OpenEMR 1-External |
| `erx_uploaded` | `tinyint(4)` | no | `0` |  | 0-Pending NewCrop upload 1-Uploaded to NewCrop |
| `drug_info_erx` | `text` | yes | `NULL` |  |  |
| `external_id` | `varchar(20)` | yes | `NULL` |  |  |
| `end_date` | `date` | yes | `NULL` |  |  |
| `indication` | `text` | yes | `NULL` |  |  |
| `prn` | `varchar(30)` | yes | `NULL` |  |  |
| `ntx` | `int(2)` | yes | `NULL` |  |  |
| `rtx` | `int(2)` | yes | `NULL` |  |  |
| `txDate` | `date` | no |  |  |  |
| `usage_category` | `varchar(100)` | yes | `NULL` |  | option_id in list_options.list_id=medication-usage-category |
| `usage_category_title` | `varchar(255)` | no |  |  | title in list_options.list_id=medication-usage-category |
| `request_intent` | `varchar(100)` | yes | `NULL` |  | option_id in list_options.list_id=medication-request-intent |
| `request_intent_title` | `varchar(255)` | no |  |  | title in list_options.list_id=medication-request-intent |
| `drug_dosage_instructions` | `longtext` | yes | `NULL` |  | Medication dosage instructions |
| `diagnosis` | `text` | yes | `NULL` |  | Diagnosis or reason for the prescription |
| `created_by` | `bigint(20)` | yes | `NULL` |  | users.id the user that first created this record |
| `updated_by` | `bigint(20)` | yes | `NULL` |  | users.id the user that last modified this record |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `patient_id` |  | `patient_id` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.1:** `route` type int(11) → varchar(100)
- **7.0.4:** added `diagnosis` text

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
