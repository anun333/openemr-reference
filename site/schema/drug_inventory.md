# `drug_inventory`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `inventory_id` | `int(11)` | no |  | auto_increment |  |
| `drug_id` | `int(11)` | no |  |  |  |
| `lot_number` | `varchar(20)` | yes | `NULL` |  |  |
| `expiration` | `date` | yes | `NULL` |  |  |
| `manufacturer` | `varchar(255)` | yes | `NULL` |  |  |
| `on_hand` | `int(11)` | no | `0` |  |  |
| `warehouse_id` | `varchar(31)` | no | `''` |  |  |
| `vendor_id` | `bigint(20)` | no | `0` |  |  |
| `last_notify` | `date` | yes | `NULL` |  |  |
| `destroy_date` | `date` | yes | `NULL` |  |  |
| `destroy_method` | `varchar(255)` | yes | `NULL` |  |  |
| `destroy_witness` | `varchar(255)` | yes | `NULL` |  |  |
| `destroy_notes` | `varchar(255)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `inventory_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
