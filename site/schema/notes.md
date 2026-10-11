# `notes`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no | `0` |  |  |
| `foreign_id` | `int(11)` | no | `0` |  |  |
| `note` | `varchar(255)` | yes | `NULL` |  |  |
| `owner` | `int(11)` | yes | `NULL` |  |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `revision` | `timestamp` | no |  |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `date` |  | `date` |
| `foreign_id` |  | `owner` |
| `foreign_id_2` |  | `foreign_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
