# `form_misc_billing_options`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `user` | `varchar(255)` | yes | `NULL` |  |  |
| `groupname` | `varchar(255)` | yes | `NULL` |  |  |
| `authorized` | `tinyint(4)` | yes | `NULL` |  |  |
| `activity` | `tinyint(4)` | yes | `NULL` |  |  |
| `employment_related` | `tinyint(1)` | yes | `NULL` |  |  |
| `auto_accident` | `tinyint(1)` | yes | `NULL` |  |  |
| `accident_state` | `varchar(2)` | yes | `NULL` |  |  |
| `other_accident` | `tinyint(1)` | yes | `NULL` |  |  |
| `medicaid_referral_code` | `varchar(2)` | yes | `NULL` |  |  |
| `epsdt_flag` | `tinyint(1)` | yes | `NULL` |  |  |
| `provider_qualifier_code` | `varchar(2)` | yes | `NULL` |  |  |
| `provider_id` | `int(11)` | yes | `NULL` |  |  |
| `outside_lab` | `tinyint(1)` | yes | `NULL` |  |  |
| `lab_amount` | `decimal(5,2)` | yes | `NULL` |  |  |
| `is_unable_to_work` | `tinyint(1)` | yes | `NULL` |  |  |
| `onset_date` | `date` | yes | `NULL` |  |  |
| `date_initial_treatment` | `date` | yes | `NULL` |  |  |
| `off_work_from` | `date` | yes | `NULL` |  |  |
| `off_work_to` | `date` | yes | `NULL` |  |  |
| `is_hospitalized` | `tinyint(1)` | yes | `NULL` |  |  |
| `hospitalization_date_from` | `date` | yes | `NULL` |  |  |
| `hospitalization_date_to` | `date` | yes | `NULL` |  |  |
| `medicaid_resubmission_code` | `varchar(10)` | yes | `NULL` |  |  |
| `medicaid_original_reference` | `varchar(15)` | yes | `NULL` |  |  |
| `prior_auth_number` | `varchar(20)` | yes | `NULL` |  |  |
| `comments` | `varchar(255)` | yes | `NULL` |  |  |
| `replacement_claim` | `tinyint(1)` | yes | `0` |  |  |
| `icn_resubmission_number` | `varchar(35)` | yes | `NULL` |  |  |
| `box_14_date_qual` | `char(3)` | yes | `NULL` |  |  |
| `box_15_date_qual` | `char(3)` | yes | `NULL` |  |  |
| `encounter` | `bigint(20)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `encounter` | yes | `encounter` |

## Changes since 7.0.0

- **7.0.4:** added `encounter` bigint(20); index `encounter` added (encounter)

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
