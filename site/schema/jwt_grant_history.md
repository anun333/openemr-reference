# `jwt_grant_history`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. Holds JWT authorization grant ids to prevent replay attacks

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `jti` | `varchar(100)` | no |  |  | Unique JWT id |
| `client_id` | `varchar(80)` | no |  |  | FK oauth2_clients.client_id |
| `jti_exp` | `timestamp` | yes | `NULL` |  | jwt exp claim when the jwt expires |
| `creation_date` | `datetime` | no | `current_timestamp()` |  | datetime the grant authorization was requested |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `jti` |  | `jti` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
