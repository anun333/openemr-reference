# `eligibility_verification`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `verification_id` | `bigint(20)` | no |  | auto_increment |  |
| `response_id` | `varchar(32)` | yes | `NULL` |  |  |
| `insurance_id` | `bigint(20)` | yes | `NULL` |  |  |
| `eligibility_check_date` | `datetime` | yes | `NULL` |  |  |
| `copay` | `int(11)` | yes | `NULL` |  |  |
| `deductible` | `int(11)` | yes | `NULL` |  |  |
| `deductiblemet` | `enum('Y','N')` | yes | `'Y'` |  |  |
| `create_date` | `date` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `verification_id` |
| `insurance_id` |  | `insurance_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
