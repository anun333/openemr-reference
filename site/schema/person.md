# `person`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. Core person demographics - contact info in contact_telecom

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `title` | `varchar(31)` | yes | `NULL` |  | Mr., Mrs., Dr., etc. |
| `first_name` | `varchar(63)` | yes | `NULL` |  |  |
| `middle_name` | `varchar(63)` | yes | `NULL` |  |  |
| `last_name` | `varchar(63)` | yes | `NULL` |  |  |
| `preferred_name` | `varchar(63)` | yes | `NULL` |  | Name person prefers to be called |
| `gender` | `varchar(31)` | yes | `NULL` |  |  |
| `birth_date` | `date` | yes | `NULL` |  |  |
| `death_date` | `date` | yes | `NULL` |  |  |
| `marital_status` | `varchar(31)` | yes | `NULL` |  |  |
| `race` | `varchar(63)` | yes | `NULL` |  |  |
| `ethnicity` | `varchar(63)` | yes | `NULL` |  |  |
| `preferred_language` | `varchar(63)` | yes | `NULL` |  | ISO 639-1 code |
| `communication` | `varchar(254)` | yes | `NULL` |  | Communication preferences/needs |
| `ssn` | `varchar(31)` | yes | `NULL` |  | Should be encrypted in application |
| `active` | `tinyint(1)` | yes | `1` |  | 1=active, 0=inactive |
| `inactive_reason` | `varchar(255)` | yes | `NULL` |  |  |
| `inactive_date` | `datetime` | yes | `NULL` |  |  |
| `notes` | `text` | yes | `NULL` |  |  |
| `created_date` | `datetime` | no | `current_timestamp()` |  |  |
| `created_by` | `bigint(20)` | yes | `NULL` |  | users.id |
| `updated_date` | `datetime` | yes | `current_timestamp()` | on update current_timestamp() |  |
| `updated_by` | `bigint(20)` | yes | `NULL` |  | users.id |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `idx_person_active` |  | `active` |
| `idx_person_dob` |  | `birth_date` |
| `idx_person_name` |  | `last_name`, `first_name` |
| `idx_person_search` |  | `last_name`, `first_name`, `birth_date` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.4:** table added

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
