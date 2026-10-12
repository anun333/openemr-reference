# `form_eye_mag_orders`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `form_id` | `int(20)` | no |  |  |  |
| `pid` | `bigint(20)` | no |  |  |  |
| `ORDER_DETAILS` | `varchar(255)` | no |  |  |  |
| `ORDER_STATUS` | `varchar(50)` | yes | `NULL` |  |  |
| `ORDER_PRIORITY` | `varchar(50)` | yes | `NULL` |  |  |
| `ORDER_DATE_PLACED` | `date` | no |  |  |  |
| `ORDER_PLACED_BYWHOM` | `varchar(50)` | yes | `NULL` |  |  |
| `ORDER_DATE_COMPLETED` | `date` | yes | `NULL` |  |  |
| `ORDER_COMPLETED_BYWHOM` | `varchar(50)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `VISIT_ID` | yes | `pid`, `ORDER_DETAILS`, `ORDER_DATE_PLACED` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
