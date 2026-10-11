# `form_clinical_notes`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `form_id` | `bigint(20)` | no |  |  |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `date` | `date` | yes | `NULL` |  |  |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `encounter` | `varchar(255)` | yes | `NULL` |  |  |
| `user` | `varchar(255)` | yes | `NULL` |  |  |
| `groupname` | `varchar(255)` | yes | `NULL` |  |  |
| `authorized` | `tinyint(4)` | yes | `NULL` |  |  |
| `activity` | `tinyint(4)` | yes | `NULL` |  |  |
| `code` | `varchar(255)` | yes | `NULL` |  |  |
| `codetext` | `text` | yes | `NULL` |  |  |
| `description` | `text` | yes | `NULL` |  |  |
| `external_id` | `varchar(30)` | yes | `NULL` |  |  |
| `clinical_notes_type` | `varchar(100)` | yes | `NULL` |  |  |
| `clinical_notes_category` | `varchar(100)` | yes | `NULL` |  |  |
| `note_related_to` | `text` | yes | `NULL` |  |  |
| `last_updated` | `datetime` | no | `current_timestamp()` | on update current_timestamp() |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.3:** added `last_updated` datetime

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
