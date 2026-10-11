# `migrations`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `version` | `varchar(191)` | no |  |  |  |
| `executed_at` | `datetime` | yes | `NULL` |  |  |
| `execution_duration_ms` | `int(11)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `version` |

## Changes since 7.0.0

- **8.1.0:** table added

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
