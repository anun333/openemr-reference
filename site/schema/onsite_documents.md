# `onsite_documents`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(10) unsigned` | no |  | auto_increment |  |
| `pid` | `bigint(20) unsigned` | yes | `NULL` |  |  |
| `facility` | `int(10) unsigned` | yes | `NULL` |  |  |
| `provider` | `int(10) unsigned` | yes | `NULL` |  |  |
| `encounter` | `int(10) unsigned` | yes | `NULL` |  |  |
| `create_date` | `timestamp` | no | `current_timestamp()` |  |  |
| `doc_type` | `varchar(255)` | no |  |  |  |
| `patient_signed_status` | `smallint(5) unsigned` | no |  |  |  |
| `patient_signed_time` | `datetime` | yes | `NULL` |  |  |
| `authorize_signed_time` | `datetime` | yes | `NULL` |  |  |
| `accept_signed_status` | `smallint(5)` | no |  |  |  |
| `authorizing_signator` | `varchar(50)` | no |  |  |  |
| `review_date` | `datetime` | yes | `NULL` |  |  |
| `denial_reason` | `varchar(255)` | no |  |  |  |
| `authorized_signature` | `text` | yes | `NULL` |  |  |
| `patient_signature` | `text` | yes | `NULL` |  |  |
| `full_document` | `mediumblob` | yes | `NULL` |  |  |
| `file_name` | `varchar(255)` | no |  |  |  |
| `file_path` | `varchar(255)` | no |  |  |  |
| `template_data` | `longtext` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |

## Changes since 7.0.0

- **7.0.2:** added `template_data` longtext

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
