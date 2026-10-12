# `oauth_trusted_user`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `user_id` | `varchar(80)` | yes | `NULL` |  |  |
| `client_id` | `varchar(80)` | yes | `NULL` |  |  |
| `scope` | `text` | yes | `NULL` |  |  |
| `persist_login` | `tinyint(1)` | yes | `0` |  |  |
| `time` | `timestamp` | yes | `NULL` |  |  |
| `code` | `text` | yes | `NULL` |  |  |
| `session_cache` | `text` | yes | `NULL` |  |  |
| `grant_type` | `varchar(32)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `accounts_id` |  | `user_id` |
| `clients_id` |  | `client_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
