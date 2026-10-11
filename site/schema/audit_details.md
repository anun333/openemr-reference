# `audit_details`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `table_name` | `varchar(100)` | no |  |  | openemr table name |
| `field_name` | `varchar(100)` | no |  |  | openemr table's field name |
| `field_value` | `longtext` | yes | `NULL` |  | openemr table's field value |
| `audit_master_id` | `bigint(20)` | no |  |  | Id of the audit_master table |
| `entry_identification` | `varchar(255)` | no | `'1'` |  | Used when multiple entry occurs from the same table.1 means no multiple entry |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `audit_master_id` |  | `audit_master_id` |

## Changes since 7.0.0

- **7.0.1:** `field_value` type text → longtext

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
