# `fee_schedule`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `insurance_company_id` | `int(11)` | no | `0` |  |  |
| `plan` | `varchar(20)` | yes | `''` |  |  |
| `code` | `varchar(10)` | yes | `''` |  |  |
| `modifier` | `varchar(2)` | yes | `''` |  |  |
| `type` | `varchar(20)` | yes | `''` |  |  |
| `fee` | `decimal(12,2)` | yes | `NULL` |  |  |
| `effective_date` | `date` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `ins_plan_code_mod_type_date` | yes | `insurance_company_id`, `plan`, `code`, `modifier`, `type`, `effective_date` |

## Changes since 7.0.0

- **7.0.2:** table added

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
