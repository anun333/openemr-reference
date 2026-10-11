# `x12_remote_tracker`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `x12_partner_id` | `int(11)` | no |  |  |  |
| `x12_filename` | `varchar(255)` | no |  |  |  |
| `status` | `varchar(255)` | no |  |  |  |
| `claims` | `text` | yes | `NULL` |  |  |
| `messages` | `text` | yes | `NULL` |  |  |
| `created_at` | `datetime` | yes | `NULL` |  |  |
| `updated_at` | `datetime` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
