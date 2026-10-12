# `drug_sales`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `uuid` | `binary(16)` | yes | `NULL` |  | UUID for this drug sales record, for data exchange purposes |
| `sale_id` | `int(11)` | no |  | auto_increment |  |
| `drug_id` | `int(11)` | no |  |  |  |
| `inventory_id` | `int(11)` | no |  |  |  |
| `prescription_id` | `int(11)` | no | `0` |  |  |
| `pid` | `bigint(20)` | no | `0` |  |  |
| `encounter` | `int(11)` | no | `0` |  |  |
| `user` | `varchar(255)` | yes | `NULL` |  |  |
| `sale_date` | `date` | no |  |  |  |
| `quantity` | `int(11)` | no | `0` |  |  |
| `fee` | `decimal(12,2)` | no | `0.00` |  |  |
| `billed` | `tinyint(1)` | no | `0` |  | indicates if the sale is posted to accounting |
| `xfer_inventory_id` | `int(11)` | no | `0` |  |  |
| `distributor_id` | `bigint(20)` | no | `0` |  | references users.id |
| `notes` | `varchar(255)` | no | `''` |  |  |
| `bill_date` | `datetime` | yes | `NULL` |  |  |
| `pricelevel` | `varchar(31)` | yes | `''` |  |  |
| `selector` | `varchar(255)` | yes | `''` |  | references drug_templates.selector |
| `trans_type` | `tinyint(4)` | no | `1` |  | 1=sale, 2=purchase, 3=return, 4=transfer, 5=adjustment |
| `chargecat` | `varchar(31)` | yes | `''` |  |  |
| `pharmacy_supply_type` | `varchar(50)` | yes | `NULL` |  | fk to list_options.option_id where list_id=pharmacy_supply_type to indicate type of dispensing first order, refil, emergency, partial order, etc |
| `last_updated` | `datetime` | no | `current_timestamp()` | on update current_timestamp() |  |
| `date_created` | `datetime` | no | `current_timestamp()` |  |  |
| `updated_by` | `bigint(20)` | yes | `NULL` |  | fk to users.id for user that last updated this entry |
| `created_by` | `bigint(20)` | yes | `NULL` |  | fk to users.id for user that created this entry |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `sale_id` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.4:** added `uuid` binary(16); added `pharmacy_supply_type` varchar(50); added `last_updated` datetime; added `date_created` datetime; added `updated_by` bigint(20); added `created_by` bigint(20); index `uuid` added (uuid)

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
