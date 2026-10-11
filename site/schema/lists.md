# `lists`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `type` | `varchar(255)` | yes | `NULL` |  |  |
| `subtype` | `varchar(31)` | no | `''` |  |  |
| `title` | `varchar(255)` | yes | `NULL` |  |  |
| `udi` | `varchar(255)` | yes | `NULL` |  |  |
| `udi_data` | `text` | yes | `NULL` |  |  |
| `begdate` | `datetime` | yes | `NULL` |  |  |
| `enddate` | `datetime` | yes | `NULL` |  |  |
| `returndate` | `date` | yes | `NULL` |  |  |
| `occurrence` | `int(11)` | yes | `0` |  | Reference to list_options option_id='occurrence' |
| `classification` | `int(11)` | yes | `0` |  |  |
| `referredby` | `varchar(255)` | yes | `NULL` |  |  |
| `extrainfo` | `varchar(255)` | yes | `NULL` |  |  |
| `diagnosis` | `varchar(255)` | yes | `NULL` |  |  |
| `activity` | `tinyint(4)` | yes | `NULL` |  |  |
| `comments` | `longtext` | yes | `NULL` |  |  |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `user` | `varchar(255)` | yes | `NULL` |  |  |
| `groupname` | `varchar(255)` | yes | `NULL` |  |  |
| `outcome` | `int(11)` | no | `0` |  |  |
| `destination` | `varchar(255)` | yes | `NULL` |  |  |
| `reinjury_id` | `bigint(20)` | no | `0` |  |  |
| `injury_part` | `varchar(31)` | no | `''` |  |  |
| `injury_type` | `varchar(31)` | no | `''` |  |  |
| `injury_grade` | `varchar(31)` | no | `''` |  |  |
| `reaction` | `varchar(255)` | no | `''` |  |  |
| `verification` | `varchar(36)` | no | `''` |  | Reference to list_options option_id = allergyintolerance-verification |
| `external_allergyid` | `int(11)` | yes | `NULL` |  |  |
| `erx_source` | `enum('0','1')` | no | `'0'` |  | 0-OpenEMR 1-External |
| `erx_uploaded` | `enum('0','1')` | no | `'0'` |  | 0-Pending NewCrop upload 1-Uploaded TO NewCrop |
| `modifydate` | `timestamp` | no | `current_timestamp()` | on update current_timestamp() |  |
| `severity_al` | `varchar(50)` | yes | `NULL` |  |  |
| `external_id` | `varchar(20)` | yes | `NULL` |  |  |
| `list_option_id` | `varchar(100)` | yes | `NULL` |  | Reference to list_options table |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `pid` |  | `pid` |
| `type` |  | `type` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
