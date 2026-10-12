# `users_secure`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  |  |  |
| `username` | `varchar(255)` | yes | `NULL` |  |  |
| `password` | `varchar(255)` | yes | `NULL` |  |  |
| `last_update_password` | `datetime` | yes | `NULL` |  |  |
| `last_update` | `timestamp` | no | `current_timestamp()` | on update current_timestamp() |  |
| `password_history1` | `varchar(255)` | yes | `NULL` |  |  |
| `password_history2` | `varchar(255)` | yes | `NULL` |  |  |
| `password_history3` | `varchar(255)` | yes | `NULL` |  |  |
| `password_history4` | `varchar(255)` | yes | `NULL` |  |  |
| `last_challenge_response` | `datetime` | yes | `NULL` |  |  |
| `login_work_area` | `text` | yes | `NULL` |  |  |
| `total_login_fail_counter` | `bigint(20)` | yes | `0` |  |  |
| `login_fail_counter` | `int(11)` | yes | `0` |  |  |
| `last_login_fail` | `datetime` | yes | `NULL` |  |  |
| `auto_block_emailed` | `tinyint(4)` | yes | `0` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `USERNAME_ID` | yes | `id`, `username` |

## Changes since 7.0.0

- **7.0.2:** added `total_login_fail_counter` bigint(20); added `last_login_fail` datetime; added `auto_block_emailed` tinyint(4)

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
