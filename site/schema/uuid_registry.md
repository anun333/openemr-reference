# `uuid_registry`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `uuid` | `binary(16)` | no | `x'00000000000000000000000000000000'` |  |  |
| `table_name` | `varchar(255)` | no | `''` |  |  |
| `table_id` | `varchar(255)` | no | `''` |  |  |
| `table_vertical` | `varchar(255)` | no | `''` |  |  |
| `couchdb` | `varchar(255)` | no | `''` |  |  |
| `document_drive` | `tinyint(4)` | no | `0` |  |  |
| `mapped` | `tinyint(4)` | no | `0` |  |  |
| `created` | `timestamp` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `uuid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
