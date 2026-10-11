# `uuid_mapping`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | no | `x'00000000000000000000000000000000'` |  |  |
| `resource` | `varchar(255)` | no | `''` |  |  |
| `resource_path` | `varchar(255)` | yes | `NULL` |  |  |
| `table` | `varchar(255)` | no | `''` |  |  |
| `target_uuid` | `binary(16)` | no | `x'00000000000000000000000000000000'` |  |  |
| `created` | `timestamp` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `resource` |  | `resource` |
| `table` |  | `table` |
| `target_uuid` |  | `target_uuid` |
| `uuid` |  | `uuid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
