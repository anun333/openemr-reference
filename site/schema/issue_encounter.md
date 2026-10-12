# `issue_encounter`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  | UUID for this issue encounter record, for data exchange purposes |
| `pid` | `bigint(20)` | no |  |  |  |
| `list_id` | `int(11)` | no |  |  |  |
| `encounter` | `int(11)` | no |  |  |  |
| `resolved` | `tinyint(1)` | no |  |  |  |
| `created_by` | `bigint(20)` | yes | `NULL` |  | fk to users.id for the user that entered in the issue encounter data |
| `updated_by` | `bigint(20)` | yes | `NULL` |  | fk to users.id for the user that last updated the issue encounter data |
| `created_at` | `datetime` | yes | `current_timestamp()` |  | timestamp when this issue encounter record was created |
| `updated_at` | `datetime` | yes | `current_timestamp()` | on update current_timestamp() | timestamp when this issue encounter record was last updated |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `uniq_issue_key` | yes | `pid`, `list_id`, `encounter` |
| `uuid_unique` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.4:** added `id` bigint(20); added `uuid` binary(16); added `created_by` bigint(20); added `updated_by` bigint(20); added `created_at` datetime; added `updated_at` datetime; index `uniq_issue_key` added (pid, list_id, encounter); index `uuid_unique` added (uuid)

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
