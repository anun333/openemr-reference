# `form_encounter`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `reason` | `longtext` | yes | `NULL` |  |  |
| `facility` | `longtext` | yes | `NULL` |  |  |
| `facility_id` | `int(11)` | no | `0` |  |  |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `encounter` | `bigint(20)` | yes | `NULL` |  |  |
| `onset_date` | `datetime` | yes | `NULL` |  |  |
| `sensitivity` | `varchar(30)` | yes | `NULL` |  |  |
| `billing_note` | `text` | yes | `NULL` |  |  |
| `pc_catid` | `int(11)` | no | `5` |  | event category from openemr_postcalendar_categories |
| `last_level_billed` | `int(11)` | no | `0` |  | 0=none, 1=ins1, 2=ins2, etc |
| `last_level_closed` | `int(11)` | no | `0` |  | 0=none, 1=ins1, 2=ins2, etc |
| `last_stmt_date` | `date` | yes | `NULL` |  |  |
| `stmt_count` | `int(11)` | no | `0` |  |  |
| `provider_id` | `int(11)` | yes | `0` |  | default and main provider for this visit |
| `supervisor_id` | `int(11)` | yes | `0` |  | supervising provider, if any, for this visit |
| `invoice_refno` | `varchar(31)` | no | `''` |  |  |
| `referral_source` | `varchar(31)` | no | `''` |  |  |
| `billing_facility` | `int(11)` | no | `0` |  |  |
| `external_id` | `varchar(20)` | yes | `NULL` |  |  |
| `pos_code` | `tinyint(4)` | yes | `NULL` |  |  |
| `parent_encounter_id` | `bigint(20)` | yes | `NULL` |  |  |
| `class_code` | `varchar(10)` | no | `'AMB'` |  |  |
| `shift` | `varchar(31)` | no | `''` |  |  |
| `voucher_number` | `varchar(255)` | no | `''` |  | also called referral number |
| `discharge_disposition` | `varchar(100)` | yes | `NULL` |  |  |
| `encounter_type_code` | `varchar(31)` | yes | `NULL` |  | not all types are categories |
| `encounter_type_description` | `text` | yes | `NULL` |  |  |
| `referring_provider_id` | `int(11)` | yes | `0` |  | referring provider, if any, for this visit |
| `date_end` | `datetime` | yes | `NULL` |  |  |
| `in_collection` | `tinyint(1)` | yes | `NULL` |  |  |
| `last_update` | `timestamp` | no | `current_timestamp()` | on update current_timestamp() |  |
| `ordering_provider_id` | `int(11)` | yes | `0` |  | referring provider, if any, for this visit |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `encounter_date` |  | `date` |
| `pid_encounter` |  | `pid`, `encounter` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.1:** added `in_collection` tinyint(1)
- **7.0.3:** added `last_update` timestamp; added `ordering_provider_id` int(11)

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
