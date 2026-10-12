# `ccda`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `encounter` | `bigint(20)` | yes | `NULL` |  |  |
| `ccda_data` | `longtext` | yes | `NULL` |  |  |
| `time` | `varchar(50)` | yes | `NULL` |  |  |
| `status` | `smallint(6)` | yes | `NULL` |  |  |
| `updated_date` | `timestamp` | no | `current_timestamp()` | on update current_timestamp() |  |
| `user_id` | `varchar(50)` | yes | `NULL` |  |  |
| `couch_docid` | `varchar(100)` | yes | `NULL` |  |  |
| `couch_revid` | `varchar(100)` | yes | `NULL` |  |  |
| `hash` | `varchar(255)` | yes | `NULL` |  |  |
| `view` | `tinyint(4)` | no | `0` |  |  |
| `transfer` | `tinyint(4)` | no | `0` |  |  |
| `emr_transfer` | `tinyint(4)` | no | `0` |  |  |
| `encrypted` | `tinyint(4)` | no | `0` |  | 0->No,1->Yes |
| `transaction_id` | `bigint(20)` | yes | `NULL` |  | fk to transaction referral record |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `unique_key` | yes | `pid`, `encounter`, `time` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.1:** `ccda_data` type mediumtext → longtext

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
