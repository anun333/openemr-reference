# `contact_telecom`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `contact_id` | `bigint(20)` | no |  |  |  |
| `rank` | `int(11)` | yes | `NULL` |  | Specify preferred order of use (1 = highest) |
| `system` | `varchar(255)` | yes | `NULL` |  | FK to list_options.option_id for list_id telecom_systems [phone, fax, email, pager, url, sms, other] |
| `use` | `varchar(255)` | yes | `NULL` |  | FK to list_options.option_id for list_id telecom_uses [home, work, temp, old, mobile] |
| `value` | `varchar(255)` | yes | `NULL` |  |  |
| `status` | `char(1)` | yes | `NULL` |  | A=active,I=inactive |
| `is_primary` | `char(1)` | yes | `NULL` |  | Y=yes,N=no |
| `notes` | `tinytext` | yes | `NULL` |  |  |
| `period_start` | `datetime` | yes | `NULL` |  | Date the telecom became active |
| `period_end` | `datetime` | yes | `NULL` |  | Date the telecom became deactivated |
| `inactivated_reason` | `varchar(45)` | yes | `NULL` |  | [Values: ???, etc] |
| `created_date` | `datetime` | no | `current_timestamp()` |  |  |
| `created_by` | `bigint(20)` | yes | `NULL` |  | users.id |
| `updated_date` | `datetime` | yes | `current_timestamp()` | on update current_timestamp() |  |
| `updated_by` | `bigint(20)` | yes | `NULL` |  | users.id |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `contact_id` |  | `contact_id` |

## Changes since 7.0.0

- **7.0.4:** table added

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
