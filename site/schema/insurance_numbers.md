# `insurance_numbers`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no | `0` |  |  |
| `provider_id` | `int(11)` | no | `0` |  |  |
| `insurance_company_id` | `int(11)` | yes | `NULL` |  |  |
| `provider_number` | `varchar(20)` | yes | `NULL` |  |  |
| `rendering_provider_number` | `varchar(20)` | yes | `NULL` |  |  |
| `group_number` | `varchar(20)` | yes | `NULL` |  |  |
| `provider_number_type` | `varchar(4)` | yes | `NULL` |  |  |
| `rendering_provider_number_type` | `varchar(4)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
