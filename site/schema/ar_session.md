# `ar_session`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `session_id` | `int(10) unsigned` | no |  | auto_increment |  |
| `payer_id` | `int(11)` | no |  |  | 0=pt else references insurance_companies.id |
| `user_id` | `int(11)` | no |  |  | references users.id for session owner |
| `closed` | `tinyint(1)` | no | `0` |  | 0=no, 1=yes |
| `reference` | `varchar(255)` | no | `''` |  | check or EOB number |
| `check_date` | `date` | yes | `NULL` |  |  |
| `deposit_date` | `date` | yes | `NULL` |  |  |
| `pay_total` | `decimal(12,2)` | no | `0.00` |  |  |
| `created_time` | `timestamp` | no | `current_timestamp()` |  |  |
| `modified_time` | `datetime` | no |  |  |  |
| `global_amount` | `decimal(12,2)` | no |  |  |  |
| `payment_type` | `varchar(50)` | no |  |  |  |
| `description` | `text` | yes | `NULL` |  |  |
| `adjustment_code` | `varchar(50)` | no |  |  |  |
| `post_to_date` | `date` | no |  |  |  |
| `patient_id` | `bigint(20)` | no |  |  |  |
| `payment_method` | `varchar(25)` | no |  |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `session_id` |
| `deposit_date` |  | `deposit_date` |
| `user_closed` |  | `user_id`, `closed` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
