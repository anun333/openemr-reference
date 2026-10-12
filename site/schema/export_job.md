# `export_job`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. fhir export jobs

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `user_id` | `varchar(40)` | no |  |  |  |
| `client_id` | `varchar(80)` | no |  |  |  |
| `status` | `varchar(40)` | no |  |  |  |
| `start_time` | `datetime` | yes | `NULL` |  |  |
| `resource_include_time` | `datetime` | yes | `NULL` |  |  |
| `output_format` | `varchar(128)` | no |  |  |  |
| `request_uri` | `varchar(128)` | no |  |  |  |
| `resources` | `text` | yes | `NULL` |  |  |
| `output` | `text` | yes | `NULL` |  |  |
| `errors` | `text` | yes | `NULL` |  |  |
| `access_token_id` | `text` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
