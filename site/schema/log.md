# `log`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `event` | `varchar(255)` | yes | `NULL` |  |  |
| `category` | `varchar(255)` | yes | `NULL` |  |  |
| `user` | `varchar(255)` | yes | `NULL` |  |  |
| `groupname` | `varchar(255)` | yes | `NULL` |  |  |
| `comments` | `longtext` | yes | `NULL` |  |  |
| `user_notes` | `longtext` | yes | `NULL` |  |  |
| `patient_id` | `bigint(20)` | yes | `NULL` |  |  |
| `success` | `tinyint(1)` | yes | `1` |  |  |
| `checksum` | `longtext` | yes | `NULL` |  |  |
| `crt_user` | `varchar(255)` | yes | `NULL` |  |  |
| `log_from` | `varchar(20)` | yes | `'open-emr'` |  |  |
| `menu_item_id` | `int(11)` | yes | `NULL` |  |  |
| `ccda_doc_id` | `int(11)` | yes | `NULL` |  | CCDA document id from ccda |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `patient_id` |  | `patient_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
