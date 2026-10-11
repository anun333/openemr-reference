# `api_token`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `user_id` | `varchar(40)` | yes | `NULL` |  |  |
| `token` | `varchar(128)` | yes | `NULL` |  |  |
| `expiry` | `datetime` | yes | `NULL` |  |  |
| `client_id` | `varchar(80)` | yes | `NULL` |  |  |
| `scope` | `text` | yes | `NULL` |  | json encoded |
| `revoked` | `tinyint(1)` | no | `0` |  | 1=revoked,0=not revoked |
| `context` | `text` | yes | `NULL` |  | context values that change/govern how access token are used |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `token` | yes | `token` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
