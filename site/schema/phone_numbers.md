# `phone_numbers`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no | `0` |  |  |
| `country_code` | `varchar(5)` | yes | `NULL` |  |  |
| `area_code` | `char(3)` | yes | `NULL` |  |  |
| `prefix` | `char(3)` | yes | `NULL` |  |  |
| `number` | `varchar(4)` | yes | `NULL` |  |  |
| `type` | `int(11)` | yes | `NULL` |  |  |
| `foreign_id` | `int(11)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `foreign_id` |  | `foreign_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
