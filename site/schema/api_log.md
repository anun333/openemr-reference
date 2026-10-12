# `api_log`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `log_id` | `int(11)` | no |  |  |  |
| `user_id` | `bigint(20)` | no |  |  |  |
| `client_id` | `varchar(80)` | no | `''` |  | oauth_clients.client_id of the API client that made the request |
| `patient_id` | `bigint(20)` | no |  |  |  |
| `ip_address` | `varchar(255)` | no |  |  |  |
| `method` | `varchar(20)` | no |  |  |  |
| `request` | `varchar(255)` | no |  |  |  |
| `request_url` | `text` | yes | `NULL` |  |  |
| `request_body` | `longtext` | yes | `NULL` |  |  |
| `response` | `longtext` | yes | `NULL` |  |  |
| `created_time` | `timestamp` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |

## Changes since 7.0.0

- **8.4.0:** added `client_id` varchar(80)

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
