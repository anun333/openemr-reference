# `form_vitals`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `pid` | `bigint(20)` | yes | `0` |  |  |
| `user` | `varchar(255)` | yes | `NULL` |  |  |
| `groupname` | `varchar(255)` | yes | `NULL` |  |  |
| `authorized` | `tinyint(4)` | yes | `0` |  |  |
| `activity` | `tinyint(4)` | yes | `0` |  |  |
| `bps` | `varchar(40)` | yes | `NULL` |  |  |
| `bpd` | `varchar(40)` | yes | `NULL` |  |  |
| `weight` | `decimal(12,6)` | yes | `0.000000` |  |  |
| `height` | `decimal(12,6)` | yes | `0.000000` |  |  |
| `temperature` | `decimal(12,6)` | yes | `0.000000` |  |  |
| `temp_method` | `varchar(255)` | yes | `NULL` |  |  |
| `pulse` | `decimal(12,6)` | yes | `0.000000` |  |  |
| `respiration` | `decimal(12,6)` | yes | `0.000000` |  |  |
| `note` | `varchar(255)` | yes | `NULL` |  |  |
| `BMI` | `decimal(12,6)` | yes | `0.000000` |  |  |
| `BMI_status` | `varchar(255)` | yes | `NULL` |  |  |
| `waist_circ` | `decimal(12,6)` | yes | `0.000000` |  |  |
| `head_circ` | `decimal(12,6)` | yes | `0.000000` |  |  |
| `oxygen_saturation` | `decimal(6,2)` | yes | `0.00` |  |  |
| `oxygen_flow_rate` | `decimal(12,6)` | yes | `0.000000` |  |  |
| `external_id` | `varchar(20)` | yes | `NULL` |  |  |
| `ped_weight_height` | `decimal(6,2)` | yes | `0.00` |  |  |
| `ped_bmi` | `decimal(6,2)` | yes | `0.00` |  |  |
| `ped_head_circ` | `decimal(6,2)` | yes | `0.00` |  |  |
| `inhaled_oxygen_concentration` | `decimal(6,2)` | yes | `0.00` |  |  |
| `last_updated` | `datetime` | no | `current_timestamp()` | on update current_timestamp() |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `pid` |  | `pid` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.3:** added `last_updated` datetime

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
