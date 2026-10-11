# `login_mfa_registrations`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `user_id` | `bigint(20)` | no |  |  |  |
| `name` | `varchar(30)` | no |  |  |  |
| `last_challenge` | `datetime` | yes | `NULL` |  |  |
| `method` | `varchar(31)` | no |  |  | Q&A, U2F, TOTP etc. |
| `var1` | `varchar(4096)` | no | `''` |  | Question, U2F registration etc. |
| `var2` | `varchar(256)` | no | `''` |  | Answer etc. |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `user_id`, `name` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
