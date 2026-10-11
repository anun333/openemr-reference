# `standardized_tables_track`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `imported_date` | `datetime` | yes | `NULL` |  |  |
| `name` | `varchar(255)` | no | `''` |  | name of standardized tables such as RXNORM |
| `revision_version` | `varchar(255)` | no | `''` |  | revision of standardized tables that were imported |
| `revision_date` | `datetime` | yes | `NULL` |  | revision of standardized tables that were imported |
| `file_checksum` | `varchar(32)` | no | `''` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
