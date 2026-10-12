# `benefit_eligibility`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `response_id` | `bigint(20)` | no |  |  |  |
| `verification_id` | `bigint(20)` | no |  |  |  |
| `type` | `varchar(4)` | yes | `NULL` |  |  |
| `benefit_type` | `varchar(255)` | yes | `NULL` |  |  |
| `start_date` | `date` | yes | `NULL` |  |  |
| `end_date` | `date` | yes | `NULL` |  |  |
| `coverage_level` | `varchar(255)` | yes | `NULL` |  |  |
| `coverage_type` | `varchar(512)` | yes | `NULL` |  |  |
| `plan_type` | `varchar(255)` | yes | `NULL` |  |  |
| `plan_description` | `varchar(255)` | yes | `NULL` |  |  |
| `coverage_period` | `varchar(255)` | yes | `NULL` |  |  |
| `amount` | `decimal(5,2)` | yes | `NULL` |  |  |
| `percent` | `decimal(3,2)` | yes | `NULL` |  |  |
| `network_ind` | `varchar(2)` | yes | `NULL` |  |  |
| `message` | `varchar(512)` | yes | `NULL` |  |  |
| `response_status` | `enum('A','D')` | yes | `'A'` |  |  |
| `response_create_date` | `date` | yes | `NULL` |  |  |
| `response_modify_date` | `date` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
